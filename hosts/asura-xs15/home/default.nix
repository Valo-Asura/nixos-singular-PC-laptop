# Laptop-specific Home Manager module: XS15 user overrides and monitor layout.
{ ... }:

{
  imports = [
    ../hyprland/host.nix
    ../../../home/host-overrides/asura-xs15.nix
  ];
}
