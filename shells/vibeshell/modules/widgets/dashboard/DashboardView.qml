import QtQuick
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.theme
import "components"
import "pages"

Item {
    id: root

    implicitWidth: 464
    implicitHeight: panel.implicitHeight
    focus: true

    property real morphCloseness: 1
    property string ameForm: "ring"
    property point amePoint: Qt.point(width / 2, 34)
    property real ameHeat: 0.12
    property real wheelAccumX: 0
    property real wheelAccumY: 0
    readonly property int pageCount: 3
    readonly property int transitionMs: 220

    function resetWheelAccumulation() {
        wheelAccumX = 0;
        wheelAccumY = 0;
    }

    function handleWheel(wheel) {
        const dx = wheel.pixelDelta.x !== 0 ? wheel.pixelDelta.x : wheel.angleDelta.x / 8;
        const dy = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y / 8;
        if (Math.abs(dx) < 2 && Math.abs(dy) < 2) {
            wheel.accepted = false;
            return;
        }

        if (Math.abs(dx) <= Math.abs(dy) * 1.15) {
            resetWheelAccumulation();
            wheel.accepted = false;
            return;
        }

        wheelAccumX += dx;
        wheelAccumY += dy;
        wheel.accepted = true;

        if (pageCooldown.running)
            return;

        if (Math.abs(wheelAccumX) >= 76 && Math.abs(wheelAccumX) > Math.abs(wheelAccumY) * 1.15) {
            if (wheelAccumX < 0)
                pageController.nextPage();
            else
                pageController.previousPage();
            resetWheelAccumulation();
            pageCooldown.restart();
        }
    }

    QtObject {
        id: pageController

        property int currentPage: 0
        property int previousPageIndex: 0
        property int direction: 1

        function setPage(index) {
            const next = Math.max(0, Math.min(root.pageCount - 1, index));
            if (next === currentPage)
                return;
            direction = next > currentPage ? 1 : -1;
            previousPageIndex = currentPage;
            currentPage = next;
        }

        function nextPage() {
            setPage(currentPage + 1);
        }

        function previousPage() {
            setPage(currentPage - 1);
        }
    }

    Timer {
        id: pageCooldown
        interval: 350
        repeat: false
        onTriggered: root.resetWheelAccumulation()
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            Visibilities.setActiveModule("");
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            pageController.previousPage();
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            pageController.nextPage();
            event.accepted = true;
        }
    }

    StyledRect {
        id: panel
        variant: "bg"
        width: parent.width
        implicitHeight: 574
        radius: Styling.radius(16)
        enableBorder: true

        Column {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Item {
                id: viewport
                width: parent.width
                height: parent.height - navRow.height - parent.spacing
                clip: true

                Row {
                    id: pageStrip
                    width: viewport.width * root.pageCount
                    height: viewport.height
                    x: -pageController.currentPage * viewport.width

                    Behavior on x {
                        enabled: Config.animDuration > 0
                        NumberAnimation {
                            duration: root.transitionMs
                            easing.type: Easing.OutCubic
                        }
                    }

                    Loader {
                        width: viewport.width
                        height: viewport.height
                        sourceComponent: quickControlsComponent
                        opacity: pageController.currentPage === 0 ? 1 : 0.35

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: root.transitionMs; easing.type: Easing.OutCubic }
                        }
                    }

                    Loader {
                        width: viewport.width
                        height: viewport.height
                        sourceComponent: themeSettingsComponent
                        opacity: pageController.currentPage === 1 ? 1 : 0.35

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: root.transitionMs; easing.type: Easing.OutCubic }
                        }
                    }

                    Loader {
                        width: viewport.width
                        height: viewport.height
                        sourceComponent: barSettingsComponent
                        opacity: pageController.currentPage === 2 ? 1 : 0.35

                        Behavior on opacity {
                            enabled: Config.animDuration > 0
                            NumberAnimation { duration: root.transitionMs; easing.type: Easing.OutCubic }
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    propagateComposedEvents: true
                    onWheel: wheel => root.handleWheel(wheel)
                }
            }

            Row {
                id: navRow
                width: parent.width
                height: 34

                PageArrow {
                    controller: pageController
                    direction: -1
                }

                Item {
                    width: parent.width - 68
                    height: parent.height

                    PageDots {
                        anchors.centerIn: parent
                        controller: pageController
                        pageCount: root.pageCount
                    }
                }

                PageArrow {
                    controller: pageController
                    direction: 1
                }
            }
        }
    }

    Component {
        id: quickControlsComponent
        QuickControlsPage {}
    }

    Component {
        id: themeSettingsComponent
        ThemeSettingsPage {}
    }

    Component {
        id: barSettingsComponent
        BarSettingsPage {}
    }
}
