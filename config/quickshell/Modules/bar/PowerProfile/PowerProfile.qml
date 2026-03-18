import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../../Widgets"

Rectangle {
    id: root

    PowerProfileService { id: powerProfileService }

    function profileInfo(name) {
        var fallback = {
            icon: "󰾅",
            label: name || "Balanced",
            color: Theme.powerProfileColor
        };

        if (!root.profileData || !name || !root.profileData[name]) return fallback;
        return root.profileData[name];
    }

    implicitWidth: layout.implicitWidth + 24
    implicitHeight: 34
    radius: 17
    color: Theme.powerProfileColor

    Behavior on color { ColorAnimation { duration: 200 } }

    property alias currentProfile: powerProfileService.currentProfile
    property alias available: powerProfileService.available
    readonly property alias profileData: powerProfileService.profileData

    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 5

        Text {
            text: root.profileInfo(root.currentProfile).icon
            font.pixelSize: 16
            font.family: "JetBrainsMono Nerd Font"
            color: "#1e1e2e"
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            profilePopup.visible = !profilePopup.visible
            if (profilePopup.visible) powerProfileService.refresh()
        }
    }

    // --- POPUP ---
    PanelWindow {
        id: profilePopup
        visible: false
        implicitWidth: 260
        implicitHeight: 220
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors { top: true; right: true }
        margins { top: 58; right: 50 }

        function repositionPopup() {
            if (!root.QsWindow || !root.QsWindow.window) return;
            var win = root.QsWindow.window;
            var isVertBar = win.height > win.width;
            var globalPos = root.mapToGlobal(0, 0);

            if (isVertBar) {
                // Bar dikey: popup sola aç
                profilePopup.anchors.top = true;
                profilePopup.anchors.right = false;
                profilePopup.anchors.left = true;
                profilePopup.margins.top = globalPos.y;
                profilePopup.margins.left = globalPos.x - profilePopup.width - 10;
                if (profilePopup.margins.left < 10) profilePopup.margins.left = 10;
            } else {
                // Bar yatay: popup alta aç
                profilePopup.anchors.top = true;
                profilePopup.anchors.left = false;
                profilePopup.anchors.right = true;
                profilePopup.margins.top = 58;
                profilePopup.margins.right = win.width - globalPos.x - root.width;
            }
        }

        Component.onCompleted: repositionPopup()
        onVisibleChanged: {
            if (visible) repositionPopup()
        }

        Rectangle {
            anchors.fill: parent
            color: Theme.background
            border.color: Theme.powerProfileColor
            border.width: 2
            radius: 12

            MouseArea { anchors.fill: parent; z: -1 }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                // Header
                Text {
                    text: "󰾅  Power Profile"
                    color: Theme.powerProfileColor
                    font.bold: true
                    font.pixelSize: 16
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.alignment: Qt.AlignHCenter
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }

                // Not available message
                Text {
                    visible: !root.available
                    text: "powerprofilesctl not found"
                    color: Theme.overlay2
                    font.pixelSize: 12
                    font.family: "JetBrainsMono Nerd Font"
                    Layout.alignment: Qt.AlignHCenter
                }

                // Profile buttons
                Repeater {
                    model: ["performance", "balanced", "power-saver"]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 42
                        radius: 10
                        visible: root.available

                        property bool isActive: root.currentProfile === modelData
                        property var pData: root.profileInfo(modelData)

                        color: isActive ? Qt.rgba(255,255,255,0.12) : (profMa.containsMouse ? Qt.rgba(255,255,255,0.05) : "transparent")
                        border.color: isActive ? pData.color : "transparent"
                        border.width: isActive ? 2 : 0

                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: pData.icon
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 18
                                color: isActive ? pData.color : Theme.text
                            }

                            Text {
                                text: pData.label
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.bold: isActive
                                color: isActive ? pData.color : Theme.text
                                Layout.fillWidth: true
                            }

                            Text {
                                visible: isActive
                                text: "✓"
                                font.pixelSize: 14
                                color: pData.color
                            }
                        }

                        MouseArea {
                            id: profMa
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: powerProfileService.setProfile(modelData)
                        }
                    }
                }
            }
        }
    }
}
