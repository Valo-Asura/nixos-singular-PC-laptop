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
    property string sideMode: "notifications"

    readonly property var focusedBrightnessMonitor: {
        const focusedName = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "";
        const found = Brightness.monitors.find(m => m && m.screen && m.screen.name === focusedName);
        return found || (Brightness.monitors.length > 0 ? Brightness.monitors[0] : null);
    }
    readonly property int controlsWidth: Math.min(304, Math.max(252, Math.round(width * 0.36)))

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

    function openWifiList() {
        sideMode = "wifi";
        if (!NetworkService.wifiEnabled)
            NetworkService.enableWifi(true);
        NetworkService.rescanWifi();
    }

    function openBluetoothList() {
        sideMode = "bluetooth";
        if (!BluetoothService.enabled)
            BluetoothService.setEnabled(true);
        else
            BluetoothService.startDiscovery();
    }

    function showNotifications() {
        sideMode = "notifications";
    }

    function notificationTime(notif) {
        if (!notif || !notif.time)
            return "";
        const delta = Math.max(0, Date.now() - notif.time);
        const minutes = Math.floor(delta / 60000);
        if (minutes < 1)
            return "now";
        if (minutes < 60)
            return minutes + "m";
        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return hours + "h";
        return Math.floor(hours / 24) + "d";
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
            width: root.controlsWidth
            height: parent.height
            spacing: 8

            Row {
                width: parent.width
                height: 42
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
                height: 54
                icon: NetworkService.wifiEnabled ? NetworkService.wifiIconForStrength(NetworkService.networkStrength) : Icons.wifiOff
                title: NetworkService.networkName.length > 0 ? NetworkService.networkName : "Wi-Fi"
                subtitle: NetworkService.wifiStatus
                active: NetworkService.wifiEnabled
                arrow: true
                onClicked: NetworkService.toggleWifi()
                onArrowClicked: root.openWifiList()
            }

            QuickTile {
                width: parent.width
                height: 54
                icon: BluetoothService.connected ? Icons.bluetoothConnected : (BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothOff)
                title: "Bluetooth"
                subtitle: BluetoothService.connected ? BluetoothService.connectedDevices + " connected" : (BluetoothService.enabled ? "On" : "Off")
                active: BluetoothService.enabled
                arrow: true
                onClicked: BluetoothService.toggle()
                onArrowClicked: root.openBluetoothList()
            }

            QuickSlider {
                width: parent.width
                height: 48
                icon: Audio.sink?.audio?.muted ? Icons.speakerX : Icons.speakerHigh
                value: Audio.sink?.audio?.volume ?? 0
                label: "Audio"
                valueText: Math.round((Audio.sink?.audio?.volume ?? 0) * 100) + "%"
                onMoved: value => Audio.setVolume(value)
                onIconClicked: Audio.toggleMute()
            }

            QuickSlider {
                width: parent.width
                height: 48
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
                height: 50
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
                    height: 44
                    icon: Icons.nightLight
                    title: "Night Light"
                    subtitle: NightLightService.active ? "On" : "Off"
                    active: NightLightService.active
                    onClicked: NightLightService.toggle()
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    icon: Notifications.silent ? Icons.bellZ : Icons.bell
                    title: "Do Not Disturb"
                    subtitle: Notifications.silent ? "On" : "Off"
                    active: Notifications.silent
                    onClicked: Notifications.silent = !Notifications.silent
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    icon: Icons.globe
                    title: "Airplane Mode"
                    subtitle: root.airplaneMode ? "On" : "Off"
                    active: root.airplaneMode
                    onClicked: airplaneCommand.running = true
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    icon: Icons.caffeine
                    title: "Power Saver"
                    subtitle: root.powerSaver ? "On" : "Off"
                    active: root.powerSaver
                    onClicked: powerProfileCommand.running = true
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
                    icon: Config.theme.lightMode ? Icons.sun : Icons.moon
                    title: "Dark Theme"
                    subtitle: Config.theme.lightMode ? "Off" : "On"
                    active: !Config.theme.lightMode
                    onClicked: root.setDarkTheme(Config.theme.lightMode)
                }

                MiniToggle {
                    width: (parent.width - parent.spacing) / 2
                    height: 44
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

        Item {
            width: parent.width - root.controlsWidth - 1 - parent.spacing * 2
            height: parent.height

            Column {
                id: notificationsPane
                width: parent.width
                height: parent.height
                spacing: 10
                visible: root.sideMode === "notifications"
                enabled: visible
                opacity: visible ? 1 : 0

                Row {
                    width: parent.width
                    height: 30

                    Text {
                        width: parent.width - 66
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Notifications"
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        font.weight: Font.Bold
                    }

                    MiniIconButton {
                        icon: Notifications.silent ? Icons.bellZ : Icons.bell
                        onClicked: Notifications.silent = !Notifications.silent
                    }

                    MiniIconButton {
                        icon: Icons.trash
                        onClicked: Notifications.discardAllNotifications()
                    }
                }

                StyledRect {
                    width: parent.width
                    height: 44
                    variant: "pane"
                    radius: Styling.radius(10)

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ProductivityService.openApp()
                    }

                    Row {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            width: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.notepad
                            font.family: Icons.font
                            font.pixelSize: 16
                            color: ProductivityService.running ? Colors.primary : Colors.overBackground
                        }

                        Column {
                            width: parent.width - 20 - githubButton.width - exportButton.width - parent.spacing * 3
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                width: parent.width
                                text: "Super Productivity"
                                color: Colors.overBackground
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-3)
                                font.weight: Font.Bold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: ProductivityService.githubStatusText + " · " + ProductivityService.lastExportStatus
                                color: Colors.overSurfaceVariant
                                font.family: Config.theme.font
                                font.pixelSize: Styling.fontSize(-5)
                                elide: Text.ElideRight
                            }
                        }

                        MiniIconButton {
                            id: githubButton
                            icon: ProductivityService.githubConnected ? Icons.link : Icons.globe
                            onClicked: ProductivityService.openGithubSetup()
                        }

                        MiniIconButton {
                            id: exportButton
                            icon: ProductivityService.exporting ? Icons.sync : Icons.copy
                            onClicked: ProductivityService.exportNotes()
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 138

                    ListView {
                        id: notificationList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: Notifications.list

                        delegate: NotificationRow {
                            required property var modelData
                            width: notificationList.width
                            notification: modelData
                        }
                    }

                    EmptyState {
                        anchors.fill: parent
                        visible: Notifications.list.length === 0
                        icon: Icons.bell
                        title: "No notifications"
                        subtitle: "Fresh and quiet."
                    }
                }

                QuickFooter {
                    width: parent.width
                    title: Notifications.silent ? "Do Not Disturb is on" : "Notification Settings"
                    onClicked: Notifications.silent = !Notifications.silent
                }
            }

            Column {
                id: wifiPane
                width: parent.width
                height: parent.height
                spacing: 10
                visible: root.sideMode === "wifi"
                enabled: visible
                opacity: visible ? 1 : 0

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
                        icon: NetworkService.wifiScanning ? Icons.sync : Icons.arrowCounterClockwise
                        onClicked: NetworkService.rescanWifi()
                    }

                    MiniIconButton {
                        icon: Icons.faders
                        onClicked: Quickshell.execDetached(["nm-connection-editor"])
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 84

                    ListView {
                        id: wifiList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: NetworkService.friendlyWifiNetworks

                        delegate: WifiRow {
                            required property var modelData
                            width: wifiList.width
                            network: modelData
                        }
                    }

                    EmptyState {
                        anchors.fill: parent
                        visible: NetworkService.friendlyWifiNetworks.length === 0
                        icon: NetworkService.wifiEnabled ? Icons.wifiNone : Icons.wifiOff
                        title: NetworkService.wifiEnabled ? "No networks found" : "Wi-Fi is off"
                        subtitle: NetworkService.wifiScanning ? "Scanning..." : "Use the toggle to enable Wi-Fi."
                    }
                }

                QuickFooter {
                    width: parent.width
                    title: "Network Settings"
                    onClicked: Quickshell.execDetached(["nm-connection-editor"])
                }
            }

            Column {
                id: bluetoothPane
                width: parent.width
                height: parent.height
                spacing: 10
                visible: root.sideMode === "bluetooth"
                enabled: visible
                opacity: visible ? 1 : 0

                Row {
                    width: parent.width
                    height: 30

                    Text {
                        width: parent.width - 66
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Bluetooth"
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(0)
                        font.weight: Font.Bold
                    }

                    MiniIconButton {
                        icon: BluetoothService.discovering ? Icons.sync : Icons.arrowCounterClockwise
                        onClicked: BluetoothService.enabled ? BluetoothService.startDiscovery() : BluetoothService.setEnabled(true)
                    }

                    MiniIconButton {
                        icon: Icons.faders
                        onClicked: Quickshell.execDetached(["blueman-manager"])
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 84

                    ListView {
                        id: bluetoothList
                        anchors.fill: parent
                        clip: true
                        spacing: 6
                        model: BluetoothService.friendlyDeviceList

                        delegate: BluetoothRow {
                            required property var modelData
                            width: bluetoothList.width
                            device: modelData
                        }
                    }

                    EmptyState {
                        anchors.fill: parent
                        visible: BluetoothService.friendlyDeviceList.length === 0
                        icon: BluetoothService.enabled ? Icons.bluetooth : Icons.bluetoothOff
                        title: BluetoothService.enabled ? "No devices found" : "Bluetooth is off"
                        subtitle: BluetoothService.enabled ? "Scan to discover nearby devices." : "Turn it on to scan."
                    }
                }

                QuickFooter {
                    width: parent.width
                    title: BluetoothService.discovering ? "Scanning nearby devices" : "Bluetooth Settings"
                    onClicked: BluetoothService.enabled ? BluetoothService.startDiscovery() : BluetoothService.setEnabled(true)
                }
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
        readonly property bool hovered: tileBodyMouse.containsMouse || arrowMouse.containsMouse
        signal clicked
        signal arrowClicked

        height: 54
        variant: active || hovered ? "primary" : "common"
        radius: Styling.radius(10)

        MouseArea {
            id: tileBodyMouse
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.rightMargin: tile.arrow ? 34 : 0
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: tile.clicked()
        }

        MouseArea {
            id: arrowMouse
            visible: tile.arrow
            enabled: tile.arrow
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 34
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            z: 3
            onClicked: tile.arrowClicked()
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
                color: tile.active || tile.hovered ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - 31 - (tile.arrow ? 24 : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: tile.title
                    color: tile.active || tile.hovered ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: tile.subtitle
                    color: tile.active || tile.hovered ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    elide: Text.ElideRight
                }
            }

            Text {
                visible: tile.arrow
                width: 15
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.caretRight
                font.family: Icons.font
                font.pixelSize: 15
                horizontalAlignment: Text.AlignRight
                color: tile.active || tile.hovered ? Styling.srItem("primary") : Colors.overSurfaceVariant
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

        height: 48
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

        height: 44
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
                    font.pixelSize: Styling.fontSize(-5)
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

    component EmptyState: Item {
        id: empty

        property string icon: ""
        property string title: ""
        property string subtitle: ""

        visible: false

        Column {
            anchors.centerIn: parent
            width: parent.width
            spacing: 8

            Text {
                width: parent.width
                text: empty.icon
                color: Colors.overSurfaceVariant
                font.family: Icons.font
                font.pixelSize: 26
                horizontalAlignment: Text.AlignHCenter
                opacity: 0.72
            }

            Text {
                width: parent.width
                text: empty.title
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                font.weight: Font.Bold
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                width: parent.width
                text: empty.subtitle
                color: Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-4)
                horizontalAlignment: Text.AlignHCenter
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

    component NotificationRow: StyledRect {
        id: row

        required property var notification

        height: 56
        variant: rowMouse.containsMouse ? "focus" : "pane"
        radius: Styling.radius(9)

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Notifications.discardNotification(row.notification.id)
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 9

            StyledRect {
                width: 32
                height: 32
                anchors.verticalCenter: parent.verticalCenter
                radius: Styling.radius(8)
                variant: row.notification.urgency === "critical" ? "error" : "common"

                Text {
                    anchors.centerIn: parent
                    text: row.notification.urgency === "critical" ? Icons.alert : Icons.bell
                    color: row.notification.urgency === "critical" ? Styling.srItem("error") : Colors.primary
                    font.family: Icons.font
                    font.pixelSize: 15
                }
            }

            Column {
                width: parent.width - 78
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Row {
                    width: parent.width
                    spacing: 6

                    Text {
                        width: parent.width - notifTime.width - parent.spacing
                        text: (row.notification.appName || "Notification") + (row.notification.summary ? " - " + row.notification.summary : "")
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-3)
                        font.weight: Font.Bold
                        elide: Text.ElideRight
                    }

                    Text {
                        id: notifTime
                        width: 34
                        text: root.notificationTime(row.notification)
                        color: Colors.overSurfaceVariant
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-5)
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Text {
                    width: parent.width
                    text: row.notification.body || ""
                    color: Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-5)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            Text {
                width: 14
                anchors.verticalCenter: parent.verticalCenter
                text: Icons.cancel
                color: rowMouse.containsMouse ? Colors.primary : Colors.overSurfaceVariant
                font.family: Icons.font
                font.pixelSize: 12
            }
        }
    }

    component BluetoothRow: StyledRect {
        id: row

        required property var device

        height: 46
        variant: (device && device.connected) || rowMouse.containsMouse ? "primary" : "pane"
        radius: Styling.radius(9)

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!row.device)
                    return;
                if (row.device.connected)
                    BluetoothService.disconnectDevice(row.device.address);
                else
                    BluetoothService.connectDevice(row.device.address);
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
                text: row.device && row.device.connected ? Icons.bluetoothConnected : Icons.bluetooth
                font.family: Icons.font
                font.pixelSize: 14
                color: row.device && (row.device.connected || rowMouse.containsMouse) ? Styling.srItem("primary") : Colors.overBackground
            }

            Column {
                width: parent.width - 64
                anchors.verticalCenter: parent.verticalCenter
                spacing: 1

                Text {
                    width: parent.width
                    text: row.device && row.device.name ? row.device.name : "Bluetooth device"
                    color: row.device && (row.device.connected || rowMouse.containsMouse) ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
                    font.weight: row.device && row.device.connected ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: row.device && row.device.connected ? "Connected" : (row.device && row.device.paired ? "Paired" : "Available")
                    color: row.device && (row.device.connected || rowMouse.containsMouse) ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-5)
                    elide: Text.ElideRight
                }
            }

            Text {
                width: 30
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                text: row.device && row.device.batteryAvailable ? row.device.battery + "%" : (row.device && row.device.connected ? Icons.accept : Icons.caretRight)
                color: row.device && (row.device.connected || rowMouse.containsMouse) ? Styling.srItem("primary") : Colors.overSurfaceVariant
                font.family: row.device && row.device.batteryAvailable ? Config.theme.font : Icons.font
                font.pixelSize: Styling.fontSize(-4)
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
