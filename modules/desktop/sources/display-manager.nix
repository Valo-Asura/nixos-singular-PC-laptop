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

    export XDG_CURRENT_DESKTOP=Hyprland
    export XDG_SESSION_DESKTOP=Hyprland
    export XDG_SESSION_TYPE=wayland

    exec ${config.programs.hyprland.package}/bin/start-hyprland >>"$state_dir/session.log" 2>&1
  '';

  labwcSession = import ../sessions/labwc {
    inherit
      inputs
      lib
      pkgs
      ;
  };

  plasmaSession = import ../sessions/plasma {
    inherit pkgs;
  };
in
{
  # Registered sessions in greetd tuigreet menu: Hyprland (Quickshell/VibeShell), Labwc & Plasma 6.
  environment.etc."asura-wayland-sessions/hyprland.desktop".text = ''
    [Desktop Entry]
    Name=Hyprland (Quickshell / VibeShell)
    Comment=Asura Hyprland session with Quickshell VibeShell backend
    Exec=${quietHyprlandSession}
    Type=Application
  '';

  environment.etc."asura-wayland-sessions/labwc.desktop".text = labwcSession.desktopEntry;
  environment.etc."asura-wayland-sessions/plasma.desktop".text = plasmaSession.desktopEntry;

  # Full Plasma 6 desktop; selectable from tuigreet. Hyprland is the greeter default.
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm.enable = lib.mkForce false;
  services.orca.enable = lib.mkForce false;

  services.greetd = {
    enable = true;
    settings.default_session = {
      command = "${pkgs.tuigreet}/bin/tuigreet --remember --remember-session --asterisks --container-padding 2 --time --time-format '%I:%M %p | %a • %h | %F' --sessions /etc/asura-wayland-sessions --cmd ${quietHyprlandSession}";
      user = "greeter";
    };
  };

  security.pam.services.greetd.enableGnomeKeyring = true;
  security.pam.services.greetd.kwallet = {
    enable = true;
    package = pkgs.kdePackages.kwallet-pam;
  };
  security.pam.services.hyprlock = { };

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

  environment.systemPackages = plasmaSession.packages ++ labwcSession.packages;
}
