import QtQuick
import qs.modules.components
import qs.modules.services
import qs.config

Item {
    implicitWidth: powerMenu.implicitWidth
    implicitHeight: powerMenu.implicitHeight
    property real morphCloseness: 1
    property string morphForm: "dock"
    property point morphPoint: Qt.point(width / 2, height / 2)
    property real morphHeat: 0

    Behavior on implicitWidth {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    Behavior on implicitHeight {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Config.animDuration
            easing.type: Easing.OutQuart
        }
    }

    PowerMenu {
        id: powerMenu
        anchors.fill: parent
        
        onItemSelected: {
            Visibilities.setActiveModule("")
        }
    }
    
    // Forzar foco cuando aparece la vista en el StackView
    onVisibleChanged: {
        if (visible) {
            Qt.callLater(() => {
                powerMenu.forceActiveFocus();
            });
        }
    }
    
    Component.onCompleted: {
        if (visible) {
            Qt.callLater(() => {
                powerMenu.forceActiveFocus();
            });
        }
    }
}
