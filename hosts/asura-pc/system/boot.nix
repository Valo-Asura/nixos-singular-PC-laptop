# PC-specific module: Limine bootloader with Secure Boot, Plymouth, and boot params.
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

  cleanStaleLoaderEntries = pkgs.writeShellScriptBin "asura-pc-clean-loader-entries" ''
    set -u

    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.gnugrep
      ]
    }

    entries_dir="/boot/loader/entries"
    boot_dir="/boot"

    [ -d "$entries_dir" ] || exit 0

    for entry in "$entries_dir"/*.conf; do
      [ -e "$entry" ] || continue
      name="$(basename "$entry")"

      # Keep explicit Windows chainloaders. They do not reference NixOS kernels.
      if [ "$name" = "windows.conf" ]; then
        continue
      fi

      if grep -Eiq 'Atlas|Limine|UEFI OS|rescue-no-nvidia' "$entry"; then
        echo "Removing stale third-party loader entry: $entry"
        rm -f "$entry"
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
        rm -f "$entry"
      fi
    done
  '';

  cleanStaleEfiBootEntries = pkgs.writeShellScriptBin "asura-pc-clean-efi-boot-entries" ''
    set -u

    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.efibootmgr
        pkgs.gawk
        pkgs.gnugrep
        pkgs.gnused
      ]
    }

    [ -d /sys/firmware/efi/efivars ] || exit 0

    status="$(efibootmgr -v 2>/dev/null || true)"
    [ -n "$status" ] || exit 0

    printf '%s\n' "$status" \
      | awk '
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
            # Keep the real Windows firmware entry, but remove duplicate
            # Windows entries accidentally registered against the Linux ESP.
            if printf '%s\n' "$desc" | grep -qi '${linuxEspPartUuid}'; then
              should_delete=1
            fi
            ;;
          UEFI\ OS*|*Atlas*)
            should_delete=1
            ;;
        esac

        if printf '%s\n' "$desc" | grep -Fqi '\EFI\nixos\' \
          || printf '%s\n' "$desc" | grep -Fqi '/EFI/nixos/'; then
          should_delete=1
        fi

        if printf '%s\n' "$desc" | grep -q '^Linux Boot Manager'; then
          should_delete=1
        fi

        if [ "$should_delete" = 1 ]; then
          echo "Removing stale EFI boot entry Boot$id: $desc"
          efibootmgr -b "$id" -B || true
        fi
      done

    status="$(efibootmgr -v 2>/dev/null || true)"
    limine_entry="$(printf '%s\n' "$status" | grep -i "Limine.*${linuxEspPartUuid}" | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | head -n1)"
    windows_entries="$(printf '%s\n' "$status" | grep -i '^Boot[0-9A-Fa-f]\{4\}.*Windows Boot Manager' | sed -n 's/^Boot\([0-9A-Fa-f]\{4\}\).*/\1/p' | paste -sd, -)"
    current_order="$(printf '%s\n' "$status" | sed -n 's/^BootOrder: //p' | head -n1)"

    [ -n "$limine_entry" ] || exit 0
    [ -n "$current_order" ] || exit 0

    new_order="$limine_entry"
    if [ -n "$windows_entries" ]; then
      new_order="$new_order,$windows_entries"
    fi

    if [ "$new_order" != "$current_order" ]; then
      efibootmgr -o "$new_order" || true
    fi
  '';

  cleanStaleEfiFiles = pkgs.writeShellScriptBin "asura-pc-clean-stale-efi-files" ''
    set -u

    export PATH=${
      lib.makeBinPath [
        pkgs.coreutils
      ]
    }

    for stale in \
      /boot/EFI/BOOT \
      /boot/EFI/Microsoft \
      /boot/EFI/nixos \
      /boot/EFI/systemd
    do
      if [ -e "$stale" ]; then
        echo "Removing stale EFI path from Linux ESP: $stale"
        rm -rf -- "$stale"
      fi
    done
  '';

  cleanBootEntries = pkgs.writeShellScriptBin "asura-pc-clean-boot-entries" ''
    set -u

    ${cleanStaleEfiFiles}/bin/asura-pc-clean-stale-efi-files || true
    ${cleanStaleLoaderEntries}/bin/asura-pc-clean-loader-entries || true
    ${cleanStaleEfiBootEntries}/bin/asura-pc-clean-efi-boot-entries || true
  '';
in
{
  environment.systemPackages = with pkgs; [
    sbctl
    efibootmgr
    tpm2-tools
    cleanBootEntries
  ];

  boot = {
    consoleLogLevel = 0;
    initrd = {
      systemd.enable = lib.mkForce true;
      verbose = false;
    };

    loader = {
      efi.canTouchEfiVariables = lib.mkForce true;
      timeout = 12;

      # Limine handles native Secure Boot on the PC host.
      limine = {
        enable = true;
        secureBoot.enable = true;
        extraEntries = ''
          /Windows Boot Manager
            protocol: efi
            path: guid(${windowsEspPartUuid}):/EFI/Microsoft/Boot/bootmgfw.efi
            if_fw_type: UEFI
        '';
      };

      systemd-boot.enable = lib.mkForce false;
      grub.enable = false;
    };

    plymouth = {
      enable = lib.mkForce true;
      theme = "circle_hud";
      themePackages = [ circleHudPlymouth ];
    };

    kernelParams = [
      "quiet"
      "splash"
      "loglevel=0"
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
    ${cleanStaleLoaderEntries}/bin/asura-pc-clean-loader-entries || true
  '';

  system.activationScripts.cleanStaleEfiBootEntries.text = ''
    ${cleanStaleEfiBootEntries}/bin/asura-pc-clean-efi-boot-entries || true
  '';

  system.activationScripts.cleanStaleEfiFiles.text = ''
    ${cleanStaleEfiFiles}/bin/asura-pc-clean-stale-efi-files || true
  '';
}
