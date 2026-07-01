import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import qs.modules.theme
import qs.modules.globals
import qs.config

Button {
    id: root

    required property string buttonIcon
    required property string tooltipText
    required property var onToggle
    property bool iconTint: false
    property bool iconFullTint: false
    property int iconSize: 18
    property bool enableShadow: true

    implicitWidth: 36
    implicitHeight: 36
    clip: false

    padding: 0
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    // Check if buttonIcon is a single character (icon font) or a file path
    readonly property bool isIconPath: root.buttonIcon && root.buttonIcon.length > 1 && !root.buttonIcon.startsWith("<")

    background: StyledRect {
        variant: "bg"
        enableShadow: root.enableShadow && Config.showBackground
        Rectangle {
            anchors.fill: parent
            color: parent.item || "transparent"
            opacity: root.pressed ? 0.5 : (root.hovered ? 0.25 : 0)
            radius: parent.radius ?? 0

            Behavior on opacity {
                enabled: (Config.animDuration ?? 0) > 0
                NumberAnimation {
                    duration: (Config.animDuration ?? 0) / 2
                }
            }
        }
    }

    contentItem: Item {
        implicitWidth: root.implicitWidth
        implicitHeight: root.implicitHeight
        clip: false
        // Text icon (single character or rich text HTML tag)
        Text {
            visible: !root.isIconPath
            anchors.fill: parent
            text: root.buttonIcon
            textFormat: (root.buttonIcon && root.buttonIcon.startsWith("<")) ? Text.RichText : Text.PlainText
            font.family: Icons.font
            font.pixelSize: root.iconSize
            color: root.pressed ? (Styling.srItem("primary") || Colors.background) : (Styling.srItem("bg") || Colors.foreground)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
        }

        // Image icon (SVG/PNG)
        Image {
            id: iconImage
            visible: root.isIconPath
            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: root.isIconPath ? (root.buttonIcon.startsWith("/") ? "file://" + root.buttonIcon : root.buttonIcon) : ""
            sourceSize: Qt.size(width * 2, height * 2)
            fillMode: Image.PreserveAspectFit
            smooth: true
            asynchronous: true
            layer.enabled: root.iconTint || root.iconFullTint
            layer.effect: MultiEffect {
                brightness: root.iconFullTint ? 1.0 : 0.1
                contrast: root.iconFullTint ? 0.0 : -0.25
                colorization: root.iconFullTint ? 1.0 : 0.25
                colorizationColor: Styling.srItem("bg") || Colors.foreground
            }
        }
    }

    onClicked: root.onToggle()

    ToolTip.visible: false
    ToolTip.text: root.tooltipText
    ToolTip.delay: 1000
}
