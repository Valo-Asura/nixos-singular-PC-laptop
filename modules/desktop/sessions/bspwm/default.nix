# Shared session factory: BSPWM hotfiles-lite X11 fallback.
#
# This ports the Tokyo Night/hotfiles look without the original heavy Arch
# autostart stack. Intentionally omitted for RAM: EWW, Conky, Plank, GLava,
# parcellite, xfce4-power-manager, ukui-window-switch, and system76-power.
{
  asuraX11Terminal,
  config,
  lib,
  pkgs,
  ...
}:

let
  wallpaper = ./assets/tokyo.png;

  batteryScript = pkgs.writeShellScriptBin "asura-polybar-battery" ''
    set -u

    battery=""
    for candidate in /sys/class/power_supply/BAT*; do
      if [ -r "$candidate/capacity" ]; then
        battery="$candidate"
        break
      fi
    done

    if [ -z "$battery" ]; then
      printf '\n'
      exit 0
    fi

    capacity="$(cat "$battery/capacity" 2>/dev/null || printf '?')"
    status="$(cat "$battery/status" 2>/dev/null || printf Unknown)"
    suffix=""
    case "$status" in
      Charging) suffix="+" ;;
      Full) suffix="*" ;;
      Discharging) suffix="-" ;;
    esac
    printf 'BAT %s%%%s\n' "$capacity" "$suffix"
  '';

  networkScript = pkgs.writeShellScriptBin "asura-polybar-network" ''
    set -u

    if ! command -v nmcli >/dev/null 2>&1; then
      printf '\n'
      exit 0
    fi

    ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$1 == "yes" { print $2; exit }')"
    if [ -n "$ssid" ]; then
      printf 'WIFI %s\n' "$ssid"
      exit 0
    fi

    wired="$(nmcli -t -f TYPE,STATE dev status 2>/dev/null | ${pkgs.gawk}/bin/awk -F: '$1 == "ethernet" && $2 == "connected" { print "NET wired"; exit }')"
    if [ -n "$wired" ]; then
      printf '%s\n' "$wired"
      exit 0
    fi

    printf 'NET down\n'
  '';

  bspwmConfig = pkgs.writeShellScript "asura-bspwmrc-hotfiles-lite" ''
    # Hotfiles-lite BSPWM config: shared X11 fallback for laptop and PC.
    ${pkgs.bspwm}/bin/bspc monitor -d 1 2 3 4 5 6 7 8 9 10
    ${pkgs.bspwm}/bin/bspc config border_width 2
    ${pkgs.bspwm}/bin/bspc config window_gap 18
    ${pkgs.bspwm}/bin/bspc config split_ratio 0.52
    ${pkgs.bspwm}/bin/bspc config borderless_monocle true
    ${pkgs.bspwm}/bin/bspc config gapless_monocle true
    ${pkgs.bspwm}/bin/bspc config focus_follows_pointer true
    ${pkgs.bspwm}/bin/bspc config pointer_modifier mod4
    ${pkgs.bspwm}/bin/bspc config pointer_action1 move
    ${pkgs.bspwm}/bin/bspc config pointer_action3 resize_corner
    ${pkgs.bspwm}/bin/bspc config normal_border_color "#1a1b26"
    ${pkgs.bspwm}/bin/bspc config active_border_color "#7aa2f7"
    ${pkgs.bspwm}/bin/bspc config focused_border_color "#ff8080"
    ${pkgs.bspwm}/bin/bspc config presel_feedback_color "#bb9af7"

    ${pkgs.bspwm}/bin/bspc rule -a Gimp desktop='^8' state=floating follow=on
    ${pkgs.bspwm}/bin/bspc rule -a Pavucontrol state=floating
    ${pkgs.bspwm}/bin/bspc rule -a Blueman-manager state=floating
    ${pkgs.bspwm}/bin/bspc rule -a Rofi state=floating
    ${pkgs.bspwm}/bin/bspc rule -a org.gnome.Nautilus state=floating
    ${pkgs.bspwm}/bin/bspc rule -a Xarchiver state=floating
  '';

  picomConfig = pkgs.writeText "asura-bspwm-picom.conf" ''
    # Hotfiles-lite Picom: rounded/shadowed Tokyo Night look without the
    # Pijulius animation fork or GLava/EWW exclusions that cost RAM.
    backend = "glx";
    vsync = true;
    use-damage = true;

    shadow = true;
    shadow-radius = 22;
    shadow-opacity = 0.45;
    shadow-offset-x = -18;
    shadow-offset-y = -18;
    shadow-exclude = [
      "window_type = 'dock'",
      "window_type = 'desktop'",
      "window_type = 'menu'",
      "class_g = 'Polybar'",
      "_GTK_FRAME_EXTENTS@:c"
    ];

    fading = true;
    fade-in-step = 0.035;
    fade-out-step = 0.035;
    fade-delta = 5;

    corner-radius = 15;
    rounded-corners-exclude = [
      "window_type = 'desktop'",
      "window_type = 'dock'",
      "window_type = 'tooltip'",
      "class_g = 'Polybar'",
      "_GTK_FRAME_EXTENTS@:c"
    ];

    inactive-opacity = 1.0;
    active-opacity = 1.0;
    frame-opacity = 1.0;
    inactive-opacity-override = false;
    detect-rounded-corners = true;
    detect-client-opacity = true;
    detect-transient = true;
    mark-wmwin-focused = true;
    mark-ovredir-focused = true;
    log-level = "warn";
  '';

  rofiTheme = pkgs.writeText "asura-bspwm-rofi.rasi" ''
    /* Shared BSPWM hotfiles-lite launcher theme. */
    configuration {
      modi: "run,drun,window";
      lines: 5;
      font: "JetBrainsMono Nerd Font 13";
      show-icons: true;
      icon-theme: "Papirus";
      terminal: "kitty";
      drun-display-format: "{name}";
      disable-history: false;
      hide-scrollbar: true;
      display-drun: "Apps";
      display-run: "Run";
      display-window: "Window";
      sidebar-mode: true;
    }

    * {
      bg: #1a1b26;
      bg-alt: #24283b;
      fg: #c0caf5;
      muted: #565f89;
      accent: #ff8080;
      accent-alt: #7aa2f7;
      selected: #bb9af7;
    }

    window {
      width: 58%;
      height: 500px;
      border: 2px;
      border-color: @accent;
      background-color: @bg;
      border-radius: 15px;
    }

    mainbox {
      background-color: @bg;
      children: [ mode-switcher, inputbar, listview ];
      padding: 16px;
    }

    inputbar {
      children: [ prompt, entry ];
      background-color: @bg-alt;
      border-radius: 10px;
      padding: 8px;
      margin: 0 0 12px 0;
    }

    prompt {
      background-color: @accent;
      text-color: @bg;
      border-radius: 8px;
      padding: 8px 12px;
      margin: 0 10px 0 0;
    }

    entry {
      text-color: @fg;
      background-color: transparent;
      padding: 8px;
    }

    listview {
      columns: 4;
      spacing: 12px;
      background-color: @bg;
      padding: 8px;
    }

    element {
      orientation: vertical;
      spacing: 8px;
      padding: 10px;
      border-radius: 10px;
      background-color: @bg;
      text-color: @fg;
    }

    element selected {
      background-color: @accent;
      text-color: @bg;
    }

    element-icon {
      size: 48px;
      horizontal-align: 0.5;
    }

    element-text {
      horizontal-align: 0.5;
      vertical-align: 0.5;
      text-color: inherit;
      font: "JetBrainsMono Nerd Font Bold 11";
    }

    mode-switcher {
      spacing: 8px;
      margin: 0 0 8px 0;
    }

    button {
      padding: 8px 14px;
      border-radius: 10px;
      background-color: @bg-alt;
      text-color: @fg;
    }

    button selected {
      background-color: @selected;
      text-color: @bg;
    }
  '';

  dunstConfig = pkgs.writeText "asura-bspwm-dunstrc" ''
    # Shared BSPWM notification theme. Kept small and standalone for fallback use.
    [global]
      monitor = 0
      follow = keyboard
      width = 380
      height = 180
      origin = bottom-right
      offset = 32x32
      notification_limit = 5
      progress_bar = true
      progress_bar_height = 8
      progress_bar_frame_width = 1
      progress_bar_min_width = 140
      progress_bar_max_width = 280
      separator_height = 2
      padding = 10
      horizontal_padding = 12
      frame_width = 2
      frame_color = "#ff8080"
      separator_color = frame
      sort = yes
      font = JetBrainsMono Nerd Font 11
      markup = full
      format = "<b>%s</b>\n%b"
      alignment = left
      vertical_alignment = center
      ellipsize = middle
      icon_position = left
      min_icon_size = 48
      max_icon_size = 96
      icon_theme = "Papirus, Adwaita"
      enable_recursive_icon_lookup = true
      sticky_history = yes
      history_length = 20
      corner_radius = 15
      title = Dunst
      class = Dunst
      background = "#1a1b26"
      foreground = "#c0caf5"
      timeout = 6

    [urgency_low]
      background = "#1a1b26"
      foreground = "#c0caf5"
      frame_color = "#7aa2f7"
      timeout = 4

    [urgency_normal]
      background = "#1a1b26"
      foreground = "#c0caf5"
      frame_color = "#ff8080"
      timeout = 6

    [urgency_critical]
      background = "#1a1b26"
      foreground = "#f7768e"
      frame_color = "#f7768e"
      timeout = 0
  '';

  polybarConfig = pkgs.writeText "asura-bspwm-polybar.ini" ''
    ; Shared BSPWM hotfiles-lite Polybar. Avoids EWW custom script modules.
    [colors]
    background = #1a1b26
    background-alt = #24283b
    foreground = #c0caf5
    muted = #565f89
    accent = #ff8080
    accent-alt = #7aa2f7
    purple = #bb9af7
    green = #9ece6a
    yellow = #e0af68

    [bar/asura]
    monitor = ''${env:MONITOR:}
    width = 98%
    height = 32
    offset-x = 1%
    offset-y = 8
    radius = 8
    fixed-center = true
    bottom = false
    background = ''${colors.background}
    foreground = ''${colors.foreground}
    line-size = 2
    border-size = 0
    padding-left = 1
    padding-right = 1
    module-margin = 1
    font-0 = JetBrainsMono Nerd Font:size=10;2
    font-1 = JetBrainsMono Nerd Font:size=14;3
    modules-left = launcher bspwm
    modules-center = xwindow
    modules-right = network pulseaudio battery date powermenu
    cursor-click = pointer
    cursor-scroll = ns-resize
    enable-ipc = true
    wm-restack = bspwm

    [module/launcher]
    type = custom/text
    content = ASURA
    content-padding = 2
    content-background = ''${colors.accent-alt}
    content-foreground = ''${colors.background}
    click-left = ${pkgs.rofi}/bin/rofi -show drun -theme ${rofiTheme}

    [module/bspwm]
    type = internal/bspwm
    pin-workspaces = true
    label-focused = %name%
    label-focused-foreground = ''${colors.background}
    label-focused-background = ''${colors.accent}
    label-focused-padding = 2
    label-occupied = %name%
    label-occupied-foreground = ''${colors.foreground}
    label-occupied-background = ''${colors.background-alt}
    label-occupied-padding = 2
    label-urgent = %name%
    label-urgent-foreground = ''${colors.background}
    label-urgent-background = ''${colors.yellow}
    label-urgent-padding = 2
    label-empty = %name%
    label-empty-foreground = ''${colors.muted}
    label-empty-padding = 2

    [module/xwindow]
    type = internal/xwindow
    label = %title:0:82:...%
    label-empty = BSPWM Hotfiles Lite
    label-empty-foreground = ''${colors.muted}

    [module/network]
    type = custom/script
    exec = ${networkScript}/bin/asura-polybar-network
    interval = 5
    label = %output%
    label-foreground = ''${colors.green}

    [module/pulseaudio]
    type = internal/pulseaudio
    format-volume = VOL <label-volume>
    label-volume = %percentage%%
    label-muted = MUTED
    label-muted-foreground = ''${colors.muted}

    [module/battery]
    type = custom/script
    exec = ${batteryScript}/bin/asura-polybar-battery
    interval = 10
    label = %output%
    label-foreground = ''${colors.purple}

    [module/date]
    type = internal/date
    interval = 1
    date = %a %d %b
    time = %I:%M %p
    label = %date%  %time%
    label-foreground = ''${colors.accent}

    [module/powermenu]
    type = custom/text
    content = POWER
    content-padding = 2
    content-foreground = ''${colors.accent}
    click-left = asura-vibeshell run powermenu

    [settings]
    screenchange-reload = true
    pseudo-transparency = false
  '';

  sxhkdConfig = pkgs.writeText "asura-bspwm-sxhkdrc" ''
    # Shared BSPWM bindings mirrored from current Hyprland bindings.
    super + q
      ${pkgs.bspwm}/bin/bspc node -c

    super + h
      ${pkgs.bspwm}/bin/bspc quit

    super + f
      asura-file-manager "$HOME"

    super + g
      ${pkgs.bspwm}/bin/bspc node -t '~floating'

    super + j
      ${pkgs.bspwm}/bin/bspc node @parent -R 90

    super + b
      ${pkgs.brave}/bin/brave

    super + {t,Return}
      asura-x11-terminal

    super + c
      code --ozone-platform=x11

    super + a
      asura-vibeshell run tools

    super + @space
      ${pkgs.rofi}/bin/rofi -show drun -theme ${rofiTheme}

    super + e
      ${pkgs.telegram-desktop}/bin/telegram-desktop

    super + w
      skwd-wall

    super + p
      asura-display-manager

    super + shift + p
      asura-monitor-guard --restore

    {ctrl,super} + l
      /run/current-system/sw/bin/vibeshell-safe-lock

    super + v
      asura-vibeshell run dashboard-clipboard

    super + shift + v
      ${pkgs.bspwm}/bin/bspc node -t '~floating'

    super + shift + c
      clipboard

    super + shift + e
      asura-shell-launcher /emo

    super + shift + s
      asura-screenshot region

    super + shift + w
      skwd-wall

    super + shift + r
      /run/current-system/sw/bin/asura-screen-record-toggle

    super + shift + x
      asura-screenshot region-edit

    super + F2
      night-shift

    super + n
      asura-vibeshell run dashboard-notes

    super + d
      asura-vibeshell run dashboard-controls

    super + s
      asura-vibeshell run config

    ctrl + alt + Delete
      asura-vibeshell run powermenu

    super + BackSpace
      asura-vibeshell run powermenu

    super + period
      asura-vibeshell run dashboard-emoji

    ctrl + super + r
      asura-vibeshell reload

    Print
      asura-screenshot full

    shift + Print
      asura-screenshot region

    super + Print
      asura-screenshot output

    super + shift + Print
      asura-screenshot region-edit

    super + {Left,Down,Up,Right}
      ${pkgs.bspwm}/bin/bspc node -f {west,south,north,east}

    alt + Tab
      ${pkgs.bspwm}/bin/bspc node -f next.local.!hidden.window

    alt + shift + Tab
      ${pkgs.bspwm}/bin/bspc node -f prev.local.!hidden.window

    super + Tab
      ${pkgs.bspwm}/bin/bspc node -f next.local.!hidden.window

    super + shift + Tab ; {Left,Right,Up,Down,Escape}
      {${pkgs.bspwm}/bin/bspc node -z left -30 0,${pkgs.bspwm}/bin/bspc node -z right 30 0,${pkgs.bspwm}/bin/bspc node -z top 0 -30,${pkgs.bspwm}/bin/bspc node -z bottom 0 30,true}

    super + {1-9}
      ${pkgs.bspwm}/bin/bspc desktop -f '^{1-9}'

    super + shift + {1-9}
      ${pkgs.bspwm}/bin/bspc node -d '^{1-9}' --follow

    super + 0
      ${pkgs.bspwm}/bin/bspc desktop -f '^10'

    super + shift + 0
      ${pkgs.bspwm}/bin/bspc node -d '^10' --follow

    XF86AudioMute
      sound-toggle

    XF86AudioPlay
      ${pkgs.playerctl}/bin/playerctl play-pause

    XF86AudioNext
      ${pkgs.playerctl}/bin/playerctl next

    XF86AudioPrev
      ${pkgs.playerctl}/bin/playerctl previous

    F3
      sound-toggle

    F5
      sound-down

    F6
      sound-up

    F8
      brightness-down

    F9
      brightness-up

    F10
      asura-camera-app

    F11
      asura-airplane-toggle

    F12
      night-shift

    XF86AudioRaiseVolume
      sound-up

    XF86AudioLowerVolume
      sound-down

    XF86MonBrightnessUp
      brightness-up

    XF86MonBrightnessDown
      brightness-down
  '';

  start = pkgs.writeShellScriptBin "asura-start-bspwm" ''
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

    echo "---- bspwm hotfiles-lite fallback session: $(date -Is) ----"

    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/asura/bin:$PATH"
    export PATH="${
      lib.makeBinPath [
        batteryScript
        networkScript
        pkgs.bspwm
        pkgs.brave
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.dunst
        pkgs.feh
        pkgs.gawk
        pkgs.i3lock-color
        pkgs.kitty
        pkgs.libnotify
        pkgs.networkmanager
        pkgs.pamixer
        pkgs.picom
        pkgs.playerctl
        pkgs.polybar
        pkgs.procps
        pkgs.rofi
        pkgs.sxhkd
        pkgs.telegram-desktop
        pkgs.xrandr
        pkgs.xsetroot
        pkgs.xterm
        asuraX11Terminal
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

    ${pkgs.xsetroot}/bin/xsetroot -cursor_name left_ptr -solid "#1a1b26" || true
    ${pkgs.feh}/bin/feh --bg-fill ${wallpaper} >>"$state_dir/feh.log" 2>&1 || true

    ${pkgs.picom}/bin/picom --config ${picomConfig} >>"$state_dir/picom.log" 2>&1 &
    picom_pid="$!"

    ${pkgs.sxhkd}/bin/sxhkd -c ${sxhkdConfig} >>"$state_dir/sxhkd.log" 2>&1 &
    sxhkd_pid="$!"

    ${pkgs.dunst}/bin/dunst -conf ${dunstConfig} >>"$state_dir/dunst.log" 2>&1 &
    dunst_pid="$!"

    polybar_pids=()
    while IFS= read -r monitor; do
      [ -n "$monitor" ] || continue
      MONITOR="$monitor" ${pkgs.polybar}/bin/polybar --reload -c ${polybarConfig} asura >>"$state_dir/polybar-$monitor.log" 2>&1 &
      polybar_pids+=("$!")
    done < <(${pkgs.xrandr}/bin/xrandr --query | ${pkgs.gawk}/bin/awk '/ connected/{print $1}')

    if [ "''${#polybar_pids[@]}" -eq 0 ]; then
      ${pkgs.polybar}/bin/polybar --reload -c ${polybarConfig} asura >>"$state_dir/polybar.log" 2>&1 &
      polybar_pids+=("$!")
    fi

    cleanup() {
      kill "$sxhkd_pid" "$dunst_pid" "$picom_pid" "''${polybar_pids[@]}" >/dev/null 2>&1 || true
    }
    trap cleanup EXIT

    ${pkgs.bspwm}/bin/bspwm -c ${bspwmConfig}
  '';

  sessionRss = pkgs.writeShellScriptBin "asura-bspwm-session-rss" ''
    set -eu

    pattern='(^|/)(Xorg|xinit|bspwm|sxhkd|polybar|dunst|picom|asura-start-bspwm)( |$)'
    total_kb="$(
      ${pkgs.procps}/bin/ps -eo rss=,args= \
        | ${pkgs.gawk}/bin/awk -v pattern="$pattern" '$0 ~ pattern { total += $1 } END { print total + 0 }'
    )"
    total_mb="$(( (total_kb + 1023) / 1024 ))"

    printf 'BSPWM fallback baseline RSS: %s MiB\n' "$total_mb"
    ${pkgs.procps}/bin/ps -eo pid=,rss=,comm=,args= --sort=-rss \
      | ${pkgs.gawk}/bin/awk -v pattern="$pattern" '$0 ~ pattern { printf "%7s %7.1f MiB  %s\n", $1, $2 / 1024, substr($0, index($0,$4)) }'

    if [ "$total_mb" -lt 1024 ]; then
      printf 'OK: under 1 GiB target.\n'
    else
      printf 'WARN: over 1 GiB target. Check for extra autostarted UI daemons.\n'
      exit 1
    fi
  '';
in
{
  inherit start sessionRss;
  desktopEntry = ''
    [Desktop Entry]
    Name=BSPWM Hotfiles Lite (X11)
    Comment=Low-RAM Tokyo Night BSPWM fallback; hotfiles style without EWW/Conky/Plank/GLava
    Exec=${start}/bin/asura-start-bspwm
    Type=Application
  '';
  packages = [
    batteryScript
    networkScript
    sessionRss
    start
    pkgs.bspwm
    pkgs.dunst
    pkgs.feh
    pkgs.kitty
    pkgs.networkmanager
    pkgs.picom
    pkgs.polybar
    pkgs.rofi
    pkgs.sxhkd
    pkgs.xrandr
    pkgs.xsetroot
    pkgs.xterm
  ];
}
