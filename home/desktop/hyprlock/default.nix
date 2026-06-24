# Shared Home Manager module: Hyprlock settings are owned by the shared Hyprland tree.
{ ... }:

{
  imports = [
    ../hyprland/hyprlock.nix
  ];
}
