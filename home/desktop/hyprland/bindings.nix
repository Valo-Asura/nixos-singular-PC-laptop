# Shared Home Manager module: common Hyprland keybindings.
{ pkgs, lib, ... }:
let
  inherit (import ./lib.nix { inherit lib; }) mkBind mkExecBind;

  terminal = "${pkgs.foot}/bin/foot";
  browser = "${pkgs.brave}/bin/brave";
  editor = "code --ozone-platform=wayland";
  lock = "/run/current-system/sw/bin/asura-session-lock";

  workspaceBinds =
    builtins.concatLists (
      builtins.genList (
        i:
        let
          ws = i + 1;
          key = toString ws;
        in
        [
          (mkBind "SUPER" key "hl.dsp.focus({ workspace = ${toString ws} })" { })
          (mkBind "SUPER SHIFT" key "hl.dsp.window.move({ workspace = ${toString ws} })" { })
        ]
      ) 9
    )
    ++ [
      (mkBind "SUPER" "0" "hl.dsp.focus({ workspace = 10 })" { })
      (mkBind "SUPER SHIFT" "0" "hl.dsp.window.move({ workspace = 10 })" { })
    ];
in
{
  wayland.windowManager.hyprland = {
    settings = {
      bind =
        [
          (mkBind "SUPER" "Q" "hl.dsp.window.close()" { })
          (mkBind "SUPER" "H" "hl.dsp.exit()" { })
          (mkExecBind "SUPER" "F" ''asura-file-manager "$HOME"'' { })
          (mkBind "SUPER" "G" ''hl.dsp.window.float({ action = "toggle" })'' { })
          (mkBind "SUPER" "J" ''hl.dsp.layout("togglesplit")'' { })
          (mkExecBind "SUPER" "B" browser { })
          (mkExecBind "SUPER" "T" terminal { })
          (mkExecBind "SUPER" "C" editor { })
          (mkExecBind "SUPER" "E" "${pkgs.telegram-desktop}/bin/telegram-desktop" { })
          (mkExecBind "SUPER" "W" "skwd-wall" { })
          (mkExecBind "SUPER" "P" "asura-display-manager" { })
          (mkExecBind "SUPER SHIFT" "P" "asura-monitor-guard --restore" { })
          (mkExecBind "CTRL" "L" lock { })
          (mkExecBind "SUPER" "L" lock { })
          (mkExecBind "SUPER" "V" "asura-shell-launcher /clipboard" { })
          (mkBind "SUPER SHIFT" "V" ''hl.dsp.window.float({ action = "toggle" })'' { })
          (mkExecBind "SUPER SHIFT" "C" "asura-shell-launcher /clipboard" { })
          (mkExecBind "SUPER SHIFT" "E" "asura-shell-launcher /emo" { })
          (mkExecBind "SUPER SHIFT" "S" "asura-screenshot region" { })
          (mkExecBind "SUPER SHIFT" "W" "skwd-wall" { })
          (mkExecBind "SUPER SHIFT" "R" "/run/current-system/sw/bin/asura-screen-record-toggle" { })
          (mkExecBind "SUPER SHIFT" "X" "asura-screenshot region-edit" { })
          (mkExecBind "SUPER" "F2" "night-shift" { })
          (mkExecBind "SUPER" "N" "asura-shell-launcher /notes" { })
          (mkExecBind "SUPER" "D" "asura-shell-launcher /dashboard" { })
          (mkExecBind "SUPER" "S" "asura-shell-launcher /config" { })
          (mkExecBind "CTRL ALT" "Delete" "asura-shell-launcher /session" { })
          (mkExecBind "SUPER" "BackSpace" "asura-shell-launcher /session" { })
          (mkExecBind "SUPER" "Period" "asura-shell-launcher /emo" { })
          (mkExecBind "CTRL SUPER" "R" "asura-shell-switch reload" { })
          (mkExecBind "" "Print" "asura-screenshot full" { })
          (mkExecBind "SHIFT" "Print" "asura-screenshot region" { })
          (mkExecBind "SUPER" "Print" "asura-screenshot output" { })
          (mkExecBind "SUPER SHIFT" "Print" "asura-screenshot region-edit" { })
          (mkBind "SUPER" "left" ''hl.dsp.focus({ direction = "left" })'' { })
          (mkBind "SUPER" "right" ''hl.dsp.focus({ direction = "right" })'' { })
          (mkBind "SUPER" "up" ''hl.dsp.focus({ direction = "up" })'' { })
          (mkBind "SUPER" "down" ''hl.dsp.focus({ direction = "down" })'' { })
          (mkExecBind "ALT" "Tab" "asura-shell-launcher /overview" { })
          (mkBind "ALT SHIFT" "Tab" ''hl.dsp.window.cycle_next({ direction = "prev" })'' { })
          (mkBind "SUPER" "Tab" "hl.dsp.window.cycle_next()" { })
          (mkBind "SUPER SHIFT" "Tab" ''hl.dsp.submap("resize")'' { })
        ]
        ++ workspaceBinds;

      bindm = [
        (mkBind "SUPER" "mouse:272" "hl.dsp.window.drag()" { mouse = true; })
        (mkBind "SUPER" "mouse:273" "hl.dsp.window.resize()" { mouse = true; })
      ];

      bindr = [
        (mkExecBind "SUPER" "SUPER_L" "asura-shell-launcher" { release = true; })
        (mkExecBind "SUPER" "SUPER_R" "asura-shell-launcher" { release = true; })
      ];

      bindl = [
        (mkExecBind "" "XF86AudioMute" "sound-toggle" { locked = true; })
        (mkExecBind "" "XF86AudioPlay" "${pkgs.playerctl}/bin/playerctl play-pause" { locked = true; })
        (mkExecBind "" "XF86AudioNext" "${pkgs.playerctl}/bin/playerctl next" { locked = true; })
        (mkExecBind "" "XF86AudioPrev" "${pkgs.playerctl}/bin/playerctl previous" { locked = true; })
        (mkExecBind "" "switch:Lid Switch" lock { locked = true; })
        (mkExecBind "" "F3" "sound-toggle" { locked = true; })
        (mkExecBind "" "F5" "sound-down" { locked = true; })
        (mkExecBind "" "F6" "sound-up" { locked = true; })
        (mkExecBind "" "F8" "brightness-down" { locked = true; })
        (mkExecBind "" "F9" "brightness-up" { locked = true; })
        (mkExecBind "" "F10" "asura-camera-app" { locked = true; })
        (mkExecBind "" "F11" "asura-airplane-toggle" { locked = true; })
        (mkExecBind "" "F12" "night-shift" { locked = true; })
      ];

      bindle = [
        (mkExecBind "" "XF86AudioRaiseVolume" "sound-up" {
          locked = true;
          repeating = true;
        })
        (mkExecBind "" "XF86AudioLowerVolume" "sound-down" {
          locked = true;
          repeating = true;
        })
        (mkExecBind "" "XF86MonBrightnessUp" "brightness-up" {
          locked = true;
          repeating = true;
        })
        (mkExecBind "" "XF86MonBrightnessDown" "brightness-down" {
          locked = true;
          repeating = true;
        })
      ];
    };

    submaps.resize.settings = {
      binde = [
        {
          _args = [
            "right"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 30, y = 0, relative = true })")
            {
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "left"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = -30, y = 0, relative = true })")
            {
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "up"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 0, y = -30, relative = true })")
            {
              repeating = true;
            }
          ];
        }
        {
          _args = [
            "down"
            (lib.generators.mkLuaInline "hl.dsp.window.resize({ x = 0, y = 30, relative = true })")
            {
              repeating = true;
            }
          ];
        }
      ];
      bind = [
        {
          _args = [
            "escape"
            (lib.generators.mkLuaInline ''hl.dsp.submap("reset")'')
          ];
        }
        {
          _args = [
            "SUPER SHIFT + Tab"
            (lib.generators.mkLuaInline ''hl.dsp.submap("reset")'')
          ];
        }
      ];
    };
  };
}
