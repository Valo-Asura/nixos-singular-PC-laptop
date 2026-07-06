import QtQuick
import qs.config
import qs.modules.globals

Item {
    id: root

    property bool isVisible: false

    scale: isVisible ? 1.0 : 0.86
    opacity: isVisible ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on scale {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Motion.standard
            easing.type: Motion.easeStandard
        }
    }

    Behavior on opacity {
        enabled: Config.animDuration > 0
        NumberAnimation {
            duration: Math.max(120, Config.animDuration * 0.7)
            easing.type: Easing.OutQuint
        }
    }
}
