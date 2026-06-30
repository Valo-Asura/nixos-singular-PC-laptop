{ lib, pkgs, ... }:

let
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
  # Needed because a second instance always segfaults on Wayland.
  xdmOpen = pkgs.writeShellScriptBin "xdm-open" ''
    set -euo pipefail
    if pgrep -x xdm-app >/dev/null 2>&1; then
      if [ "$#" -eq 0 ]; then
        ${pkgs.hyprland}/bin/hyprctl dispatch focuswindow class:xdm-app >/dev/null 2>&1 || true
        exit 0
      fi
      exec ${xdmanGtk}/bin/xdman "$@"
    fi
    exec ${xdmanGtk}/bin/xdman "$@"
  '';
in
{
  inherit xdmanGtk xdmOpen;
}
