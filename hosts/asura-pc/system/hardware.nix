# PC-specific module: AMD CPU, NVIDIA desktop GPU, Broadcom Wi-Fi, and camera loopback.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  broadcomSta = config.boot.kernelPackages.broadcom_sta.overrideAttrs (oldAttrs: {
    patches = (oldAttrs.patches or [ ]) ++ [
      ./patches/broadcom-sta-linux-7.1-cfg80211-wdev.patch
    ];
  });
  pinnedNvidiaPackage = config.boot.kernelPackages.nvidiaPackages.mkDriver {
    version = "580.159.04";
    sha256_64bit = "sha256-weZnYbCI0Xs632y2l53przi+JoTRArABoXbc+vq9yh4=";
    sha256_aarch64 = "sha256-iRLyYjvHyDl2Xzb87j20o1MYNKLK/zql1JwSWbI3Kus=";
    openSha256 = "sha256-zsNmjZW0cyZWPp3vDT3mNeqAo0hS0M7e9Tbvwvij+F4=";
    settingsSha256 = "sha256-U0hics4gQeZWsD+ch9PBz42zfTOEVcKRVIqYZb3VOY8=";
    persistencedSha256 = "sha256-vDawiy52GB8JABUKZDiQUc8uda8p/7jCFW7rTu6QMa4=";
  };
in
{
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
    i2c.enable = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        nvidia-vaapi-driver
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    nvidia = {
      modesetting.enable = lib.mkForce true;
      powerManagement.enable = false;
      nvidiaPersistenced = false;
      open = lib.mkForce false;
      nvidiaSettings = true;
      # Pin the validated 580 LTSB build instead of following the moving
      # legacy_580 alias, which can force large proprietary downloads mid-update.
      package = pinnedNvidiaPackage;
      prime = {
        offload.enable = lib.mkForce false;
        sync.enable = lib.mkForce false;
        reverseSync.enable = lib.mkForce false;
      };
    };
  };

  boot.extraModulePackages = [
    broadcomSta
    config.boot.kernelPackages.v4l2loopback
  ];

  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=9 card_label="OBS Virtual Camera" exclusive_caps=1
  '';

  # Load NVIDIA after the real root is mounted. The PC does not need the
  # proprietary NVIDIA stack in initrd, and early KMS made boot failures look
  # like a Plymouth hang.
  boot.initrd.kernelModules = [ ];

  boot.kernelModules = [
    "wl"
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
    "v4l2loopback"
  ];

  boot.blacklistedKernelModules = [
    "b43"
    "b43legacy"
    "ssb"
    "bcma"
    "brcm80211"
    "brcmfmac"
    "brcmsmac"
  ];
}
