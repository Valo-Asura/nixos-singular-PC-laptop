# Shared session factory: full BSPWM hotfiles X11 fallback.
#
# This keeps the original Arch hotfiles widgets/session payload in this BSPWM
# module only. Hyprland, Noctalia, VibeShell, and the shared laptop config do
# not import or depend on these EWW/Conky/Plank/GLava assets.
{
  asuraX11Terminal,
  lib,
  pkgs,
  ...
}:

let
  hotfilesSource = ./hotfiles;

  pythonForHotfiles = pkgs.python3.withPackages (
    pythonPackages: with pythonPackages; [
      pytz
      requests
    ]
  );

  # The old dotfiles expect a plain `polybar` command with no bar argument.
  polybarCompat = pkgs.writeShellScriptBin "polybar" ''
    if [ "$#" -eq 0 ]; then
      exec ${pkgs.polybar}/bin/polybar --reload bar
    fi

    exec ${pkgs.polybar}/bin/polybar "$@"
  '';

  # Keep the Pijulius animation fork behind the legacy command name.
  picomCompat = pkgs.writeShellScriptBin "picom" ''
    exec ${pkgs.picom-pijulius}/bin/picom "$@"
  '';

  # xqp is not packaged in nixpkgs. The original binding uses it only as a
  # guard before jgmenu_run, so a success shim preserves the right-click menu.
  xqpCompat = pkgs.writeShellScriptBin "xqp" ''
    exit 0
  '';

  # ukui-window-switch is an Arch-only optional switcher in the hotfiles stack.
  ukuiWindowSwitchCompat = pkgs.writeShellScriptBin "ukui-window-switch" ''
    exit 0
  '';

  # parcellite was removed from nixpkgs. The original bspwmrc starts it as an
  # optional clipboard tray daemon; xclip-backed hotfiles actions still work.
  parcelliteCompat = pkgs.writeShellScriptBin "parcellite" ''
    echo "parcellite is not packaged in current nixpkgs; skipping optional tray clipboard daemon." >&2
    exit 0
  '';

  # Polybar update modules call paru. NixOS has no AUR, so return empty counts
  # for query modes and keep interactive clicks readable.
  paruCompat = pkgs.writeShellScriptBin "paru" ''
    case " $* " in
      *" -Qu "*|*" -Qum "*)
        exit 0
        ;;
    esac

    echo "paru is not available in this NixOS BSPWM hotfiles session." >&2
    exit 127
  '';

  # The EWW power-profile script asks system76-power for a simple state toggle.
  # This compatibility command keeps the widget functional without enabling the
  # System76 daemon on non-System76 hardware.
  system76PowerCompat = pkgs.writeShellScriptBin "system76-power" ''
    set -eu

    state_dir="''${XDG_RUNTIME_DIR:-/tmp}"
    state_file="$state_dir/asura-bspwm-system76-power-profile"
    current="$(cat "$state_file" 2>/dev/null || printf balanced)"

    if [ "''${1:-}" = "profile" ] && [ -z "''${2:-}" ]; then
      printf 'Power Profile: %s\n' "$current"
      exit 0
    fi

    if [ "''${1:-}" = "profile" ]; then
      case "''${2:-}" in
        performance|balanced|battery)
          printf '%s\n' "$2" > "$state_file"
          command -v notify-send >/dev/null 2>&1 \
            && notify-send "Power profile" "BSPWM hotfiles profile set to $2" \
            || true
          exit 0
          ;;
      esac
    fi

    echo "system76-power compatibility shim supports: system76-power profile [performance|balanced|battery]" >&2
    exit 1
  '';

  hotfilesPackages = [
    asuraX11Terminal
    paruCompat
    parcelliteCompat
    picomCompat
    polybarCompat
    pythonForHotfiles
    system76PowerCompat
    ukuiWindowSwitchCompat
    xqpCompat

    pkgs.acpi
    pkgs.alsa-utils
    pkgs.bash
    pkgs.bluez
    pkgs.bluez-tools
    pkgs.blueman
    pkgs.brave
    pkgs.brightnessctl
    pkgs.bsp-layout
    pkgs.bspwm
    pkgs.conky
    pkgs.coreutils
    pkgs.curl
    pkgs.dbus
    pkgs.dunst
    pkgs.eww
    pkgs.feh
    pkgs.file-roller
    pkgs.gamemode
    pkgs.gawk
    pkgs.glava
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gpick
    pkgs.i3lock-color
    pkgs.imagemagick
    pkgs.jgmenu
    pkgs.jq
    pkgs.kitty
    pkgs.libnotify
    pkgs.lsof
    pkgs.maim
    pkgs.mate-polkit
    pkgs.moreutils
    pkgs.mpv
    pkgs.networkmanager
    pkgs.networkmanager_dmenu
    pkgs.papirus-icon-theme
    pkgs.pavucontrol
    pkgs.plank
    pkgs.playerctl
    pkgs.procps
    pkgs.recode
    pkgs.redshift
    pkgs.rofi
    pkgs.sxhkd
    pkgs.tint2
    pkgs.upower
    pkgs.wirelesstools
    pkgs.wmctrl
    pkgs.xclip
    pkgs.xdg-user-dirs
    pkgs.xdo
    pkgs.xdotool
    pkgs.xfce4-power-manager
    pkgs.xfce4-settings
    pkgs.xrandr
    pkgs.xrdb
    pkgs.xsetroot
    pkgs.xterm
    pkgs.yaru-theme
    pkgs.zscroll
    pkgs.zsh
  ];

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

    echo "---- bspwm full hotfiles fallback session: $(date -Is) ----"

    export PATH="${lib.makeBinPath hotfilesPackages}:/run/current-system/sw/bin:/etc/profiles/per-user/''${USER:-asura}/bin:$PATH"
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

    hotfiles_src="${hotfilesSource}"
    backup_root="$HOME/.local/state/asura-bspwm-hotfiles-backups/$(date +%Y%m%d-%H%M%S)"

    backup_target() {
      target="$1"
      mkdir -p "$backup_root"
      backup_name="$(basename "$target")"
      if [ -e "$backup_root/$backup_name" ] || [ -L "$backup_root/$backup_name" ]; then
        backup_name="$backup_name-$(date +%s%N)"
      fi
      mv "$target" "$backup_root/$backup_name"
      echo "Backed up $target to $backup_root/$backup_name"
    }

    install_managed_dir() {
      source_path="$1"
      target_path="$2"
      marker="$target_path/.asura-bspwm-hotfiles-managed"

      [ -d "$source_path" ] || return 0
      mkdir -p "$(dirname "$target_path")"

      if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ ! -f "$marker" ]; then
          backup_target "$target_path"
        else
          rm -rf "$target_path"
        fi
      fi

      cp -a "$source_path" "$target_path"
      chmod -R u+rwX "$target_path" 2>/dev/null || true
      touch "$marker" 2>/dev/null || true
    }

    install_managed_file() {
      source_path="$1"
      target_path="$2"
      marker="$target_path.asura-bspwm-hotfiles-managed"

      [ -f "$source_path" ] || return 0
      mkdir -p "$(dirname "$target_path")"

      if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        if [ ! -f "$marker" ]; then
          backup_target "$target_path"
        else
          rm -f "$target_path"
        fi
      fi

      cp -a "$source_path" "$target_path"
      chmod u+rw "$target_path" 2>/dev/null || true
      touch "$marker" 2>/dev/null || true
    }

    # Install only the BSPWM hotfiles desktop pieces. Do not overwrite shared
    # fish, pipewire, btop, neofetch, or spicetify config from the main system.
    install_managed_dir "$hotfiles_src/.config/bspwm" "$HOME/.config/bspwm"
    install_managed_dir "$hotfiles_src/.config/conky" "$HOME/.config/conky"
    install_managed_dir "$hotfiles_src/.config/dunst" "$HOME/.config/dunst"
    install_managed_dir "$hotfiles_src/.config/eww" "$HOME/.config/eww"
    install_managed_dir "$hotfiles_src/.config/glava" "$HOME/.config/glava"
    install_managed_dir "$hotfiles_src/.config/gtk-3.0" "$HOME/.config/gtk-3.0"
    install_managed_dir "$hotfiles_src/.config/gtk-4.0" "$HOME/.config/gtk-4.0"
    install_managed_dir "$hotfiles_src/.config/jgmenu" "$HOME/.config/jgmenu"
    install_managed_dir "$hotfiles_src/.config/networkmanager-dmenu" "$HOME/.config/networkmanager-dmenu"
    install_managed_dir "$hotfiles_src/.config/polybar" "$HOME/.config/polybar"
    install_managed_dir "$hotfiles_src/.config/redshift" "$HOME/.config/redshift"
    install_managed_dir "$hotfiles_src/.config/rofi" "$HOME/.config/rofi"
    install_managed_dir "$hotfiles_src/.config/sxhkd" "$HOME/.config/sxhkd"
    install_managed_dir "$hotfiles_src/.config/tint2" "$HOME/.config/tint2"
    install_managed_dir "$hotfiles_src/.scripts" "$HOME/.scripts"
    install_managed_dir "$hotfiles_src/.wallpapers" "$HOME/.wallpapers"
    install_managed_dir "$hotfiles_src/.fonts" "$HOME/.fonts"
    install_managed_dir "$hotfiles_src/.cache/dunst" "$HOME/.cache/dunst"
    install_managed_dir "$hotfiles_src/.local/share/plank" "$HOME/.local/share/plank"
    install_managed_file "$hotfiles_src/.Xresources" "$HOME/.Xresources"
    install_managed_file "$hotfiles_src/.gtkrc-2.0" "$HOME/.gtkrc-2.0"

    find "$HOME/.scripts" "$HOME/.config/eww" "$HOME/.config/bspwm/scripts" "$HOME/.config/polybar/scripts" \
      -type f -exec chmod u+x {} + 2>/dev/null || true

    mkdir -p "$HOME/.cache" "$HOME/Pictures/Screenshots"
    if [ ! -s "$HOME/.cache/dunst.log.json" ]; then
      printf '{"items":[]}\n' > "$HOME/.cache/dunst.log.json"
    fi

    fc-cache -r "$HOME/.fonts" >/dev/null 2>&1 &
    xrdb -merge "$HOME/.Xresources" >/dev/null 2>&1 || true
    xsetroot -cursor_name left_ptr >/dev/null 2>&1 || true

    pkill -u "''${USER:-asura}" -x sxhkd >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x polybar >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x eww >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x conky >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x plank >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x parcellite >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x picom >/dev/null 2>&1 || true

    ${pkgs.playerctl}/bin/playerctld daemon >/dev/null 2>&1 &
    ${pkgs.mate-polkit}/libexec/polkit-mate-authentication-agent-1 >/dev/null 2>&1 &

    ${pkgs.bspwm}/bin/bspwm -c "$HOME/.config/bspwm/bspwmrc"
    session_rc="$?"

    pkill -u "''${USER:-asura}" -x sxhkd >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x polybar >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x eww >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x conky >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x plank >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x parcellite >/dev/null 2>&1 || true
    pkill -u "''${USER:-asura}" -x picom >/dev/null 2>&1 || true

    exit "$session_rc"
  '';

  sessionRss = pkgs.writeShellScriptBin "asura-bspwm-session-rss" ''
    set -eu

    pattern='(^|/)(Xorg|xinit|bspwm|sxhkd|polybar|dunst|picom|eww|conky|plank|parcellite|xfce4-power-manager|glava|playerctld|asura-start-bspwm)( |$)'
    total_kb="$(
      ${pkgs.procps}/bin/ps -eo rss=,args= \
        | ${pkgs.gawk}/bin/awk -v pattern="$pattern" '$0 ~ pattern { total += $1 } END { print total + 0 }'
    )"
    total_mb="$(( (total_kb + 1023) / 1024 ))"

    printf 'BSPWM full hotfiles session RSS: %s MiB\n' "$total_mb"
    ${pkgs.procps}/bin/ps -eo pid=,rss=,comm=,args= --sort=-rss \
      | ${pkgs.gawk}/bin/awk -v pattern="$pattern" '$0 ~ pattern { printf "%7s %7.1f MiB  %s\n", $1, $2 / 1024, substr($0, index($0,$4)) }'

    if [ "$total_mb" -lt 1024 ]; then
      printf 'OK: under 1 GiB target.\n'
    else
      printf 'WARN: full hotfiles visuals are over 1 GiB; use the report above to trim optional widgets.\n'
    fi
  '';
in
{
  inherit start sessionRss;

  desktopEntry = ''
    [Desktop Entry]
    Name=BSPWM Hotfiles Full (X11)
    Comment=Full Tokyo Night hotfiles BSPWM with EWW, Conky, Plank, GLava, Polybar, Rofi, Dunst
    Exec=${start}/bin/asura-start-bspwm
    Type=Application
  '';

  packages = hotfilesPackages ++ [
    sessionRss
    start
  ];
}
