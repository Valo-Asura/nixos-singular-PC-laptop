# Shared module: greetd display manager and session registration.
{
  config,
  inputs,
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

  asuraX11Terminal = pkgs.writeShellScriptBin "asura-x11-terminal" ''
    set -uo pipefail

    export GDK_BACKEND=x11
    export QT_QPA_PLATFORM=xcb
    export SDL_VIDEODRIVER=x11
    export CLUTTER_BACKEND=x11
    export NIXOS_OZONE_WL=0
    export DRI_PRIME=0
    export __NV_PRIME_RENDER_OFFLOAD=0

    if [ -n "''${DISPLAY:-}" ] && [ -x ${pkgs.kitty}/bin/kitty ]; then
      exec ${pkgs.kitty}/bin/kitty "$@"
    fi

    exec ${pkgs.xterm}/bin/xterm "$@"
  '';

  bspwmSession = import ../sessions/bspwm {
    inherit
      asuraX11Terminal
      config
      lib
      pkgs
      ;
  };

  qtileSession = import ../sessions/qtile {
    inherit
      asuraX11Terminal
      lib
      pkgs
      ;
  };

  swaySession = import ../sessions/sway {
    inherit
      inputs
      lib
      pkgs
      ;
  };

  xorgConfig = pkgs.writeText "asura-xorg-fallback.conf" ''
    Section "ServerFlags"
      Option "AllowMouseOpenFail" "on"
      Option "DontZap" "on"
    EndSection

    Section "InputClass"
      Identifier "asura libinput keyboard"
      MatchIsKeyboard "on"
      Driver "libinput"
      Option "XkbLayout" "us"
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
      set -- ${bspwmSession.start}/bin/asura-start-bspwm
    fi

    echo "starting Xorg on :$display"
    exec ${pkgs.xinit}/bin/startx "$@" -- ":$display" \
      -config ${xorgConfig} \
      -modulepath ${lib.escapeShellArg xorgModulePath} \
      -nolisten tcp
  '';
in
{
  # Shared login/session menu for laptop and PC. Hyprland remains the default,
  # BSPWM/Qtile are X11 fallbacks, and Sway is an experimental Wayland option.

  environment.etc."asura-wayland-sessions/noctalia-hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Noctalia + Hyprland
    Comment=Current Asura Hyprland session with Noctalia
    Exec=${quietHyprlandSession}
    Type=Application
  '';

  environment.etc."asura-wayland-sessions/noctalia-sway.desktop".text = swaySession.desktopEntry;
  environment.etc."asura-xsessions/bspwm.desktop".text = bspwmSession.desktopEntry;
  environment.etc."asura-xsessions/qtile.desktop".text = qtileSession.desktopEntry;

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
    asuraX11Terminal
    xsessionWrapper
    pkgs.xinit
    pkgs.xauth
    pkgs.xf86-input-evdev
    pkgs.xf86-input-libinput
    pkgs.xorg-server
  ]
  ++ bspwmSession.packages
  ++ qtileSession.packages
  ++ swaySession.packages;
}
