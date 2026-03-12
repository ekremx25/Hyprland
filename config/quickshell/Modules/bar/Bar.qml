import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "."

import "Launcher"
import "./Workspaces"
import "./Tray"
import "./SysInfo"
import "./Volume"
import "./power"
import "./Calendar"
import "./Notepad"
import "./Weather"
import "./Notifications"
import "./Clipboard"
import "./Settings"
import "./Equalizer"

import "./Group"
import "./System" as Sys
import "../../Widgets"
import "../../Services" as S

Variants {
    id: root
    model: S.ScreenManager.getFilteredScreens("bar")
    BarBackend { id: backend }
    property var barLayout: ({
        left: ["Launcher", "Calendar"],
        center: ["Workspaces", "Notifications"],
        right: ["Clipboard", "Weather", "Volume", "Tray", "Power"],
        workspaces: {
            format: "arabic",
            style: "fill",
            transparent: false
        }
    })
    property string barPosition: "top"
    property bool isVertical: false
    property var workspacesConfig: ({ format: "arabic", style: "fill", transparent: false })

    function syncFromBackend() {
        root.barLayout = backend.barLayout;
        root.barPosition = backend.barPosition;
        root.isVertical = backend.isVertical;
        root.workspacesConfig = backend.workspacesConfig;
    }

    Connections {
        target: backend
        function onBarLayoutChanged() { root.syncFromBackend(); }
        function onBarPositionChanged() { root.syncFromBackend(); }
        function onIsVerticalChanged() { root.syncFromBackend(); }
        function onWorkspacesConfigChanged() { root.syncFromBackend(); }
    }


    // Module component map (excluding Launcher)
    property var moduleMap: ({
        "Calendar": calendarComp,
        "Notepad": notepadComp,
        "Notifications": notificationsComp,
        "Weather": weatherComp,
        "Volume": volumeComp,
        "Equalizer": equalizerComp,
        "Tray": trayComp,
        "Clipboard": clipboardComp,
        "Power": powerComp,

        "PowerGroup": powerGroupComp,
        "SysInfoGroup": sysInfoGroupComp,
        "RamModule": ramModuleComp,
        "RAM": ramComp
    })

    Component { id: calendarComp; Calendar {} }
    Component { id: notepadComp; Notepad {} }
    Component { id: notificationsComp; Notifications {} }
    Component { id: weatherComp; Weather {} }
    Component { id: volumeComp; Volume {} }
    Component { id: equalizerComp; Equalizer {} }
    Component { id: trayComp; Tray {} }
    Component { id: clipboardComp; Clipboard {} }
    Component { id: powerComp; Power {} }

    Component { id: powerGroupComp; PowerGroup {} }
    Component { id: sysInfoGroupComp; SysInfoGroup {} }
    Component { id: ramModuleComp; RamModule {} }
    Component { id: ramComp; RamModule {} }

    Item {
        id: screenItem
        required property var modelData

        property bool showWorkspaces: {
            var prefs = S.ScreenManager.screenPreferences["workspaces"];
            if (!prefs || !Array.isArray(prefs) || prefs.length === 0 || prefs.indexOf("all") !== -1) {
                return true;
            }
            if (prefs.indexOf("none") !== -1 || prefs[0] === "none") {
                return false;
            }
            return prefs.indexOf(modelData.name) !== -1;
        }

        Component { id: workspacesComp; Workspaces { monitorName: modelData.name; config: root.workspacesConfig } }

        PanelWindow {
            id: barWindow
            screen: modelData

            // Dinamik anchor'lar pozisyona göre
            anchors {
                left:   root.barPosition !== "right"
                right:  root.barPosition !== "left"
                top:    root.barPosition !== "bottom"
                bottom: root.barPosition !== "top"
            }
            color: "transparent"
            property real barSize: 52

            // Yatay modda height, dikey modda width ayarla
            implicitHeight: root.isVertical ? -1 : barSize
            implicitWidth:  root.isVertical ? barSize : -1
            exclusiveZone: barSize
            WlrLayershell.layer: WlrLayer.Top

            // Settings Popup
                Settings {
                    id: settingsMenu
                    screen: modelData
                    onConfigSaved: (newConfig) => {
                        root.barLayout = newConfig;
                        root.workspacesConfig = newConfig.workspaces || { format: "arabic", style: "fill", transparent: false };
                        if (newConfig.barPosition) root.barPosition = newConfig.barPosition;
                        root.isVertical = root.barPosition === "left" || root.barPosition === "right";
                    }
                }




            // Launcher Component — signal connection
            Component {
                id: launcherComp
                Launcher {
                    logo: root.barLayout.launcherLogo || ""
                    Component.onCompleted: {
                        settingsRequested.connect(function() {
                            settingsMenu.visible = !settingsMenu.visible;
                        });
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"

                // === YATAY MOD (top/bottom) ===
                // --- LEFT ---
                RowLayout {
                    visible: !root.isVertical
                    anchors { left: parent.left; leftMargin: 15; verticalCenter: parent.verticalCenter }
                    spacing: 18
                    Repeater {
                        model: root.barLayout.left
                        Loader {
                            active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                            sourceComponent: {
                                if (modelData === "Launcher") return launcherComp;
                                if (modelData === "Workspaces") return workspacesComp;
                                return root.moduleMap[modelData] || null;
                            }
                        }
                    }
                }

                // --- CENTER ---
                RowLayout {
                    visible: !root.isVertical
                    anchors.centerIn: parent
                    Repeater {
                        model: root.barLayout.center
                        Loader {
                            active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                            sourceComponent: {
                                if (modelData === "Launcher") return launcherComp;
                                if (modelData === "Workspaces") return workspacesComp;
                                return root.moduleMap[modelData] || null;
                            }
                        }
                    }
                }

                // --- RIGHT ---
                RowLayout {
                    visible: !root.isVertical
                    anchors { right: parent.right; rightMargin: 15; verticalCenter: parent.verticalCenter }
                    spacing: 15
                    Repeater {
                        model: root.barLayout.right
                        Loader {
                            active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                            sourceComponent: {
                                if (modelData === "Launcher") return launcherComp;
                                if (modelData === "Workspaces") return workspacesComp;
                                return root.moduleMap[modelData] || null;
                            }
                        }
                    }
                }

                // === DİKEY MOD (left/right) ===
                // --- TOP (= left modules) ---
                ColumnLayout {
                    visible: root.isVertical
                    anchors { top: parent.top; topMargin: 10; horizontalCenter: parent.horizontalCenter }
                    spacing: 6
                    Repeater {
                        model: root.barLayout.left
                        Item {
                            Layout.preferredWidth: vLeftLoader.item ? vLeftLoader.item.height + 4 : barWindow.barSize - 8
                            Layout.preferredHeight: vLeftLoader.item ? vLeftLoader.item.width + 4 : 40
                            Layout.alignment: Qt.AlignHCenter
                            Loader {
                                id: vLeftLoader
                                active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                                sourceComponent: {
                                    if (modelData === "Launcher") return launcherComp;
                                    if (modelData === "Workspaces") return workspacesComp;
                                    return root.moduleMap[modelData] || null;
                                }
                                anchors.centerIn: parent
                                rotation: -90
                            }
                        }
                    }
                }

                // --- CENTER ---
                ColumnLayout {
                    visible: root.isVertical
                    anchors.centerIn: parent
                    spacing: 6
                    Repeater {
                        model: root.barLayout.center
                        Item {
                            Layout.preferredWidth: vCenterLoader.item ? vCenterLoader.item.height + 4 : barWindow.barSize - 8
                            Layout.preferredHeight: vCenterLoader.item ? vCenterLoader.item.width + 4 : 40
                            Layout.alignment: Qt.AlignHCenter
                            Loader {
                                id: vCenterLoader
                                active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                                sourceComponent: {
                                    if (modelData === "Launcher") return launcherComp;
                                    if (modelData === "Workspaces") return workspacesComp;
                                    return root.moduleMap[modelData] || null;
                                }
                                anchors.centerIn: parent
                                rotation: -90
                            }
                        }
                    }
                }

                // --- BOTTOM (= right modules) ---
                ColumnLayout {
                    visible: root.isVertical
                    anchors { bottom: parent.bottom; bottomMargin: 10; horizontalCenter: parent.horizontalCenter }
                    spacing: 6
                    Repeater {
                        model: root.barLayout.right
                        Item {
                            Layout.preferredWidth: vRightLoader.item ? vRightLoader.item.height + 4 : barWindow.barSize - 8
                            Layout.preferredHeight: vRightLoader.item ? vRightLoader.item.width + 4 : 40
                            Layout.alignment: Qt.AlignHCenter
                            Loader {
                                id: vRightLoader
                                active: (modelData === "Workspaces") ? screenItem.showWorkspaces : true
                                sourceComponent: {
                                    if (modelData === "Launcher") return launcherComp;
                                    if (modelData === "Workspaces") return workspacesComp;
                                    return root.moduleMap[modelData] || null;
                                }
                                anchors.centerIn: parent
                                rotation: -90
                            }
                        }
                    }

                }
            }
        }
    }
}
