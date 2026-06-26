# Shared module: greetd display manager, Hyprland entry, and X11 fallback sessions.
{ ... }:

{
  imports = [
    ./sources/display-manager.nix
  ];
}
