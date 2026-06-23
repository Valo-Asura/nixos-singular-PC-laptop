# Optional Quickshell profiles for the normal Hyprland session.
{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:

let
  caelestiaSource = ./profiles/caelestia;
  ricelinShellRoot = ./profiles/ricelin;
  dotfilesShellRoot = ./profiles/dotfiles;
  tideIslandSource = ./profiles/tide-island;
  vibeshellRoot = ./profiles/vibeshell;
  nandoroidRoot = ./profiles/nandoroid;
  waybarRoot = ../waybar;
  colorshellRyoRoot = ../ags-v3-colorshell-ryo;
  vibeshellPhosphorIcons = import "${vibeshellRoot}/nix/packages/phosphor-icons.nix" {
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
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  hyprlandPackage = config.programs.hyprland.package;

  buildCliStub = pkgs.writeShellScriptBin "caelestia-build-stub" ''
    echo "caelestia-cli is not used while building the Asura Hyprland profile" >&2
    exit 127
  '';

  caelestiaShell = pkgs.callPackage "${caelestiaSource}/nix" {
    rev = "asura-hyprland-local";
    stdenv = pkgs.clangStdenv;
    quickshell = pkgs.quickshell;
    hyprland = hyprlandPackage;
    caelestia-cli = buildCliStub;
    withCli = false;
    extraRuntimeDeps = with pkgs; [
      foot
      grim
      hyprlandPackage
      libnotify
      slurp
      wl-clipboard
      xdg-utils
    ];
  };

  caelestiaCli = pkgs.writeShellApplication {
    name = "caelestia";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      libnotify
      quickshell
    ];
    text = ''
      set -euo pipefail

      config_path="${caelestiaShell}/share/caelestia-shell"
      state_dir="''${XDG_STATE_HOME:-$HOME/.local/state}/caelestia/wallpaper"
      state_file="$state_dir/path.txt"

      usage() {
        printf '%s\n' \
          'usage:' \
          '  caelestia shell -s' \
          '  caelestia shell -d' \
          '  caelestia shell TARGET FUNCTION [ARGS...]' \
          '  caelestia wallpaper -f PATH' \
          '  caelestia wallpaper -r' >&2
      }

      if [ "$#" -eq 0 ]; then
        usage
        exit 64
      fi

      case "$1" in
        shell)
          shift
          case "''${1:-}" in
            -d|daemon)
              exec ${caelestiaShell}/bin/caelestia-shell
              ;;
            -s|status|show)
              exec qs ipc --any-display -p "$config_path" show
              ;;
          esac

          if [ "$#" -lt 2 ]; then
            usage
            exit 64
          fi

          target="$1"
          function="$2"
          shift 2
          exec qs ipc --any-display -p "$config_path" call "$target" "$function" "$@"
          ;;

        wallpaper)
          shift
          mkdir -p "$state_dir"
          case "''${1:-}" in
            -f|--file|set)
              path="''${2:-}"
              if [ -z "$path" ]; then
                echo "caelestia wallpaper: missing path" >&2
                exit 64
              fi
              printf '%s\n' "$path" > "$state_file"
              notify-send -a caelestia-shell "Wallpaper selected" "$path" 2>/dev/null || true
              ;;
            -p|--preview)
              printf '{}\n'
              ;;
            -r|--random|random)
              walls="''${CAELESTIA_WALLPAPERS_DIR:-$HOME/Pictures/Wallpapers}"
              path="$(
                find "$walls" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) 2>/dev/null \
                  | shuf -n 1
              )"
              if [ -z "$path" ]; then
                echo "caelestia wallpaper: no wallpapers found in $walls" >&2
                exit 1
              fi
              printf '%s\n' "$path" > "$state_file"
              notify-send -a caelestia-shell "Wallpaper selected" "$path" 2>/dev/null || true
              ;;
            get)
              test -s "$state_file" && cat "$state_file"
              ;;
            *)
              usage
              exit 64
              ;;
          esac
          ;;

        scheme)
          exit 0
          ;;

        record)
          if command -v asura-screen-record-toggle >/dev/null 2>&1; then
            exec asura-screen-record-toggle toggle
          fi
          echo "recording helper is unavailable" >&2
          exit 127
          ;;

        *)
          usage
          exit 64
          ;;
      esac
    '';
  };

  tideIsland = pkgs.stdenv.mkDerivation {
    pname = "tide-island-asura";
    version = "1.0.11-local";
    src = tideIslandSource;

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
      pkg-config
      makeWrapper
      qt6.wrapQtAppsHook
    ];

    buildInputs = with pkgs; [
      qt6.qtbase
      qt6.qtdeclarative
      qt6.qtconnectivity
      qt6.qtsvg
      qt6.qtwayland
      quickshell
      systemd
    ];

    propagatedBuildInputs = with pkgs; [
      bluez
      brightnessctl
      cava
      dbus
      hyprlandPackage
      imagemagick
      networkmanager
      pavucontrol
      playerctl
      pulseaudio
      quickshell
      upower
      wireplumber
    ];

    dontWrapQtApps = true;

    cmakeFlags = [
      (lib.cmakeFeature "CMAKE_BUILD_TYPE" "Release")
      (lib.cmakeFeature "CMAKE_INSTALL_LIBDIR" "lib")
    ];

    postInstall = ''
      rm -f $out/bin/tide-island
      makeWrapper ${pkgs.quickshell}/bin/qs $out/bin/tide-island \
        --prefix PATH : "${
          lib.makeBinPath [
            pkgs.bluez
            pkgs.brightnessctl
            pkgs.cava
            pkgs.dbus
            hyprlandPackage
            pkgs.imagemagick
            pkgs.networkmanager
            pkgs.pavucontrol
            pkgs.playerctl
            pkgs.pulseaudio
            pkgs.upower
            pkgs.wireplumber
          ]
        }" \
        --prefix QML2_IMPORT_PATH : "$out/lib/qt6/qml" \
        --prefix QML_IMPORT_PATH : "$out/lib/qt6/qml" \
        --set QUICKSHELL_LYRICS_BACKEND "$out/share/tide-island/bin/lyricsmpris" \
        --add-flags "-p $out/share/tide-island"
    '';

    postFixup = ''
      wrapQtApp $out/bin/tide-island
      wrapQtApp $out/share/tide-island/bin/lyricsmpris
      wrapQtApp $out/share/tide-island/bin/tide-island-setup
    '';

    meta = {
      description = "Tide Island dynamic island Quickshell profile packaged for Asura Hyprland";
      homepage = "https://github.com/enhaoswen/Tide-island";
      license = lib.licenses.unfreeRedistributable;
      mainProgram = "tide-island";
    };
  };

  asuraWaybar = pkgs.writeShellApplication {
    name = "asura-waybar";
    runtimeInputs = with pkgs; [
      coreutils
      hyprlandPackage
      jq
      networkmanagerapplet
      waybar
    ];
    text = ''
      exec waybar \
        -c /etc/xdg/waybar-asura/config.jsonc \
        -s /etc/xdg/waybar-asura/style.css "$@"
    '';
  };

  asuraWaybarSysbar = pkgs.writeShellApplication {
    name = "asura-waybar-sysbar";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      gnugrep
      procps
    ];
    text = builtins.readFile "${waybarRoot}/scripts/sysbar.sh";
  };

  asuraWaybarWorkspaces = pkgs.writeShellApplication {
    name = "asura-waybar-workspaces";
    runtimeInputs = [
      hyprlandPackage
      pkgs.jq
    ];
    text = builtins.readFile "${waybarRoot}/scripts/workspaces.sh";
  };

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

  asuraNandoroid = pkgs.writeShellApplication {
    name = "asura-nandoroid";
    runtimeInputs =
      with pkgs;
      [
        bash
        bluez
        brightnessctl
        coreutils
        dbus
        findutils
        gawk
        glib
        gnugrep
        grim
        imagemagick
        jq
        libnotify
        matugen
        networkmanager
        pavucontrol
        playerctl
        procps
        pulseaudio
        quickshell
        slurp
        util-linux
        wireplumber
        wl-clipboard
        xdg-utils
      ]
      ++ [ hyprlandPackage ];
    text = ''
      export QS_ICON_THEME="''${QS_ICON_THEME:-Papirus-Dark}"
      export XDG_DATA_DIRS="${pkgs.gtk3}/share:${pkgs.shared-mime-info}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"

      case "''${1:-}" in
        launcher|spotlight|notifications|quicksettings|systemmonitor|overview|session|dashboard|quickactions|settings)
          target="$1"
          method="''${2:-toggle}"
          shift 2 || true
          exec qs -c nandoroid ipc call "$target" "$method" "$@"
          ;;
        wallpaper)
          target="$1"
          method="''${2:-openDesktop}"
          shift 2 || true
          exec qs -c nandoroid ipc call "$target" "$method" "$@"
          ;;
        pomodoro)
          target="$1"
          method="''${2:-start}"
          shift 2 || true
          exec qs -c nandoroid ipc call "$target" "$method" "$@"
          ;;
        "")
          exec qs -c nandoroid
          ;;
        *)
          exec qs -c nandoroid "$@"
          ;;
      esac
    '';
  };

  colorshellRyoPackage = inputs.colorshell-ryo.packages.${system}.colorshell;

  asuraColorshellRyo = pkgs.writeShellApplication {
    name = "asura-colorshell-ryo";
    runtimeInputs =
      with pkgs;
      [
        bluez
        brightnessctl
        coreutils
        grim
        hyprlandPackage
        jq
        libnotify
        networkmanager
        pavucontrol
        playerctl
        procps
        pulseaudio
        slurp
        socat
        util-linux
        wireplumber
        wl-clipboard
        wlogout
        xdg-utils
      ]
      ++ [ colorshellRyoPackage ];
    text = ''
      export XDG_DATA_DIRS="${pkgs.gtk4}/share:${pkgs.gtk3}/share:${pkgs.shared-mime-info}/share:''${XDG_DATA_DIRS:-/run/current-system/sw/share}"
      export GIO_EXTRA_MODULES="${pkgs.dconf.lib}/lib/gio/modules:''${GIO_EXTRA_MODULES:-}"
      exec ${colorshellRyoPackage}/bin/colorshell "$@"
    '';
  };

  quickShellSwitch = pkgs.writeShellApplication {
    name = "asura-quickshell-switch";
    runtimeInputs = with pkgs; [
      bluez
      brightnessctl
      coreutils
      gawk
      glib
      gnugrep
      jq
      libnotify
      networkmanager
      pavucontrol
      playerctl
      procps
      python3
      quickshell
      socat
      systemd
      util-linux
      wireplumber
      xdg-utils
    ];
    text =
      builtins.replaceStrings
        [
          "@RICELIN_QUICKSHELL_PATH@"
          "@DOTFILES_QUICKSHELL_PATH@"
          "@CAELESTIA_SHELL_BIN@"
          "@TIDE_ISLAND_BIN@"
          "@ASURA_ISLAND_PATH@"
          "@VIBESHELL_BIN@"
          "@VIBESHELL_PATH@"
          "@NANDOROID_BIN@"
          "@NANDOROID_PATH@"
          "@COLORSHELL_RYO_BIN@"
          "@WAYBAR_BIN@"
          "@NOCTALIA_BIN@"
        ]
        [
          "/etc/xdg/quickshell/ricelin"
          "/etc/xdg/quickshell/dotfiles"
          "${caelestiaShell}/bin/caelestia-shell"
          "${tideIsland}/bin/tide-island"
          "/home/asura/Projects/asura-island-shell"
          "${asuraVibeshell}/bin/asura-vibeshell"
          "/etc/xdg/quickshell/vibeshell"
          "${asuraNandoroid}/bin/asura-nandoroid"
          "/etc/xdg/quickshell/nandoroid"
          "${asuraColorshellRyo}/bin/asura-colorshell-ryo"
          "${asuraWaybar}/bin/asura-waybar"
          "${noctaliaPackage}/bin/noctalia"
        ]
        (builtins.readFile ./scripts/asura-quickshell-switch);
  };

  shellLauncher = pkgs.writeShellApplication {
    name = "asura-shell-launcher";
    runtimeInputs =
      (with pkgs; [
        coreutils
        gawk
        gnugrep
        jq
        libnotify
        procps
        quickshell
      ])
      ++ [
        hyprlandPackage
      ];
    text =
      builtins.replaceStrings
        [
          "@CAELESTIA_BIN@"
          "@DOTFILES_QUICKSHELL_PATH@"
          "@RICELIN_QUICKSHELL_PATH@"
          "@TIDE_ISLAND_PATH@"
          "@ASURA_ISLAND_PATH@"
          "@VIBESHELL_BIN@"
          "@VIBESHELL_PATH@"
          "@NANDOROID_BIN@"
          "@NANDOROID_PATH@"
          "@COLORSHELL_RYO_BIN@"
          "@NOCTALIA_BIN@"
        ]
        [
          "${caelestiaCli}/bin/caelestia"
          "/etc/xdg/quickshell/dotfiles"
          "/etc/xdg/quickshell/ricelin"
          "${tideIsland}/share/tide-island"
          "/home/asura/Projects/asura-island-shell"
          "${asuraVibeshell}/bin/asura-vibeshell"
          "/etc/xdg/quickshell/vibeshell"
          "${asuraNandoroid}/bin/asura-nandoroid"
          "/etc/xdg/quickshell/nandoroid"
          "${asuraColorshellRyo}/bin/asura-colorshell-ryo"
          "${noctaliaPackage}/bin/noctalia"
        ]
        (builtins.readFile ./scripts/asura-shell-launcher);
  };
