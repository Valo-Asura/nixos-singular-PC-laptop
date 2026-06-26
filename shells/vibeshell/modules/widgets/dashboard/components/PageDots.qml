import QtQuick
import qs.modules.theme
import qs.config

Row {
    id: root

    property var controller
    property int pageCount: 3

    spacing: 7

    Repeater {
        model: root.pageCount

        Rectangle {
            id: dot
            required property int index

            width: active ? 18 : 8
            height: 8
            radius: 4
            color: active ? Colors.primary : Colors.surfaceBright
            opacity: dotMouse.containsMouse || active ? 1 : 0.62

            readonly property bool active: root.controller && root.controller.currentPage === index

            Behavior on width {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on opacity {
                enabled: Config.animDuration > 0
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                id: dotMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.controller) root.controller.setPage(dot.index)
            }
        }
    }
}
