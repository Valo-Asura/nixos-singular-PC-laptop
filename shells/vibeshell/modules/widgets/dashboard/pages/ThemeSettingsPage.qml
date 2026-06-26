import QtQuick
import Quickshell.Io
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    property string gtkStatus: "GTK: checking"
    property string qtStatus: "Qt: config generated"

    Component.onCompleted: gtkThemeQuery.running = true

    Process {
        id: gtkThemeQuery
        running: false
        command: ["bash", "-lc", "gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d \"'\" || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                root.gtkStatus = value.length > 0 ? ("GTK: " + value) : "GTK: unavailable";
            }
        }
    }

    Flickable {
        anchors.fill: parent
        clip: true
        contentHeight: content.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            width: parent.width
            spacing: 12

            SectionTitle { text: "Theme & Appearance" }

            SettingBlock {
                title: "Theme mode"
                subtitle: "Dark, light, or time-based auto"

                ChoicePills {
                    width: parent.width
                    options: [
                        { id: "dark", label: "Dark" },
                        { id: "light", label: "Light" },
                        { id: "auto", label: "Auto" }
                    ]
                    currentValue: Config.theme.themeMode || (Config.theme.lightMode ? "light" : "dark")
                    onChosen: value => AppearanceService.applyThemeMode(value)
                }
            }

            SettingBlock {
                title: "Preset theme"
                subtitle: "Bundled colors, OLED, Catppuccin, Rose Pine"

                ChoicePills {
                    width: parent.width
                    options: AppearanceService.colorSchemes
                    currentValue: Config.theme.colorScheme || "Cherry Blossom"
                    onChosen: value => AppearanceService.applyColorScheme(value)
                }
            }

            SettingBlock {
                title: "Accent color"
                subtitle: "Shared active accent"

                Flow {
                    width: parent.width
                    spacing: 8

                    Repeater {
                        model: AppearanceService.accentPresets

                        StyledRect {
                            id: accentPill
                            required property var modelData

                            width: 56
                            height: 34
                            radius: Styling.radius(8)
                            variant: active ? "primary" : (accentMouse.containsMouse ? "focus" : "common")
                            readonly property bool active: Config.theme.accentPreset === modelData.id

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 8
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                color: accentPill.modelData.hex
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 31
                                anchors.verticalCenter: parent.verticalCenter
                                text: accentPill.active ? Icons.accept : ""
                                font.family: Icons.font
                                font.pixelSize: 13
                                color: accentPill.active ? Styling.srItem("primary") : Colors.overBackground
                            }

                            MouseArea {
                                id: accentMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: AppearanceService.applyAccent(accentPill.modelData.id)
                            }
                        }
                    }
                }
            }

            SettingButton {
                title: "Wallpaper selector"
                subtitle: "Open skwd-wall"
                icon: Icons.image
                onClicked: AppearanceService.openWallpaperSelector()
            }

            ToggleRow {
                title: "Use wallpaper colors"
                subtitle: Config.theme.useWallpaperColors ? "Matugen colors active" : "Preset colors active"
                checked: Config.theme.useWallpaperColors
                onToggled: value => AppearanceService.setWallpaperColorsEnabled(value)
            }

            SettingSlider {
                title: "Blur intensity"
                valueText: String(Config.hyprland.blurSize)
                from: 0
                to: 12
                step: 1
                value: Config.hyprland.blurSize
                onChanged: value => {
                    Config.hyprland.blurSize = Math.round(value);
                    Config.saveHyprland();
                }
            }

            SettingSlider {
                title: "Border opacity"
                valueText: Math.round((Config.theme.borderOpacity ?? 1) * 100) + "%"
                from: 0
                to: 1
                step: 0.05
                value: Config.theme.borderOpacity ?? 1
                onChanged: value => {
                    Config.theme.borderOpacity = value;
                    Config.saveTheme();
                }
            }

            SettingSlider {
                title: "Corner radius"
                valueText: String(Config.theme.roundness)
                from: 0
                to: 36
                step: 1
                value: Config.theme.roundness
                onChanged: value => {
                    Config.theme.roundness = Math.round(value);
                    Config.saveTheme();
                }
            }

            SettingSlider {
                title: "Animation speed"
                valueText: Config.theme.animDuration + " ms"
                from: 0
                to: 500
                step: 25
                value: Config.theme.animDuration
                onChanged: value => {
                    Config.theme.animDuration = Math.round(value);
                    Config.saveTheme();
                }
            }

            SettingSlider {
                title: "Font size"
                valueText: String(Config.theme.fontSize)
                from: 10
                to: 20
                step: 1
                value: Config.theme.fontSize
                onChanged: value => {
                    Config.theme.fontSize = Math.round(value);
                    Config.saveTheme();
                }
            }

            SettingBlock {
                title: "Icon theme"
                subtitle: Config.theme.iconTheme || "Papirus-Dark"

                ChoicePills {
                    width: parent.width
                    options: AppearanceService.iconThemes
                    currentValue: Config.theme.iconTheme || "Papirus-Dark"
                    onChosen: value => AppearanceService.applyIconTheme(value)
                }
            }

            SettingBlock {
                title: "Toolkit theme status"
                subtitle: root.gtkStatus + "  -  " + root.qtStatus
            }

            Row {
                width: parent.width
                spacing: 8

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    title: "Apply / Reload Shell"
                    icon: Icons.sync
                    onClicked: AppearanceService.reloadShell()
                }

                ActionButton {
                    width: (parent.width - parent.spacing) / 2
                    title: "Reset Theme"
                    icon: Icons.arrowCounterClockwise
                    onClicked: AppearanceService.resetTheme()
                }
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

    component SettingButton: StyledRect {
        id: button

        property string title: ""
        property string subtitle: ""
        property string icon: ""
        signal clicked

        width: parent ? parent.width : 0
        height: 56
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
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                width: 24
                anchors.verticalCenter: parent.verticalCenter
                text: button.icon
                color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                font.family: Icons.font
                font.pixelSize: 18
            }

            Column {
                width: parent.width - 48
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: button.title
                    color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-2)
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: button.subtitle
                    color: buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overSurfaceVariant
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ActionButton: SettingButton {
        height: 42
    }
}
