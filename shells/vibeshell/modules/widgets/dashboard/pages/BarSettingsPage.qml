import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    function positionSegment() {
        const position = Config.notch.position || "top-center";
        if (position === "top-left")
            return "left";
        if (position === "top-right")
            return "right";
        return "center";
    }

    function setNotchPosition(value) {
        Config.notch.position = value === "left" ? "top-left" : (value === "right" ? "top-right" : "top-center");
        Config.saveNotch();
    }

    function currentNotchStyle() {
        return Config.notch.style || (Config.notch.theme === "island" ? "pill" : "default");
    }

    function setNotchStyle(value) {
        Config.notch.style = value;
        Config.notch.theme = value === "default" ? "default" : "island";
        Config.saveNotch();
    }

    function setWorkspaceStyle(value) {
        Config.workspaces.indicatorStyle = value;
        Config.workspaces.alwaysShowNumbers = value === "numbers";
        Config.workspaces.showNumbers = value === "numbers";
        Config.workspaces.showAppIcons = value === "icons";
        Config.saveWorkspaces();
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: Math.max(content.implicitHeight, height)
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 10

            TopRail {
                width: parent.width
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surfaceBright
                opacity: 0.45
            }

            Row {
                width: parent.width
                spacing: 10

                Column {
                    width: 260
                    spacing: 10

                    Text {
                        width: parent.width
                        text: "Bar & Shell Settings"
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(1)
                        font.weight: Font.ExtraBold
                    }

                    Text {
                        width: parent.width
                        text: "Customize your top bar, notch and shell experience."
                        color: Colors.overSurfaceVariant
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-5)
                        wrapMode: Text.Wrap
                    }

                    SettingsCard {
                        title: "Notch"

                        ToggleLine {
                            title: "Enable notch"
                            checked: Config.notch.enabled
                            onToggled: value => {
                                Config.notch.enabled = value;
                                Config.saveNotch();
                            }
                        }

                        Text {
                            width: parent.width
                            text: "Position"
                            color: Colors.overSurfaceVariant
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-4)
                        }

                        SegmentedChoice {
                            width: parent.width
                            options: [
                                { id: "left", label: "Left" },
                                { id: "center", label: "Center" },
                                { id: "right", label: "Right" }
                            ]
                            currentValue: root.positionSegment()
                            onChosen: value => root.setNotchPosition(value)
                        }

                        ControlSlider {
                            title: "Width"
                            valueText: Config.notch.width + "px"
                            from: 120
                            to: 520
                            step: 4
                            value: Config.notch.width
                            onChanged: value => {
                                Config.notch.width = Math.round(value);
                                Config.saveNotch();
                            }
                        }

                        ControlSlider {
                            title: "Height"
                            valueText: Config.notch.height + "px"
                            from: 24
                            to: 96
                            step: 2
                            value: Config.notch.height
                            onChanged: value => {
                                Config.notch.height = Math.round(value);
                                Config.saveNotch();
                            }
                        }
                    }

                    SettingsCard {
                        title: "Bar"

                        ControlSlider {
                            title: "Height"
                            valueText: Config.bar.height + "px"
                            from: 24
                            to: 80
                            step: 2
                            value: Config.bar.height
                            onChanged: value => {
                                Config.bar.height = Math.round(value);
                                Config.saveBar();
                            }
                        }

                        ControlSlider {
                            title: "Opacity"
                            valueText: Math.round((Config.bar.backgroundOpacity ?? 1) * 100) + "%"
                            from: 0.2
                            to: 1
                            step: 0.05
                            value: Config.bar.backgroundOpacity ?? 1
                            onChanged: value => {
                                Config.bar.backgroundOpacity = value;
                                Config.saveBar();
                            }
                        }
                    }

                    SettingsCard {
                        title: "Panel Margin"
                        subtitle: "Space between panel and screen edges"

                        ControlSlider {
                            title: ""
                            valueText: Config.bar.margin + "px"
                            from: 0
                            to: 32
                            step: 1
                            value: Config.bar.margin
                            onChanged: value => {
                                Config.bar.margin = Math.round(value);
                                Config.saveBar();
                            }
                        }
                    }
                }

                Column {
                    width: 250
                    spacing: 10

                    SettingsCard {
                        title: "Notch Style Preview"
                        subtitle: "Preview notch styles"

                        NotchStyleOption {
                            label: "Default"
                            value: "default"
                        }

                        NotchStyleOption {
                            label: "Minimal"
                            value: "minimal"
                        }

                        NotchStyleOption {
                            label: "Pill"
                            value: "pill"
                        }
                    }

                    SettingsCard {
                        title: "Bar Style Preview"
                        subtitle: "Preview bar appearances"

                        BarStyleOption {
                            label: "Transparent"
                            value: "transparent"
                        }

                        BarStyleOption {
                            label: "Solid"
                            value: "solid"
                        }
                    }

                }

                Column {
                    width: parent.width - 530
                    spacing: 10

                    SettingsCard {
                        title: "Clock"

                        FormRow {
                            title: "Time format"

                            SegmentedChoice {
                                width: 96
                                options: ["12h", "24h"]
                                currentValue: Config.bar.clockFormat || "12h"
                                onChosen: value => {
                                    Config.bar.clockFormat = value;
                                    Config.saveBar();
                                }
                            }
                        }
                    }

                    SettingsCard {
                        title: "Workspace Indicator"
                        subtitle: "Indicator style"

                        Row {
                            width: parent.width
                            spacing: 8

                            IndicatorButton {
                                style: "numbers"
                                label: "1"
                            }
                            IndicatorButton {
                                style: "dots"
                                label: ".."
                            }
                            IndicatorButton {
                                style: "pills"
                                label: "o  o"
                            }
                            IndicatorButton {
                                style: "icons"
                                label: "* *"
                            }
                        }
                    }

                    SettingsCard {
                        title: "Module Visibility"
                        subtitle: "Show or hide modules"

                        Grid {
                            width: parent.width
                            columns: 2
                            spacing: 6

                            ModuleToggle { icon: Icons.dotsNine; label: "Workspace"; checked: Config.bar.showWorkspaceModule; onToggled: v => { Config.bar.showWorkspaceModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.clock; label: "Uptime"; checked: Config.bar.showUptimeModule; onToggled: v => { Config.bar.showUptimeModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.batteryHigh; label: "Battery"; checked: Config.bar.showBatteryModule; onToggled: v => { Config.bar.showBatteryModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.bell; label: "Notices"; checked: Config.bar.showNotificationsModule; onToggled: v => { Config.bar.showNotificationsModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.wifiHigh; label: "Network"; checked: Config.bar.showNetworkModule; onToggled: v => { Config.bar.showNetworkModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.cube; label: "Tray"; checked: Config.bar.showTrayModule; onToggled: v => { Config.bar.showTrayModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.bluetooth; label: "Bluetooth"; checked: Config.bar.showBluetoothModule; onToggled: v => { Config.bar.showBluetoothModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.speakerHigh; label: "Volume"; checked: Config.bar.showVolumeModule; onToggled: v => { Config.bar.showVolumeModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.sun; label: "Brightness"; checked: Config.bar.showBrightnessModule; onToggled: v => { Config.bar.showBrightnessModule = v; Config.saveBar(); } }
                            ModuleToggle { icon: Icons.shutdown; label: "Power"; checked: Config.bar.showPowerModule; onToggled: v => { Config.bar.showPowerModule = v; Config.saveBar(); } }
                        }
                    }

                    SettingsCard {
                        title: "Shell"
                        subtitle: "Quickshell"

                        ToggleLine {
                            title: "Dock / Sidebar"
                            checked: Config.dock.enabled
                            onToggled: value => {
                                Config.dock.enabled = value;
                                Config.saveDock();
                            }
                        }

                        ActionButton {
                            width: parent.width
                            label: "Reload"
                            icon: Icons.sync
                            onClicked: AppearanceService.reloadShell()
                        }
                    }
                }
            }

            Row {
                width: parent.width
                height: 22

                Text {
                    width: parent.width / 2
                    text: "Quickshell v2.1.0"
                    color: Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-6)
                }

                Text {
                    width: parent.width / 2
                    text: "Save automatically"
                    horizontalAlignment: Text.AlignRight
                    color: Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-6)
                }
            }
        }
    }

    component TopRail: Item {
        height: 64

        Rectangle {
            width: 56
            height: 56
            radius: 28
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.color: Colors.primary
            border.width: 2

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 4
                radius: width / 2
                clip: true

                Image {
                    anchors.fill: parent
                    source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                    fillMode: Image.PreserveAspectCrop
                    smooth: true
                }
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 22

            RailButton { icon: Icons.speakerHigh }
            RailButton { icon: Icons.recordScreen }
            RailButton { icon: Icons.lock }
            RailButton { icon: Icons.gear; active: true }
            RailButton { icon: Icons.shutdown }
        }
    }

    component RailButton: StyledRect {
        id: button
        property string icon: ""
        property bool active: false
        width: 38
        height: 38
        radius: 19
        variant: active ? "primary" : "common"

        Text {
            anchors.centerIn: parent
            text: button.icon
            color: button.active ? Styling.srItem("primary") : Colors.primary
            font.family: Icons.font
            font.pixelSize: 17
        }
    }

    component SettingsCard: StyledRect {
        id: card
        property string title: ""
        property string subtitle: ""
        default property alias cardData: cardContent.data
        width: parent ? parent.width : 0
        implicitHeight: cardContent.implicitHeight + 18
        variant: "common"
        radius: Styling.radius(9)

        Column {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Text {
                width: parent.width
                text: card.title
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.ExtraBold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: card.subtitle.length > 0
                text: card.subtitle
                color: Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-5)
                wrapMode: Text.Wrap
            }
        }
    }

    component FormRow: Item {
        id: row
        property string title: ""
        default property alias rowData: rowContent.data
        width: parent ? parent.width : 0
        height: 30

        Text {
            width: 100
            anchors.verticalCenter: parent.verticalCenter
            text: row.title
            color: Colors.overSurfaceVariant
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-4)
            elide: Text.ElideRight
        }

        Row {
            id: rowContent
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component SegmentedChoice: Row {
        id: choices
        property var options: []
        property string currentValue: ""
        signal chosen(string value)
        height: 30
        spacing: 2

        Repeater {
            model: choices.options

            StyledRect {
                id: pill
                required property var modelData
                readonly property string value: typeof modelData === "object" ? modelData.id : modelData
                readonly property string label: typeof modelData === "object" ? modelData.label : modelData
                readonly property bool active: choices.currentValue === value
                width: Math.max(46, labelText.implicitWidth + 20)
                height: 28
                radius: Styling.radius(6)
                variant: active ? "primary" : (pillMouse.containsMouse ? "focus" : "pane")

                Text {
                    id: labelText
                    anchors.centerIn: parent
                    text: pill.label
                    color: pill.active ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: pillMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: choices.chosen(pill.value)
                }
            }
        }
    }

    component ToggleLine: Item {
        id: row
        property string title: ""
        property bool checked: false
        signal toggled(bool value)
        width: parent ? parent.width : 0
        height: 28

        Text {
            anchors.left: parent.left
            anchors.right: toggle.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: row.title
            color: Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-4)
            elide: Text.ElideRight
        }

        ToggleSwitch {
            id: toggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: row.checked
            onClicked: row.toggled(!row.checked)
        }
    }

    component ToggleSwitch: StyledRect {
        id: sw
        property bool checked: false
        signal clicked
        width: 34
        height: 19
        radius: 10
        variant: checked ? "primary" : "pane"

        Rectangle {
            width: 15
            height: 15
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            x: sw.checked ? parent.width - width - 2 : 2
            color: sw.checked ? Styling.srItem("primary") : Colors.overSurfaceVariant

            Behavior on x {
                enabled: Config.animDuration > 0
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: sw.clicked()
        }
    }

    component ControlSlider: Item {
        id: slider
        property string title: ""
        property string valueText: ""
        property real from: 0
        property real to: 1
        property real step: 0
        property real value: 0
        signal changed(real value)
        width: parent ? parent.width : 0
        height: 28

        Text {
            visible: slider.title.length > 0
            width: 58
            anchors.verticalCenter: parent.verticalCenter
            text: slider.title
            color: Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-4)
            font.weight: Font.Bold
            elide: Text.ElideRight
        }

        Text {
            width: 44
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            horizontalAlignment: Text.AlignRight
            text: slider.valueText
            color: Colors.overSurfaceVariant
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-5)
        }

        Item {
            anchors.left: parent.left
            anchors.leftMargin: slider.title.length > 0 ? 66 : 0
            anchors.right: parent.right
            anchors.rightMargin: 52
            anchors.verticalCenter: parent.verticalCenter
            height: 18

            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 4; radius: 2; color: Colors.surfaceBright }
            Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: Math.max(4, parent.width * Math.max(0, Math.min(1, (slider.value - slider.from) / Math.max(0.001, slider.to - slider.from)))); height: 4; radius: 2; color: Colors.primary }
            Rectangle { x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, (slider.value - slider.from) / Math.max(0.001, slider.to - slider.from))) - width / 2)); anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Colors.primary }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                function commit(mouseX) {
                    let ratio = Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
                    let next = slider.from + ratio * (slider.to - slider.from);
                    if (slider.step > 0)
                        next = Math.round(next / slider.step) * slider.step;
                    slider.value = Math.max(slider.from, Math.min(slider.to, next));
                    slider.changed(slider.value);
                }
                onPressed: mouse => commit(mouse.x)
                onPositionChanged: mouse => { if (pressed) commit(mouse.x); }
            }
        }
    }

    component NotchStyleOption: StyledRect {
        id: option
        property string label: ""
        property string value: ""
        readonly property bool active: root.currentNotchStyle() === value
        width: parent ? parent.width : 0
        height: 48
        radius: Styling.radius(8)
        variant: active ? "focus" : (optionMouse.containsMouse ? "focus" : "pane")
        enableBorder: active

        MouseArea {
            id: optionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setNotchStyle(option.value)
        }

        Rectangle {
            width: option.value === "default" ? 146 : (option.value === "minimal" ? 108 : 136)
            height: option.value === "pill" ? 18 : 16
            radius: option.value === "default" ? 4 : 9
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 10
            color: Colors.background
            opacity: 0.9

            Text {
                anchors.centerIn: parent
                text: option.value === "default" ? "ASURA - 91%" : ".  o  o"
                color: Colors.overSurfaceVariant
                font.family: Config.theme.monoFont
                font.pixelSize: Styling.fontSize(-8)
            }
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: option.label
            color: Colors.overSurfaceVariant
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-6)
        }
    }

    component BarStyleOption: StyledRect {
        id: option
        property string label: ""
        property string value: ""
        readonly property bool active: value === "transparent" ? (Config.bar.backgroundOpacity ?? 1) < 0.75 : (Config.bar.backgroundOpacity ?? 1) >= 0.75
        width: parent ? parent.width : 0
        height: 48
        radius: Styling.radius(8)
        variant: active ? "focus" : (optionMouse.containsMouse ? "focus" : "pane")
        enableBorder: active

        MouseArea {
            id: optionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                Config.bar.backgroundOpacity = option.value === "transparent" ? 0.52 : 1;
                Config.saveBar();
            }
        }

        StyledRect {
            width: 160
            height: 18
            radius: Styling.radius(7)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 9
            variant: "bg"
            opacity: option.value === "transparent" ? 0.58 : 1
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6
            text: option.label
            color: Colors.overSurfaceVariant
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-6)
        }
    }

    component IndicatorButton: StyledRect {
        id: option
        property string style: ""
        property string label: ""
        readonly property bool active: (Config.workspaces.indicatorStyle || "pills") === style
        width: (parent.width - 24) / 4
        height: 30
        radius: Styling.radius(8)
        variant: active ? "primary" : (optionMouse.containsMouse ? "focus" : "pane")

        Text {
            anchors.centerIn: parent
            text: option.label
            color: option.active ? Styling.srItem("primary") : Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-3)
            font.weight: Font.Bold
        }

        MouseArea {
            id: optionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.setWorkspaceStyle(option.style)
        }
    }

    component ModuleToggle: Item {
        id: module
        property string icon: ""
        property string label: ""
        property bool checked: false
        signal toggled(bool value)
        width: (parent.width - 6) / 2
        height: 28

        Text {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: module.icon
            color: Colors.overBackground
            font.family: Icons.font
            font.pixelSize: 13
        }

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 20
            anchors.right: toggle.left
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            text: module.label
            color: Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-5)
            elide: Text.ElideRight
        }

        ToggleSwitch {
            id: toggle
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            checked: module.checked
            onClicked: module.toggled(!module.checked)
        }
    }

    component ActionButton: StyledRect {
        id: button
        property string label: ""
        property string icon: ""
        signal clicked
        height: 34
        variant: buttonMouse.containsMouse ? "primary" : "common"
        radius: Styling.radius(7)

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text { anchors.verticalCenter: parent.verticalCenter; text: button.icon; color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.primary; font.family: Icons.font; font.pixelSize: 14 }
            Text { anchors.verticalCenter: parent.verticalCenter; text: button.label; color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-3); font.weight: Font.Bold }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }
    }
}
