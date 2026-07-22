# Shared helpers for Home Manager's Hyprland Lua config generator.
{ lib, ... }:
let
  inherit (lib.generators) mkLuaInline;
  toLua = lib.generators.toLua { };

  focusDirs = {
    l = "left";
    r = "right";
    u = "up";
    d = "down";
  };

  keyCombo =
    mods: key:
    if mods == "" then
      key
    else
      let
        cleanedMods = lib.replaceStrings [ "," ] [ "" ] mods;
        splitMods = lib.splitString " " cleanedMods;
        nonEmptyMods = builtins.filter (s: s != "") splitMods;
      in
      lib.concatStringsSep " + " (nonEmptyMods ++ [ key ]);

  dsp = expr: mkLuaInline expr;

  mkBind =
    mods: key: action: opts:
    {
      _args = [ (keyCombo mods key) (dsp action) ] ++ lib.optional (opts != { }) opts;
    };

  mkExecBind =
    mods: key: cmd:
    opts:
    mkBind mods key "hl.dsp.exec_cmd(${toLua cmd})" opts;

  mkEnv =
    entry:
    let
      idx = lib.strMatch "(.*),(.*)" entry;
      key = builtins.elemAt (builtins.match "(.*),(.*)" entry) 0;
      val = builtins.elemAt (builtins.match "(.*),(.*)" entry) 1;
    in
    {
      _args = [ key val ];
    };

  mkMonitorLine =
    line:
    let
      parts = lib.splitString "," line;
      output = builtins.elemAt parts 0;
      mode = builtins.elemAt parts 1;
      position = builtins.elemAt parts 2;
      scale = builtins.fromJSON (builtins.elemAt parts 3);
    in
    {
      _args = [
        {
          output = output;
          mode = mode;
          position = position;
          scale = scale;
        }
      ];
    };

  mkMonitor =
    output: mode: position: scale:
    {
      _args = [
        {
          output = output;
          mode = mode;
          position = position;
          scale = scale;
        }
      ];
    };

  mkCurve =
    line:
    let
      parts = lib.splitString ", " line;
      name = builtins.head parts;
      coords = map builtins.fromJSON (lib.drop 1 parts);
    in
    {
      _args = [
        name
        {
          type = "bezier";
          points = [
            [
              (builtins.elemAt coords 0)
              (builtins.elemAt coords 1)
            ]
            [
              (builtins.elemAt coords 2)
              (builtins.elemAt coords 3)
            ]
          ];
        }
      ];
    };

  mkAnimation =
    leaf: enabled: speed: bezier: style:
    {
      _args = [
        ({
          leaf = leaf;
          enabled = enabled;
          speed = builtins.fromJSON speed;
          bezier = bezier;
        }
        // lib.optionalAttrs (style != null) {
          style = style;
        })
      ];
    };

  mkGesture =
    fingers: direction: action:
    {
      _args = [
        {
          fingers = fingers;
          direction = direction;
          action = action;
        }
      ];
    };

  mkWindowRule =
    name: match: rules:
    {
      _args = [
        ({
          inherit name match;
        }
        // rules)
      ];
    };

  mkLayerRule =
    name: namespace: rules:
    {
      _args = [
        ({
          inherit name;
          match.namespace = namespace;
        }
        // rules)
      ];
    };

  mkStartupHook = commands: {
    _args = [
      "hyprland.start"
      (mkLuaInline ''
        function()
        ${lib.concatMapStrings (cmd: "  hl.exec_cmd(${toLua cmd})\n") commands}
        end
      '')
    ];
  };

  dispatch =
    dispatcher: arg:
    if dispatcher == "killactive" then
      "hl.dsp.window.close()"
    else if dispatcher == "exit" then
      "hl.dsp.exit()"
    else if dispatcher == "togglefloating" then
      "hl.dsp.window.float({ action = \"toggle\" })"
    else if dispatcher == "layoutmsg" then
      "hl.dsp.layout(${toLua arg})"
    else if dispatcher == "exec" then
      "hl.dsp.exec_cmd(${toLua arg})"
    else if dispatcher == "workspace" then
      "hl.dsp.focus({ workspace = ${arg} })"
    else if dispatcher == "movetoworkspace" then
      "hl.dsp.window.move({ workspace = ${arg} })"
    else if dispatcher == "movefocus" then
      "hl.dsp.focus({ direction = ${toLua (focusDirs.${arg} or arg)} })"
    else if dispatcher == "cyclenext" then
      if arg == "prev" then
        "hl.dsp.window.cycle_next({ direction = \"prev\" })"
      else
        "hl.dsp.window.cycle_next()"
    else if dispatcher == "submap" then
      "hl.dsp.submap(${toLua arg})"
    else if dispatcher == "movewindow" then
      "hl.dsp.window.drag()"
    else if dispatcher == "resizewindow" then
      "hl.dsp.window.resize()"
    else if dispatcher == "resizeactive" then
      let
        parts = lib.splitString " " arg;
      in
      "hl.dsp.window.resize({ x = ${builtins.elemAt parts 0}, y = ${builtins.elemAt parts 1}, relative = true })"
    else
      throw "Unsupported Hyprland dispatcher: ${dispatcher}";

  parseBindLine =
    line:
    let
      parts = lib.splitString ", " line;
      len = builtins.length parts;
      key = builtins.elemAt parts 1;
      mods = builtins.elemAt parts 0;
      dispatcher = builtins.elemAt parts 2;
      arg = lib.concatStringsSep ", " (lib.drop 3 parts);
    in
    mkBind mods key (dispatch dispatcher arg) { };

  parseMouseBindLine =
    line:
    let
      parts = lib.splitString ", " line;
      mods = builtins.elemAt parts 0;
      key = builtins.elemAt parts 1;
      dispatcher = builtins.elemAt parts 2;
    in
    mkBind mods key (dispatch dispatcher "") { mouse = true; };

  parseLockedBindLine =
    line: repeating:
    let
      parts = lib.splitString ", " line;
      mods = builtins.elemAt parts 0;
      key = builtins.elemAt parts 1;
      dispatcher = builtins.elemAt parts 2;
      arg = lib.concatStringsSep ", " (lib.drop 3 parts);
    in
    mkBind mods key (dispatch dispatcher arg) (
      {
        locked = true;
      }
      // lib.optionalAttrs repeating {
        repeating = true;
      }
    );

  parseReleaseBindLine =
    line:
    let
      parts = lib.splitString ", " line;
      mods = builtins.elemAt parts 0;
      key = builtins.elemAt parts 1;
      dispatcher = builtins.elemAt parts 2;
      arg = lib.concatStringsSep ", " (lib.drop 3 parts);
    in
    mkBind mods key (dispatch dispatcher arg) {
      release = true;
    };

  mapBindLines = lines: map parseBindLine lines;
  mapMouseBindLines = lines: map parseMouseBindLine lines;
  mapLockedBindLines = lines: map (line: parseLockedBindLine line false) lines;
  mapLockedRepeatBindLines = lines: map (line: parseLockedBindLine line true) lines;
  mapReleaseBindLines = lines: map parseReleaseBindLine lines;
in
{
  inherit
    dsp
    mkBind
    mkExecBind
    mkEnv
    mkMonitor
    mkMonitorLine
    mkCurve
    mkAnimation
    mkGesture
    mkWindowRule
    mkLayerRule
    mkStartupHook
    ;
}
