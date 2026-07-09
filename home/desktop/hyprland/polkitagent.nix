# Shared Home Manager module: Hyprland polkit agent startup.
{ lib, ... }:

{
  wayland.windowManager.hyprland.settings."exec-once" = lib.mkAfter [
    "systemctl --user start hyprpolkitagent"
  ];

  systemd.user.services.hyprpolkitagent = {
    Service = {
      Environment = [
        "VK_LOADER_DRIVERS_DISABLE=*nvidia*"
        "__EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json"
      ];
    };
  };
}
