import QtQuick
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 12

            SectionTitle { text: "Notch, Bar & Shell" }

            ToggleRow {
                title: "Notch"
                subtitle: Config.notch.enabled ? "Enabled" : "Disabled"
                checked: Config.notch.enabled
                onToggled: value => {
                    Config.notch.enabled = value;
                    Config.saveNotch();
                }
            }

            SettingBlock {
                title: "Notch position"
                subtitle: Config.notch.position || "top-center"

                ChoicePills {
                    width: parent.width
                    options: [
                        { id: "top-center", label: "Center" },
                        { id: "top-left", label: "Left" },
                        { id: "top-right", label: "Right" }
                    ]
                    currentValue: Config.notch.position || "top-center"
                    onChosen: value => {
                        Config.notch.position = value;
                        Config.saveNotch();
                    }
                }
            }

            SettingSlider {
                title: "Notch width"
                valueText: Config.notch.width + " px"
                from: 120
                to: 360
                step: 4
                value: Config.notch.width
                onChanged: value => {
                    Config.notch.width = Math.round(value);
                    Config.saveNotch();
                }
            }

            SettingSlider {
                title: "Notch height"
                valueText: Config.notch.height + " px"
                from: 24
                to: 72
                step: 2
                value: Config.notch.height
                onChanged: value => {
                    Config.notch.height = Math.round(value);
                    Config.saveNotch();
                }
            }

            SettingSlider {
                title: "Bar height"
                valueText: Config.bar.height + " px"
                from: 24
                to: 80
                step: 2
                value: Config.bar.height
                onChanged: value => {
                    Config.bar.height = Math.round(value);
                    Config.saveBar();
                }
            }

            SettingSlider {
                title: "Bar opacity"
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

            SettingBlock {
                title: "Workspace indicator"
                subtitle: Config.workspaces.indicatorStyle || "pills"

                ChoicePills {
                    width: parent.width
                    options: ["numbers", "dots", "pills", "icons"]
                    currentValue: Config.workspaces.indicatorStyle || "pills"
                    onChosen: value => {
                        Config.workspaces.indicatorStyle = value;
                        Config.workspaces.alwaysShowNumbers = value === "numbers";
                        Config.workspaces.showNumbers = value === "numbers";
                        Config.workspaces.showAppIcons = value === "icons";
                        Config.saveWorkspaces();
                    }
                }
            }

            SettingBlock {
                title: "Clock format"
                subtitle: Config.bar.clockFormat || "12h"

                ChoicePills {
                    width: parent.width
                    options: ["12h", "24h"]
                    currentValue: Config.bar.clockFormat || "12h"
                    onChosen: value => {
                        Config.bar.clockFormat = value;
                        Config.saveBar();
                    }
                }
            }

            SettingBlock {
                title: "Show modules"
                subtitle: "Battery, network, tray, Bluetooth, volume, brightness, power"

                Grid {
                    width: parent.width
                    columns: 2
                    spacing: 8

                    ModuleToggle { label: "Battery"; checked: Config.bar.showBatteryModule; onToggled: v => { Config.bar.showBatteryModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Network"; checked: Config.bar.showNetworkModule; onToggled: v => { Config.bar.showNetworkModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Tray"; checked: Config.bar.showTrayModule; onToggled: v => { Config.bar.showTrayModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Bluetooth"; checked: Config.bar.showBluetoothModule; onToggled: v => { Config.bar.showBluetoothModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Volume"; checked: Config.bar.showVolumeModule; onToggled: v => { Config.bar.showVolumeModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Brightness"; checked: Config.bar.showBrightnessModule; onToggled: v => { Config.bar.showBrightnessModule = v; Config.saveBar(); } }
                    ModuleToggle { label: "Power"; checked: Config.bar.showPowerModule; onToggled: v => { Config.bar.showPowerModule = v; Config.saveBar(); } }
                }
            }

            ToggleRow {
                title: "Dock / sidebar"
                subtitle: Config.dock.enabled ? "Enabled" : "Disabled"
                checked: Config.dock.enabled
                onToggled: value => {
                    Config.dock.enabled = value;
                    Config.saveDock();
                }
            }

            SettingSlider {
                title: "Panel margin"
                valueText: Config.bar.margin + " px"
                from: 0
                to: 32
                step: 1
                value: Config.bar.margin
                onChanged: value => {
                    Config.bar.margin = Math.round(value);
                    Config.saveBar();
                }
            }

            ActionButton {
                width: parent.width
                title: "Reload Quickshell"
                icon: Icons.sync
                onClicked: AppearanceService.reloadShell()
            }
        }
    }

    component SectionTitle: Text {
        width: parent ? parent.width : 0
        color: Colors.overBackground
        font.family: Config.theme.font
        font.pixelSize: Styling.fontSize(2)
        font.weight: Font.ExtraBold
    }

    component SettingBlock: StyledRect {
        id: block

        property string title: ""
        property string subtitle: ""
        default property alias blockData: blockContent.data

        width: parent ? parent.width : 0
        implicitHeight: blockContent.implicitHeight + 20
        variant: "common"
        radius: Styling.radius(10)

        Column {
            id: blockContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 10
            spacing: 8

            Text {
                width: parent.width
                text: block.title
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                visible: block.subtitle.length > 0
                text: block.subtitle
                color: Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-4)
                wrapMode: Text.Wrap
            }
        }
    }

    component ChoicePills: Flow {
        id: choices

        property var options: []
        property string currentValue: ""
        signal chosen(string value)

        spacing: 8

        Repeater {
            model: choices.options

            StyledRect {
                id: pill
                required property var modelData

                readonly property string value: typeof modelData === "object" ? modelData.id : modelData
                readonly property string label: typeof modelData === "object" ? modelData.label : modelData
                readonly property bool active: choices.currentValue === value

                width: Math.max(64, labelText.implicitWidth + 24)
                height: 32
                radius: Styling.radius(8)
                variant: active ? "primary" : (pillMouse.containsMouse ? "focus" : "pane")

                Text {
                    id: labelText
                    anchors.centerIn: parent
                    text: pill.label
                    color: pill.active ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-3)
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

    component ToggleRow: StyledRect {
        id: row

        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool value)

        width: parent ? parent.width : 0
        height: 56
        variant: rowMouse.containsMouse ? "focus" : "common"
        radius: Styling.radius(10)

        MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.toggled(!row.checked)
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: toggle.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: row.title
                color: Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.Bold
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: row.subtitle
                color: Colors.overSurfaceVariant
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-4)
                elide: Text.ElideRight
            }
        }

        StyledRect {
            id: toggle
            width: 46
            height: 26
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            radius: 13
            variant: row.checked ? "primary" : "pane"

            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: row.checked ? parent.width - width - 4 : 4
                color: row.checked ? Styling.srItem("primary") : Colors.overBackground

                Behavior on x {
                    enabled: Config.animDuration > 0
                    NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    component ModuleToggle: StyledRect {
        id: module

        property string label: ""
        property bool checked: false
        signal toggled(bool value)

        width: (parent.width - parent.spacing) / 2
        height: 34
        radius: Styling.radius(8)
        variant: checked || moduleMouse.containsMouse ? "primary" : "pane"

        Text {
            anchors.centerIn: parent
            text: module.label
            color: module.checked || moduleMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-3)
            font.weight: Font.Bold
        }

        MouseArea {
            id: moduleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: module.toggled(!module.checked)
        }
    }

    component SettingSlider: SettingBlock {
        id: sliderBlock

        property real from: 0
        property real to: 1
        property real step: 0
        property real value: 0
        property string valueText: ""
        signal changed(real value)

        subtitle: valueText

        Item {
            width: parent.width
            height: 24

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
                width: Math.max(6, parent.width * Math.max(0, Math.min(1, (sliderBlock.value - sliderBlock.from) / Math.max(0.001, sliderBlock.to - sliderBlock.from))))
                height: 6
                radius: 3
                color: Colors.primary
            }

            Rectangle {
                x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, (sliderBlock.value - sliderBlock.from) / Math.max(0.001, sliderBlock.to - sliderBlock.from))) - width / 2))
                anchors.verticalCenter: parent.verticalCenter
                width: 16
                height: 16
                radius: 8
                color: Colors.overBackground
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor

                function commit(mouseX) {
                    let ratio = Math.max(0, Math.min(1, mouseX / Math.max(1, width)));
                    let next = sliderBlock.from + ratio * (sliderBlock.to - sliderBlock.from);
                    if (sliderBlock.step > 0)
                        next = Math.round(next / sliderBlock.step) * sliderBlock.step;
                    sliderBlock.value = Math.max(sliderBlock.from, Math.min(sliderBlock.to, next));
                    sliderBlock.changed(sliderBlock.value);
                }

                onPressed: mouse => commit(mouse.x)
                onPositionChanged: mouse => { if (pressed) commit(mouse.x); }
            }
        }
    }

    component ActionButton: StyledRect {
        id: button

        property string title: ""
        property string icon: ""
        signal clicked

        height: 44
        variant: buttonMouse.containsMouse ? "primary" : "common"
        radius: Styling.radius(10)

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.clicked()
        }

        Row {
            anchors.centerIn: parent
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.icon
                font.family: Icons.font
                font.pixelSize: 16
                color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: button.title
                color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-2)
                font.weight: Font.Bold
            }
        }
    }
}
