# Shared session factory: experimental Labwc + Noctalia v5 Wayland session.
#
# Labwc is a stacking Wayland compositor, so Hyprland tiling-only actions are
# mapped to nearest native Labwc actions. This session is selectable, not default.
{
  inputs,
  lib,
  pkgs,
  ...
}:

let
  system = pkgs.stdenv.hostPlatform.system;
  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  wallpaper = ../bspwm/assets/tokyo.png;
  libinputGesturesConfig = pkgs.writeText "asura-labwc-libinput-gestures.conf" ''
    gesture swipe left 3 ${pkgs.wtype}/bin/wtype -M logo -M ctrl -P right -p right -m ctrl -m logo
    gesture swipe right 3 ${pkgs.wtype}/bin/wtype -M logo -M ctrl -P left -p left -m ctrl -m logo
  '';

  workspaceKeybinds = lib.concatMapStringsSep "\n" (
    workspace:
    let
      name = toString workspace;
      key = if workspace == 10 then "0" else name;
    in
    ''
      <keybind key="W-${key}">
        <action name="GoToDesktop" to="${name}" />
      </keybind>
      <keybind key="W-S-${key}">
        <action name="SendToDesktop" to="${name}" follow="yes" />
      </keybind>
    ''
  ) (lib.range 1 10);

  rcXmlBody = ''
        <labwc_config>
          <core>
            <decoration>server</decoration>
            <gap>6</gap>
            <xwaylandPersistence>no</xwaylandPersistence>
            <primarySelection>yes</primarySelection>
          </core>

          <desktops number="10">
            <names>
              <name>1</name>
              <name>2</name>
              <name>3</name>
              <name>4</name>
              <name>5</name>
              <name>6</name>
              <name>7</name>
              <name>8</name>
              <name>9</name>
              <name>10</name>
            </names>
            <popupTime>650</popupTime>
          </desktops>

          <theme>
            <cornerRadius>12</cornerRadius>
            <dropShadows>yes</dropShadows>
            <dropShadowsOnTiled>no</dropShadowsOnTiled>
            <keepBorder>yes</keepBorder>
            <maximizedDecoration>none</maximizedDecoration>
            <font place="ActiveWindow">
              <name>JetBrainsMono Nerd Font</name>
              <size>10</size>
              <weight>bold</weight>
            </font>
            <font place="InactiveWindow">
              <name>JetBrainsMono Nerd Font</name>
              <size>10</size>
            </font>
            <font place="MenuItem">
              <name>JetBrainsMono Nerd Font</name>
              <size>10</size>
            </font>
          </theme>

          <placement>
            <policy>automatic</policy>
            <cascadeOffset x="24" y="24" />
          </placement>

          <snapping>
            <range>
              <inner>16</inner>
              <outer>16</outer>
            </range>
            <cornerRange>48</cornerRange>
            <overlay>
              <enabled>yes</enabled>
            </overlay>
            <topMaximize>no</topMaximize>
            <notifyClient>always</notifyClient>
          </snapping>

          <libinput>
            <device category="touchpad">
              <naturalScroll>yes</naturalScroll>
              <tap>yes</tap>
              <tapButtonMap>lrm</tapButtonMap>
              <disableWhileTyping>yes</disableWhileTyping>
              <clickMethod>clickfinger</clickMethod>
              <scrollMethod>twofinger</scrollMethod>
              <threeFingerDrag>no</threeFingerDrag>
            </device>
          </libinput>

          <keyboard>
            <default />
            <keybind key="W-q">
              <action name="Close" />
            </keybind>
            <keybind key="W-h">
              <action name="Exit" />
            </keybind>
            <keybind key="W-f">
              <action name="Execute">
                <command>sh -lc 'asura-file-manager "$HOME"'</command>
              </action>
            </keybind>
            <keybind key="W-g">
              <action name="ToggleMaximize" />
            </keybind>
            <keybind key="W-j">
              <action name="SnapToEdge" direction="right" combine="yes" />
            </keybind>
            <keybind key="W-b">
              <action name="Execute" command="${pkgs.brave}/bin/brave" />
            </keybind>
            <keybind key="W-t">
              <action name="Execute" command="${pkgs.foot}/bin/foot" />
            </keybind>
            <keybind key="W-Return">
              <action name="Execute" command="${pkgs.foot}/bin/foot" />
            </keybind>
            <keybind key="W-c">
              <action name="Execute" command="code --ozone-platform=wayland" />
            </keybind>
            <keybind key="W-a">
              <action name="Execute" command="asura-vibeshell run tools" />
            </keybind>
            <keybind key="W-space">
              <action name="Execute" command="${pkgs.rofi}/bin/rofi -show drun" />
            </keybind>
            <keybind key="W-e">
              <action name="Execute" command="${pkgs.telegram-desktop}/bin/telegram-desktop" />
            </keybind>
            <keybind key="W-w">
              <action name="Execute" command="skwd-wall" />
            </keybind>
            <keybind key="W-p">
              <action name="Execute" command="asura-display-manager" />
            </keybind>
            <keybind key="W-S-p">
              <action name="Execute" command="asura-monitor-guard --restore" />
            </keybind>
            <keybind key="C-l">
              <action name="Execute" command="/run/current-system/sw/bin/vibeshell-safe-lock" />
            </keybind>
            <keybind key="W-l">
              <action name="Execute" command="/run/current-system/sw/bin/vibeshell-safe-lock" />
            </keybind>
            <keybind key="W-v">
              <action name="Execute" command="asura-vibeshell run dashboard-clipboard" />
            </keybind>
            <keybind key="W-S-v">
              <action name="ToggleAlwaysOnTop" />
            </keybind>
            <keybind key="W-S-c">
              <action name="Execute" command="clipboard" />
            </keybind>
            <keybind key="W-S-e">
              <action name="Execute" command="asura-shell-launcher /emo" />
            </keybind>
            <keybind key="W-S-s">
              <action name="Execute" command="asura-screenshot region" />
            </keybind>
            <keybind key="W-S-w">
              <action name="Execute" command="skwd-wall" />
            </keybind>
            <keybind key="W-S-r">
              <action name="Execute" command="/run/current-system/sw/bin/asura-screen-record-toggle" />
            </keybind>
            <keybind key="W-S-x">
              <action name="Execute" command="asura-screenshot region-edit" />
            </keybind>
            <keybind key="W-F2">
              <action name="Execute" command="night-shift" />
            </keybind>
            <keybind key="W-n">
              <action name="Execute" command="asura-vibeshell run dashboard-notes" />
            </keybind>
            <keybind key="W-d">
              <action name="Execute" command="asura-vibeshell run dashboard-controls" />
            </keybind>
            <keybind key="W-s">
              <action name="Execute" command="asura-vibeshell run config" />
            </keybind>
            <keybind key="C-A-Delete">
              <action name="Execute" command="asura-vibeshell run powermenu" />
            </keybind>
            <keybind key="W-BackSpace">
              <action name="Execute" command="asura-vibeshell run powermenu" />
            </keybind>
            <keybind key="W-period">
              <action name="Execute" command="asura-vibeshell run dashboard-emoji" />
            </keybind>
            <keybind key="C-W-r">
              <action name="Execute" command="asura-vibeshell reload" />
            </keybind>
            <keybind key="Print">
              <action name="Execute" command="asura-screenshot full" />
            </keybind>
            <keybind key="S-Print">
              <action name="Execute" command="asura-screenshot region" />
            </keybind>
            <keybind key="W-Print">
              <action name="Execute" command="asura-screenshot output" />
            </keybind>
            <keybind key="W-S-Print">
              <action name="Execute" command="asura-screenshot region-edit" />
            </keybind>
            <keybind key="W-Left">
              <action name="SnapToEdge" direction="left" combine="yes" />
            </keybind>
            <keybind key="W-Right">
              <action name="SnapToEdge" direction="right" combine="yes" />
            </keybind>
            <keybind key="W-Up">
              <action name="ToggleMaximize" />
            </keybind>
            <keybind key="W-Down">
              <action name="SnapToEdge" direction="down" combine="yes" />
            </keybind>
            <keybind key="W-C-Left">
              <action name="GoToDesktop" to="left" wrap="yes" />
            </keybind>
            <keybind key="W-C-Right">
              <action name="GoToDesktop" to="right" wrap="yes" />
            </keybind>
            <keybind key="A-Tab">
              <action name="NextWindow" workspace="current" />
            </keybind>
            <keybind key="A-S-Tab">
              <action name="PreviousWindow" workspace="current" />
            </keybind>
            <keybind key="W-Tab">
              <action name="NextWindow" workspace="current" />
            </keybind>
            <keybind key="W-S-Tab">
              <action name="PreviousWindow" workspace="current" />
            </keybind>
    ${workspaceKeybinds}
            <keybind key="XF86AudioMute">
              <action name="Execute" command="sound-toggle" />
            </keybind>
            <keybind key="XF86AudioPlay">
              <action name="Execute" command="${pkgs.playerctl}/bin/playerctl play-pause" />
            </keybind>
            <keybind key="XF86AudioNext">
              <action name="Execute" command="${pkgs.playerctl}/bin/playerctl next" />
            </keybind>
            <keybind key="XF86AudioPrev">
              <action name="Execute" command="${pkgs.playerctl}/bin/playerctl previous" />
            </keybind>
            <keybind key="F3">
              <action name="Execute" command="sound-toggle" />
            </keybind>
            <keybind key="F5">
              <action name="Execute" command="sound-down" />
            </keybind>
            <keybind key="F6">
              <action name="Execute" command="sound-up" />
            </keybind>
            <keybind key="F8">
              <action name="Execute" command="brightness-down" />
            </keybind>
            <keybind key="F9">
              <action name="Execute" command="brightness-up" />
            </keybind>
            <keybind key="F10">
              <action name="Execute" command="asura-camera-app" />
            </keybind>
            <keybind key="F11">
              <action name="Execute" command="asura-airplane-toggle" />
            </keybind>
            <keybind key="F12">
              <action name="Execute" command="night-shift" />
            </keybind>
            <keybind key="XF86AudioRaiseVolume">
              <action name="Execute" command="sound-up" />
            </keybind>
            <keybind key="XF86AudioLowerVolume">
              <action name="Execute" command="sound-down" />
            </keybind>
            <keybind key="XF86MonBrightnessUp">
              <action name="Execute" command="brightness-up" />
            </keybind>
            <keybind key="XF86MonBrightnessDown">
              <action name="Execute" command="brightness-down" />
            </keybind>
          </keyboard>

          <mouse>
            <default />
            <context name="Frame">
              <mousebind button="W-Left" action="Drag">
                <action name="Move" />
              </mousebind>
              <mousebind button="W-Right" action="Drag">
                <action name="Resize" />
              </mousebind>
              <mousebind button="W-Middle" action="Press">
                <action name="ToggleMaximize" />
              </mousebind>
            </context>
          </mouse>
        </labwc_config>
  '';

  rcXml = pkgs.writeText "asura-labwc-rc.xml" (
    "<?xml version=\"1.0\"?>\n" + lib.removePrefix "\n" rcXmlBody
  );

  autostart = pkgs.writeShellScript "asura-labwc-autostart" ''
    # Shared Labwc autostart. Keep this guarded to avoid duplicate Noctalia.
    set -u

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/labwc"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/labwc"
    else
      state_dir="/tmp/asura-labwc-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"

    systemctl --user --no-block start labwc-session.target >/dev/null 2>&1 || true

    ${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill >>"$state_dir/swaybg.log" 2>&1 &
    ${pkgs.procps}/bin/pkill -xu "''${USER:-asura}" -f "libinput-gestures.*asura-labwc-libinput-gestures.conf" >/dev/null 2>&1 || true
    ${pkgs.libinput-gestures}/bin/libinput-gestures -c ${libinputGesturesConfig} >>"$state_dir/libinput-gestures.log" 2>&1 &

    if systemctl --user --quiet is-active noctalia.service >/dev/null 2>&1; then
      exit 0
    fi

    if systemctl --user list-unit-files noctalia.service >/dev/null 2>&1; then
      systemctl --user start noctalia.service >>"$state_dir/noctalia-service.log" 2>&1 || true
      exit 0
    fi

    if ! pgrep -xu "''${USER:-asura}" noctalia >/dev/null 2>&1; then
      nohup ${noctaliaPackage}/bin/noctalia >>"$state_dir/noctalia.log" 2>&1 &
    fi
  '';

  environmentFile = pkgs.writeText "asura-labwc-environment" ''
    XDG_SESSION_TYPE=wayland
    XDG_CURRENT_DESKTOP=labwc
    XDG_SESSION_DESKTOP=labwc
    NIXOS_OZONE_WL=1
    GDK_BACKEND=wayland,x11
    QT_QPA_PLATFORM=wayland;xcb
    SDL_VIDEODRIVER=wayland
    MOZ_ENABLE_WAYLAND=1
    XCURSOR_SIZE=24
  '';

  menuXmlBody = ''
    <openbox_menu>
      <menu id="root-menu" label="Asura">
        <item label="Terminal">
          <action name="Execute" command="${pkgs.foot}/bin/foot" />
        </item>
        <item label="Launcher">
          <action name="Execute" command="${pkgs.rofi}/bin/rofi -show drun" />
        </item>
        <item label="Dashboard">
          <action name="Execute" command="asura-vibeshell run dashboard-controls" />
        </item>
        <separator />
        <item label="Reload Labwc">
          <action name="Reconfigure" />
        </item>
        <item label="Exit Labwc">
          <action name="Exit" />
        </item>
      </menu>
    </openbox_menu>
  '';

  menuXml = pkgs.writeText "asura-labwc-menu.xml" (
    "<?xml version=\"1.0\"?>\n" + lib.removePrefix "\n" menuXmlBody
  );

  configDir = pkgs.runCommand "asura-labwc-config" { } ''
    mkdir -p "$out"
    ln -s ${rcXml} "$out/rc.xml"
    ln -s ${autostart} "$out/autostart"
    ln -s ${environmentFile} "$out/environment"
    ln -s ${menuXml} "$out/menu.xml"
  '';

  start = pkgs.writeShellScriptBin "asura-start-labwc-noctalia" ''
    set -uo pipefail

    if [ -n "''${XDG_STATE_HOME:-}" ]; then
      state_dir="$XDG_STATE_HOME/labwc"
    elif [ -n "''${HOME:-}" ]; then
      state_dir="$HOME/.local/state/labwc"
    else
      state_dir="/tmp/asura-labwc-''${UID:-session}"
    fi
    mkdir -p "$state_dir" 2>/dev/null || state_dir="/tmp"
    exec >>"$state_dir/session.log" 2>&1

    echo "---- labwc + noctalia session: $(date -Is) ----"

    export PATH="/run/current-system/sw/bin:/etc/profiles/per-user/asura/bin:$PATH"
    export PATH="${
      lib.makeBinPath [
        noctaliaPackage
        pkgs.brave
        pkgs.brightnessctl
        pkgs.coreutils
        pkgs.foot
        pkgs.labwc
        pkgs.libinput-gestures
        pkgs.libnotify
        pkgs.playerctl
        pkgs.procps
        pkgs.rofi
        pkgs.swaybg
        pkgs.telegram-desktop
        pkgs.wtype
        pkgs.wl-clipboard
        pkgs.xwayland
      ]
    }:$PATH"

    export XDG_SESSION_TYPE=wayland
    export XDG_CURRENT_DESKTOP=labwc
    export XDG_SESSION_DESKTOP=labwc
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland,x11
    export QT_QPA_PLATFORM="wayland;xcb"
    export SDL_VIDEODRIVER=wayland
    export MOZ_ENABLE_WAYLAND=1

    dbus-update-activation-environment --systemd \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true
    systemctl --user import-environment \
      XDG_SESSION_TYPE XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP \
      NIXOS_OZONE_WL GDK_BACKEND QT_QPA_PLATFORM SDL_VIDEODRIVER MOZ_ENABLE_WAYLAND >/dev/null 2>&1 || true

    exec ${pkgs.labwc}/bin/labwc -C ${configDir}
  '';
in
{
  inherit start;
  desktopEntry = ''
    [Desktop Entry]
    Name=Noctalia + Labwc
    Comment=Experimental Labwc Wayland session with guarded Noctalia v5 startup
    Exec=${start}/bin/asura-start-labwc-noctalia
    Type=Application
  '';
  packages = [
    start
    noctaliaPackage
    pkgs.foot
    pkgs.labwc
    pkgs.libinput-gestures
    pkgs.rofi
    pkgs.swaybg
    pkgs.wtype
    pkgs.wl-clipboard
    pkgs.xwayland
  ];
}
