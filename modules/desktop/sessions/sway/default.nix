# Shared session factory: experimental Sway + Noctalia v5 Wayland session.
#
# This replaces the old Labwc experiment in the login menu. It keeps Sway
# minimal: no swaybar, no skwd-wall daemon, static wallpaper via Sway output
# config, and guarded Noctalia startup.
{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  wallpaper = ../bspwm/assets/tokyo.png;

  libinputGesturesConfig = pkgs.writeText "asura-sway-libinput-gestures.conf" ''
    gesture swipe left 3 ${pkgs.sway}/bin/swaymsg workspace next_on_output
    gesture swipe right 3 ${pkgs.sway}/bin/swaymsg workspace prev_on_output
    gesture swipe left 4 ${pkgs.sway}/bin/swaymsg workspace next_on_output
    gesture swipe right 4 ${pkgs.sway}/bin/swaymsg workspace prev_on_output
  '';

  workspaceKeybinds = lib.concatMapStringsSep "\n" (
    workspace:
    let
      name = toString workspace;
      key = if workspace == 10 then "0" else name;
    in
    ''
      bindsym $mod+${key} workspace number ${name}
      bindsym $mod+Shift+${key} move container to workspace number ${name}; workspace number ${name}
    ''
  ) (lib.range 1 10);

  noctaliaPanel = panel: "sh -lc 'noctalia msg panel-toggle ${panel} || true'";

  autostart = pkgs.writeShellScript "asura-sway-noctalia-autostart" ''
    set -u

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/sway"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/sway"
    else
      state_dir="/tmp/asura-sway-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"

    systemctl --user --no-block start sway-session.target >/dev/null 2>&1 || true

    ${pkgs.procps}/bin/pkill -xu "''${USER:-asura}" -f "libinput-gestures.*asura-sway-libinput-gestures.conf" >/dev/null 2>&1 || true
    ${pkgs.libinput-gestures}/bin/libinput-gestures -c ${libinputGesturesConfig} >>"$state_dir/libinput-gestures.log" 2>&1 &

    if systemctl --user --quiet is-active noctalia.service >/dev/null 2>&1; then
      exit 0
    fi

    if systemctl --user list-unit-files noctalia.service >/dev/null 2>&1; then
      systemctl --user start noctalia.service >>"$state_dir/noctalia-service.log" 2>&1 || true
      exit 0
    fi

    if ! pgrep -xu "''${USER:-asura}" noctalia >/dev/null 2>&1; then
      nohup ${noctaliaPackage}/bin/noctalia >>"$state_dir/noctalia.log" 2>&1 &
    fi
  '';

  configFile = pkgs.writeText "asura-sway-noctalia.conf" ''
    set $mod Mod4
    set $term ${pkgs.foot}/bin/foot
    set $menu ${pkgs.rofi}/bin/rofi -show drun

    font pango:JetBrainsMono Nerd Font 10
    default_border pixel 1
    default_floating_border pixel 1
    hide_edge_borders smart
    gaps inner 4
    gaps outer 8
    smart_gaps on
    smart_borders on
    focus_follows_mouse yes
    mouse_warping none
    floating_modifier $mod normal
    workspace_layout default
    xwayland enable

    output * bg ${wallpaper} fill
    seat * xcursor_theme Bibata-Modern-Amber 24

    input type:keyboard {
      xkb_layout us
      xkb_options caps:escape
      repeat_delay 300
      repeat_rate 50
    }

    input type:touchpad {
      natural_scroll enabled
      tap enabled
      tap_button_map lrm
      click_method clickfinger
      scroll_method two_finger
      dwt enabled
    }

    exec dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS
    exec systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS
    exec ${autostart}

    bindsym $mod+q kill
    bindsym $mod+h exec swaymsg exit
    bindsym $mod+f exec sh -lc 'asura-file-manager "$HOME"'
    bindsym $mod+g fullscreen toggle
    bindsym $mod+b exec ${pkgs.brave}/bin/brave
    bindsym $mod+t exec $term
    bindsym $mod+Return exec $term
    bindsym $mod+c exec code --ozone-platform=wayland
    bindsym $mod+a exec ${noctaliaPanel "control-center"}
    bindsym $mod+space exec sh -lc 'noctalia msg panel-toggle launcher || ${pkgs.rofi}/bin/rofi -show drun'
    bindsym $mod+e exec ${pkgs.telegram-desktop}/bin/telegram-desktop
    bindsym $mod+w exec sh -lc 'noctalia msg panel-toggle wallpaper || true'
    bindsym $mod+p exec asura-display-manager
    bindsym $mod+Shift+p exec asura-monitor-guard --restore
    bindsym Ctrl+l exec asura-session-lock
    bindsym $mod+l exec asura-session-lock
    bindsym $mod+v exec ${noctaliaPanel "clipboard"}
    bindsym $mod+Shift+v floating toggle; sticky toggle
    bindsym $mod+Shift+c exec clipboard
    bindsym $mod+Shift+e exec ${noctaliaPanel "emoji"}
    bindsym $mod+Shift+s exec asura-screenshot region
    bindsym $mod+Shift+w exec sh -lc 'noctalia msg panel-toggle wallpaper || true'
    bindsym $mod+Shift+r exec /run/current-system/sw/bin/asura-screen-record-toggle
    bindsym $mod+Shift+x exec asura-screenshot region-edit
    bindsym $mod+F2 exec night-shift
    bindsym $mod+n exec ${noctaliaPanel "control-center"}
    bindsym $mod+d exec ${noctaliaPanel "control-center"}
    bindsym $mod+s exec ${noctaliaPanel "control-center"}
    bindsym Ctrl+Mod1+Delete exec ${noctaliaPanel "session"}
    bindsym $mod+BackSpace exec ${noctaliaPanel "session"}
    bindsym $mod+period exec ${noctaliaPanel "emoji"}
    bindsym Ctrl+$mod+r reload

    bindsym Print exec asura-screenshot full
    bindsym Shift+Print exec asura-screenshot region
    bindsym $mod+Print exec asura-screenshot output
    bindsym $mod+Shift+Print exec asura-screenshot region-edit

    bindsym $mod+Left focus left
    bindsym $mod+Down focus down
    bindsym $mod+Up focus up
    bindsym $mod+Right focus right
    bindsym $mod+Shift+Left move left
    bindsym $mod+Shift+Down move down
    bindsym $mod+Shift+Up move up
    bindsym $mod+Shift+Right move right
    bindsym $mod+Ctrl+Left workspace prev_on_output
    bindsym $mod+Ctrl+Right workspace next_on_output
    bindsym Mod1+Tab focus next
    bindsym Mod1+Shift+Tab focus prev
    bindsym $mod+Tab focus next
    bindsym $mod+Shift+Tab focus prev

    ${workspaceKeybinds}

    bindsym XF86AudioMute exec sound-toggle
    bindsym XF86AudioPlay exec ${pkgs.playerctl}/bin/playerctl play-pause
    bindsym XF86AudioNext exec ${pkgs.playerctl}/bin/playerctl next
    bindsym XF86AudioPrev exec ${pkgs.playerctl}/bin/playerctl previous
    bindsym F3 exec sound-toggle
    bindsym F5 exec sound-down
    bindsym F6 exec sound-up
    bindsym F8 exec brightness-down
    bindsym F9 exec brightness-up
    bindsym F10 exec asura-camera-app
    bindsym F11 exec asura-airplane-toggle
    bindsym F12 exec night-shift
    bindsym XF86AudioRaiseVolume exec sound-up
    bindsym XF86AudioLowerVolume exec sound-down
    bindsym XF86MonBrightnessUp exec brightness-up
    bindsym XF86MonBrightnessDown exec brightness-down

    for_window [app_id="foot"] inhibit_idle visible
    for_window [app_id="org.gnome.Nautilus"] floating enable
    for_window [app_id="pcmanfm-qt"] floating enable
    for_window [app_id="org.gnome.Loupe"] floating enable
    for_window [app_id="xdg-desktop-portal-gtk"] floating enable
    for_window [title="Authentication Required"] floating enable, move position center
    for_window [window_role="pop-up"] floating enable
    for_window [window_role="bubble"] floating enable
    for_window [window_type="dialog"] floating enable
    for_window [window_type="utility"] floating enable
  '';

  start = pkgs.writeShellScriptBin "asura-start-sway-noctalia" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/sway"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/sway"
    else
      state_dir="/tmp/asura-sway-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/session.log" 2>&1

    echo "---- sway + noctalia session: $(date -Is) ----"

    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/asura/bin:$PATH"
    export PATH="${
      lib.makeBinPath [
        noctaliaPackage
        pkgs.brave
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.dbus
        pkgs.foot
        pkgs.libinput-gestures
        pkgs.libnotify
        pkgs.playerctl
        pkgs.procps
        pkgs.rofi
        pkgs.sway
        pkgs.swaybg
        pkgs.telegram-desktop
        pkgs.wl-clipboard
        pkgs.xwayland
      ]
    }:$PATH"

    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_DESKTOP=sway
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland,x11
    export QT_QPA_PLATFORM="wayland;xcb"
    export SDL_VIDEODRIVER=wayland
    export MOZ_ENABLE_WAYLAND=1

    dbus-update-activation-environment --systemd \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true
    systemctl --user import-environment \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true

    exec ${pkgs.sway}/bin/sway --config ${configFile}
  '';
in
{
  inherit start;

  desktopEntry = ''
    [Desktop Entry]
    Name=Noctalia + Sway
    Comment=Experimental Sway Wayland session with guarded Noctalia v5 startup
    Exec=${start}/bin/asura-start-sway-noctalia
    Type=Application
  '';

  packages = [
    start
    noctaliaPackage
    pkgs.foot
    pkgs.libinput-gestures
    pkgs.rofi
    pkgs.sway
    pkgs.swaybg
    pkgs.wl-clipboard
    pkgs.xwayland
  ];
}
