# Laptop VPN client integration.
{ lib, pkgs, ... }:

{
  networking.networkmanager.plugins = [
    pkgs.networkmanager-openvpn
  ];

  environment.systemPackages = [
    pkgs.proton-vpn
    pkgs.proton-vpn-cli
    pkgs.openvpn
    pkgs.wireguard-tools
  ];

  # Proton stores session credentials through the Linux Secret Service API.
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = lib.mkForce false;
  xdg.portal.config.common."org.freedesktop.impl.portal.Secret" = [ "gnome-keyring" ];
}
