import QtQuick
import Quickshell.Hyprland._GlobalShortcuts
import qs.modules.globals
import qs.modules.services
import qs.config

import Quickshell.Io

Item {
    id: root

    readonly property string appId: "vibeshell"
    readonly property string ipcPipe: "/tmp/vibeshell_ipc.pipe"

    // High-performance Pipe Listener (Daemon mode)
    // Creates a named pipe and listens for commands continuously
    Process {
        id: pipeListener
        command: ["bash", "-c", "rm -f " + root.ipcPipe + "; mkfifo " + root.ipcPipe + "; tail -f " + root.ipcPipe]
        running: true

        stdout: SplitParser {
            onRead: data => {
                const cmd = data.trim();
                if (cmd !== "") {
                    root.run(cmd);
                }
            }
        }
    }

    Process {
        id: vibewallProcess
        command: ["vibewall", "toggle"]
        running: false
    }

    Process {
        id: caffeineCommand
        running: false
    }

    function setCaffeine(next) {
        CaffeineService.inhibit = next;
        caffeineCommand.running = false;
        caffeineCommand.command = ["env", "ASURA_SHELL_QUIET=1", "asura-quickshell-switch", next ? "caffeine-on" : "caffeine-off"];
        caffeineCommand.running = true;
    }

    function run(command) {
        console.log("IPC run command received:", command);
        switch (command) {
        // Dashboard
        case "dashboard-close":
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            break;
        case "notch-launcher":
            toggleNotchLauncher();
            break;
        case "dashboard":
            GlobalStates.settingsVisible = !GlobalStates.settingsVisible;
            break;
        case "dashboard-widgets":
            toggleNotchLauncher();
            break;
        case "dashboard-wallpapers":
            vibewallProcess.running = false;
            vibewallProcess.running = true;
            break;
        case "dashboard-kanban":
            GlobalStates.notesVisible = !GlobalStates.notesVisible;
            break;
        case "dashboard-pomodoro":
            toggleNotchLauncher();
            break;
        case "dashboard-wifi":
            NetworkService.rescanWifi();
            GlobalStates.settingsVisible = true;
            break;
        case "dashboard-controls":
            GlobalStates.settingsVisible = !GlobalStates.settingsVisible;
            break;
        case "dashboard-clipboard":
            toggleDashboardWithPrefix(Config.prefix.clipboard + " ");
            break;
        case "dashboard-emoji":
            toggleDashboardWithPrefix(Config.prefix.emoji + " ");
            break;
        case "dashboard-tmux":
            toggleDashboardWithPrefix(Config.prefix.tmux + " ");
            break;
        case "dashboard-notes":
            GlobalStates.notesVisible = !GlobalStates.notesVisible;
            break;
        case "notes-new":
            GlobalStates.notesVisible = true;
            GlobalStates.notesRequestedSection = 0;
            GlobalStates.notesRequestedId = NotesService.createQuickNote();
            break;
        case "reminder-new":
            GlobalStates.notesVisible = true;
            GlobalStates.notesRequestedSection = 1;
            NotesService.createQuickReminder();
            break;

        // System
        case "overview":
            toggleSimpleModule("overview");
            break;
        case "powermenu":
            toggleSimpleModule("powermenu");
            break;
        case "tools":
            toggleSimpleModule("tools");
            break;
        case "config":
            GlobalStates.settingsVisible = !GlobalStates.settingsVisible;
            break;
        case "screenshot":
            GlobalStates.screenshotToolVisible = true;
            break;
        case "screenrecord":
            GlobalStates.screenRecordToolVisible = true;
            break;
        case "caffeine-on":
            setCaffeine(true);
            break;
        case "caffeine-off":
            setCaffeine(false);
            break;
        case "caffeine-toggle":
            setCaffeine(!CaffeineService.inhibit);
            break;
        case "lens":
            Screenshot.captureMode = "lens";
            GlobalStates.screenshotToolVisible = true;
            break;
        case "lockscreen":
            GlobalStates.lockscreenVisible = true;
            break;
        case "gamemode-toggle":
            GameModeService.toggle();
            break;
        case "gamemode-enable":
            GameModeService.toggled = true;
            GameModeService.saveState();
            break;
        case "gamemode-disable":
            GameModeService.toggled = false;
            GameModeService.saveState();
            break;

        // Media
        case "media-seek-backward":
            seekActivePlayer(-mediaSeekStepMs);
            break;
        case "media-seek-forward":
            seekActivePlayer(mediaSeekStepMs);
            break;
        case "media-play-pause":
            if (MprisController.canTogglePlaying)
                MprisController.togglePlaying();
            break;
        case "media-next":
            MprisController.next();
            break;
        case "media-prev":
            MprisController.previous();
            break;
        default:
            console.warn("Unknown IPC command:", command);
        }
    }

    IpcHandler {
        target: "vibeshell"

        function run(command: string) {
            root.run(command);
        }
    }

    function toggleSimpleModule(moduleName) {
        if (Visibilities.currentActiveModule === moduleName) {
            Visibilities.setActiveModule("");
        } else {
            Visibilities.setActiveModule(moduleName);
        }
    }

    function toggleNotchLauncher() {
        const isActive = Visibilities.currentActiveModule === "launcher";

        if (isActive && GlobalStates.launcherSearchText === "") {
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            return;
        }

        GlobalStates.launcherSearchText = "";
        GlobalStates.launcherSelectedIndex = -1;
        GlobalStates.launcherCurrentTab = 0;

        if (!isActive) {
            Visibilities.setActiveModule("launcher");
        }
    }

    function toggleDashboardWithPrefix(prefix) {
        const isActive = Visibilities.currentActiveModule === "launcher";

        if (isActive && GlobalStates.launcherSearchText === prefix) {
            Visibilities.setActiveModule("");
            GlobalStates.clearLauncherState();
            return;
        }

        GlobalStates.launcherSelectedIndex = -1;

        if (!isActive) {
            Visibilities.setActiveModule("launcher");
            Qt.callLater(() => {
                GlobalStates.launcherSearchText = prefix;
            });
        } else {
            GlobalStates.launcherSearchText = prefix;
        }
    }

    function seekActivePlayer(offset) {
        const player = MprisController.activePlayer;
        if (!player || !player.canSeek) {
            return;
        }

        const maxLength = typeof player.length === "number" && !isNaN(player.length) ? player.length : Number.MAX_SAFE_INTEGER;
        const clamped = Math.max(0, Math.min(maxLength, player.position + offset));
        player.position = clamped;
    }

    GlobalShortcut {
        appid: root.appId
        name: "overview"
        description: "Toggle window overview"

        onPressed: toggleSimpleModule("overview")
    }

    GlobalShortcut {
        appid: root.appId
        name: "powermenu"
        description: "Toggle power menu"

        onPressed: toggleSimpleModule("powermenu")
    }

    GlobalShortcut {
        appid: root.appId
        name: "tools"
        description: "Toggle tools menu"

        onPressed: toggleSimpleModule("tools")
    }

    GlobalShortcut {
        appid: root.appId
        name: "screenshot"
        description: "Open screenshot tool"

        onPressed: GlobalStates.screenshotToolVisible = true
    }

    GlobalShortcut {
        appid: root.appId
        name: "screenrecord"
        description: "Open screen record tool"

        onPressed: GlobalStates.screenRecordToolVisible = true
    }

    GlobalShortcut {
        appid: root.appId
        name: "lens"
        description: "Open Google Lens (screenshot)"

        onPressed: {
            Screenshot.captureMode = "lens";
            GlobalStates.screenshotToolVisible = true;
        }
    }

    // Dashboard tab shortcuts
    GlobalShortcut {
        appid: root.appId
        name: "dashboard-widgets"
        description: "Open notch app launcher"

        onPressed: toggleNotchLauncher()
    }

    GlobalShortcut {
        appid: root.appId
        name: "notch-launcher"
        description: "Open notch app launcher"

        onPressed: toggleNotchLauncher()
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-clipboard"
        description: "Open launcher clipboard prefix"

        onPressed: toggleDashboardWithPrefix(Config.prefix.clipboard + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-emoji"
        description: "Open launcher emoji prefix"

        onPressed: toggleDashboardWithPrefix(Config.prefix.emoji + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-tmux"
        description: "Open launcher tmux prefix"

        onPressed: toggleDashboardWithPrefix(Config.prefix.tmux + " ")
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-kanban"
        description: "Open Vibeshell notes"

        onPressed: GlobalStates.notesVisible = !GlobalStates.notesVisible
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-pomodoro"
        description: "Open notch app launcher"

        onPressed: toggleNotchLauncher()
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-wallpapers"
        description: "Open Vibewall"

        onPressed: {
            vibewallProcess.running = false;
            vibewallProcess.running = true;
        }
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-notes"
        description: "Open Vibeshell Notes"

        onPressed: GlobalStates.notesVisible = !GlobalStates.notesVisible
    }

    GlobalShortcut {
        appid: root.appId
        name: "dashboard-controls"
        description: "Open Vibeshell settings"

        onPressed: GlobalStates.settingsVisible = !GlobalStates.settingsVisible
    }

    // Media player shortcuts
    GlobalShortcut {
        appid: root.appId
        name: "media-seek-backward"
        description: "Seek backward in media player"

        onPressed: seekActivePlayer(-mediaSeekStepMs)
    }

    GlobalShortcut {
        appid: root.appId
        name: "media-seek-forward"
        description: "Seek forward in media player"

        onPressed: seekActivePlayer(mediaSeekStepMs)
    }

    GlobalShortcut {
        appid: root.appId
        name: "media-play-pause"
        description: "Toggle play/pause in media player"

        onPressed: {
            if (MprisController.canTogglePlaying) {
                MprisController.togglePlaying();
            }
        }
    }
}
