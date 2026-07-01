# System GUI Applications Configuration
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  whatsapp = pkgs.callPackage ./whatsappwrap.nix { };
  xdman = pkgs.callPackage ./xdman.nix { };
  desktopScripts = pkgs.callPackage ./desktop-scripts.nix { };
  superProductivity = pkgs.callPackage ./super-productivity.nix { };
in
{
  environment.systemPackages = [
    # Web Browsers
    pkgs.google-chrome # Standard Chrome browser; main web navigator
    inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default # Helium lightweight browser/editor

    # File Management & Archive
    pkgs.pcmanfm-qt # Lightweight file manager; fast alternative browser
    pkgs.gnome-disk-utility # Disk configuration tool; format & partition UI
    pkgs.xarchiver # Desktop archiver; handles ZIP, RAR, 7z formats
    pkgs.loupe # GNOME image viewer; quick pictures browser
    pkgs.kdePackages.okular # Multi-format document viewer; opens PDFs and epubs

    # Multimedia Players & Editors
    pkgs.mpv # Minimal media player; handles audio/video formats
    pkgs.easyeffects # Audio effects processor; system-wide equalizer control
    pkgs.freetube # Private YouTube player; ad-free video streaming
    pkgs.kdePackages.kdenlive # Video editing application; multi-track editor
    pkgs.obs-studio # Streaming/recording suite; captures gameplay & webcam
    pkgs.pwvucontrol # PipeWire mixer GUI; monitors nodes routing

    # IDEs, Editors & AI tools
    (pkgs.callPackage ./cursor.nix { }) # Cursor AI Editor; agentic development IDE
    pkgs.zed-editor # High performance code editor; fast editing sessions
    pkgs.vscode # Visual Studio Code editor; fallback coding environment

    # Database Administration Tools
    pkgs.mysql-workbench # MySQL admin panel; edits local developer databases
    pkgs.mongodb-compass # MongoDB GUI explorer; queries local developer collections

    # Social & Instant Messaging
    pkgs.telegram-desktop # Telegram messenger client; developer chats
    whatsapp.whatsappWeb # Custom script wrapper; keeps WhatsApp Web on Intel GPU
    whatsapp.whatsappWebDesktop # WhatsApp Web desktop item shortcut

    # Desktop Utilities & Controls
    pkgs.piper # Mouse setup tool; configures Logitech gaming mice profiles
    pkgs.solaar # Receiver manager; manages Logitech wireless keyboards/mice
    desktopScripts.asuraScreenshot # Screenshot script; handles region and full captures
    desktopScripts.asuraScreenRecordToggle # Screen recording script; controls start/stop processes
    pkgs.nwg-look # Theme selection UI; styles GTK apps on Wayland

    # Productivity & Time Management
    pkgs.super-productivity # Task manager; tracks developer assignments
    superProductivity.asuraSuperProductivity # Wrapper launcher; runs Super Productivity on Wayland
    superProductivity.asuraSuperProductivityBridge # Export bridge; synchronizes Vibeshell notes with tasks

    # Desktop download managers
    xdman.xdmanGtk # Xtreme Download Manager; accelerates file fetches
    xdman.xdmOpen # Smart launcher; works around Wayland double-instance segfaults
  ];

  systemd.tmpfiles.rules = [
    "L+ /opt/xdman - - - - ${xdman.xdmanGtk}/opt/xdman"
  ];

  systemd.user.services.xdman = {
    description = "Xtreme Download Manager browser monitor bridge";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = lib.mkForce [ ];
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
    serviceConfig = {
      ExecStart = "${xdman.xdmanGtk}/bin/xdman --background";
      Restart = "on-failure";
      RestartSec = 15;
      Environment = "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
  };
}
