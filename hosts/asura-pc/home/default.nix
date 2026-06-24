# PC-specific Home Manager module: host-only overrides.
{ ... }:

{
  imports = [
    ../hyprland/host.nix
    ../../../home/host-overrides/asura-pc.nix
  ];
}
