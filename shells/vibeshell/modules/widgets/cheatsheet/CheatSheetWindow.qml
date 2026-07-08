pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.config
import qs.modules.components
import qs.modules.globals
import qs.modules.services
import qs.modules.theme

FloatingWindow {
    id: root

    visible: GlobalStates.cheatSheetVisible
    title: "Vibeshell Cheat Sheet"
    color: "transparent"
    minimumSize: Qt.size(900, 660)
    maximumSize: Qt.size(900, 660)

    property int currentPage: 0
    readonly property var currentItems: currentPage === 0 ? CheatSheetService.binds : CheatSheetService.aliases

    onVisibleChanged: {
        if (visible)
            CheatSheetService.refresh();
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Colors.background.r, Colors.background.g, Colors.background.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.38)
        radius: 0
        clip: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 10

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.86)
                radius: Styling.radius(0)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 8
                    spacing: 10

                    StyledRect {
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        variant: "surface"
                        radius: 17

                        Text {
                            anchors.centerIn: parent
                            text: Icons.shortcut
                            font.family: Icons.font
                            font.pixelSize: 17
                            color: Colors.overSurface
                        }
                    }

                    Text {
                        text: "Cheat Sheet"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(2)
                        font.weight: Font.Bold
                        color: Styling.srItem("overprimary")
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    RowLayout {
                        spacing: 6

                        Repeater {
                            model: [
                                { label: "Hyprland", page: 0, count: CheatSheetService.binds.length },
                                { label: "Aliases", page: 1, count: CheatSheetService.aliases.length }
                            ]

                            Button {
                                id: tabButton
                                required property var modelData
                                Layout.preferredHeight: 32
                                leftPadding: 12
                                rightPadding: 12

                                readonly property bool selected: root.currentPage === modelData.page

                                background: Rectangle {
                                    radius: Styling.radius(-4)
                                    color: tabButton.selected ? Styling.srItem("overprimary") : Colors.surfaceContainerHighest
                                    opacity: tabButton.hovered || tabButton.selected ? 1 : 0.72
                                }

                                contentItem: Text {
                                    text: tabButton.modelData.label + " " + tabButton.modelData.count
                                    font.family: Config.theme.font
                                    font.pixelSize: Styling.fontSize(-1)
                                    font.weight: Font.DemiBold
                                    color: tabButton.selected ? Colors.overPrimary : Colors.overSurface
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: root.currentPage = modelData.page
                            }
                        }
                    }

                    Button {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        background: Rectangle {
                            radius: Styling.radius(-4)
                            color: parent.hovered ? Colors.primary : "transparent"
                        }

                        contentItem: Text {
                            text: Icons.sync
                            font.family: Icons.font
                            font.pixelSize: 18
                            color: parent.hovered ? Colors.overPrimary : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: CheatSheetService.refresh()
                    }

                    Button {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32

                        background: Rectangle {
                            radius: Styling.radius(-4)
                            color: parent.hovered ? Colors.error : "transparent"
                        }

                        contentItem: Text {
                            text: Icons.cancel
                            font.family: Icons.font
                            font.pixelSize: 18
                            color: parent.hovered ? Colors.overError : Colors.overSurface
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: GlobalStates.cheatSheetVisible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                color: Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.54)
                radius: Styling.radius(-1)

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    Text {
                        text: root.currentPage === 0 ? "Binding" : "Alias"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        font.weight: Font.Bold
                        color: Colors.outline
                        Layout.preferredWidth: 230
                    }

                    Text {
                        text: root.currentPage === 0 ? "Action" : "Command"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        font.weight: Font.Bold
                        color: Colors.outline
                        Layout.fillWidth: true
                    }

                    Text {
                        visible: root.currentPage === 0
                        text: "Flags"
                        font.family: Config.theme.font
                        font.pixelSize: Styling.fontSize(-1)
                        font.weight: Font.Bold
                        color: Colors.outline
                        Layout.preferredWidth: 120
                    }
                }
            }

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: root.currentItems

                delegate: Rectangle {
                    required property var modelData
                    width: listView.width
                    height: Math.max(38, rowLayout.implicitHeight + 12)
                    color: index % 2 === 0 ? Qt.rgba(Colors.surfaceContainer.r, Colors.surfaceContainer.g, Colors.surfaceContainer.b, 0.58) : Qt.rgba(Colors.surfaceContainerHighest.r, Colors.surfaceContainerHighest.g, Colors.surfaceContainerHighest.b, 0.48)
                    radius: Styling.radius(-2)

                    RowLayout {
                        id: rowLayout
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 10

                        Text {
                            text: root.currentPage === 0 ? modelData.combo : modelData.name
                            font.family: Config.theme.monoFont
                            font.pixelSize: Styling.fontSize(-1)
                            font.weight: Font.DemiBold
                            color: Colors.overSurface
                            elide: Text.ElideRight
                            Layout.preferredWidth: 230
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            text: root.currentPage === 0 ? modelData.action : modelData.command
                            font.family: Config.theme.monoFont
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.overBackground
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                        }

                        Text {
                            visible: root.currentPage === 0
                            text: modelData.flags
                            font.family: Config.theme.font
                            font.pixelSize: Styling.fontSize(-2)
                            color: Colors.outline
                            elide: Text.ElideRight
                            Layout.preferredWidth: 120
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }
            }

            Text {
                visible: CheatSheetService.loading || CheatSheetService.lastError.length > 0 || root.currentItems.length === 0
                text: CheatSheetService.loading ? "Loading..." : (CheatSheetService.lastError.length > 0 ? CheatSheetService.lastError : "No entries")
                font.family: Config.theme.font
                font.pixelSize: Styling.fontSize(-1)
                color: CheatSheetService.lastError.length > 0 ? Colors.error : Colors.outline
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
