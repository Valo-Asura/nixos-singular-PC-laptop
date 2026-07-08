pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var binds: []
    property var aliases: []
    property bool loadingBinds: false
    property bool loadingAliases: false
    readonly property bool loading: loadingBinds || loadingAliases
    property string lastError: ""

    function modMaskToText(mask) {
        const bits = [
            { bit: 64, name: "SUPER" },
            { bit: 8, name: "ALT" },
            { bit: 4, name: "CTRL" },
            { bit: 1, name: "SHIFT" }
        ];
        const names = [];
        for (let i = 0; i < bits.length; i++) {
            if ((mask & bits[i].bit) !== 0)
                names.push(bits[i].name);
        }
        return names.join(" + ");
    }

    function normalizeBind(item) {
        const key = item.key && item.key.length > 0 ? item.key : (item.keycode ? "code:" + item.keycode : "");
        const mods = modMaskToText(item.modmask || 0);
        const combo = [mods, key].filter(part => part && part.length > 0).join(" + ");
        const dispatcher = item.dispatcher || "";
        const arg = item.arg || "";
        const flags = [];
        if (item.submap && item.submap.length > 0)
            flags.push(item.submap);
        if (item.locked)
            flags.push("locked");
        if (item.release)
            flags.push("release");
        if (item.repeat)
            flags.push("repeat");
        if (item.mouse)
            flags.push("mouse");

        return {
            combo: combo.length > 0 ? combo : "unbound",
            action: [dispatcher, arg].filter(part => part && part.length > 0).join(" "),
            flags: flags.join(" / ")
        };
    }

    function refresh() {
        loadingBinds = true;
        loadingAliases = true;
        lastError = "";
        bindsProcess.running = true;
        aliasesProcess.running = true;
    }

    Process {
        id: bindsProcess
        running: false
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text.trim() || "[]");
                    const normalized = [];
                    for (let i = 0; i < parsed.length; i++)
                        normalized.push(root.normalizeBind(parsed[i]));
                    normalized.sort((a, b) => a.combo.localeCompare(b.combo));
                    root.binds = normalized;
                } catch (e) {
                    root.lastError = "Could not parse Hyprland binds";
                    root.binds = [];
                }
            }
        }
        onExited: code => {
            root.loadingBinds = false;
            if (code !== 0)
                root.lastError = "hyprctl binds failed";
        }
    }

    Process {
        id: aliasesProcess
        running: false
        command: [
            "python3",
            "-c",
            [
                "import json, pathlib, re",
                "path = pathlib.Path('/etc/nixos/home/shell/default.nix')",
                "text = path.read_text() if path.exists() else ''",
                "match = re.search(r'shellAliases\\s*=\\s*\\{(?P<body>.*?)\\n\\s*\\};', text, re.S)",
                "aliases = []",
                "if match:",
                "    for name, cmd in re.findall(r'\\n\\s*([A-Za-z0-9_.-]+)\\s*=\\s*\"((?:\\\\.|[^\"\\\\])*)\";', match.group('body')):",
                "        aliases.append({'name': name, 'command': bytes(cmd, 'utf-8').decode('unicode_escape')})",
                "aliases.sort(key=lambda item: item['name'])",
                "print(json.dumps(aliases))"
            ].join("\n")
        ]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                try {
                    root.aliases = JSON.parse(text.trim() || "[]");
                } catch (e) {
                    root.lastError = "Could not parse shell aliases";
                    root.aliases = [];
                }
            }
        }
        onExited: code => {
            root.loadingAliases = false;
            if (code !== 0)
                root.lastError = "alias parser failed";
        }
    }

    Component.onCompleted: refresh()
}