in
{
  environment.systemPackages = [
    caelestiaCli
    caelestiaShell
    asuraWaybar
    asuraWaybarSysbar
    asuraWaybarWorkspaces
    asuraVibeshell
    vibeshellSafeLock
    asuraNandoroid
    asuraColorshellRyo
    pkgs.quickshell
    pkgs.waybar
    quickShellSwitch
    shellLauncher
    asuraColorshellRyo
    tideIsland
  ];

  environment.etc = {
    "xdg/quickshell/caelestia".source = "${caelestiaShell}/share/caelestia-shell";
    "xdg/quickshell/ricelin".source = ricelinShellRoot;
    "xdg/quickshell/dotfiles".source = dotfilesShellRoot;
    "xdg/quickshell/tide-island".source = "${tideIsland}/share/tide-island";
    "xdg/quickshell/vibeshell".source = vibeshellRoot;
    "xdg/quickshell/nandoroid".source = nandoroidRoot;
    "xdg/waybar-asura".source = waybarRoot;
  };

  home-manager.users.asura = {
    home.packages = [
      quickShellSwitch
      shellLauncher
      asuraWaybar
      asuraWaybarSysbar
      asuraWaybarWorkspaces
      asuraVibeshell
      vibeshellSafeLock
      asuraNandoroid
      asuraColorshellRyo
    ];

    systemd.user.services.noctalia = {
      Service.KillMode = lib.mkForce "process";
      Install.WantedBy = lib.mkForce [ ];
    };

    xdg.configFile."asura-shell/profiles.txt".text = ''
      vibeshell
      noctalia
      caelestia
      ricelin
      dotfiles
      tide-island
      asura-island
      nandoroid
      colorshell-ryo
      waybar
    '';
  };
}
