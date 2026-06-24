# PC-specific Home Manager module: AOC HDMI monitor layout from hyprNixos-main.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:AOC 24G1WG4 0x000000A1,1920x1080@144,0x0,1"
      "HDMI-A-1,1920x1080@144,0x0,1"
      ",preferred,auto,1"
    ];

    cursor.default_monitor = "HDMI-A-1";
  };
}
