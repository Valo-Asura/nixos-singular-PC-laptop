# Shared module: shell launcher/switcher limited to waybar, noctalia, and vibeshell.
{ pkgs, ... }:

let
  asuraSessionLock = pkgs.writeShellApplication {
    name = "asura-session-lock";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      procps
      systemd
    ];
    text = ''
      set -euo pipefail

      if command -v noctalia >/dev/null 2>&1; then
        if systemctl --user is-active --quiet noctalia.service 2>/dev/null \
          || pgrep -u "$(id -u)" -x noctalia >/dev/null 2>&1; then
          noctalia msg session lock "$@" && exit 0
        fi
      fi

      if command -v vibeshell-safe-lock >/dev/null 2>&1; then
        exec vibeshell-safe-lock "$@"
      fi

      if command -v hyprlock >/dev/null 2>&1; then
        exec hyprlock "$@"
      fi

      notify-send -a asura-session-lock "Lock unavailable" "Noctalia, VibeShell, and hyprlock are unavailable." 2>/dev/null || true
      exit 127
    '';
  };

  asuraShellSwitch = pkgs.writeShellApplication {
    name = "asura-shell-switch";
    runtimeInputs = with pkgs; [
      coreutils
      gnugrep
      libnotify
      procps
      quickshell
      systemd
      util-linux
    ];
    text = ''
      set -euo pipefail

      active_file="/etc/asura-shell/active-shell"
      uid="$(id -u)"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/asura-shell"
      caffeine_file="$state_dir/caffeine"
      caffeine_unit="asura-caffeine-inhibit.service"

      mkdir -p "$state_dir"

      notify() {
        [ "''${ASURA_SHELL_QUIET:-0}" = 1 ] && return 0
        notify-send -a asura-shell-switch "$@" 2>/dev/null || true
      }

      caffeine_wanted() {
        [ "$(cat "$caffeine_file" 2>/dev/null || true)" = "on" ]
      }

      caffeine_active() {
        systemctl --user is-active --quiet "$caffeine_unit" 2>/dev/null \
          || pgrep -u "$uid" -f 'systemd-inhibit --what=idle:sleep:handle-lid-switch --who=asura-shell-switch' >/dev/null 2>&1
      }

      caffeine_start() {
        local quiet="''${1:-0}"
        printf '%s\n' on > "$caffeine_file"

        if ! caffeine_active; then
          systemctl --user reset-failed "$caffeine_unit" >/dev/null 2>&1 || true
          systemd-run --user \
            --unit="''${caffeine_unit%.service}" \
            --description="Asura shell caffeine inhibitor" \
            --collect \
            --quiet \
            systemd-inhibit \
              --what=idle:sleep:handle-lid-switch \
              --who=asura-shell-switch \
              --why="Asura shell caffeine mode is enabled" \
              --mode=block \
              sleep infinity \
            >/dev/null 2>&1 || {
              pkill -u "$uid" -f 'systemd-inhibit --what=idle:sleep:handle-lid-switch --who=asura-shell-switch' 2>/dev/null || true
              setsid -f systemd-inhibit \
                --what=idle:sleep:handle-lid-switch \
                --who=asura-shell-switch \
                --why="Asura shell caffeine mode is enabled" \
                --mode=block \
                sleep infinity \
                >/tmp/asura-caffeine-inhibit.log 2>&1
            }
        fi

        [ "$quiet" = 1 ] || notify "Caffeine mode on" "Idle, sleep, and lid-switch sleep are inhibited."
      }

      caffeine_stop() {
        printf '%s\n' off > "$caffeine_file"
        systemctl --user stop "$caffeine_unit" >/dev/null 2>&1 || true
        pkill -u "$uid" -f 'systemd-inhibit --what=idle:sleep:handle-lid-switch --who=asura-shell-switch' 2>/dev/null || true
        notify "Caffeine mode off" "Normal idle and sleep behavior restored."
      }

      caffeine_toggle() {
        if caffeine_wanted || caffeine_active; then
          caffeine_stop
        else
          caffeine_start
        fi
      }

      read_active() {
        if [ -r "$active_file" ]; then
          tr -d '[:space:]' < "$active_file"
        else
          printf '%s\n' vibeshell
        fi
      }

      validate_shell() {
        case "$1" in
          waybar|noctalia|vibeshell) return 0 ;;
          *)
            printf 'unsupported shell: %s\nallowed: waybar noctalia vibeshell\n' "$1" >&2
            return 64
            ;;
        esac
      }

      start_shell() {
        validate_shell "$1"
        case "$1" in
          waybar)
            if ! pgrep -u "$(id -u)" -x waybar >/dev/null 2>&1; then
              nohup /run/current-system/sw/bin/asura-waybar >/tmp/asura-waybar.log 2>&1 &
            fi
            ;;
          noctalia)
            systemctl --user start noctalia.service || {
              nohup /run/current-system/sw/bin/noctalia >/tmp/noctalia.log 2>&1 &
            }
            ;;
          vibeshell)
            if ! pgrep -u "$(id -u)" -f 'quickshell.*vibeshell|qs.*vibeshell' >/dev/null 2>&1; then
              nohup /run/current-system/sw/bin/asura-vibeshell >/tmp/asura-vibeshell.log 2>&1 &
            fi
            ;;
        esac
      }

      restart_shell() {
        validate_shell "$1"
        case "$1" in
          waybar)
            pkill -u "$(id -u)" -x waybar >/dev/null 2>&1 || true
            start_shell waybar
            ;;
          noctalia)
            systemctl --user restart noctalia.service || {
              pkill -u "$(id -u)" -x noctalia >/dev/null 2>&1 || true
              start_shell noctalia
            }
            ;;
          vibeshell)
            /run/current-system/sw/bin/asura-vibeshell reload
            ;;
        esac
      }

      case "''${1:-autostart}" in
        autostart)
          start_shell "$(read_active)"
          ;;
        current)
          read_active
          ;;
        lock)
          exec /run/current-system/sw/bin/asura-session-lock "''${@:2}"
          ;;
        reload|restart)
          restart_shell "$(read_active)"
          ;;
        waybar|noctalia|vibeshell)
          start_shell "$1"
          ;;
        caffeine-on|caffeine|awake-on|awake)
          caffeine_start
          ;;
        caffeine-off|awake-off)
          caffeine_stop
          ;;
        caffeine-toggle|awake-toggle)
          caffeine_toggle
          ;;
        caffeine-status|awake-status)
          printf 'caffeine=%s active=%s\n' "$(cat "$caffeine_file" 2>/dev/null || printf off)" "$(caffeine_active && printf yes || printf no)"
          ;;
        *)
          printf 'usage: asura-shell-switch [autostart|current|lock|reload|restart|waybar|noctalia|vibeshell|caffeine-on|caffeine-off|caffeine-toggle|caffeine-status]\n' >&2
          exit 64
          ;;
      esac
    '';
  };

  asuraShellLauncher = pkgs.writeShellApplication {
    name = "asura-shell-launcher";
    runtimeInputs = with pkgs; [
      coreutils
      walker
    ];
    text = ''
      set -euo pipefail

      active="$(
        if [ -r /etc/asura-shell/active-shell ]; then
          tr -d '[:space:]' < /etc/asura-shell/active-shell
        else
          printf '%s\n' vibeshell
        fi
      )"

      case "$active" in
        vibeshell)
          case "''${1:-}" in
            /dashboard) exec /run/current-system/sw/bin/asura-vibeshell run dashboard ;;
            /tools) exec /run/current-system/sw/bin/asura-vibeshell run tools ;;
            /clipboard) exec /run/current-system/sw/bin/asura-vibeshell run dashboard-clipboard ;;
            /emo) exec /run/current-system/sw/bin/asura-vibeshell run dashboard-emoji ;;
            /notes) exec /run/current-system/sw/bin/asura-vibeshell run dashboard-notes ;;
            /wallpaper) exec /run/current-system/sw/bin/asura-vibeshell run dashboard-wallpapers ;;
            /session|/power) exec /run/current-system/sw/bin/asura-vibeshell run powermenu ;;
            /config) exec /run/current-system/sw/bin/asura-vibeshell run config ;;
            *) exec /run/current-system/sw/bin/asura-vibeshell run notch-launcher ;;
          esac
          ;;
        noctalia)
          case "''${1:-}" in
            /dashboard) exec /run/current-system/sw/bin/noctalia msg panel-toggle control-center ;;
            /tools) exec /run/current-system/sw/bin/noctalia msg panel-toggle control-center ;;
            /clipboard) exec /run/current-system/sw/bin/noctalia msg panel-toggle clipboard ;;
            /emo) exec /run/current-system/sw/bin/noctalia msg panel-toggle emoji ;;
            /wallpaper) exec /run/current-system/sw/bin/noctalia msg panel-toggle wallpaper ;;
            /session|/power) exec /run/current-system/sw/bin/noctalia msg panel-toggle session ;;
            /config) exec /run/current-system/sw/bin/noctalia msg panel-toggle control-center ;;
            *) exec /run/current-system/sw/bin/noctalia msg panel-toggle launcher ;;
          esac
          ;;
        waybar)
          exec walker "$@"
          ;;
        *)
          printf 'unsupported active shell: %s\n' "$active" >&2
          exit 64
          ;;
      esac
    '';
  };
in
{
  environment.systemPackages = [
    asuraSessionLock
    asuraShellSwitch
    asuraShellLauncher
  ];

  home-manager.users.asura.home.packages = [
    asuraSessionLock
    asuraShellSwitch
    asuraShellLauncher
  ];
}
