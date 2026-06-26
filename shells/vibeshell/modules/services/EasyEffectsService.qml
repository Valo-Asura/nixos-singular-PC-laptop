pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Whether EasyEffects is available on the system
    property bool available: false
    readonly property var utf8Environment: ({ LANG: "C.UTF-8", LC_ALL: "C.UTF-8" })
    
    // Bypass state: false = effects active, true = bypassed
    property bool bypassed: false
    
    // Available presets
    property var outputPresets: []
    property var inputPresets: []
    
    // Currently active presets
    property string activeOutputPreset: ""
    property string activeInputPreset: ""

    // Toggle bypass state
    function toggleBypass() {
        bypassToggleProcess.command = ["easyeffects", "-b", bypassed ? "2" : "1"];
        bypassToggleProcess.running = true;
    }
    
    function setBypass(enable: bool) {
        bypassToggleProcess.command = ["easyeffects", "-b", enable ? "1" : "2"];
        bypassToggleProcess.running = true;
    }

    // Load a preset (optimistic update)
    function loadOutputPreset(name: string) {
        root.activeOutputPreset = name;  // Optimistic update
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    function loadInputPreset(name: string) {
        root.activeInputPreset = name;  // Optimistic update
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    // Legacy function for compatibility
    function loadPreset(name: string) {
        loadPresetProcess.command = ["easyeffects", "-l", name];
        loadPresetProcess.running = true;
    }

    // Refresh all data
    function refresh() {
        checkAvailableProcess.running = false;
        checkAvailableProcess.running = true;
    }

    // Open EasyEffects app
    function openApp() {
        Quickshell.execDetached(["env", "LANG=C.UTF-8", "LC_ALL=C.UTF-8", "easyeffects"]);
    }

    // Check if easyeffects is available
    Process {
        id: checkAvailableProcess
        command: ["bash", "-lc", "command -v easyeffects >/dev/null 2>&1"]
        running: true
        onExited: (exitCode, exitStatus) => {
            root.available = (exitCode === 0);
            if (root.available) {
                // Fetch initial state
                bypassStateProcess.running = false;
                presetsProcess.running = false;
                activePresetsProcess.running = false;
                bypassStateProcess.running = true;
                presetsProcess.running = true;
                activePresetsProcess.running = true;
            } else {
                root.outputPresets = [];
                root.inputPresets = [];
                root.activeOutputPreset = "";
                root.activeInputPreset = "";
            }
        }
    }

    // Get bypass state
    Process {
        id: bypassStateProcess
        command: ["easyeffects", "-b", "3"]
        running: false
        environment: root.utf8Environment
        stdout: SplitParser {
            onRead: data => {
                const val = data.trim();
                root.bypassed = (val === "1");
            }
        }
    }

    // Toggle bypass
    Process {
        id: bypassToggleProcess
        running: false
        environment: root.utf8Environment
        onExited: {
            bypassStateProcess.running = true;
        }
    }

    // Load preset
    Process {
        id: loadPresetProcess
        running: false
        environment: root.utf8Environment
        onExited: {
            // Small delay to let EasyEffects apply the preset
            refreshDelayTimer.restart();
        }
    }

    // Delay timer for refresh after preset load
    Timer {
        id: refreshDelayTimer
        interval: 100
        repeat: false
        onTriggered: {
            activePresetsProcess.running = true;
            bypassStateProcess.running = true;
        }
    }

    // List presets
    Process {
        id: presetsProcess
        command: ["easyeffects", "-p"]
        running: false
        property string buffer: ""
        environment: root.utf8Environment
        stdout: SplitParser {
            onRead: data => {
                presetsProcess.buffer += data + "\n";
            }
        }
        onExited: {
            const text = presetsProcess.buffer;
            presetsProcess.buffer = "";
            
            const lines = text.split("\n");
            let isOutput = false;
            let isInput = false;
            let outputList = [];
            let inputList = [];
            
            for (const line of lines) {
                const trimmed = line.trim();
                const lower = trimmed.toLowerCase();
                if (lower.startsWith("no output")) {
                    isOutput = false;
                    isInput = false;
                } else if (lower.startsWith("no input")) {
                    isOutput = false;
                    isInput = false;
                } else if (lower.includes("output")) {
                    isOutput = true;
                    isInput = false;
                    // Check if presets are on same line after colon
                    const parts = trimmed.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        outputList = parts[1].trim().split(",").map(p => p.trim()).filter(p => p);
                    }
                } else if (lower.includes("input")) {
                    isInput = true;
                    isOutput = false;
                    const parts = trimmed.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        inputList = parts[1].trim().split(",").map(p => p.trim()).filter(p => p);
                    }
                } else if (trimmed && !trimmed.includes(":")) {
                    // Preset name on its own line
                    if (isOutput) outputList.push(trimmed);
                    else if (isInput) inputList.push(trimmed);
                }
            }
            
            root.outputPresets = outputList;
            root.inputPresets = inputList;
        }
    }

    // Get active presets
    Process {
        id: activePresetsProcess
        command: ["easyeffects", "-s"]
        running: false
        property string buffer: ""
        environment: root.utf8Environment
        stdout: SplitParser {
            onRead: data => {
                activePresetsProcess.buffer += data + "\n";
            }
        }
        onExited: {
            const text = activePresetsProcess.buffer;
            activePresetsProcess.buffer = "";
            
            const lines = text.split("\n");
            let section = "";
            root.activeOutputPreset = "";
            root.activeInputPreset = "";
            for (const line of lines) {
                const raw = line.trim();
                const trimmed = raw.toLowerCase();
                if (trimmed.startsWith("output")) {
                    section = "output";
                    const parts = line.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        root.activeOutputPreset = parts[1].trim();
                    }
                } else if (trimmed.startsWith("input")) {
                    section = "input";
                    const parts = line.split(":");
                    if (parts.length > 1 && parts[1].trim()) {
                        root.activeInputPreset = parts[1].trim();
                    }
                } else if (raw.length > 0 && section === "output") {
                    root.activeOutputPreset = raw;
                } else if (raw.length > 0 && section === "input") {
                    root.activeInputPreset = raw;
                }
            }
        }
    }

    // Poll for state changes periodically
    Timer {
        interval: 5000
        running: root.available
        repeat: true
        onTriggered: {
            bypassStateProcess.running = true;
            activePresetsProcess.running = true;
        }
    }
}
