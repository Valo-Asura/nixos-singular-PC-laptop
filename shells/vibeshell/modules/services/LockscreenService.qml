pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import qs.modules.globals

QtObject {
    id: root

    property Process lockCommand: Process {
        id: lockCommand
        command: ["vibeshell-safe-lock"]
        running: false
    }

    function toggle() {
        lock();
    }

    function lock() {
        lockCommand.running = false;
        lockCommand.running = true;
    }

    function unlock() {
        GlobalStates.lockscreenVisible = false;
    }

    property IpcHandler ipc: IpcHandler {
        target: "lockscreen"

        function toggle() {
            root.toggle();
        }

        function lock() {
            root.lock();
        }

        function unlock() {
            root.unlock();
        }
    }
}
