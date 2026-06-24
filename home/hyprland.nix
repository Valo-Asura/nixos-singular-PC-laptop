# Backward-compatible wrapper: shared Hyprland config now lives in home/desktop/hyprland.
{ ... }:

{
  imports = [
    ./desktop/hyprland
  ];
}
