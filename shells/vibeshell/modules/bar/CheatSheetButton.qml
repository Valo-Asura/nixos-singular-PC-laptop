import QtQuick
import QtQuick.Layouts
import qs.modules.components
import qs.modules.globals
import qs.modules.theme

Item {
    id: root

    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    implicitWidth: 36
    implicitHeight: 36

    ToggleButton {
        anchors.fill: parent
        buttonIcon: Icons.shortcut
        tooltipText: "Cheat sheet"
        enableShadow: true

        onToggle: function () {
            GlobalStates.cheatSheetVisible = !GlobalStates.cheatSheetVisible;
        }
    }
}
