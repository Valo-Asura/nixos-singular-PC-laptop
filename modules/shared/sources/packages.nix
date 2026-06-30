# System Packages Configuration (CLI, Libraries, and System Utilities)
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  antigravityPkg = pkgs.callPackage ./antigravity.nix { };
  mysqlInfo = pkgs.callPackage ./mysql-info.nix { };
in
{
  environment.systemPackages = with pkgs; [
    # System Info & Terminal
    zsh       # Shell environment; used by terminal emulators (kitty, foot, ghostty, warp)

    # System Tools
    polkit    # Privilege elevation framework; used by system services and file managers
    udisks2   # Storage daemon; used by file managers for disk mounting
    udiskie   # Udisks2 tray wrapper; used by window managers for auto-mounting drives

    # Screenshot and Screen Recording (Utilities used by screenshot/record scripts)
    grimblast # Screenshot CLI tool; used by asuraScreenshot
    swappy    # Screenshot editor; used by asuraScreenshot to modify captured regions

    # Polkit Agent
    inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default # Polkit GUI agent; used by Hyprland to prompt for auth

    # File Management & NTFS Support (Libraries used by file managers)
    gvfs      # GNOME virtual filesystem; used by Nautilus for trash, admin paths, and network mounts
    ntfs3g    # NTFS driver; used by Nautilus/Disks to read/write Windows partitions
    exfat     # exFAT support; used by file managers to mount USB flash drives

    # Desktop Environment
    xdg-utils      # Desktop integration tools; used by apps to open links in default browser
    networkmanager # Network controller; used by the desktop system tray
    tuigreet       # TUI login manager; used at boot time to select desktop session
    xdg-user-dirs  # User directories management; used to handle standard folders (Downloads, Pictures)

    # Desktop shell support and rollback helpers
    (writeShellScriptBin "internet-unblock" "") # Network rollback helper; used by maintenance scripts
    dconf                      # Configuration DB system; used by GTK apps to save user settings
    gtk3                       # GTK 3 toolkit library; used by GTK applications
    gtk4                       # GTK 4 toolkit library; used by modern desktop apps
    adw-gtk3                   # Libadwaita theme for GTK3; used to unify app aesthetics
    adwaita-icon-theme         # GNOME default icon theme; used by file managers and system tools
    hicolor-icon-theme         # Fallback icon theme; used by desktop environment spec
    papirus-icon-theme         # Papirus icon theme; main system icon style
    kdePackages.breeze-icons   # Breeze icons; used by Qt/KDE programs
    gsettings-desktop-schemas  # System settings schemas; used by GTK portals to read font/theme
    at-spi2-atk                # Accessibility bridge; used by GTK apps for screen readers
    at-spi2-core               # Accessibility core; used by GTK/Qt GUI apps
    libgtop                    # System monitoring library; used by btop and VibeShell widgets

    # Multimedia (CLI utilities and dependencies)
    alsa-utils   # ALSA volume utilities; used by system audio control scripts
    v4l-utils    # Video4Linux tools; used by OBS Studio for webcams

    # Hyprland Panel Dependencies (Utilities used by waybar, walker, and vibeshell)
    bluez                           # Bluetooth stack; used by bluez-alsa and Bluetooth applet
    hyprsunset                      # Screen temperature adjuster; used by shell widgets for night-light
    hypridle                        # Idle daemon; used by Hyprland to auto-lock session on timeout
    wl-clipboard                    # Wayland clipboard; used by editors and custom clipboard panels
    cliphist                        # Clipboard manager history backend; used by custom clipboard lists
    libnotify                       # Notification library; used by screenshot/record scripts for alerts
    hyprpicker                      # Wayland color picker; used by VibeShell palette selectors
    wf-recorder                     # Wayland screen recorder; used by asuraScreenRecordToggle
    cava                            # Console audio visualizer; used by Waybar for music bar visual effect
    matugen                         # Material You generator; used by Vibeshell/Noctalia to auto-theme
    mpvpaper                        # Video wallpaper daemon; used by Vibewall for active desktop background
    songrec                         # Shazam CLI client; used by panel audio widgets to identify songs
    zenity                          # GUI dialog CLI; used by custom scripts to prompt user input
    qt6Packages.qt6ct               # Qt6 config tool; used to apply system themes to Qt6 apps
    libsForQt5.qt5ct                # Qt5 config tool; used to apply system themes to Qt5 apps
    libsForQt5.qtstyleplugin-kvantum # Kvantum styling plugin for Qt5; used for glassmorphism styling
    qt6Packages.qtstyleplugin-kvantum # Kvantum styling plugin for Qt6; used for glassmorphism styling

    # Development (CLIs, LSPs, and runtimes used by IDEs and workflows)
    wget           # Network file downloader; used by terminal scripts
    git            # Version control system; used for nix config tracking and software dev
    gh             # GitHub CLI; used by super-productivity-bridge and dev scripts
    codex          # AI terminal assistant; used by user for local shell AI tasks
    jq             # JSON parser CLI; used by asuraScreenshot and super-productivity-bridge
    ripgrep        # Ripgrep search engine; used by Neovim, VSCode, and search widgets
    nixfmt         # Nix formatter; used by editors to clean Nix files
    nixd           # Nix compiler LSP; used by editors for Nix flake diagnostics
    uv             # High-performance Python helper; used to build isolated virtualenvs
    inter          # System UI font; used by Waybar/VibeShell styling
    sops           # Secrets management CLI; used to unlock encrypted credentials
    docker         # Docker container engine; used for dev environment virtualization
    docker-compose # Multi-container manager; used to orchestrate development database clusters
    nodejs         # JavaScript runtime; used by web dev tooling and playwright tests
    playwright-test # Testing runner; used by antigravity tests
    playwright-driver # Automation driver; used by playwright browser tests
    mysql-shell    # Advanced MySQL command console; used by mysqlLocalInfo script
    mysqlInfo      # Custom dev database helper script; used to list database status
    mongosh        # MongoDB Shell console; used for database development and queries
    mongodb-tools  # MongoDB backup and dump utilities; used for database admin tasks
    antigravityPkg # Custom AI agent CLI; used for agentic automated coding tasks

    # IDE & Editor (Terminal-based)
    neovim         # Advanced command-line text editor

    # Hyprland Tools
    hyprsysteminfo # Hardware diagnostics GUI; used to check system state
    hyprshutdown   # Custom session exit menu; used by desktop exit buttons

    # Terminal enhancements
    btop           # Terminal-based task manager; used to monitor CPU, memory, and temperatures
    tree           # Directory visualizer; used in terminal commands
    curl           # HTTP transfer tool; used by shell scripts and API calls
    yq             # YAML processor; used by config files parser
    ani-cli        # CLI anime search and player; uses mpv player under the hood

    # Python Environment
    (python3.withPackages (
      ps: with ps; [
        pip        # Python package manager; used to install dependencies
        requests   # HTTP library; used by local python script tasks
      ]
    ))
  ];
}
