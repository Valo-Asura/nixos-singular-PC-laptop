# PC-specific Home Manager module: Guangxi monitor layout.
{ ... }:

{
  wayland.windowManager.hyprland.settings = {
    monitor = [
      "desc:Guangxi Century Innovation Display Electronics Co. Ltd 24FHDMIQII2G 0000000000001,1920x1080@165,0x0,1"
      "DP-1,1920x1080@165,0x0,1"
      ",preferred,auto,1"
    ];

    cursor = {
      default_monitor = "DP-1";
    };
  };
}
