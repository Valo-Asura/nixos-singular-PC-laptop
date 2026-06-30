pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: false
    property string directory: ""
    property string displayText: active ? "COPY " + elapsedText : ""
    property int startedAt: 0
    property int nowSeconds: Math.floor(Date.now() / 1000)
    property int missCount: 0
    readonly property string elapsedText: {
        const elapsed = Math.max(0, nowSeconds - startedAt);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        return String(minutes).padStart(2, "0") + ":" + String(seconds).padStart(2, "0");
    }

    function scanCommand() {
        return ["bash", "-lc", `
            roots=()
            for dir in "$HOME/Desktop" "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures" "$HOME/Videos" "$HOME/Music" "$HOME/Projects"; do
              [ -d "$dir" ] && roots+=("$dir")
            done
            [ "\${#roots[@]}" -gt 0 ] || exit 0
            find "\${roots[@]}" -xdev \\
              \\( -name '.goutputstream-*' -o -name '*.part' -o -name '*.partial' \\) \\
              -mmin -2 -printf '%T@ %h\\n' 2>/dev/null | sort -nr | head -n 1
        `];
    }

    function openLocation() {
        if (directory.length > 0)
            Quickshell.execDetached(["xdg-open", directory]);
        else
            Quickshell.execDetached(["pcmanfm-qt"]);
    }

    function applyScan(output) {
        const line = (output || "").trim().split("\n")[0] || "";
        if (line.length === 0) {
            missCount += 1;
            if (missCount >= 2)
                active = false;
            return;
        }

        const firstSpace = line.indexOf(" ");
        directory = firstSpace >= 0 ? line.substring(firstSpace + 1).trim() : "";
        missCount = 0;
        if (!active) {
            active = true;
            startedAt = Math.floor(Date.now() / 1000);
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            root.nowSeconds = Math.floor(Date.now() / 1000);
            if (!scanProcess.running) {
                scanProcess.command = root.scanCommand();
                scanProcess.running = true;
            }
        }
    }

    Process {
        id: scanProcess
        running: false
        command: []
        stdout: StdioCollector {
            id: scanStdout
        }
        onExited: root.applyScan(scanStdout.text)
    }
}
