# System Packages Configuration
{
  lib,
  pkgs,
  inputs,
  ...
}:

let
  whatsappWeb = pkgs.writeShellScriptBin "whatsapp-web" ''
    unset ELECTRON_RUN_AS_NODE ELECTRON_NO_ATTACH_CONSOLE GTK_MODULES

    export FONTCONFIG_FILE=/etc/fonts/fonts.conf
    export FONTCONFIG_PATH=/etc/fonts

    # Keep this chat webapp on the Intel/Mesa path. Chromium/Dawn can otherwise
    # wake the NVIDIA dGPU for WebGPU/Vulkan probes and print noisy adapter logs.
    export DRI_PRIME=0
    export __NV_PRIME_RENDER_OFFLOAD=0
    export __EGL_VENDOR_LIBRARY_FILENAMES=/run/opengl-driver/share/glvnd/egl_vendor.d/50_mesa.json
    export VK_ICD_FILENAMES=/run/opengl-driver/share/vulkan/icd.d/intel_icd.x86_64.json

    exec ${pkgs.google-chrome}/bin/google-chrome-stable \
      --app=https://web.whatsapp.com \
      --class=whatsapp-web \
      --name=whatsapp-web \
      --no-first-run \
      --ozone-platform=wayland \
      --use-gl=egl \
      --use-angle=gl \
      --disable-features=WebGPU,Vulkan,DefaultANGLEVulkan,VulkanFromANGLE \
      --disable-logging \
      --log-level=3 \
      "$@"
  '';

  whatsappWebDesktop = pkgs.makeDesktopItem {
    name = "whatsapp-web";
    desktopName = "WhatsApp";
    genericName = "Messaging";
    comment = "Open WhatsApp Web";
    exec = "whatsapp-web";
    icon = "whatsapp";
    categories = [
      "Network"
      "InstantMessaging"
    ];
    startupWMClass = "whatsapp-web";
  };

  antigravityWithPlaywright = pkgs.symlinkJoin {
    name = "antigravity-with-playwright";
    paths = [ pkgs.antigravity ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      playwright_browsers="${
        pkgs.playwright-driver.browsers.override {
          withFirefox = false;
          withWebkit = false;
        }
      }"
      rm "$out/bin/antigravity"
      makeWrapper ${pkgs.antigravity}/bin/antigravity "$out/bin/antigravity" \
        --prefix PATH : ${
          lib.makeBinPath [
            pkgs.playwright-test
            pkgs.nodejs
            pkgs.chromium
            pkgs.google-chrome
          ]
        } \
        --prefix NODE_PATH : ${pkgs.playwright-test}/lib/node_modules \
        --set PLAYWRIGHT_BROWSERS_PATH "$playwright_browsers" \
        --set PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD 1 \
        --set CHROME_BIN ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_PATH ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set CHROME_EXECUTABLE ${pkgs.google-chrome}/bin/google-chrome-stable \
        --set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ${pkgs.google-chrome}/bin/google-chrome-stable
    '';
  };

  mysqlLocalInfo = pkgs.writeShellScriptBin "mysql-local-info" ''
    cat <<'EOF'
    MySQL local service
      service: systemctl status mysql
      cli:     mysql -u asura asura_dev
      shell:   mysqlsh --sql asura@localhost:3306
      gui:     mysql-workbench

    Paths
      config:  /etc/my.cnf
      data:    /var/lib/mysql
      socket:  /run/mysqld/mysqld.sock
      binary:  /run/current-system/sw/bin/mysql
    EOF
  '';

  vimWrapped = pkgs.vim-full.customize {
    name = "vim";
    vimrcConfig.customRC = ''
      set number
      set relativenumber
      set expandtab
      set shiftwidth=2
      set tabstop=2
      syntax on
    '';
  };

  xdmanRuntimeLibs = with pkgs; [
    atk
    cairo
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libayatana-appindicator
    libnotify
    librsvg
    lttng-ust_2_12
    openssl
    pango
    stdenv.cc.cc.lib
    zlib
    libx11
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
  ];

  xdmanGtk = pkgs.stdenvNoCC.mkDerivation {
    pname = "xdman-gtk";
    version = "8.0.29";

    src = pkgs.fetchurl {
      url = "https://github.com/subhra74/xdm/releases/download/8.0.29/xdman_gtk_8.0.29_amd64.deb";
      hash = "sha256-Nlm7LbAlHI3w+lAeUxhf0Dx7Fde1jCKitguTFEtrnhE=";
    };

    nativeBuildInputs = with pkgs; [
      autoPatchelfHook
      dpkg
      makeWrapper
    ];

    buildInputs = xdmanRuntimeLibs;

    unpackPhase = ''
      runHook preUnpack
      dpkg-deb -x "$src" source
      runHook postUnpack
    '';

    installPhase = ''
            runHook preInstall

            mkdir -p "$out"
            cp -a source/opt "$out/"
            mkdir -p "$out/share"
            cp -a source/usr/share/. "$out/share/"

            mkdir -p "$out/bin"
            rm -f "$out/bin/xdman"
            makeWrapper "$out/opt/xdman/xdm-app" "$out/bin/xdman" \
              --set GTK_USE_PORTAL 1 \
              --set GDK_PIXBUF_MODULE_FILE "${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
              --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath xdmanRuntimeLibs}"

            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "env GTK_USE_PORTAL=1 /opt/xdman/xdm-app" "$out/bin/xdman" \
              --replace-fail "/opt/xdman/xdm-logo.svg" "$out/opt/xdman/xdm-logo.svg"
            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "MimeType=application/xdm-app;x-scheme-handler/xdm-app;" \
              "MimeType=application/xdm-app;x-scheme-handler/xdm-app;x-scheme-handler/xdm+app;"
            substituteInPlace "$out/share/applications/xdm-app.desktop" \
              --replace-fail "Categories=Network;" "Categories=Network;FileTransfer;GTK;" \
              --replace-fail "StartupNotify=true" "StartupNotify=false"
      printf '%s\n' \
        'StartupWMClass=xdm-app' \
        'DBusActivatable=false' \
        >> "$out/share/applications/xdm-app.desktop"
            mkdir -p "$out/share/pixmaps"
            ln -sf "$out/opt/xdman/xdm-logo.svg" "$out/share/pixmaps/xdm-logo.svg"

            runHook postInstall
    '';

    meta = {
      description = "Xtreme Download Manager GTK desktop application";
      homepage = "https://github.com/subhra74/xdm";
      license = lib.licenses.gpl2Plus;
      platforms = [ "x86_64-linux" ];
      mainProgram = "xdman";
    };
  };

  # Smart launcher: kills any running xdm-app first, then starts fresh.
  # Needed because a second instance always segfaults on Wayland (GTK
  # gtk_widget_get_scale_factor single-instance mutex bug in xdm 8.0.29).
  xdmOpen = pkgs.writeShellScriptBin "xdm-open" ''
    set -euo pipefail
    # XDM has no true headless monitor mode. Keep browser integration on-demand:
    # desktop/protocol launches start the GTK app only when a browser calls it.
    if pgrep -x xdm-app >/dev/null 2>&1; then
      if [ "$#" -eq 0 ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow class:xdm-app >/dev/null 2>&1 || true
        exit 0
      fi
      exec ${xdmanGtk}/bin/xdman "$@"
    fi
    exec ${xdmanGtk}/bin/xdman "$@"
  '';

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

  asuraSuperProductivity = pkgs.writeShellScriptBin "asura-super-productivity" ''
    set -euo pipefail

    export ELECTRON_OZONE_PLATFORM_HINT="''${ELECTRON_OZONE_PLATFORM_HINT:-wayland}"
    exec ${pkgs.super-productivity}/bin/super-productivity \
      --ozone-platform=wayland \
      --enable-features=UseOzonePlatform,WaylandWindowDecorations \
      "$@"
  '';

  asuraSuperProductivityBridge = pkgs.writeShellScriptBin "asura-super-productivity-bridge" ''
    set -euo pipefail

    export PATH="${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.findutils
        pkgs.gh
        pkgs.gnugrep
        pkgs.gnused
        pkgs.jq
        pkgs.libnotify
        pkgs.procps
        pkgs.xdg-utils
      ]
    }:$PATH"

    data_home="''${XDG_DATA_HOME:-$HOME/.local/share}"
    notes_dir="$data_home/vibeshell-notes"
    notes_index="$notes_dir/index.json"
    export_dir="$data_home/vibeshell-integrations/super-productivity"
    export_json="$export_dir/vibeshell-notes-export.json"
    export_md="$export_dir/vibeshell-notes-export.md"

    notify() {
      notify-send -a asura-productivity "$@" --icon=super-productivity >/dev/null 2>&1 || true
    }

    ensure_notes_index() {
      mkdir -p "$notes_dir/notes" "$export_dir"
      if [ ! -s "$notes_index" ]; then
        printf '{"order":[],"notes":{}}\n' > "$notes_index"
      fi
    }

    html_to_text() {
      sed -E \
        -e 's/<br[[:space:]/]*>/\n/gI' \
        -e 's#</p>#\n\n#gI' \
        -e 's#</div>#\n#gI' \
        -e 's/<[^>]+>//g' \
        -e 's/&nbsp;/ /g' \
        -e 's/&amp;/\&/g' \
        -e 's/&lt;/</g' \
        -e 's/&gt;/>/g'
    }

    export_notes() {
      ensure_notes_index
      exported_at="$(date -Iseconds)"

      jq \
        --arg exportedAt "$exported_at" \
        --arg notesDir "$notes_dir/notes" \
        '{
          source: "vibeshell-notes",
          target: "super-productivity",
          exportedAt: $exportedAt,
          importHint: "Bridge export. Configure GitHub issue sync inside Super Productivity with your own GitHub token.",
          notes: [
            (.order // [])[] as $id
            | ((.notes[$id] // {}) + {
                id: $id,
                htmlPath: ($notesDir + "/" + $id + ".html")
              })
          ]
        }' "$notes_index" > "$export_json.tmp"
      mv "$export_json.tmp" "$export_json"

      {
        printf '# VibeShell Notes export\n\n'
        printf 'Exported: %s\n\n' "$exported_at"
        jq -r '(.order // [])[] as $id | [$id, (.notes[$id].title // "Untitled"), (.notes[$id].updatedAt // "")] | @tsv' "$notes_index" |
          while IFS=$'\t' read -r id title updated; do
            html_path="$notes_dir/notes/$id.html"
            printf '## %s\n\n' "$title"
            [ -n "$updated" ] && printf 'Updated: %s\n\n' "$updated"
            printf 'Source: `%s`\n\n' "$html_path"
            if [ -f "$html_path" ]; then
              html_to_text < "$html_path" | head -c 3000
              printf '\n\n'
            fi
          done
      } > "$export_md.tmp"
      mv "$export_md.tmp" "$export_md"

      notify "VibeShell notes exported" "$export_json"
      printf '%s\n' "$export_json"
    }

    status() {
      installed=true
      running=false
      github_connected=false
      last_export_path=""

      if pgrep -u "$(id -u)" -x super-productivity >/dev/null 2>&1 || pgrep -u "$(id -u)" -f '/bin/super-productivity( |$)' >/dev/null 2>&1; then
        running=true
      fi
      if gh auth status -h github.com >/dev/null 2>&1; then
        github_connected=true
      fi
      if [ -s "$export_json" ]; then
        last_export_path="$export_json"
      fi

      jq -n \
        --argjson installed "$installed" \
        --argjson running "$running" \
        --argjson githubConnected "$github_connected" \
        --arg lastExportPath "$last_export_path" \
        '{
          installed: $installed,
          running: $running,
          githubConnected: $githubConnected,
          lastExportPath: $lastExportPath
        }'
    }

    github_setup() {
      xdg-open "https://github.com/settings/tokens/new?description=Super%20Productivity&scopes=repo,read:user" >/dev/null 2>&1 || true
      exec ${asuraSuperProductivity}/bin/asura-super-productivity
    }

    case "''${1:-status}" in
      status) status ;;
      open) exec ${asuraSuperProductivity}/bin/asura-super-productivity "''${@:2}" ;;
      github-setup) github_setup ;;
      export-notes) export_notes ;;
      export-open)
        export_notes >/dev/null
        xdg-open "$export_dir" >/dev/null 2>&1 || true
        ;;
      *)
        printf 'usage: asura-super-productivity-bridge [status|open|github-setup|export-notes|export-open]\n' >&2
        exit 64
        ;;
    esac
  '';

