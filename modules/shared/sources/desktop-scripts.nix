{ lib, pkgs, ... }:

let
  asuraScreenRecordToggle = pkgs.writeShellScriptBin "asura-screen-record-toggle" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.procps
        pkgs.wf-recorder
        pkgs.libnotify
      ]
    }:$PATH"

    runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    pidfile="$runtime_dir/asura-screen-record.pid"
    startfile="$runtime_dir/asura-screen-record.started"
    pausefile="$runtime_dir/asura-screen-record.paused"
    filefile="$runtime_dir/asura-screen-record.file"
    logfile="$runtime_dir/asura-screen-record.log"
    out_dir="$HOME/Videos/Screenrecords"
    mkdir -p "$out_dir"

    notify() {
      notify-send "$@" --icon=media-record || true
    }

    cleanup_state() {
      rm -f "$pidfile" "$startfile" "$pausefile" "$filefile"
    }

    read_pid() {
      [ -s "$pidfile" ] && cat "$pidfile"
    }

    live_pid() {
      pid="$(read_pid || true)"
      if [ -n "''${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        printf '%s\n' "$pid"
        return 0
      fi
      pid="$(pgrep -u "$(id -u)" -x wf-recorder | head -n 1 || true)"
      if [ -n "''${pid:-}" ] && kill -0 "$pid" 2>/dev/null; then
        printf '%s\n' "$pid" > "$pidfile"
        printf '%s\n' "$pid"
        return 0
      fi
      return 1
    }

    is_running() {
      live_pid >/dev/null
    }

    elapsed_seconds() {
      if [ ! -s "$startfile" ]; then
        printf '0\n'
        return
      fi
      now="$(date +%s)"
      start="$(cat "$startfile" 2>/dev/null || printf '%s' "$now")"
      printf '%s\n' "$((now - start))"
    }

    format_elapsed() {
      total="$1"
      printf '%02d:%02d:%02d\n' "$((total / 3600))" "$(((total % 3600) / 60))" "$((total % 60))"
    }

    status_recording() {
      if is_running; then
        elapsed="$(format_elapsed "$(elapsed_seconds)")"
        file="$(cat "$filefile" 2>/dev/null || printf '%s' "$out_dir")"
        if [ -s "$pausefile" ]; then
          notify "Screen recording paused" "Recording is paused - $elapsed"$'\n'"$file"
        else
          notify "Screen recording is currently ON" "Elapsed: $elapsed"$'\n'"$file"
        fi
        exit 0
      fi
      cleanup_state
      notify "Screen recording is OFF" "No active recording"
    }

    start_recording() {
      if is_running; then
        status_recording
        exit 0
      fi
      cleanup_state

      file="$out_dir/recording-$(date +%Y%m%d-%H%M%S).mp4"
      wf-recorder -f "$file" >"$logfile" 2>&1 &
      pid="$!"
      printf '%s\n' "$pid" > "$pidfile"
      printf '%s\n' "$(date +%s)" > "$startfile"
      printf '%s\n' "$file" > "$filefile"
      sleep 0.25

      if ! kill -0 "$pid" 2>/dev/null; then
        message="$(tail -n 5 "$logfile" 2>/dev/null || true)"
        cleanup_state
        notify "Screen recording failed" "wf-recorder could not start"$'\n'"$message"
        exit 1
      fi

      disown "$pid" 2>/dev/null || true
      notify "Screen recording started" "Recording is currently ON - 00:00:00"$'\n'"$file"
    }

    stop_recording() {
      if ! is_running; then
        cleanup_state
        notify "Screen recording is OFF" "No active recording"
        exit 0
      fi
      pid="$(live_pid)"
      elapsed="$(format_elapsed "$(elapsed_seconds)")"
      file="$(cat "$filefile" 2>/dev/null || printf '%s' "$out_dir")"
      kill -CONT "$pid" 2>/dev/null || true
      kill -INT "$pid" 2>/dev/null || true
      for _ in $(seq 1 50); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
      done
      cleanup_state
      notify "Screen recording saved" "Duration: $elapsed"$'\n'"$file"
    }

    pause_recording() {
      if ! is_running; then
        cleanup_state
        notify "Screen recording is OFF" "No active recording"
        exit 0
      fi
      if [ -s "$pausefile" ]; then
        status_recording
        exit 0
      fi
      pid="$(live_pid)"
      kill -STOP "$pid" 2>/dev/null || true
      printf '%s\n' "$(date +%s)" > "$pausefile"
      notify "Screen recording paused" "Paused at $(format_elapsed "$(elapsed_seconds)")"
    }

    resume_recording() {
      if ! is_running; then
        cleanup_state
        notify "Screen recording is OFF" "No active recording"
        exit 0
      fi
      pid="$(live_pid)"
      kill -CONT "$pid" 2>/dev/null || true
      rm -f "$pausefile"
      notify "Screen recording resumed" "Recording is currently ON - $(format_elapsed "$(elapsed_seconds)")"
    }

    case "''${1:-toggle}" in
      start) start_recording ;;
      stop) stop_recording ;;
      pause) pause_recording ;;
      resume) resume_recording ;;
      toggle-pause)
        if [ -s "$pausefile" ]; then
          resume_recording
        else
          pause_recording
        fi
        ;;
      status) status_recording ;;
      toggle)
        if is_running; then
          stop_recording
        else
          start_recording
        fi
        ;;
      *)
        printf 'usage: asura-screen-record-toggle [toggle|start|stop|pause|resume|toggle-pause|status]\n' >&2
        exit 64
        ;;
    esac
  '';

  asuraScreenshot = pkgs.writeShellScriptBin "asura-screenshot" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.grim
        pkgs.hyprland
        pkgs.jq
        pkgs.libnotify
        pkgs.slurp
        pkgs.swappy
        pkgs.wl-clipboard
      ]
    }:$PATH"

    mode="''${1:-full}"
    out_dir="''${XDG_SCREENSHOTS_DIR:-$HOME/Pictures/Screenshots}"
    mkdir -p "$out_dir"

    timestamp="$(date +%Y%m%d-%H%M%S)"
    file="$out_dir/screenshot-$timestamp.png"

    notify() {
      notify-send -a asura-screenshot "$@" --icon=applets-screenshooter >/dev/null 2>&1 || true
    }

    copy_file() {
      wl-copy --type image/png < "$file" >/dev/null 2>&1 || true
    }

    focused_output_geometry() {
      hyprctl monitors -j 2>/dev/null \
        | jq -r 'map(select(.focused == true))[0] // .[0] // empty | "\(.x),\(.y) \(.width)x\(.height)"' \
        2>/dev/null
    }

    active_window_geometry() {
      hyprctl activewindow -j 2>/dev/null \
        | jq -r 'select((.mapped // true) == true) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' \
        2>/dev/null
    }

    capture_region() {
      geometry="$(slurp 2>/dev/null || true)"
      [ -n "$geometry" ] || exit 0
      grim -g "$geometry" "$file"
    }

    capture_output() {
      geometry="$(focused_output_geometry)"
      if [ -n "$geometry" ]; then
        grim -g "$geometry" "$file"
      else
        grim "$file"
      fi
    }

    capture_window() {
      geometry="$(active_window_geometry)"
      if [ -n "$geometry" ]; then
        grim -g "$geometry" "$file"
      else
        grim "$file"
      fi
    }

    case "$mode" in
      full|screen|all)
        grim "$file"
        ;;
      region|area|select)
        capture_region
        ;;
      output|monitor)
        capture_output
        ;;
      window|active)
        capture_window
        ;;
      edit|swappy)
        grim "$file"
        swappy -f "$file" -o "$file" >/dev/null 2>&1 &
        ;;
      region-edit|area-edit|select-edit)
        capture_region
        swappy -f "$file" -o "$file" >/dev/null 2>&1 &
        ;;
      *)
        printf 'usage: asura-screenshot [full|region|output|window|edit|region-edit]\n' >&2
        exit 64
        ;;
    esac

    copy_file
    notify "Screenshot captured" "Saved and copied"$'\n'"$file"
    printf '%s\n' "$file"
  '';
in
{
  inherit asuraScreenRecordToggle asuraScreenshot;
}
