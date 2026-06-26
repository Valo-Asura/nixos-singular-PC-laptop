pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs.modules.theme

Singleton {
    id: root

    readonly property UPowerDevice primaryDevice: UPower.displayDevice

    readonly property bool available: primaryDevice !== null && primaryDevice.type === UPowerDevice.Battery
    readonly property real percentage: available ? primaryDevice.percentage : 0
    readonly property int chargeState: available ? primaryDevice.state : 0
    readonly property bool isCharging: available && (chargeState === 1 || chargeState === 5)
    readonly property bool isPluggedIn: available && (isCharging || chargeState === 4)
    readonly property bool isDischarging: available && (chargeState === 2 || chargeState === 6)
    readonly property int lowWarningThreshold: 30
    readonly property bool lowWarningActive: available && !isPluggedIn && percentage <= lowWarningThreshold
    property bool lowWarningSent: false

    // Add some helpful descriptive properties if needed
    readonly property string timeToEmpty: available && primaryDevice.timeToEmpty > 0 ? formatTime(primaryDevice.timeToEmpty) : ""
    readonly property string timeToFull: available && primaryDevice.timeToFull > 0 ? formatTime(primaryDevice.timeToFull) : ""

    function formatTime(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        if (h > 0) return h + "h " + m + "m";
        return m + "m";
    }

    function getBatteryIcon() {
        if (!available) return Icons.batteryEmpty;
        if (isPluggedIn) return Icons.batteryCharging;
        
        const pct = percentage;
        if (pct > 75) return Icons.batteryFull;
        if (pct > 50) return Icons.batteryHigh;
        if (pct > 25) return Icons.batteryMedium;
        if (pct > 5) return Icons.batteryLow;
        return Icons.batteryEmpty;
    }

    function checkLowBatteryWarning() {
        if (!available) {
            lowWarningSent = false;
            return;
        }

        if (isPluggedIn || percentage > lowWarningThreshold || percentage === 0) {
            lowWarningSent = false;
            return;
        }

        if (!lowWarningSent) {
            lowWarningSent = true;
            Quickshell.execDetached([
                "notify-send",
                "-a",
                "Vibeshell",
                "-u",
                "critical",
                "-i",
                "battery-caution",
                "Low battery",
                Math.round(percentage) + "% remaining. Plug in the laptop."
            ]);
        }
    }

    onPercentageChanged: checkLowBatteryWarning()
    onIsPluggedInChanged: checkLowBatteryWarning()
    onAvailableChanged: checkLowBatteryWarning()

    Timer {
        interval: 60000
        running: root.available
        repeat: true
        triggeredOnStart: true
        onTriggered: root.checkLowBatteryWarning()
    }
}
