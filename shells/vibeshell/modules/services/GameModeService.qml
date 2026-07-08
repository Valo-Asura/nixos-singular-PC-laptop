pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool toggled: false
    property bool initialized: false
    property bool busy: false
    property string lastError: ""

    function setEnabled(enabled) {
        if (busy)
            return;

        busy = true;
        lastError = "";
        toggled = enabled;
        gameModeProcess.command = ["asura-game-mode", enabled ? "on" : "off"];
        gameModeProcess.running = true;
    }

    function toggle() {
        setEnabled(!toggled);
    }

    function refresh() {
        statusProcess.command = ["asura-game-mode", "status"];
        statusProcess.running = true;
    }

    Process {
        id: gameModeProcess
        running: false
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                if (text.trim().length > 0)
                    root.lastError = text.trim();
            }
        }
        onExited: code => {
            root.busy = false;
            if (code !== 0) {
                root.toggled = !root.toggled;
                if (root.lastError.length === 0)
                    root.lastError = "asura-game-mode exited with " + code;
            }
            root.refresh();
        }
    }

    Process {
        id: statusProcess
        running: false
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const state = text.trim();
                if (state === "on" || state === "off")
                    root.toggled = state === "on";
                root.initialized = true;
            }
        }
        onExited: code => {
            if (code !== 0)
                root.initialized = true;
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
