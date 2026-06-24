# PC-specific module: Windows drive helper commands from the PC config.
{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "find-windows-drives" ''
      set -euo pipefail

      echo "Scanning for Windows drives"
      echo "==========================="
      lsblk -f | grep -E "(ntfs|exfat|vfat)" || echo "No Windows drives found"

      echo
      echo "Available mount points:"
      ls -la /media/ 2>/dev/null || echo "No mounted drives in /media/"

      echo
      echo "Manual mount example:"
      echo "sudo mkdir -p /media/windows"
      echo "sudo mount -t ntfs3 /dev/sdXY /media/windows"
    '')

    (pkgs.writeShellScriptBin "mount-windows" ''
      set -euo pipefail

      mode="rw"
      if [ "''${1:-}" = "--ro" ] || [ "''${1:-}" = "-r" ]; then
        mode="ro"
        shift
      fi

      if [ -z "''${1:-}" ]; then
        echo "Usage: mount-windows [--ro] /dev/sdXY [mount-point]"
        exit 1
      fi

      device="$1"
      mount_point="''${2:-/media/windows}"
      options="uid=$(id -u),gid=$(id -g),dmask=022,fmask=133"
      if [ "$mode" = "ro" ]; then
        options="ro,$options"
      fi

      sudo mkdir -p "$mount_point"
      if sudo mount -t ntfs3 -o "$options" "$device" "$mount_point"; then
        echo "Mounted $device to $mount_point ($mode)"
        exit 0
      fi

      if [ "$mode" = "rw" ]; then
        echo "Read-write mount failed. Trying read-only."
        if sudo mount -t ntfs3 -o "ro,uid=$(id -u),gid=$(id -g),dmask=022,fmask=133" "$device" "$mount_point"; then
          echo "Mounted read-only at $mount_point"
          echo "For write access, repair the NTFS volume from Windows with chkdsk."
          exit 0
        fi
      fi

      echo "Failed to mount $device"
      exit 1
    '')
  ];
}
