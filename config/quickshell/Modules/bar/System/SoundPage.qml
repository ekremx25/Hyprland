import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../../../Widgets"

Item {
    id: soundPage

    SoundService { id: soundService }

    PwNodeLinkTracker {
        id: appTracker
        node: soundService.defaultSink
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Başlık
        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰕾"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font"; color: Theme.primary }
            Text { text: "Sound Settings"; font.bold: true; font.pixelSize: 18; color: Theme.text }
        }

        // --- Çıkış (Hoparlör) ---
        SoundDeviceCard {
            iconText: "󰓃"
            accentColor: "#a6e3a1"
            title: soundService.sinkDisplayName
            volumePercent: soundService.sinkVolumePercent
            volumeMax: 150
            muted: soundService.sinkMuted
            mutedIconText: "󰝟"
            unmutedIconText: "󰕾"
            onToggleMute: function() { soundService.toggleSinkMute(); }
            onSetVolume: function(percent) { soundService.setSinkVolumePercent(percent); }
        }

        // --- Giriş (Mikrofon) ---
        SoundDeviceCard {
            iconText: "󰍬"
            accentColor: "#94e2d5"
            title: soundService.sourceDisplayName
            volumePercent: soundService.sourceVolumePercent
            volumeMax: 100
            muted: soundService.sourceMuted
            mutedIconText: "󰍭"
            unmutedIconText: "󰍬"
            onToggleMute: function() { soundService.toggleSourceMute(); }
            onSetVolume: function(percent) { soundService.setSourceVolumePercent(percent); }
        }

        // --- Uygulamalar ---
        Text { text: "Applications"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6

            model: appTracker.linkGroups

            delegate: Rectangle {
                required property PwLinkGroup modelData
                property var appNode: modelData.source

                PwObjectTracker { objects: [ appNode ] }

                width: ListView.view.width
                height: 50
                color: Theme.surface
                radius: 8

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: 30; height: 30; color: Qt.rgba(137/255, 180/255, 250/255, 0.1); radius: 8
                        Text { anchors.centerIn: parent; text: ""; color: Theme.primary; font.family: "JetBrainsMono Nerd Font" }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4
                        Text {
                            text: appNode.properties["application.name"] || appNode.name || "Unknown"
                            color: Theme.text; font.bold: true; font.pixelSize: 12; elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            Layout.fillWidth: true; height: 4; radius: 2; color: Qt.rgba(49/255, 50/255, 68/255, 0.8)
                            Rectangle {
                                width: parent.width * appNode.audio.volume
                                height: parent.height; radius: 2; color: Theme.primary
                            }
                            MouseArea {
                                anchors.fill: parent
                                onPressed: (mouse) => { var v = mouse.x / width; appNode.audio.volume = Math.min(Math.max(v, 0), 1); }
                                onPositionChanged: (mouse) => { if (pressed) { var v = mouse.x / width; appNode.audio.volume = Math.min(Math.max(v, 0), 1); } }
                            }
                        }
                    }

                    Text {
                        text: Math.round(appNode.audio.volume * 100) + "%"
                        color: Theme.subtext; font.pixelSize: 11
                    }
                }
            }
        }
    }
}
