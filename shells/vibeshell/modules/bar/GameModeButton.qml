import QtQuick
import QtQuick.Layouts
import qs.config
import qs.modules.components
import qs.modules.services
import qs.modules.theme

Item {
    id: root

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    implicitWidth: 36
    implicitHeight: 36

    Rectangle {
        anchors.centerIn: parent
        width: 34
        height: 34
        radius: 17
        color: Colors.primary
        opacity: GameModeService.toggled ? 0.35 : 0
        visible: opacity > 0

        Behavior on opacity {
            enabled: Config.animDuration > 0
            NumberAnimation {
                duration: Config.animDuration
            }
        }
    }

    ToggleButton {
        anchors.fill: parent
        buttonIcon: Icons.gameMode
        tooltipText: GameModeService.toggled ? "Game mode on - click to restore VibeShell" : "Game mode"
        enableShadow: true

        onToggle: function () {
            GameModeService.toggle();
        }
    }
}
