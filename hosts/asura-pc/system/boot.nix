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
      efi.canTouchEfiVariables = lib.mkForce false;
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

  system.activationScripts.preferSignedBootEntry.text = ''
    echo "Skipping EFI boot-order rewrite; boot.loader.efi.canTouchEfiVariables is disabled."
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
