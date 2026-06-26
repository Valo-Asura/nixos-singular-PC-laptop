# Login Manager Configuration
{
  config,
  lib,
  pkgs,
  ...
}:

let
  quietHyprlandSession = pkgs.writeShellScript "asura-start-hyprland-quiet" ''
    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/hyprland"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/hyprland"
    else
      state_dir="/tmp/asura-hyprland-''${UID:-session}"
    fi

    if ! mkdir -p "$state_dir" 2>/dev/null; then
      state_dir="/tmp"
    fi

    exec ${config.programs.hyprland.package}/bin/start-hyprland >>"$state_dir/session.log" 2>&1
  '';

  qtileConfig = pkgs.writeText "asura-qtile-config.py" ''
    from libqtile import bar, layout, widget
    from libqtile.config import Group, Key, Screen
    from libqtile.lazy import lazy

    mod = "mod4"
    terminal = "foot"

    keys = [
        Key([mod], "Return", lazy.spawn(terminal), desc="Open terminal"),
        Key([mod], "d", lazy.spawn("rofi -show drun"), desc="Open launcher"),
        Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),
        Key([mod], "q", lazy.window.kill(), desc="Close focused window"),
        Key([mod, "control"], "r", lazy.reload_config(), desc="Reload Qtile"),
        Key([mod, "shift"], "e", lazy.shutdown(), desc="Quit Qtile"),
        Key([mod], "h", lazy.layout.left(), desc="Focus left"),
        Key([mod], "j", lazy.layout.down(), desc="Focus down"),
        Key([mod], "k", lazy.layout.up(), desc="Focus up"),
        Key([mod], "l", lazy.layout.right(), desc="Focus right"),
        Key([mod, "shift"], "h", lazy.layout.shuffle_left(), desc="Move left"),
        Key([mod, "shift"], "j", lazy.layout.shuffle_down(), desc="Move down"),
        Key([mod, "shift"], "k", lazy.layout.shuffle_up(), desc="Move up"),
        Key([mod, "shift"], "l", lazy.layout.shuffle_right(), desc="Move right"),
    ]

    groups = [Group(str(i)) for i in range(1, 10)]
    for group in groups:
        keys.extend(
            [
                Key([mod], group.name, lazy.group[group.name].toscreen(), desc=f"Switch to group {group.name}"),
                Key([mod, "shift"], group.name, lazy.window.togroup(group.name, switch_group=True), desc=f"Move window to group {group.name}"),
            ]
        )

    layouts = [
        layout.MonadTall(border_focus="#ff8080", border_normal="#1e1e2e", border_width=2, margin=6),
        layout.Max(),
    ]

    widget_defaults = dict(font="JetBrainsMono Nerd Font", fontsize=12, padding=4)
    extension_defaults = widget_defaults.copy()

    screens = [
        Screen(
            top=bar.Bar(
                [
                    widget.GroupBox(active="#f8c3d4", inactive="#81717d", highlight_method="line"),
                    widget.WindowName(foreground="#f5e0dc"),
                    widget.Systray(),
                    widget.Clock(format="%I:%M %p", foreground="#f8c3d4"),
                ],
                28,
                background="#191724",
            )
        )
    ]

    follow_mouse_focus = True
    bring_front_click = False
    cursor_warp = False
    auto_fullscreen = True
    focus_on_window_activation = "smart"
    wmname = "LG3D"
  '';

  qtileStart = pkgs.writeShellScriptBin "asura-start-qtile" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/x11qtile"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/x11qtile"
    else
      state_dir="/tmp/asura-x11qtile-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/session.log" 2>&1

    echo "---- qtile fallback session: $(date -Is) ----"

    export PATH="${
      lib.makeBinPath [
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.dunst
        pkgs.feh
        pkgs.foot
        pkgs.libnotify
        pkgs.pamixer
        pkgs.playerctl
        pkgs.procps
        pkgs.python3Packages.qtile
        pkgs.rofi
        pkgs.xsetroot
      ]
    }:$PATH"
    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=Qtile
    export XDG_SESSION_DESKTOP=Qtile
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    export NIXOS_OZONE_WL=0

    dbus-update-activation-environment --systemd \
      DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL >/dev/null 2>&1 || true
    systemctl --user import-environment \
      DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL >/dev/null 2>&1 || true

    ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr -solid "#191724" || true
    ${pkgs.dunst}/bin/dunst >>"$state_dir/dunst.log" 2>&1 &

    config_file="${qtileConfig}"
    user_config="''${XDG_CONFIG_HOME:-$HOME/.config}/x11qtile/qtile/config.py"
    if [ -r "$user_config" ]; then
      config_file="$user_config"
    fi

    if ! ${pkgs.python3Packages.qtile}/bin/qtile check -c "$config_file"; then
      echo "qtile check failed for $config_file; falling back to generated config"
      config_file="${qtileConfig}"
    fi

    exec ${pkgs.python3Packages.qtile}/bin/qtile start -b x11 -c "$config_file"
  '';

  bspwmConfig = pkgs.writeShellScript "asura-bspwmrc" ''
    ${pkgs.bspwm}/bin/bspc monitor -d 1 2 3 4 5 6 7 8 9
    ${pkgs.bspwm}/bin/bspc config border_width 2
    ${pkgs.bspwm}/bin/bspc config window_gap 8
    ${pkgs.bspwm}/bin/bspc config split_ratio 0.52
    ${pkgs.bspwm}/bin/bspc config borderless_monocle true
    ${pkgs.bspwm}/bin/bspc config gapless_monocle true
    ${pkgs.bspwm}/bin/bspc config focus_follows_pointer true
    ${pkgs.bspwm}/bin/bspc config normal_border_color "#1e1e2e"
    ${pkgs.bspwm}/bin/bspc config active_border_color "#f8c3d4"
    ${pkgs.bspwm}/bin/bspc config focused_border_color "#ff8080"
    ${pkgs.bspwm}/bin/bspc rule -a Gimp desktop='^8' state=floating follow=on
    ${pkgs.bspwm}/bin/bspc rule -a Pavucontrol state=floating
    ${pkgs.bspwm}/bin/bspc rule -a Blueman-manager state=floating
  '';

  sxhkdConfig = pkgs.writeText "asura-sxhkdrc" ''
    super + Return
      ${pkgs.foot}/bin/foot

    super + d
      ${pkgs.rofi}/bin/rofi -show drun

    super + shift + q
      ${pkgs.bspwm}/bin/bspc node -c

    super + alt + r
      ${pkgs.bspwm}/bin/bspc wm -r

    super + shift + e
      ${pkgs.bspwm}/bin/bspc quit

    super + {h,j,k,l}
      ${pkgs.bspwm}/bin/bspc node -f {west,south,north,east}

    super + shift + {h,j,k,l}
      ${pkgs.bspwm}/bin/bspc node -s {west,south,north,east}

    super + {1-9}
      ${pkgs.bspwm}/bin/bspc desktop -f '^{1-9}'

    super + shift + {1-9}
      ${pkgs.bspwm}/bin/bspc node -d '^{1-9}'
  '';

  bspwmStart = pkgs.writeShellScriptBin "asura-start-bspwm" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/bspwm"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/bspwm"
    else
      state_dir="/tmp/asura-bspwm-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/session.log" 2>&1

    echo "---- bspwm fallback session: $(date -Is) ----"

    export PATH="${
      lib.makeBinPath [
        pkgs.bspwm
        pkgs.coreutils
        pkgs.dunst
        pkgs.feh
        pkgs.foot
        pkgs.libnotify
        pkgs.procps
        pkgs.rofi
        pkgs.sxhkd
        pkgs.xsetroot
      ]
    }:$PATH"
    export XDG_SESSION_TYPE=x11
    export XDG_CURRENT_DESKTOP=bspwm
    export XDG_SESSION_DESKTOP=bspwm
    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    export NIXOS_OZONE_WL=0

    dbus-update-activation-environment --systemd \
      DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL >/dev/null 2>&1 || true
    systemctl --user import-environment \
      DISPLAY XAUTHORITY XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      GDK_BACKEND QT_QPA_PLATFORM NIXOS_OZONE_WL >/dev/null 2>&1 || true

    ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr -solid "#191724" || true
    ${pkgs.sxhkd}/bin/sxhkd -c ${sxhkdConfig} >>"$state_dir/sxhkd.log" 2>&1 &
    sxhkd_pid="$!"
    ${pkgs.dunst}/bin/dunst >>"$state_dir/dunst.log" 2>&1 &
    dunst_pid="$!"

    cleanup() {
      kill "$sxhkd_pid" "$dunst_pid" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    ${pkgs.bspwm}/bin/bspwm -c ${bspwmConfig}
  '';

  xorgConfig = pkgs.writeText "asura-xorg-fallback.conf" ''
    Section "ServerFlags"
      Option "AllowMouseOpenFail" "on"
      Option "DontZap" "on"
    EndSection

    Section "InputClass"
      Identifier "asura libinput pointer"
      MatchIsPointer "on"
      Driver "libinput"
      Option "Tapping" "on"
      Option "MiddleEmulation" "on"
      Option "ScrollMethod" "twofinger"
    EndSection

    Section "InputClass"
      Identifier "asura libinput touchpad"
      MatchIsTouchpad "on"
      Driver "libinput"
      Option "Tapping" "on"
      Option "TappingDragLock" "on"
      Option "NaturalScrolling" "off"
      Option "DisableWhileTyping" "off"
      Option "ScrollMethod" "twofinger"
    EndSection
  '';
  xorgModulePath = lib.concatStringsSep "," (
    map (module: "${module}/lib/xorg/modules") [
      pkgs.xorg-server
      pkgs.xf86-input-evdev
      pkgs.xf86-input-libinput
      config.hardware.nvidia.package
    ]
  );

  xsessionWrapper = pkgs.writeShellScriptBin "asura-start-xsession" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/x11-sessions"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/x11-sessions"
    else
      state_dir="/tmp/asura-x11-sessions-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/xserver.log" 2>&1

    echo "---- x11 session wrapper: $(date -Is) ----"
    echo "session command: $*"

    display=""
    for candidate in 1 2 3 4 5; do
      lock="/tmp/.X''${candidate}-lock"
      socket="/tmp/.X11-unix/X''${candidate}"

      if [ -r "$lock" ]; then
        lock_pid="$(tr -cd '0-9' < "$lock" || true)"
        if [ -n "$lock_pid" ] && kill -0 "$lock_pid" 2>/dev/null; then
          echo "display :$candidate is active by pid $lock_pid"
          continue
        fi
        echo "removing stale X lock for :$candidate"
        rm -f "$lock" "$socket" 2>/dev/null || true
      elif [ -S "$socket" ]; then
        echo "removing stale X socket for :$candidate"
        rm -f "$socket" 2>/dev/null || true
      fi

      if [ ! -e "$lock" ] && [ ! -S "$socket" ]; then
        display="$candidate"
        break
      fi
    done

    if [ -z "$display" ]; then
      echo "no free X display found"
      exit 1
    fi

    if [ "$#" -eq 0 ]; then
      set -- ${bspwmStart}/bin/asura-start-bspwm
    fi

    echo "starting Xorg on :$display"
    exec ${pkgs.xinit}/bin/startx "$@" -- ":$display" \
      -config ${xorgConfig} \
      -modulepath ${lib.escapeShellArg xorgModulePath} \
      -nolisten tcp
  '';
in
{
  # Shared fallback sessions for both laptop and PC. Hyprland stays the normal
  # Wayland default, while BSPWM and Qtile remain selectable from greetd. The
  # X11 wrapper carries its own Xorg path so the XS15 does not need early Xserver
  # module loading during normal Wayland boots.

  environment.etc."asura-wayland-sessions/noctalia-hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Noctalia + Hyprland
    Comment=Current Asura XS15 Hyprland session with Noctalia
    Exec=${quietHyprlandSession}
    Type=Application
  '';

  environment.etc."asura-xsessions/bspwm.desktop".text = ''
    [Desktop Entry]
    Name=BSPWM (X11 fallback)
    Comment=Small X11 fallback session for recovery and low-resource use
    Exec=${bspwmStart}/bin/asura-start-bspwm
    Type=Application
  '';

  environment.etc."asura-xsessions/qtile.desktop".text = ''
    [Desktop Entry]
    Name=Qtile (X11)
    Comment=Qtile X11 session kept available as an alternate fallback
    Exec=${qtileStart}/bin/asura-start-qtile
    Type=Application
  '';

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --sessions /etc/asura-wayland-sessions --xsessions /etc/asura-xsessions --xsession-wrapper ${xsessionWrapper}/bin/asura-start-xsession --cmd ${quietHyprlandSession}";
      user = "greeter";
    };
  };

  systemd.services.greetd.serviceConfig = {
    Type = "idle";
    StandardInput = "tty";
    StandardOutput = "tty";
    StandardError = "journal";
    TTYReset = true;
    TTYVHangup = true;
    TTYVTDisallocate = true;
    ExecStartPre = [
      "-/run/current-system/sw/bin/rm -f /run/user/1000/wayland-0.lock"
      "-/run/current-system/sw/bin/rm -f /run/user/1000/wayland-1.lock"
    ];
  };

  systemd.settings.Manager.DefaultTimeoutStopSec = "10s";

  environment.systemPackages = [
    bspwmStart
    pkgs.bspwm
    pkgs.dunst
    pkgs.feh
    pkgs.python3Packages.qtile
    pkgs.rofi
    pkgs.sxhkd
    pkgs.xinit
    pkgs.xauth
    pkgs.xf86-input-evdev
    pkgs.xf86-input-libinput
    pkgs.xrandr
    pkgs.xorg-server
    pkgs.xsetroot
    qtileStart
    xsessionWrapper
  ];
}
