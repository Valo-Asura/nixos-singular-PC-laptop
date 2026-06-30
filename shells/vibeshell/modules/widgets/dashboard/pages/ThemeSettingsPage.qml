import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    property string gtkStatus: "Graphite-Dark"
    property string qtStatus: "Fluent-Dark"

    Component.onCompleted: gtkThemeQuery.running = true

    Process {
        id: gtkThemeQuery
        running: false
        command: ["bash", "-lc", "printf '%s\\n' \"$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d \"'\" || true)\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim();
                if (value.length > 0)
                    root.gtkStatus = value;
            }
        }
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
                selected: "theme"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Colors.surfaceBright
                opacity: 0.45
            }

            Row {
                width: parent.width
                spacing: 12

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 10

                    Text {
                        width: parent.width
                        text: "Theme & Appearance"
                        color: Colors.overBackground
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(1)
                        font.weight: Font.ExtraBold
                    }

                    SettingsCard {
                        title: "Theme Mode"

                        SegmentedChoice {
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

                    SettingsCard {
                        title: "Accent Color"

                        Row {
                            width: parent.width
                            spacing: 13

                            Repeater {
                                model: AppearanceService.accentPresets

                                AccentDot {
                                    required property var modelData
                                    accentId: modelData.id
                                    accentColor: modelData.hex
                                }
                            }
                        }
                    }

                    SettingsCard {
                        title: "Preset Theme"

                        Flow {
                            width: parent.width
                            spacing: 8

                            Repeater {
                                model: AppearanceService.colorSchemes

                                PillButton {
                                    required property string modelData
                                    label: modelData
                                    active: Config.theme.colorScheme === modelData
                                    onClicked: AppearanceService.applyColorScheme(modelData)
                                }
                            }
                        }
                    }

                    SettingsCard {
                        title: "Wallpaper"

                        Row {
                            width: parent.width
                            spacing: 8

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                label: "Choose Wallpaper"
                                onClicked: AppearanceService.openWallpaperSelector()
                            }

                            ActionButton {
                                width: (parent.width - parent.spacing) / 2
                                primary: Config.theme.useWallpaperColors
                                label: "Apply Matugen"
                                onClicked: AppearanceService.setWallpaperColorsEnabled(true)
                            }
                        }

                        ToggleLine {
                            title: "Matugen Auto Colors"
                            subtitle: Config.theme.useWallpaperColors ? "Auto from current wallpaper" : "Use preset theme colors"
                            checked: Config.theme.useWallpaperColors
                            onToggled: value => AppearanceService.setWallpaperColorsEnabled(value)
                        }
                    }
                }

                Column {
                    width: (parent.width - parent.spacing) / 2
                    spacing: 10

                    SettingsCard {
                        title: "Visual Tuning"

                        ControlSlider {
                            title: "Blur Intensity"
                            valueText: Math.round((Config.hyprland.blurSize / 12) * 100) + "%"
                            from: 0
                            to: 12
                            step: 1
                            value: Config.hyprland.blurSize
                            onChanged: value => {
                                Config.hyprland.blurSize = Math.round(value);
                                Config.saveHyprland();
                            }
                        }

                        ControlSlider {
                            title: "Border Opacity"
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

                        ControlSlider {
                            title: "Corner Radius"
                            valueText: Config.theme.roundness + "px"
                            from: 0
                            to: 36
                            step: 1
                            value: Config.theme.roundness
                            onChanged: value => {
                                Config.theme.roundness = Math.round(value);
                                Config.saveTheme();
                            }
                        }

                        ControlSlider {
                            title: "Animation Speed"
                            valueText: (Config.theme.animDuration / 200).toFixed(2) + "x"
                            from: 0
                            to: 500
                            step: 25
                            value: Config.theme.animDuration
                            onChanged: value => {
                                Config.theme.animDuration = Math.round(value);
                                Config.saveTheme();
                            }
                        }

                        ControlSlider {
                            title: "Font Size"
                            valueText: Config.theme.fontSize + "px"
                            from: 10
                            to: 20
                            step: 1
                            value: Config.theme.fontSize
                            onChanged: value => {
                                Config.theme.fontSize = Math.round(value);
                                Config.saveTheme();
                            }
                        }
                    }

                    SettingsCard {
                        title: "Toolkit"

                        SelectCycle {
                            title: "Icon Theme"
                            value: Config.theme.iconTheme || "Papirus-Dark"
                            options: AppearanceService.iconThemes
                            onChosen: value => AppearanceService.applyIconTheme(value)
                        }

                        SelectCycle {
                            title: "GTK Theme"
                            value: root.gtkStatus + "  - Active"
                            options: [root.gtkStatus]
                            onChosen: value => {}
                        }

                        SelectCycle {
                            title: "Qt Theme"
                            value: root.qtStatus + "  - Active"
                            options: [root.qtStatus]
                            onChosen: value => {}
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 12

                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            primary: true
                            label: "Apply & Reload Shell"
                            onClicked: AppearanceService.reloadShell()
                        }

                        ActionButton {
                            width: (parent.width - parent.spacing) / 2
                            label: "Reset Theme"
                            onClicked: AppearanceService.resetTheme()
                        }
                    }
                }
            }
        }
    }

    component TopRail: Item {
        id: rail
        property string selected: "theme"
        height: 58

        Rectangle {
            width: 48
            height: 48
            radius: 24
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: "transparent"
            border.color: Colors.primary
            border.width: 2

            Image {
                anchors.fill: parent
                anchors.margins: 5
                source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                fillMode: Image.PreserveAspectCrop
                smooth: true
            }
        }

        Row {
            anchors.centerIn: parent
            spacing: 22
            RailButton { icon: Icons.speakerHigh; active: false }
            RailButton { icon: Icons.recordScreen; active: false }
            RailButton { icon: Icons.lock; active: false }
            RailButton { icon: Icons.gear; active: true }
            RailButton { icon: Icons.shutdown; active: false }
        }
    }

    component RailButton: StyledRect {
        id: button
        property string icon: ""
        property bool active: false
        width: 42
        height: 42
        radius: 21
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
        default property alias cardData: cardContent.data
        width: parent ? parent.width : 0
        implicitHeight: cardContent.implicitHeight + 22
        variant: "common"
        radius: Styling.radius(10)

        Column {
            id: cardContent
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 11
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
        }
    }

    component FormRow: Item {
        id: row
        property string title: ""
        default property alias rowData: content.data
        width: parent ? parent.width : 0
        height: Math.max(36, content.implicitHeight)

        Text {
            width: 120
            anchors.verticalCenter: parent.verticalCenter
            text: row.title
            color: Colors.overBackground
            font.family: Config.theme.font
            font.pixelSize: Styling.fontSize(-1)
            font.weight: Font.Bold
        }

        Row {
            id: content
            anchors.left: parent.left
            anchors.leftMargin: 128
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    component SegmentedChoice: Row {
        id: seg
        property var options: []
        property string currentValue: ""
        signal chosen(string value)
        height: 30
        spacing: 0

        Repeater {
            model: seg.options
            StyledRect {
                id: item
                required property var modelData
                readonly property string value: typeof modelData === "object" ? modelData.id : modelData
                readonly property string label: typeof modelData === "object" ? modelData.label : modelData
                readonly property bool active: seg.currentValue === value
                width: seg.width / Math.max(1, seg.options.length)
                height: seg.height
                radius: Styling.radius(6)
                variant: active ? "primary" : (segMouse.containsMouse ? "focus" : "pane")

                Text {
                    anchors.centerIn: parent
                    text: item.label
                    color: item.active ? Styling.srItem("primary") : Colors.overBackground
                    font.family: Config.theme.font
                    font.pixelSize: Styling.fontSize(-4)
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: segMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: seg.chosen(item.value)
                }
            }
        }
    }

    component AccentDot: Rectangle {
        id: dot
        property string accentId: ""
        property color accentColor: "white"
        readonly property bool active: Config.theme.accentPreset === accentId
        width: 26
        height: 26
        radius: 13
        color: accentColor
        border.width: active ? 2 : 0
        border.color: Colors.overBackground

        Text {
            anchors.centerIn: parent
            visible: dot.active
            text: Icons.accept
            font.family: Icons.font
            font.pixelSize: 13
            color: Colors.overBackground
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: AppearanceService.applyAccent(dot.accentId)
        }
    }

    component PillButton: StyledRect {
        id: pill
        property string label: ""
        property bool active: false
        signal clicked
        width: Math.max(64, labelText.implicitWidth + 24)
        height: 30
        radius: Styling.radius(7)
        variant: active ? "primary" : (pillMouse.containsMouse ? "focus" : "pane")
        Text { id: labelText; anchors.centerIn: parent; text: pill.label; color: pill.active ? Styling.srItem("primary") : Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-4); font.weight: Font.Bold }
        MouseArea { id: pillMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pill.clicked() }
    }

    component ToggleLine: Item {
        id: row
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal toggled(bool value)
        width: parent ? parent.width : 0
        height: 34

        Column {
            anchors.left: parent.left
            anchors.right: toggle.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1
            Text { width: parent.width; text: row.title; color: Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-2); font.weight: Font.Bold; elide: Text.ElideRight }
            Text { width: parent.width; text: row.subtitle; color: Colors.overSurfaceVariant; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-5); elide: Text.ElideRight }
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
        Rectangle { width: 15; height: 15; radius: 8; anchors.verticalCenter: parent.verticalCenter; x: sw.checked ? parent.width - width - 2 : 2; color: sw.checked ? Styling.srItem("primary") : Colors.overSurfaceVariant; Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } } }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: sw.clicked() }
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
        height: title.length > 0 ? 28 : 20

        Text { visible: slider.title.length > 0; width: 120; anchors.verticalCenter: parent.verticalCenter; text: slider.title; color: Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-2); font.weight: Font.Bold; elide: Text.ElideRight }
        Text { visible: slider.valueText.length > 0; width: 52; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; horizontalAlignment: Text.AlignRight; text: slider.valueText; color: Colors.overSurfaceVariant; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-4) }

        Item {
            id: track
            anchors.left: parent.left
            anchors.leftMargin: slider.title.length > 0 ? 128 : 0
            anchors.right: parent.right
            anchors.rightMargin: slider.valueText.length > 0 ? 62 : 0
            anchors.verticalCenter: parent.verticalCenter
            height: 18

            Rectangle { anchors.left: parent.left; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; height: 4; radius: 2; color: Colors.surfaceBright }
            Rectangle { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: Math.max(4, parent.width * Math.max(0, Math.min(1, (slider.value - slider.from) / Math.max(0.001, slider.to - slider.from)))); height: 4; radius: 2; color: Colors.primary }
            Rectangle { x: Math.max(0, Math.min(parent.width - width, parent.width * Math.max(0, Math.min(1, (slider.value - slider.from) / Math.max(0.001, slider.to - slider.from))) - width / 2)); anchors.verticalCenter: parent.verticalCenter; width: 12; height: 12; radius: 6; color: Colors.primary }

            MouseArea {
                anchors.fill: parent
                enabled: slider.enabled
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

    component SelectCycle: StyledRect {
        id: row
        property string title: ""
        property string value: ""
        property var options: []
        signal chosen(string value)
        width: parent ? parent.width : 0
        height: 34
        variant: rowMouse.containsMouse ? "focus" : "common"
        radius: Styling.radius(7)

        function chooseNext() {
            if (!options || options.length === 0)
                return;
            const current = options.indexOf(value);
            const next = options[(current + 1 + options.length) % options.length];
            chosen(next);
        }

        Text { x: 10; anchors.verticalCenter: parent.verticalCenter; width: 112; text: row.title; color: Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-3); font.weight: Font.Bold; elide: Text.ElideRight }
        Text { anchors.left: parent.left; anchors.leftMargin: 132; anchors.right: caret.left; anchors.rightMargin: 6; anchors.verticalCenter: parent.verticalCenter; text: row.value; color: Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-4); elide: Text.ElideRight }
        Text { id: caret; anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: Icons.caretDown; color: Colors.overSurfaceVariant; font.family: Icons.font; font.pixelSize: 12 }
        MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: row.chooseNext() }
    }

    component ActionButton: StyledRect {
        id: button
        property string label: ""
        property bool primary: false
        signal clicked
        height: 36
        variant: primary || buttonMouse.containsMouse ? "primary" : "common"
        radius: Styling.radius(7)
        Text { anchors.centerIn: parent; text: button.label; color: button.primary || buttonMouse.containsMouse ? Styling.srItem("primary") : Colors.overBackground; font.family: Config.theme.font; font.pixelSize: Styling.fontSize(-3); font.weight: Font.Bold }
        MouseArea { id: buttonMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: button.clicked() }
    }

}
