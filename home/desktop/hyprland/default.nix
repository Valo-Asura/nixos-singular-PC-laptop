# Shared Home Manager module: Hyprland compositor defaults used by all Asura hosts.
{
  pkgs,
  lib,
  ...
}:
let
  inherit (import ./lib.nix { inherit lib; })
    mkEnv
    mkGesture
    mkLayerRule
    mkStartupHook
    mkWindowRule
    ;

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

  staleHyprlangFiles = [
    "hyprland.conf"
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

  home.packages = with pkgs; [
    brightnessctl
    libva
    qt6.qtwayland
    wayland-utils
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";
    package = null;
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
      on = [ (mkStartupHook startupCommands) ];

      config = {
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
          col.active_border = border-color;
        };

        decoration = {
          active_opacity = active-opacity;
          inactive_opacity = inactive-opacity;
          rounding = rounding;
          shadow.enabled = false;
          motion_blur = {
            enabled = false;
            samples = 7;
          };
          blur = {
            enabled = blur;
            size = 3;
            passes = 1;
            new_optimizations = true;
          };
        };

        group = {
          groupbar = {
            disable_when_only = true;
          };
        };

        master = {
          new_status = "master";
          allow_small_split = true;
          mfact = 0.5;
          focus_master_on_close = true;
        };

        dwindle = {
          force_split = 2;
          preserve_split = true;
          smart_split = false;
          smart_resizing = true;
        };

        debug.vfr = true;

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
      };

      env = map mkEnv [
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
        (mkGesture 3 "horizontal" "workspace")
        (mkGesture 4 "horizontal" "workspace")
      ];

      window_rule = [
        (mkWindowRule "file-picker" { title = filePickerTitle; } {
          float = true;
          center = true;
          size = "1400 840";
          suppress_event = "maximize";
        })
        (mkWindowRule "auth-dialog" { title = "^(.*(Authentication Required|PolicyKit1).*)$"; } {
          float = true;
          center = true;
          size = "500 400";
        })
        (mkWindowRule "polkit-agent" {
          class = "^(polkit-gnome-authentication-agent-1|hyprpolkitagent|polkit-kde-authentication-agent-1)$";
        } {
          float = true;
          center = true;
          size = "500 400";
        })
        (mkWindowRule "archive-ui" {
          class = "^(org\\.kde\\.ark|ark|file-roller|org\\.gnome\\.FileRoller|xarchiver)$";
        } {
          float = true;
          center = true;
          size = "860 620";
        })
        (mkWindowRule "file-manager" {
          class = "^(pcmanfm-qt|Pcmanfm-qt|org\\.gnome\\.Nautilus|nautilus)$";
        } {
          float = true;
          center = true;
          size = "1100 740";
          suppress_event = "maximize";
        })
        (mkWindowRule "image-viewer" {
          class = "^(org\\.gnome\\.Loupe|loupe|org\\.kde\\.gwenview|Gwenview)$";
        } {
          float = true;
          center = true;
          size = "980 720";
        })
        (mkWindowRule "nautilus-preview" {
          class = "^(org\\.gnome\\.NautilusPreviewer|sushi)$";
        } {
          float = true;
          center = true;
          size = "900 640";
        })
        (mkWindowRule "system-monitor" {
          class = "^(asura-system-monitor|io\\.missioncenter\\.MissionCenter)$";
        } {
          float = true;
          center = true;
          size = "980 720";
        })
        (mkWindowRule "display-manager" {
          class = "^(asura-display-manager|nwg-displays|wdisplays)$";
        } {
          float = true;
          center = true;
          size = "1040 720";
        })
        (mkWindowRule "cloudflare-warp-class" {
          class = "^(Cloudflare Warp|cloudflare-warp|warp-taskbar|Warp)$";
        } {
          float = true;
          center = true;
          size = "760 940";
          suppress_event = "maximize";
        })
        (mkWindowRule "cloudflare-warp-title" {
          title = "^(Cloudflare Warp|Warp Taskbar|Warp)$";
        } {
          float = true;
          center = true;
          size = "760 940";
          suppress_event = "maximize";
        })
        (mkWindowRule "xdg-portal" {
          class = "^(xdg-desktop-portal-.*)$";
        } {
          float = true;
          center = true;
          size = "1400 840";
          suppress_event = "maximize";
        })
        (mkWindowRule "no-auto-hdr-media" {
          class = "^(mpv|obs|gamescope)$";
        } {
          no_auto_hdr = true;
        })
        (mkWindowRule "no-auto-hdr-steam" {
          title = "^(.*Steam.*)$";
        } {
          no_auto_hdr = true;
        })
      ];

      layer_rule = [
        (mkLayerRule "notifications" "notifications" {
          no_anim = true;
          ignore_alpha = 0.69;
        })
        (mkLayerRule "control-center" "control-center" {
          no_anim = true;
          ignore_alpha = 0.5;
        })
        (mkLayerRule "launcher" "launcher" {
          no_anim = true;
          ignore_alpha = 0.5;
        })
        (mkLayerRule "overview" "overview" {
          no_anim = true;
        })
        (mkLayerRule "session" "session" {
          no_anim = true;
        })
        (mkLayerRule "ags-shell" "^ags-.*$" {
          no_anim = true;
        })
      ];
    };
  };

  services.hyprpaper.enable = false;

  home.activation.removeStaleHyprlandConf = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
    for stale in ${
      lib.concatMapStringsSep " " (name: ''"$HOME/.config/hypr/${name}"'') staleHyprlangFiles
    }; do
      if [ -L "$stale" ] && ${pkgs.coreutils}/bin/readlink "$stale" | ${pkgs.gnugrep}/bin/grep -q '^/nix/store/'; then
        ${pkgs.coreutils}/bin/rm -f "$stale"
      fi
    done
  '';

  systemd.user.targets.hyprland-session.Unit.Wants = [ "xdg-desktop-autostart.target" ];
}
