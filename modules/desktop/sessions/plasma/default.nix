# Shared session factory: Plasma 6 (KDE) Wayland session for greetd/tuigreet.
{ pkgs, ... }:

let
  plasmaWorkspace = pkgs.kdePackages.plasma-workspace;

  startWayland = pkgs.writeShellScriptBin "asura-start-plasma" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/plasma"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/plasma"
    else
      state_dir="/tmp/asura-plasma-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/session.log" 2>&1

    echo "---- plasma wayland session: $(date -Is) ----"

    # Drop Hyprland/qt6ct leftovers so Plasma owns Qt theming and XDG desktop IDs.
    unset QT_QPA_PLATFORMTHEME QT_STYLE_OVERRIDE
    export XDG_CURRENT_DESKTOP=KDE
    export XDG_SESSION_DESKTOP=KDE
    export XDG_SESSION_TYPE=wayland
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland,x11
    export QT_QPA_PLATFORM="wayland;xcb"
    export SDL_VIDEODRIVER=wayland,x11
    export MOZ_ENABLE_WAYLAND=1

    dbus-update-activation-environment --systemd \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true
    systemctl --user import-environment \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true

    exec ${plasmaWorkspace}/libexec/plasma-dbus-run-session-if-needed \
      ${plasmaWorkspace}/bin/startplasma-wayland
  '';
in
{
  start = startWayland;

  desktopEntry = ''
    [Desktop Entry]
    Name=Plasma (Wayland)
    Comment=KDE Plasma 6 Wayland desktop session
    Exec=${startWayland}/bin/asura-start-plasma
    Type=Application
    DesktopNames=KDE
  '';

  packages = [
    startWayland
  ];
}