in
{
  environment.systemPackages =
    (with pkgs; [
      # System Info & Terminal
      zsh

      # System Tools
      polkit
      udisks2
      udiskie

      # Screenshot and Screen Recording
      grimblast
      hyprshot
      swappy # Screenshot editor

      # Polkit Agent
      inputs.hyprpolkitagent.packages.${pkgs.stdenv.hostPlatform.system}.default

      # File Management & NTFS Support
      xarchiver
      nautilus
      gnome-disk-utility
      pcmanfm-qt
      gvfs
      ntfs3g
      exfat # Windows filesystem support

      # Desktop Environment
      xdg-utils
      networkmanager
      tuigreet
      xdg-user-dirs # xdg-desktop-portals in services.nix

      # Desktop shell support and rollback helpers.
      (writeShellScriptBin "internet-unblock" "")
      dconf
      gtk3
      gtk4
      adw-gtk3
      adwaita-icon-theme
      hicolor-icon-theme
      papirus-icon-theme
      kdePackages.breeze-icons
      gsettings-desktop-schemas
      at-spi2-atk
      at-spi2-core
      libgtop
      loupe
      kdePackages.okular
      sushi

      # Multimedia
      mpv
      vlc
      easyeffects
      freetube
      kdePackages.kdenlive
      obs-studio
      alsa-utils
      pavucontrol
      pulseaudio
      pwvucontrol
      v4l-utils

      # Hyprland Panel Dependencies
      bluez
      hyprsunset
      hypridle
      wl-clipboard
      cliphist
      libnotify
      hyprpicker
      wf-recorder
      cava
      matugen
      mpvpaper
      songrec
      zenity
      qt6Packages.qt6ct
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      qt6Packages.qtstyleplugin-kvantum
      nwg-look

      # Development
      wget
      git
      gh
      codex
      jq
      ripgrep
      nixfmt
      nil
      nixd
      uv
      inter
      sops
      docker
      docker-compose
      nodejs
      playwright-test
      playwright-driver
      chromium
      mysql-shell
      mysql-workbench
      mysqlLocalInfo
      mongosh
      mongodb-tools

      # IDE & Editor
      neovim
      vscode
      antigravityWithPlaywright
      (pkgs.callPackage ./cursor.nix { })
      zed-editor
      vimWrapped
      inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Hyprland Tools
      hyprsysteminfo
      hyprshutdown

      # Desktop apps
      whatsappWeb
      whatsappWebDesktop
      xdmanGtk
      xdmOpen
      asuraScreenRecordToggle
      piper # Linux GUI for Logitech G304/G305 DPI and button profiles
      solaar # Logitech receiver and wireless device manager
      mongodb-compass
      telegram-desktop
      ani-cli
      asuraScreenshot
      super-productivity
      asuraSuperProductivity
      asuraSuperProductivityBridge

      # Terminal enhancements
      btop
      tree
      curl
      yq

      # Python Environment
      (python3.withPackages (
        ps: with ps; [
          pip
          requests
        ]
      ))
    ])
    ++ lib.optionals (builtins.hasAttr "windsurf" pkgs) [
      pkgs.windsurf
    ];

  systemd.tmpfiles.rules = [
    "L+ /opt/xdman - - - - ${xdmanGtk}/opt/xdman"
  ];

  systemd.user.services.xdman = {
    description = "Xtreme Download Manager browser monitor bridge";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    unitConfig = {
      StartLimitBurst = 3;
      StartLimitIntervalSec = 60;
    };
    serviceConfig = {
      ExecStart = "${xdmanGtk}/bin/xdman --background";
      Restart = "on-failure";
      RestartSec = 15;
      Environment = "GDK_PIXBUF_MODULE_FILE=${pkgs.librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache";
    };
  };
}
