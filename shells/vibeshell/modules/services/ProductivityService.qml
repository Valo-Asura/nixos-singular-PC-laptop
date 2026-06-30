pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string bridgeCommand: "/run/current-system/sw/bin/asura-super-productivity-bridge"
    readonly property string appCommand: "/run/current-system/sw/bin/asura-super-productivity"

    property bool installed: false
    property bool running: false
    property bool githubConnected: false
    property bool exporting: false
    property string lastExportPath: ""
    property string lastExportStatus: "Ready"
    readonly property string githubStatusText: githubConnected ? "GitHub ready" : "Setup GitHub"

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true;
    }

    function openApp() {
        Quickshell.execDetached([appCommand]);
        refreshSoon.restart();
    }

    function openGithubSetup() {
        Quickshell.execDetached([bridgeCommand, "github-setup"]);
        refreshSoon.restart();
    }

    function exportNotes() {
        if (exportProcess.running)
            return;
        exporting = true;
        lastExportStatus = "Exporting";
        exportProcess.running = true;
    }

    function openExportFolder() {
        if (lastExportPath.length > 0)
            Quickshell.execDetached(["xdg-open", lastExportPath.substring(0, lastExportPath.lastIndexOf("/"))]);
    }

    function applyStatus(text) {
        try {
            const parsed = JSON.parse((text || "").trim() || "{}");
            installed = parsed.installed === true;
            running = parsed.running === true;
            githubConnected = parsed.githubConnected === true;
            if (parsed.lastExportPath)
                lastExportPath = String(parsed.lastExportPath);
        } catch (e) {
            installed = false;
            running = false;
            githubConnected = false;
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Timer {
        id: refreshSoon
        interval: 1200
        repeat: false
        onTriggered: root.refresh()
    }

    Process {
        id: statusProcess
        running: false
        command: [root.bridgeCommand, "status"]
        stdout: StdioCollector {
            id: statusStdout
        }
        onExited: root.applyStatus(statusStdout.text)
    }

    Process {
        id: exportProcess
        running: false
        command: [root.bridgeCommand, "export-notes"]
        stdout: StdioCollector {
            id: exportStdout
        }
        stderr: StdioCollector {}
        onExited: exitCode => {
            root.exporting = false;
            const out = exportStdout.text.trim();
            if (exitCode === 0 && out.length > 0) {
                root.lastExportPath = out.split("\n").pop();
                root.lastExportStatus = "Notes exported";
            } else {
                root.lastExportStatus = "Export failed";
            }
            root.refresh();
        }
    }
}
