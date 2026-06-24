import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.modules.theme
import qs.modules.services
import qs.modules.components
import qs.config

MouseArea {
    id: root

    required property var bar
    required property SystemTrayItem item
    property int trayItemSize: 20
    readonly property string itemIdentity: [
        item.id || "",
        item.title || "",
        item.icon || ""
    ].join(" ").toLowerCase()
    readonly property bool blockedTrayItem: itemIdentity.includes("easyeffects") || itemIdentity.includes("easy effects") || itemIdentity.includes("wwmm")

    acceptedButtons: Qt.LeftButton | Qt.RightButton
    visible: !blockedTrayItem
    enabled: !blockedTrayItem
    Layout.fillHeight: bar.orientation === "horizontal"
    Layout.preferredWidth: blockedTrayItem ? 0 : trayItemSize
    Layout.preferredHeight: blockedTrayItem ? 0 : trayItemSize
    implicitWidth: blockedTrayItem ? 0 : trayItemSize
    implicitHeight: blockedTrayItem ? 0 : trayItemSize
    
    onClicked: event => {
        switch (event.button) {
        case Qt.LeftButton:
            item.activate();
            break;
        case Qt.RightButton:
            if (item.hasMenu && Visibilities.contextMenu) {
                Visibilities.contextMenu.openMenu(item.menu);
            }
            break;
        }
        event.accepted = true;
    }

    IconImage {
        id: trayIcon
        source: {
            const iconPath = root.item.icon.toString();
            if (iconPath.includes("spotify")) {
                return Quickshell.iconPath("spotify-client");
            }
            return root.item.icon;
        }
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        smooth: true
        visible: !Config.tintIcons
    }

    Tinted {
        sourceItem: trayIcon
        anchors.fill: trayIcon
    }
}
