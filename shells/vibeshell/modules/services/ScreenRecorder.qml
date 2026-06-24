pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: root

    property bool isRecording: false
    property string duration: ""
    property string lastError: ""
    property bool canRecordDirectly: true // Default optimistic
    property string lastRecordingFile: ""
    property string currentOutputDir: ""
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property string pidFile: runtimeDir + "/asura-screen-record.pid"
    readonly property string fileFile: runtimeDir + "/asura-screen-record.file"

    property Process checkCapabilitiesProcess: Process {
        id: checkCapabilitiesProcess
        command: ["bash", "-lc", "command -v asura-screen-record-toggle >/dev/null 2>&1 && echo true || echo false"]
        running: true
        stdout: StdioCollector {
            onTextChanged: {
                root.canRecordDirectly = (text.trim() === "true");
            }
        }
    }

    property string videosDir: ""

    // Resolve XDG_VIDEOS_DIR
    property Process xdgVideosProcess: Process {
        id: xdgVideosProcess
        command: ["bash", "-c", "xdg-user-dir VIDEOS"]
        running: true // Run on startup
        stdout: StdioCollector {
            onTextChanged: {
                // Not strictly necessary here as we read in onExited
            }
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                var dir = xdgVideosProcess.stdout.text.trim();
                if (dir === "") {
                    dir = Quickshell.env("HOME") + "/Videos";
                }
                root.videosDir = dir + "/Recordings";
            } else {
                root.videosDir = Quickshell.env("HOME") + "/Videos/Recordings";
            }
        }
    }

    // Poll status — only while recording to avoid idle process churn
    property Timer statusTimer: Timer {
        interval: 2000
        repeat: true
        running: root.isRecording
        onTriggered: {
            checkProcess.running = true
        }
    }

    property Process checkProcess: Process {
        id: checkProcess
        command: ["bash", "-lc", "pid_file=" + shellQuote(root.pidFile) + "; if [ -s \"$pid_file\" ]; then pid=$(cat \"$pid_file\"); kill -0 \"$pid\" 2>/dev/null; else pgrep -u \"$(id -u)\" -x wf-recorder >/dev/null; fi"]
        onExited: exitCode => {
            var wasRecording = root.isRecording;
            root.isRecording = (exitCode === 0);
            
            if (root.isRecording && !wasRecording) {
                console.log("[ScreenRecorder] Detected running instance.");
            }

            if (root.isRecording) {
                timeProcess.running = true;
            } else {
                root.duration = "";
            }
        }
    }

    property Process timeProcess: Process {
        id: timeProcess
        command: ["bash", "-lc", "pid_file=" + shellQuote(root.pidFile) + "; if [ -s \"$pid_file\" ]; then pid=$(cat \"$pid_file\"); ps -o etime= -p \"$pid\" 2>/dev/null || true; fi"]
        stdout: StdioCollector {
            onTextChanged: {
                root.duration = text.trim();
            }
        }
    }

    function toggleRecording() {
        if (isRecording) {
            stopProcess.running = true;
        } else {
            // Default behavior: Portal, no audio
            startRecording(false, false, "portal", "");
        }
    }

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function normalizeRegion(regionStr) {
        if (!regionStr)
            return "";
        const match = String(regionStr).match(/^(\d+)x(\d+)\+(-?\d+)\+(-?\d+)$/);
        if (!match)
            return regionStr;
        let w = parseInt(match[1]);
        let h = parseInt(match[2]);
        const x = match[3];
        const y = match[4];
        if (w % 2 !== 0)
            w -= 1;
        if (h % 2 !== 0)
            h -= 1;
        if (w < 2 || h < 2)
            return regionStr;
        return w + "x" + h + "+" + x + "+" + y;
    }

    function startRecording(recordAudioOutput, recordAudioInput, mode, regionStr) {
        if (isRecording) return;
        
        var outputDir = Quickshell.env("HOME") + "/Videos/Screenrecords";
        root.currentOutputDir = outputDir;
        root.lastRecordingFile = "";
        root.lastError = "";
        startProcess.command = ["asura-screen-record-toggle", "start"];
        
        prepareProcess.running = true;
    }
    
    // 1. Ensure directory exists
    property Process prepareProcess: Process {
        id: prepareProcess
        command: ["mkdir", "-p", root.currentOutputDir]
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.lastError = "Could not create recording directory";
                notifyErrorProcess.running = true;
                return;
            }
            root.isRecording = true;
            notifyStartProcess.running = true;
            startProcess.running = true;
        }
    }

    // 2. Notify start
    property Process notifyStartProcess: Process {
        id: notifyStartProcess
        command: ["notify-send", "Screen Recorder", "Starting recording..."]
    }

    // 3. Start recording (Foreground)
    property Process startProcess: Process {
        id: startProcess
        command: ["asura-screen-record-toggle", "start"]
        
        stdout: StdioCollector {
            onTextChanged: console.log("[ScreenRecorder] OUT: " + text)
        }
        stderr: StdioCollector {
            id: stderrCollector
            onTextChanged: {
                console.warn("[ScreenRecorder] ERR: " + text)
                // root.lastError = text // gpu-screen-recorder is verbose
            }
        }
        
        onExited: exitCode => {
            console.log("[ScreenRecorder] Exited with code: " + exitCode)
            if (exitCode !== 0) {
                root.isRecording = false
                root.duration = ""
                notifyErrorProcess.running = true
            } else {
                root.isRecording = true
                fileReadProcess.running = true
                checkProcess.running = true
            }
        }
    }

    property Process notifyErrorProcess: Process {
        id: notifyErrorProcess
        command: ["notify-send", "-u", "critical", "Screen Recorder Error", "Failed to start. Check logs."]
    }

    property Process notifySavedProcess: Process {
        id: notifySavedProcess
        command: ["notify-send", "Screen Recorder", root.lastRecordingFile ? ("Recording saved to " + root.lastRecordingFile) : ("Recording saved to " + root.currentOutputDir)]
    }
    
    property Process openVideosProcess: Process {
        id: openVideosProcess
        command: ["xdg-open", root.currentOutputDir || (Quickshell.env("HOME") + "/Videos/Screenrecords")]
    }

    function openRecordingsFolder() {
        openVideosProcess.running = true;
    }

    property Process stopProcess: Process {
        id: stopProcess
        command: ["asura-screen-record-toggle", "stop"]
        onExited: {
            fileReadProcess.running = true;
            root.isRecording = false;
            root.duration = "";
            notifySavedProcess.running = true;
        }
    }

    property Process fileReadProcess: Process {
        id: fileReadProcess
        command: ["bash", "-lc", "file_file=" + shellQuote(root.fileFile) + "; [ -s \"$file_file\" ] && cat \"$file_file\" || true"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: {
                const value = text.trim();
                if (value.length > 0)
                    root.lastRecordingFile = value;
            }
        }
    }
}
