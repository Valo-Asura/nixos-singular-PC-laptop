# Laptop-specific Home Manager module: XS15 internal panel and fallback monitor layout.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:eDP-1,1920x1080@144,0x0,1"
      "eDP-1,1920x1080@144,0x0,1"
      ",preferred,auto,1"
    ];

    cursor.default_monitor = "eDP-1";
  };
}
