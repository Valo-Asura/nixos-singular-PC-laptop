# Shared module: Noctalia shell integration and custom config files.
{
  inputs,
  pkgs,
  config,
  lib,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  enabled = (config.asura.shell.active or null) == "noctalia";
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  noctaliaSafeLock = pkgs.writeShellScriptBin "noctalia-safe-lock" ''
    set -euo pipefail
    exec ${noctaliaPackage}/bin/noctalia msg session lock "$@"
  '';
in
{
  config = lib.mkIf enabled {
    # Upstream cache for Noctalia v5.
    nix.settings = {
      extra-substituters = [ "https://noctalia.cachix.org" ];
      extra-trusted-public-keys = [
        "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
      ];
    };

    environment.systemPackages = [
      noctaliaPackage
      noctaliaSafeLock
    ];

    services = {
      tlp.enable = lib.mkForce false;
      upower.enable = lib.mkDefault true;
      tuned.enable = true;
    };

    home-manager.users.asura = {
      imports = [
        inputs.noctalia.homeModules.default
      ];

      programs.noctalia = {
        enable = true;
        systemd.enable = true;
        package = noctaliaPackage;
        settings = ./settings.toml;
      };
      # Force disable HM fish and neovim to prevent conflicts, so we can link files manually
      programs.fish.enable = lib.mkForce false;
      programs.neovim.enable = lib.mkForce false;

      # Foot terminal configuration
      xdg.configFile."foot/foot.ini".source = lib.mkForce ./foot.ini;
      xdg.configFile."foot/themes/noctalia".source = lib.mkForce ./foot-noctalia-theme;

      # Tmux
      home.file.".tmux.conf".source = ./tmux.conf;

      # Zed settings
      xdg.configFile."zed/settings.json".source = ./zed-settings.json;

      # Neovim
      xdg.configFile."nvim/init.lua".source = ./nvim/init.lua;
      xdg.configFile."nvim/lazy-lock.json".source = ./nvim/lazy-lock.json;

      # Fastfetch
      xdg.configFile."fastfetch/config.jsonc".source = ./fastfetch/config.jsonc;

      # Fish shell configuration
      xdg.configFile."fish/config.fish" = {
        source = ./fish/config.fish;
        force = true;
      };
      xdg.configFile."fish/fish_variables" = {
        source = ./fish/fish_variables;
        force = true;
      };

      # Noctalia state
      home.file.".local/state/noctalia/state.toml".source = ./state.toml;

      # Mime Types
      xdg.mimeApps = {
        enable = true;
        defaultApplications = lib.mkForce {
          "inode/directory" = "pcmanfm-qt.desktop";
          "x-scheme-handler/antigravity" = "antigravity-url-handler.desktop";
          "x-scheme-handler/antigravity-ide" = "antigravity-url-handler.desktop";
          "text/plain" = "cursor.desktop";
          "application/zip" = "xarchiver.desktop";
          "application/x-7z-compressed" = "xarchiver.desktop";
          "application/vnd.rar" = "xarchiver.desktop";
          "application/x-rar" = "xarchiver.desktop";
          "application/x-tar" = "xarchiver.desktop";
          "application/gzip" = "xarchiver.desktop";
          "application/x-bzip2" = "xarchiver.desktop";
          "application/x-xz" = "xarchiver.desktop";
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";
          "image/png" = "org.gnome.Loupe.desktop";
          "image/jpeg" = "org.gnome.Loupe.desktop";
          "image/webp" = "org.gnome.Loupe.desktop";
          "image/gif" = "org.gnome.Loupe.desktop";
          "image/avif" = "org.gnome.Loupe.desktop";
          "image/bmp" = "org.gnome.Loupe.desktop";
          "image/tiff" = "org.gnome.Loupe.desktop";
          "image/svg+xml" = "org.gnome.Loupe.desktop";
          "application/pdf" = "org.kde.okular.desktop";
          "application/epub+zip" = "org.kde.okular.desktop";
          "application/x-fictionbook" = "org.kde.okular.desktop";
          "application/postscript" = "org.kde.okular.desktop";
          "image/vnd.djvu" = "org.kde.okular.desktop";
          "application/zstd" = "xarchiver.desktop";
          "application/x-lz4" = "xarchiver.desktop";
          "application/x-iso9660-image" = "xarchiver.desktop";
          "video/mp4" = "mpv.desktop";
          "video/x-matroska" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "video/x-msvideo" = "mpv.desktop";
          "video/quicktime" = "mpv.desktop";
          "audio/mpeg" = "mpv.desktop";
          "audio/flac" = "mpv.desktop";
          "audio/ogg" = "mpv.desktop";
          "audio/x-wav" = "mpv.desktop";
          "audio/mp4" = "mpv.desktop";
          "text/markdown" = "cursor.desktop";
          "text/x-python" = "cursor.desktop";
          "text/x-csrc" = "cursor.desktop";
          "text/x-chdr" = "cursor.desktop";
          "text/x-c++src" = "cursor.desktop";
          "text/x-c++hdr" = "cursor.desktop";
          "application/json" = "cursor.desktop";
          "application/x-shellscript" = "cursor.desktop";
          "application/xml" = "firefox.desktop";
          "text/css" = "cursor.desktop";
          "application/javascript" = "cursor.desktop";
          "application/xhtml+xml" = "firefox.desktop";
          "image/jpg" = "org.gnome.Loupe.desktop";
          "image/heic" = "org.gnome.Loupe.desktop";
          "image/heif" = "org.gnome.Loupe.desktop";
          "image/jxl" = "org.gnome.Loupe.desktop";
          "application/x-zip-compressed" = "xarchiver.desktop";
          "application/x-compressed-tar" = "xarchiver.desktop";
          "application/x-bzip-compressed-tar" = "xarchiver.desktop";
          "application/x-xz-compressed-tar" = "xarchiver.desktop";
          "x-scheme-handler/mailto" = "helium.desktop";
          "text/xml" = "firefox.desktop";
          "application/x-gnome-saved-search" = "pcmanfm-qt.desktop";
          "x-scheme-handler/postman" = "Postman.desktop";
          "application/xdm-app" = "xdm-app.desktop";
          "x-scheme-handler/xdm-app" = "xdm-app.desktop";
          "x-scheme-handler/xdm+app" = "xdm-app.desktop";
        };
      };
    };
  };
}
