import QtQuick
import qs.modules.components
import qs.modules.theme
import qs.config

StyledRect {
    id: root

    property var controller
    property int direction: 1
    readonly property bool available: controller && (direction < 0 ? controller.currentPage > 0 : controller.currentPage < 2)

    signal clicked

    width: 34
    height: 34
    radius: Styling.radius(8)
    variant: arrowMouse.containsMouse && available ? "primary" : "common"
    opacity: available ? 1 : 0.36

    Behavior on opacity {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Text {
        anchors.centerIn: parent
        text: root.direction < 0 ? Icons.caretLeft : Icons.caretRight
        font.family: Icons.font
        font.pixelSize: 17
        color: arrowMouse.containsMouse && root.available ? Styling.srItem("primary") : Colors.overBackground
    }

    MouseArea {
        id: arrowMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.available
        cursorShape: root.available ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.direction < 0)
                root.controller.previousPage();
            else
                root.controller.nextPage();
            root.clicked();
        }
    }
}
