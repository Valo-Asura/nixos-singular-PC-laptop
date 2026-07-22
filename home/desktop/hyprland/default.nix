# Shared Home Manager module: Hyprland compositor defaults used by all Asura hosts.
{
  pkgs,
  lib,
  ...
}:
let
  border-size = 1;
  gaps-in = 4;
  gaps-out = 8;
  active-opacity = 1.0;
  inactive-opacity = 1.0;
  rounding = 10;
  blur = false;
  keyboardLayout = "us";
  border-color = "rgb(b4befe)";

  filePickerTitle = "^(.*(Open File|Open Folder|Choose Files|Choose Folder|File Upload|Save As|Select.*(File|Folder|Directory|extension directory)|Browse.*(File|Folder|Directory)|Library).*)$";

  startupCommands = [
    "dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_SESSION_ID XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS"
    "systemctl --user start skwd-daemon.service"
    "asura-apply-cursor-theme"
    "asura-monitor-guard --daemon"
    "asura-shell-switch autostart"
    "systemctl --user start hyprpolkitagent"
  ];
in
{
  imports = [
    ./animations.nix
    ./bindings.nix
    ./hyprlock.nix
    ./polkitagent.nix
    ./hypridle.nix
  ];

  xdg.configFile."hypr/hyprland.conf".force = true;

  home.packages = with pkgs; [
    brightnessctl
    libva
    qt6.qtwayland
    wayland-utils
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang";
    package = pkgs.hyprland;
    portalPackage = null;
    plugins = [ ];
    xwayland.enable = true;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
      variables = [
        "DISPLAY"
        "HYPRLAND_INSTANCE_SIGNATURE"
        "WAYLAND_DISPLAY"
        "XDG_CURRENT_DESKTOP"
        "XDG_SESSION_DESKTOP"
        "XDG_SESSION_TYPE"
        "XDG_SESSION_CLASS"
        "XDG_RUNTIME_DIR"
        "DBUS_SESSION_BUS_ADDRESS"
      ];
    };

    settings = {
      "exec-once" = startupCommands;

      cursor = {
        no_hardware_cursors = 2;
        inactive_timeout = 0;
        enable_hyprcursor = true;
        sync_gsettings_theme = true;
      };

      general = {
        resize_on_border = true;
        gaps_in = gaps-in;
        gaps_out = gaps-out;
        border_size = border-size;
        layout = "dwindle";
        "col.active_border" = border-color;
      };

      decoration = {
        active_opacity = active-opacity;
        inactive_opacity = inactive-opacity;
        rounding = rounding;
        "shadow:enabled" = false;
        blur = {
          enabled = blur;
          size = 3;
          passes = 1;
          new_optimizations = true;
        };
      };

      master = {
        new_status = "master";
        allow_small_split = true;
        mfact = 0.5;
      };

      dwindle = {
        force_split = 2;
        preserve_split = true;
        smart_split = false;
        smart_resizing = true;
      };

      "debug:vfr" = true;

      misc = {
        vrr = 1;
        animate_manual_resizes = false;
        animate_mouse_windowdragging = false;
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
        force_default_wallpaper = 0;
        focus_on_activate = true;
        enable_swallow = false;
        swallow_regex = "";
      };

      render = {
        direct_scanout = 2;
        cm_auto_hdr = 1;
      };

      input = {
        kb_layout = keyboardLayout;
        kb_options = "caps:escape";
        follow_mouse = 1;
        sensitivity = 0.5;
        repeat_delay = 300;
        repeat_rate = 50;
        numlock_by_default = true;
        touchpad = {
          natural_scroll = true;
          tap_button_map = "lrm";
          clickfinger_behavior = false;
        };
      };

      env = [
        "XDG_SESSION_TYPE,wayland"
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_DESKTOP,Hyprland"
        "XDG_SESSION_CLASS,user"
        "LANG,en_US.UTF-8"
        "MOZ_ENABLE_WAYLAND,1"
        "QT_QPA_PLATFORM,wayland;xcb"
        "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
        "ELECTRON_OZONE_PLATFORM_HINT,auto"
        "SDL_VIDEODRIVER,wayland,x11"
        "CLUTTER_BACKEND,wayland"
        "XCURSOR_SIZE,24"
        "XCURSOR_THEME,Bibata-Modern-Amber"
        "HYPRCURSOR_SIZE,24"
        "HYPRCURSOR_THEME,Bibata-Modern-Amber"
      ];

      gesture = [
        "3, horizontal, workspace"
        "4, horizontal, workspace"
      ];
    };

    extraConfig = "";
  };

  services.hyprpaper.enable = false;

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
