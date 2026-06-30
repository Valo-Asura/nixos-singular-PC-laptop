# PC-specific module: removable filesystem support and NVMe root mount tuning.
{ ... }:

{
  # PC root filesystem is ext4 on NVMe. noatime/lazytime reduce metadata writes
  # and keep storage latency steadier under desktop workloads.
  fileSystems."/".options = [
    "noatime"
    "lazytime"
  ];

  boot.supportedFilesystems = [
    "ntfs"
    "exfat"
    "vfat"
  ];

  programs.fuse.userAllowOther = true;

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
          action.id == "org.freedesktop.udisks2.filesystem-mount" ||
          action.id == "org.freedesktop.udisks2.filesystem-unmount" ||
          action.id == "org.freedesktop.udisks2.encrypted-unlock" ||
          action.id == "org.freedesktop.udisks2.encrypted-lock" ||
          action.id == "org.freedesktop.udisks2.eject-media") {
        if (subject.isInGroup("wheel") || subject.isInGroup("storage")) {
          return polkit.Result.YES;
        }
      }
    });
  '';

  environment.variables.UDISKS2_MOUNT_OPTIONS = "uid=1000,gid=983,dmask=022,fmask=133";
}
