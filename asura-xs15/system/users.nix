# User Configuration
{ pkgs, ... }:

{
  users = {
    users.asura = {
      isNormalUser = true;
      description = "asura";
      group = "asura";
      shell = pkgs.fish;
      linger = true;
      extraGroups = [
        "networkmanager"
        "wheel"
        "storage"
        "audio"
        "video"
        "input"
        "power"
        "docker"
        "libvirtd"
        "kvm"
      ];
    };
    groups.asura = { };
  };
}
