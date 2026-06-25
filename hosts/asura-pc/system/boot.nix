# PC-specific module: bootloader, Secure Boot helper tools, Plymouth, boot params, and Windows boot entry.
{ lib, pkgs, ... }:

let
  pkiBundle = "/var/lib/sbctl";
  linuxEspPartUuid = "30d0727b-1228-439e-a04f-0d9402748e9d";
  windowsEspPartUuid = "98a6f918-4a0b-4479-a940-784bb92cfa77";

  circleHudPlymouth = pkgs.stdenvNoCC.mkDerivation {
    pname = "asura-pc-circle-hud-plymouth-theme";
    version = "local";
    src = ../plymouth/circle_hud;

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall

      theme_dir="$out/share/plymouth/themes/circle_hud"
      mkdir -p "$theme_dir"
      cp -a "$src"/. "$theme_dir"/
      chmod -R u+w "$theme_dir"

      cat > "$theme_dir/circle_hud.plymouth" <<EOF
      [Plymouth Theme]
      Name=circle_hud
      Description=Asura PC local circle HUD boot theme
      Comment=Local declarative copy from /etc/nixos/hosts/asura-pc/plymouth/circle_hud
      ModuleName=script

      [script]
      ImageDir=$theme_dir
      ScriptFile=$theme_dir/circle_hud.script
      EOF

      runHook postInstall
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
    tpm2-tools
  ];

  boot = {
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      stage1Greeting = "";
    };

    loader = {
      efi.canTouchEfiVariables = lib.mkForce true;
      timeout = 12;

      systemd-boot = {
        enable = lib.mkForce true;
        editor = false;
        consoleMode = "max";
        configurationLimit = 8;
        rebootForBitlocker = true;
      };

      grub.enable = false;
      limine.enable = false;
    };

    plymouth = {
      enable = true;
      theme = "circle_hud";
      themePackages = [ circleHudPlymouth ];
    };

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_level=3"
      "vt.global_cursor_default=0"
      "video=HDMI-A-1:1920x1080@144"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nowatchdog"
      "nmi_watchdog=0"
      "split_lock_detect=off"
      "cryptomgr.notests"
    ];
  };

  specialisation.rescue-no-nvidia.configuration = {
    boot = {
      plymouth.enable = lib.mkForce false;
      kernelParams = [
        "systemd.unit=multi-user.target"
        "plymouth.enable=0"
        "modprobe.blacklist=nvidia,nvidia_drm,nvidia_modeset,nvidia_uvm"
        "rd.systemd.show_status=true"
        "systemd.show_status=true"
        "loglevel=6"
      ];
    };
  };

  system.activationScripts.createSbctlKeys.text = ''
    if [ -f /etc/nixos/enable-sbctl-auto-create ]; then
      if [ ! -d ${pkiBundle} ]; then
        echo "Auto-creating Secure Boot keys (sbctl)..."
        ${pkgs.sbctl}/bin/sbctl create-keys || true
      else
        echo "sbctl key bundle already exists at ${pkiBundle}; skipping creation."
      fi
    fi
  '';

  system.activationScripts.cleanStaleLoaderEntries.text = ''
    entries_dir="/boot/loader/entries"
    boot_dir="/boot"

    if [ -d "$entries_dir" ]; then
      for entry in "$entries_dir"/*.conf; do
        [ -e "$entry" ] || continue
        name="$(${pkgs.coreutils}/bin/basename "$entry")"

        # Keep explicit Windows chainloaders. They do not reference NixOS kernels.
        if [ "$name" = "windows.conf" ]; then
          continue
        fi

        if ${pkgs.gnugrep}/bin/grep -Eiq 'Atlas|Limine|UEFI OS' "$entry"; then
          echo "Removing stale third-party loader entry: $entry"
          ${pkgs.coreutils}/bin/rm -f "$entry"
          continue
        fi

        missing_ref=0
        while IFS= read -r line; do
          set -- $line
          key="''${1:-}"
          path="''${2:-}"

          case "$key" in
            linux|initrd|efi|uki)
              [ -n "$path" ] || continue
              case "$path" in
                \#*) continue ;;
              esac

              relative="''${path#/}"
              if [ ! -e "$boot_dir/$relative" ]; then
                missing_ref=1
              fi
              ;;
          esac
        done < "$entry"

        if [ "$missing_ref" = 1 ]; then
          echo "Removing stale loader entry with missing boot file: $entry"
          ${pkgs.coreutils}/bin/rm -f "$entry"
        fi
      done
    fi
  '';

  system.activationScripts.cleanStaleEfiBootEntries.text = ''
    if [ ! -d /sys/firmware/efi/efivars ]; then
      exit 0
    fi

    status="$(${pkgs.efibootmgr}/bin/efibootmgr -v 2>/dev/null || true)"
    if [ -z "$status" ]; then
      exit 0
    fi

    printf '%s\n' "$status" \
      | ${pkgs.gawk}/bin/awk '
        /^Boot[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f][* ]/ {
          id = substr($1, 5, 4)
          desc = substr($0, index($0, $2))
          print id "\t" desc
        }
      ' \
      | while IFS="$(printf '\t')" read -r id desc; do
        [ -n "$id" ] || continue

        should_delete=0
        case "$desc" in
          Windows\ Boot\ Manager*)
            should_delete=0
            ;;
          Limine*|UEFI\ OS*|*Atlas*)
            should_delete=1
            ;;
        esac

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -Eiq '\\EFI\\nixos\\|/EFI/nixos/'; then
          should_delete=1
        fi

        if printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -q '^Linux Boot Manager' \
          && ! printf '%s\n' "$desc" | ${pkgs.gnugrep}/bin/grep -qi '${linuxEspPartUuid}'; then
          should_delete=1
        fi

        if [ "$should_delete" = 1 ]; then
          echo "Removing stale EFI boot entry Boot$id: $desc"
          ${pkgs.efibootmgr}/bin/efibootmgr -b "$id" -B || true
        fi
      done

    status="$(${pkgs.efibootmgr}/bin/efibootmgr -v 2>/dev/null || true)"
    linux_entry="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i "Linux Boot Manager.*${linuxEspPartUuid}" | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/head -n1)"
    windows_entries="$(printf '%s\n' "$status" | ${pkgs.gnugrep}/bin/grep -i '^Boot[0-9A-Fa-f]\{4\}.*Windows Boot Manager' | ${pkgs.gnused}/bin/sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | ${pkgs.coreutils}/bin/paste -sd, -)"
    current_order="$(printf '%s\n' "$status" | ${pkgs.gnused}/bin/sed -n 's/^BootOrder: //p' | ${pkgs.coreutils}/bin/head -n1)"

    if [ -z "$linux_entry" ] || [ -z "$current_order" ]; then
      exit 0
    fi

    rest="$(printf '%s\n' "$current_order" \
      | ${pkgs.gawk}/bin/awk -v linux="$linux_entry" -v windows="$windows_entries" '
        BEGIN {
          RS = ","
          ORS = ""
          split(windows, win, ",")
          for (i in win) skip[win[i]] = 1
          skip[linux] = 1
        }
        $0 != "" && !($0 in skip) {
          if (out != "") out = out ","
          out = out $0
        }
        END { print out }
      ')"

    new_order="$linux_entry"
    if [ -n "$windows_entries" ]; then
      new_order="$new_order,$windows_entries"
    fi
    if [ -n "$rest" ]; then
      new_order="$new_order,$rest"
    fi

    if [ "$new_order" != "$current_order" ]; then
      ${pkgs.efibootmgr}/bin/efibootmgr -o "$new_order" || true
    fi
  '';

  system.activationScripts.syncWindowsBootEntry.text = ''
    windows_esp="/dev/disk/by-partuuid/${windowsEspPartUuid}"
    mount_dir="$(${pkgs.coreutils}/bin/mktemp -d)"

    if [ -d /boot/loader/entries ]; then
      ${pkgs.coreutils}/bin/rm -f /boot/loader/entries/*[Aa]tlas*.conf
    fi

    cleanup() {
      ${pkgs.util-linux}/bin/umount "$mount_dir" >/dev/null 2>&1 || true
      ${pkgs.coreutils}/bin/rmdir "$mount_dir" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    if [ -e "$windows_esp" ] && ${pkgs.util-linux}/bin/mount -o ro "$windows_esp" "$mount_dir" >/dev/null 2>&1; then
      if [ -f "$mount_dir/EFI/Microsoft/Boot/bootmgfw.efi" ]; then
        ${pkgs.coreutils}/bin/mkdir -p /boot/EFI/Microsoft /boot/loader/entries
        ${pkgs.coreutils}/bin/rm -rf /boot/EFI/Microsoft/Boot
        ${pkgs.coreutils}/bin/cp -a "$mount_dir/EFI/Microsoft/Boot" /boot/EFI/Microsoft/Boot
        ${pkgs.coreutils}/bin/cat > /boot/loader/entries/windows.conf <<'EOF'
title Windows Boot Manager
efi /EFI/Microsoft/Boot/bootmgfw.efi
sort-key z_windows
EOF
      fi
    fi
  '';
}
