import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import "../../../Widgets"

ColumnLayout {
    id: diskPage
    spacing: 12
    anchors.margins: 16

    DiskService { id: diskService }

    // --- Başlık ---
    RowLayout {
        Layout.fillWidth: true
        Text {
            text: "󰋊"
            font.pixelSize: 22
            font.family: "JetBrainsMono Nerd Font"
            color: Theme.primary
        }
        Text {
            text: "Disk Management"
            font.bold: true
            font.pixelSize: 20
            color: Theme.text
        }
        Item { Layout.fillWidth: true }
        // Yenile butonu
        Rectangle {
            width: 32; height: 32; radius: 16
            color: refreshMA.containsMouse ? Theme.surface : "transparent"
            Text { anchors.centerIn: parent; text: "↻"; color: Theme.text; font.pixelSize: 18 }
            MouseArea {
                id: refreshMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                onClicked: diskService.refresh()
            }
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surface }

    // --- Disk Listesi ---
    ListView {
        id: diskListView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 8
        model: diskService.disks

        delegate: Rectangle {
            required property var modelData
            width: diskListView.width
            height: 80
            color: Theme.surface
            radius: 12
            // Sadece görsel çerçeve, interactive değil
            border.color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 16

                // Sol Taraf: Grafik veya İkon
                Item {
                    width: 50; height: 50
                    
                    // Bağlı diskler için: Daire Grafik
                    Item {
                        anchors.fill: parent
                        visible: modelData.mountpoint !== "" && modelData.fsused !== ""

                        // Arkaplan halkası
                        Shape {
                            anchors.fill: parent
                            ShapePath {
                                strokeColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.1)
                                strokeWidth: 4
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 25; centerY: 25
                                    radiusX: 23; radiusY: 23
                                    startAngle: 0
                                    sweepAngle: 360
                                }
                            }
                        }

                        // Doluluk halkası
                        Shape {
                            anchors.fill: parent
                            ShapePath {
                                strokeColor: {
                                    var p = parseFloat(modelData.usePercent.replace("%","")) || 0;
                                    if (p > 90) return Theme.red;
                                    if (p > 75) return Theme.yellow;
                                    return Theme.primary;
                                }
                                strokeWidth: 4
                                fillColor: "transparent"
                                capStyle: ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: 25; centerY: 25
                                    radiusX: 23; radiusY: 23
                                    startAngle: -90
                                    sweepAngle: 3.6 * (parseFloat(modelData.usePercent.replace("%","")) || 0)
                                }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            text: modelData.usePercent ? modelData.usePercent : "?"
                            font.pixelSize: 10
                            font.bold: true
                            color: Theme.text
                        }
                    }

                    // Bağlı OLMAYAN diskler için: İkon
                    Rectangle {
                        visible: modelData.mountpoint === "" || modelData.fsused === ""
                        anchors.fill: parent
                        radius: 25
                        color: Qt.rgba(Theme.subtext.r, Theme.subtext.g, Theme.subtext.b, 0.1)
                        Text {
                            anchors.centerIn: parent
                            text: "󰋊"
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 24
                            color: Theme.subtext
                        }
                    }
                }

                // Bilgiler
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    
                    // İsim ve Bağlama Noktası
                    RowLayout {
                        Text {
                            text: modelData.name
                            color: Theme.text
                            font.bold: true
                            font.pixelSize: 15
                        }
                        
                        Text {
                            visible: modelData.mountpoint !== ""
                            text: " (" + modelData.mountpoint + ")"
                            color: Theme.subtext
                            font.pixelSize: 12
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    // Detaylar (Kullanılan / Toplam / Boş)
                    Text {
                        text: {
                            if (modelData.mountpoint && modelData.fsused) {
                                return "Used: " + modelData.fsused + " / " + modelData.size + "  •  Free: " + modelData.fsavail
                            } else {
                                return "Capacity: " + modelData.size + " (Not Mounted)"
                            }
                        }
                        color: modelData.mountpoint ? Theme.text : Theme.overlay2
                        font.pixelSize: 12
                        opacity: 0.8
                    }
                    
                    // FSType (küçük bilgi)
                    Text {
                        visible: modelData.fstype !== ""
                        text: modelData.fstype.toUpperCase()
                        color: Theme.overlay
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
