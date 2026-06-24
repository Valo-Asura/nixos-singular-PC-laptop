# Shared module: one default VibeShell/Quickshell config under shells/vibeshell.
{
  config,
  pkgs,
  ...
}:

let
  vibeshellRoot = ../../shells/vibeshell;
  hyprlandPackage = config.programs.hyprland.package;
  vibeshellPhosphorIcons = import (vibeshellRoot + "/nix/packages/phosphor-icons.nix") {
    inherit pkgs;
  };
  vibeshellFonts = pkgs.symlinkJoin {
    name = "asura-vibeshell-fonts";
    paths = [
      vibeshellPhosphorIcons
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.nerd-fonts.symbols-only
    ];
  };
  vibeshellFontconfig = pkgs.writeTextDir "etc/fonts/conf.d/99-asura-vibeshell-fonts.conf" ''
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
    <fontconfig>
      <dir>${vibeshellFonts}/share/fonts</dir>
    </fontconfig>
  '';
  vibeshellSafeLock = pkgs.writeShellApplication {
    name = "vibeshell-safe-lock";
    runtimeInputs = with pkgs; [
      coreutils
      hyprlock
      procps
    ];
    text = ''
      if pgrep -u "$(id -u)" -x hyprlock >/dev/null 2>&1; then
        exit 0
      fi

      exec hyprlock "$@"
    '';
  };
  asuraVibeshell = pkgs.writeShellApplication {
    name = "asura-vibeshell";
    runtimeInputs =
      with pkgs;
      [
        bash
        brightnessctl
        coreutils
        dbus
        findutils
        fontconfig
        gawk
        glib
        gnugrep
        grim
        hyprlock
        hyprpicker
        hyprshutdown
        jq
        libnotify
        matugen
        mpvpaper
        networkmanager
        hicolor-icon-theme
        papirus-icon-theme
        playerctl
        procps
        pulseaudio
        quickshell
        slurp
        util-linux
        wl-clipboard
        wlogout
        xdg-utils
      ]
      ++ [
        hyprlandPackage
        vibeshellSafeLock
        vibeshellFonts
        vibeshellPhosphorIcons
      ];
    text = ''
      export VIBESHELL_QS="${pkgs.quickshell}/bin/qs"
      export QS_ICON_THEME="''${QS_ICON_THEME:-Papirus-Dark}"
      export VIBESHELL_WEATHER_LOCATION="''${VIBESHELL_WEATHER_LOCATION:-Rishikesh, Uttarakhand, India}"
      export VIBESHELL_WEATHER_COORDS="''${VIBESHELL_WEATHER_COORDS:-30.0869,78.2676}"
      export FONTCONFIG_PATH="${vibeshellFontconfig}/etc/fonts:${pkgs.fontconfig.out}/etc/fonts:''${FONTCONFIG_PATH:-}"
      export XDG_DATA_DIRS="${vibeshellFonts}/share:${pkgs.papirus-icon-theme}/share:${pkgs.hicolor-icon-theme}/share:${pkgs.gtk3}/share:${pkgs.shared-mime-info}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
      exec ${vibeshellRoot}/cli.sh "$@"
    '';
  };
in
{
  environment.systemPackages = [
    asuraVibeshell
    vibeshellSafeLock
    pkgs.quickshell
  ];

  environment.etc."xdg/quickshell/vibeshell".source = vibeshellRoot;

  home-manager.users.asura.home.packages = [
    asuraVibeshell
    vibeshellSafeLock
  ];
}
