# Android device and recovery tooling for the Galaxy S24 workflow.
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    android-tools # adb, fastboot, logcat
    heimdall # Samsung download-mode flashing/recovery utility
    simple-mtpfs # FUSE MTP mount helper; jmtpfs was removed from nixpkgs
    mtpfs # alternate MTP mount helper
    scrcpy # Android screen/control bridge over adb
  ];
}
