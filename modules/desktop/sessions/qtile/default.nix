# Shared session factory: lightweight Qtile X11 fallback kept selectable from greetd.
{
  asuraX11Terminal,
  lib,
  pkgs,
  ...
}:

let
  qtileConfig = pkgs.writeText "asura-qtile-config.py" ''
    from libqtile import bar, layout, widget
    from libqtile.config import Group, Key, Screen
    from libqtile.lazy import lazy

    mod = "mod4"
    terminal = "asura-x11-terminal"

    keys = [
        Key([mod], "Return", lazy.spawn(terminal), desc="Open terminal"),
        Key([mod], "t", lazy.spawn(terminal), desc="Open terminal"),
        Key([mod], "a", lazy.spawn("asura-vibeshell run tools"), desc="Open tools"),
        Key([mod], "space", lazy.spawn("rofi -show drun"), desc="App launcher"),
        Key([mod], "d", lazy.spawn("asura-vibeshell run dashboard-controls"), desc="Dashboard"),
        Key([mod], "s", lazy.spawn("asura-vibeshell run config"), desc="Settings"),
        Key([mod], "Tab", lazy.next_layout(), desc="Next layout"),
        Key([mod], "q", lazy.window.kill(), desc="Close focused window"),
        Key([mod, "control"], "r", lazy.reload_config(), desc="Reload Qtile"),
        Key([mod], "h", lazy.shutdown(), desc="Quit Qtile"),
        Key([mod], "Left", lazy.layout.left(), desc="Focus left"),
        Key([mod], "Down", lazy.layout.down(), desc="Focus down"),
        Key([mod], "Up", lazy.layout.up(), desc="Focus up"),
        Key([mod], "Right", lazy.layout.right(), desc="Focus right"),
        Key([mod, "shift"], "Left", lazy.layout.shuffle_left(), desc="Move left"),
        Key([mod, "shift"], "Down", lazy.layout.shuffle_down(), desc="Move down"),
        Key([mod, "shift"], "Up", lazy.layout.shuffle_up(), desc="Move up"),
        Key([mod, "shift"], "Right", lazy.layout.shuffle_right(), desc="Move right"),
    ]

    groups = [Group(str(i)) for i in range(1, 11)]
    for group in groups:
        key = "0" if group.name == "10" else group.name
        keys.extend(
            [
                Key([mod], key, lazy.group[group.name].toscreen(), desc=f"Switch to group {group.name}"),
                Key([mod, "shift"], key, lazy.window.togroup(group.name, switch_group=True), desc=f"Move window to group {group.name}"),
            ]
        )

    layouts = [
        layout.MonadTall(border_focus="#ff8080", border_normal="#1a1b26", border_width=2, margin=8),
        layout.Max(),
    ]

    widget_defaults = dict(font="JetBrainsMono Nerd Font", fontsize=12, padding=4)
    extension_defaults = widget_defaults.copy()

    screens = [
        Screen(
            top=bar.Bar(
                [
                    widget.GroupBox(active="#f8c3d4", inactive="#7f849c", highlight_method="line"),
                    widget.WindowName(foreground="#c0caf5"),
                    widget.Systray(),
                    widget.Clock(format="%I:%M %p", foreground="#ff8080"),
                ],
                30,
                background="#1a1b26",
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

  start = pkgs.writeShellScriptBin "asura-start-qtile" ''
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

    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/asura/bin:$PATH"
    export PATH="${
      lib.makeBinPath [
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.dunst
        pkgs.feh
        pkgs.kitty
        pkgs.libnotify
        pkgs.pamixer
        pkgs.playerctl
        pkgs.procps
        pkgs.python3Packages.qtile
        pkgs.rofi
        pkgs.xsetroot
        pkgs.xterm
        asuraX11Terminal
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

    ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr -solid "#1a1b26" || true
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
in
{
  inherit start;
  desktopEntry = ''
    [Desktop Entry]
    Name=Qtile (X11)
    Comment=Qtile X11 session kept available as an alternate fallback
    Exec=${start}/bin/asura-start-qtile
    Type=Application
  '';
  packages = [
    start
    pkgs.dunst
    pkgs.feh
    pkgs.kitty
    pkgs.python3Packages.qtile
    pkgs.rofi
    pkgs.xsetroot
    pkgs.xterm
  ];
}
