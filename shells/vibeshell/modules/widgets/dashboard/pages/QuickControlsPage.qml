import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    property date now: new Date()
    property bool airplaneMode: false
    property bool powerSaver: false

    readonly property var focusedBrightnessMonitor: {
        const focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const found = Brightness.monitors.find(m => m && m.screen && m.screen.name === focusedName);
        return found || (Brightness.monitors.length > 0 ? Brightness.monitors[0] : null);
    }

    function formatTime(date) {
        const use24h = Config.bar.clockFormat === "24h";
        let hours = date.getHours();
        const minutes = String(date.getMinutes()).padStart(2, "0");
        if (use24h)
            return String(hours).padStart(2, "0") + ":" + minutes;
        const suffix = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        if (hours === 0)
            hours = 12;
        return String(hours).padStart(2, "0") + ":" + minutes + " " + suffix;
    }

    function formatDate(date) {
        return Qt.formatDate(date, "dddd, MMMM d");
    }

    function setCaffeine(next) {
        CaffeineService.inhibit = next;
        caffeineCommand.running = false;
        caffeineCommand.command = ["env", "ASURA_SHELL_QUIET=1", "asura-shell-switch", next ? "caffeine-on" : "caffeine-off"];
        caffeineCommand.running = true;
    }

    function setDarkTheme(next) {
        Config.theme.themeMode = next ? "dark" : "light";
        Config.theme.lightMode = !next;
        Config.saveTheme();
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: {
        NetworkService.rescanWifi();
        powerProfileQuery.running = true;
        airplaneQuery.running = true;
    }

    Process {
        id: caffeineCommand
        running: false
    }

    Process {
        id: airplaneQuery
        running: false
        command: ["bash", "-lc", "rfkill -rn list 2>/dev/null | awk '{print $4}' | grep -q blocked"]
        onExited: exitCode => root.airplaneMode = exitCode === 0
    }

    Process {
        id: airplaneCommand
        running: false
        command: ["bash", "-lc", "asura-airplane-toggle >/dev/null 2>&1 || rfkill " + (root.airplaneMode ? "unblock" : "block") + " all"]
        onExited: airplaneQuery.running = true
    }

    Process {
        id: powerProfileQuery
        running: false
        command: ["bash", "-lc", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl get | grep -q '^power-saver$'"]
        onExited: exitCode => root.powerSaver = exitCode === 0
    }

    Process {
        id: powerProfileCommand
        running: false
        command: ["bash", "-lc", "command -v powerprofilesctl >/dev/null 2>&1 && powerprofilesctl set " + (root.powerSaver ? "balanced" : "power-saver") + " || true"]
        onExited: powerProfileQuery.running = true
    }

    Row {
        anchors.fill: parent
        spacing: 12

        Column {
            width: 204
            height: parent.height
            spacing: 10

            Row {
                width: parent.width
                height: 48
                spacing: 10

                Column {
                    width: parent.width - batteryPill.width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        text: root.formatTime(root.now)
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(8)
                        font.weight: Font.ExtraBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        text: root.formatDate(root.now)
                        color: Colors.overSurfaceVariant
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-2)
                        elide: Text.ElideRight
                    }
                }

                StyledRect {
                    id: batteryPill
                    visible: Battery.available
                    variant: Battery.lowWarningActive ? "error" : (Battery.isPluggedIn ? "primary" : "common")
                    width: Battery.available ? 70 : 0
                    height: 38
                    anchors.verticalCenter: parent.verticalCenter
                    radius: Styling.radius(10)

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Battery.getBatteryIcon()
                            font.family: Icons.font
                            font.pixelSize: 15
                            color: Battery.isPluggedIn ? Styling.srItem("primary") : Colors.overBackground
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Battery.percentage) + "%"
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            font.weight: Font.Bold
                            color: Battery.isPluggedIn ? Styling.srItem("primary") : Colors.overBackground
                        }
                    }
                }
            }

            QuickTile {
                width: parent.width
                icon: NetworkService.wifiEnabled ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                title: NetworkService.networkName.length > 0 ? NetworkService.networkName : "Wi-Fi"
                subtitle: NetworkService.wifiStatus
                active: NetworkService.wifiEnabled
                arrow: true
                onClicked: NetworkService.toggleWifi()
                onArrowClicked: NetworkService.rescanWifi()
            }

            QuickTile {
                width: parent.width
                icon: BluetoothService.connected ? Icons.bluetoothConnected : (BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothOff)
                title: "Bluetooth"
                subtitle: BluetoothService.connected ? BluetoothService.connectedDevices + " connected" : (BluetoothService.enabled ? "On" : "Off")
                active: BluetoothService.enabled
                arrow: true
                onClicked: BluetoothService.toggle()
                onArrowClicked: {
                    if (!BluetoothService.enabled)
                        BluetoothService.setEnabled(true);
                    else if (BluetoothService.discovering)
                        BluetoothService.stopDiscovery();
                    else
                        BluetoothService.startDiscovery();
                }
            }

            QuickSlider {
                width: parent.width
                icon: Audio.sink?.audio?.muted ? Icons.speakerX : Icons.speakerHigh
                value: Audio.sink?.audio?.volume ?? 0
                label: "Audio"
                valueText: Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
                onMoved: value => Audio.setVolume(value)
                onIconClicked: Audio.toggleMute()
            }

            QuickSlider {
                width: parent.width
                icon: Icons.sun
                value: root.focusedBrightnessMonitor ? root.focusedBrightnessMonitor.brightness : 0
                label: "Brightness"
                valueText: Math.round((root.focusedBrightnessMonitor ? root.focusedBrightnessMonitor.brightness : 0) * 100) + "%"
                onMoved: value => {
                    if (root.focusedBrightnessMonitor)
                        root.focusedBrightnessMonitor.setBrightness(value);
                }
            }

            QuickTile {
                width: parent.width
                height: 58
                icon: Battery.getBatteryIcon()
                title: "Battery"
                subtitle: Battery.available ? (Math.round(Battery.percentage) + "% - " + (Battery.isPluggedIn ? "Charging" : "Discharging")) : "Unavailable"
                active: Battery.lowWarningActive
                onClicked: {}
            }

            Grid {
                width: parent.width
                columns: 2
                spacing: 8

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Icons.nightLight
                    title: "Night Light"
                    subtitle: NightLightService.active ? "On" : "Off"
                    active: NightLightService.active
                    onClicked: NightLightService.toggle()
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Notifications.silent ? Icons.bellZ : Icons.bell
                    title: "Do Not Disturb"
                    subtitle: Notifications.silent ? "On" : "Off"
                    active: Notifications.silent
                    onClicked: Notifications.silent = !Notifications.silent
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Icons.globe
                    title: "Airplane Mode"
                    subtitle: root.airplaneMode ? "On" : "Off"
                    active: root.airplaneMode
                    onClicked: airplaneCommand.running = true
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Icons.caffeine
                    title: "Power Saver"
                    subtitle: root.powerSaver ? "On" : "Off"
                    active: root.powerSaver
                    onClicked: powerProfileCommand.running = true
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Config.theme.lightMode ? Icons.sun : Icons.moon
                    title: "Dark Theme"
                    subtitle: Config.theme.lightMode ? "Off" : "On"
                    active: !Config.theme.lightMode
                    onClicked: root.setDarkTheme(Config.theme.lightMode)
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    icon: Icons.recordScreen
                    title: "Screen Cast"
                    subtitle: ScreenRecorder.isRecording ? ScreenRecorder.duration : "Off"
                    active: ScreenRecorder.isRecording
                    onClicked: ScreenRecorder.toggleRecording()
                }
            }
        }

        Rectangle {
            width: 1
            height: parent.height
            color: Colors.surfaceBright
            opacity: 0.6
        }

        Column {
            width: parent.width - 204 - 1 - parent.spacing * 2
            height: parent.height
            spacing: 10

            Row {
                width: parent.width
                height: 30

                Text {
                    width: parent.width - 66
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Networks"
                    color: Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(0)
                    font.weight: Font.Bold
                }

                MiniIconButton {
                    icon: Icons.sync
                    onClicked: NetworkService.rescanWifi()
                }

                MiniIconButton {
                    icon: Icons.faders
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            ListView {
                id: wifiList
                width: parent.width
                height: parent.height - 74
                clip: true
                spacing: 6
                model: NetworkService.friendlyWifiNetworks

                delegate: WifiRow {
                    required property var modelData
                    width: wifiList.width
                    network: modelData
                }
            }

            QuickFooter {
                width: parent.width
                title: "Network Settings"
                onClicked: Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }

    component QuickTile: StyledRect {
        id: tile

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        property bool arrow: false
        signal clicked
        signal arrowClicked

        height: 62
        variant: active || tileMouse.containsMouse ? "primary" : "common"
        radius: Styling.radius(10)

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }

        Row {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 9

            Text {
                width: 22
                anchors.verticalCenter: parent.verticalCenter
                text: tile.icon
                font.family: Icons.font
                font.pixelSize: 19
                color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - 56
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: tile.arrow
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 15
                color: tile.active || tileMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.arrowClicked()
                }
            }
        }
    }

    component QuickSlider: StyledRect {
        id: sliderBox

        property string icon: ""
        property string label: ""
        property string valueText: ""
        property real value: 0
        signal moved(real value)
        signal iconClicked

        height: 54
        variant: "common"
        radius: Styling.radius(10)

        Column {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 5

            Row {
                width: parent.width

                Text {
                    width: 24
                    text: sliderBox.icon
                    font.family: Icons.font
                    font.pixelSize: 16
                    color: Colors.overBackground

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sliderBox.iconClicked()
                    }
                }

                Text {
                    width: parent.width - 62
                    text: sliderBox.label
                    color: Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: 38
                    horizontalAlignment: Text.AlignRight
                    text: sliderBox.valueText
                    color: Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                }
            }

            Item {
                id: track
                width: parent.width
                height: 18

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    height: 6
                    radius: 3
                    color: Colors.surfaceBright
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.max(6, parent.width * Math.max(0, Math.min(1, sliderBox.value)))
                    height: 6
                    radius: 3
                    color: Colors.primary
                }

                Rectangle {
                    x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, sliderBox.value)) - width / 2))
                    anchors.verticalCenter: parent.verticalCenter
                    width: 14
                    height: 14
                    radius: 7
                    color: Colors.overBackground
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor

                    function commit(mouseX) {
                        const next = Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
                        sliderBox.value = next;
                        sliderBox.moved(next);
                    }

                    onPressed: mouse => commit(mouse.x)
                    onPositionChanged: mouse => {
                        if (pressed)
                            commit(mouse.x);
                    }
                    onWheel: wheel => {
                        const next = Math.max(0, Math.min(1, sliderBox.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05)));
                        sliderBox.value = next;
                        sliderBox.moved(next);
                    }
                }
            }
        }
    }

    component MiniToggle: StyledRect {
        id: button

        property string icon: ""
        property string title: ""
        property string subtitle: ""
        property bool active: false
        signal clicked

        height: 50
        variant: active || buttonMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(9)

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Column {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 2

            Row {
                width: parent.width
                spacing: 6

                Text {
                    width: 17
                    text: button.icon
                    color: button.active || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Icons.font
                    font.pixelSize: 14
                }

                Text {
                    width: parent.width - 23
                    text: button.title
                    color: button.active || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }
            }

            Text {
                width: parent.width
                text: button.subtitle
                color: button.active || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-5)
                elide: Text.ElideRight
            }
        }
    }

    component MiniIconButton: StyledRect {
        id: button

        property string icon: ""
        signal clicked

        width: 30
        height: 30
        variant: buttonMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(8)

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Text {
            anchors.centerIn: parent
            text: button.icon
            font.family: Icons.font
            font.pixelSize: 15
            color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
        }
    }

    component WifiRow: StyledRect {
        id: row

        required property var network

        height: 42
        variant: network.active || rowMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(9)

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (row.network.active)
                    NetworkService.disconnectWifiNetwork();
                else
                    NetworkService.connectToWifiNetwork(row.network);
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8

            Text {
                width: 18
                anchors.verticalCenter: parent.verticalCenter
                text: NetworkService.wifiIconForStrength(row.network.strength)
                font.family: Icons.font
                font.pixelSize: 13
                color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - strengthIcon.width - 34
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: row.network.ssid
                    color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    font.weight: row.network.active ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: ((row.network.security || "").length > 0 ? "Secured" : "Open") + " - " + row.network.strength + "%"
                    color: row.network.active || rowMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-5)
                    elide: Text.ElideRight
                }
            }

            Text {
                id: strengthIcon
                width: 16
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: row.network.active ? Icons.accept : ""
                color: Styling.srItem("primary")
                font.family: Icons.font
                font.pixelSize: 14
            }
        }
    }

    component QuickFooter: StyledRect {
        id: footer

        property string title: ""
        signal clicked

        height: 34
        variant: footerMouse.containsMouse ? "focus" : "transparent"
        radius: Styling.radius(8)

        MouseArea {
            id: footerMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: footer.clicked()
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
                width: parent.width - 18
                anchors.verticalCenter: parent.verticalCenter
                text: footer.title
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                elide: Text.ElideRight
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.caretRight
                color: Colors.overSurfaceVariant
                font.family: Icons.font
                font.pixelSize: 13
            }
        }
    }
}
