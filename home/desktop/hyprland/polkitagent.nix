# Shared Home Manager module: Hyprland polkit agent startup.
{ lib, ... }:

{
  wayland.windowManager.hyprland.settings."exec-once" = lib.mkAfter [
    "systemctl --user start hyprpolkitagent"
  ];
}
