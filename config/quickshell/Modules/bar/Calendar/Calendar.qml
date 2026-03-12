import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import "."
import "../../../Widgets"

Rectangle {
    id: dateRoot

    // --- RENK AYARLARI ---
    property color barBgColor: Theme.calendarColor
    property color barTextColor: Theme.background

    property color popupBg: Theme.background
    property color popupText: Theme.text
    property color accentColor: Theme.calendarColor

    CalendarBackend { id: backend }
    property alias showFullDate: backend.showFullDate
    property alias currentDate: backend.currentDate

    height: 34
    radius: 17
    color: barBgColor

    // GENİŞLİK: İçeriğe göre otomatik ayarla
    // GENİŞLİK: İçeriğe göre otomatik ayarla
    implicitWidth: layout.implicitWidth + 24
    Behavior on implicitWidth { NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } }

    
    // ... (Timer iptal edilebilir veya sadece takvim popup için kullanılabilir)

    // --- BAR İÇERİĞİ ---
    RowLayout {
        id: layout
        anchors.centerIn: parent
        spacing: 6

        Text {
            text: ""
            color: "#1e1e2e"
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 16
        }

        Text {
            id: timeText
            // Format: 17:11 • 16 Şub Paz
            text: {
                if (dateRoot.showFullDate) {
                    return Qt.formatTime(dateRoot.currentDate, "HH:mm") + " • " + Qt.formatDate(dateRoot.currentDate, "dd MMM ddd")
                } else {
                    return Qt.formatTime(dateRoot.currentDate, "HH:mm")
                }
            }
            color: "#1e1e2e"
            font.bold: true
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 13 // Matches others roughly
        }
    }

    // Popup Kapatma Zamanlayıcısı
    Timer {
        id: closeTimer
        interval: 300
        repeat: false
        onTriggered: calWindow.visible = false
    }

    // --- FARE ETKİLEŞİMİ ---
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        // Üstüne Gelince: Takvimi Aç
        onEntered: {
            closeTimer.stop()
            calWindow.visible = true
        }

        // Üzerinden Gidince: Takvimi Kapat (Timer ile)
        onExited: {
            closeTimer.start()
        }

        // Tıklayınca: Tarih yazısını Genişlet/Daralt (Takvimi etkilemez)
        onClicked: {
            dateRoot.showFullDate = !dateRoot.showFullDate
        }
    }

    // --- TAKVİM PENCERESİ ---
    PanelWindow {
        id: calWindow
        visible: false
        property real panelOpacity: 0.0
        property real panelYOffset: -18
        Behavior on panelOpacity { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
        Behavior on panelYOffset { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
        implicitWidth: 400
        implicitHeight: 560
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        anchors {
            top: true
            left: true
        }

        // Position below/beside the calendar button
        margins {
            top: 58
            left: 0
        }

        function repositionCalendar() {
            if (!dateRoot.QsWindow || !dateRoot.QsWindow.window) return;
            var win = dateRoot.QsWindow.window;
            var isVertBar = win.height > win.width;
            var globalPos = dateRoot.mapToGlobal(0, 0);

            if (isVertBar) {
                calWindow.margins.top = globalPos.y;
                calWindow.margins.left = globalPos.x - calWindow.width - 10;
                if (calWindow.margins.left < 10) calWindow.margins.left = 10;
            } else {
                var desiredTop = globalPos.y + dateRoot.height + 8;
                if (desiredTop + calWindow.height > win.height - 8) {
                    desiredTop = globalPos.y - calWindow.height - 8;
                }
                calWindow.margins.top = Math.max(8, desiredTop);

                var desiredLeft = globalPos.x - (calWindow.width / 2) + (dateRoot.width / 2);
                var maxLeft = Math.max(10, win.width - calWindow.width - 10);
                calWindow.margins.left = Math.max(10, Math.min(desiredLeft, maxLeft));
            }
        }

        Rectangle {
            id: bgRect
            anchors.fill: parent
            opacity: calWindow.panelOpacity
            transform: Translate { y: calWindow.panelYOffset }
            color: popupBg
            border.color: accentColor
            border.width: 2
            radius: 12

            HoverHandler {
                id: popupHover
                onHoveredChanged: {
                    if (hovered) closeTimer.stop()
                    else closeTimer.start()
                }
            }

            // Click blocker - sits behind children so they get events first
            MouseArea {
                anchors.fill: parent
                z: -1
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                // TAB BAR
                TabBar {
                    id: navBar
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    currentIndex: viewStack.currentIndex

                    background: Rectangle { color: "transparent" }

                    component MyTabButton: TabButton {
                        property string iconChar
                        background: Rectangle {
                            color: parent.checked ? Qt.rgba(1,1,1,0.1) : "transparent"
                            radius: 5
                        }
                        contentItem: Text {
                            text: parent.iconChar
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 16
                            color: parent.checked ? accentColor : popupText
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: viewStack.currentIndex = TabBar.index
                    }

                    MyTabButton { iconChar: "" } // Calendar
                    MyTabButton { iconChar: "" } // Countdown

                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255,255,255,0.1) }

                // CONTENT STACK
                StackLayout {
                    id: viewStack
                    currentIndex: navBar.currentIndex
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // 1. CALENDAR VIEW
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 10

                            // BAŞLIK
                            RowLayout {
                                Layout.fillWidth: true

                                Rectangle {
                                    width: 30; height: 30; radius: 15
                                    color: prevMouse.containsMouse ? "#313244" : "transparent"
                                    Text { anchors.centerIn: parent; text: ""; color: accentColor; font.pixelSize: 16 }
                                    MouseArea { id: prevMouse; anchors.fill: parent; hoverEnabled: true; onClicked: backend.prevMonth() }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: backend.monthName + " " + backend.displayYear
                                    color: popupText
                                    font.bold: true; font.pixelSize: 18
                                    font.family: "JetBrainsMono Nerd Font"
                                }

                                Item { Layout.fillWidth: true }

                                Rectangle {
                                    width: 30; height: 30; radius: 15
                                    color: nextMouse.containsMouse ? "#313244" : "transparent"
                                    Text { anchors.centerIn: parent; text: ""; color: accentColor; font.pixelSize: 16 }
                                    MouseArea { id: nextMouse; anchors.fill: parent; hoverEnabled: true; onClicked: backend.nextMonth() }
                                }
                            }

                            // GÜN İSİMLERİ
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Repeater {
                                    model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                    Text {
                                        text: modelData
                                        Layout.preferredWidth: 36
                                        horizontalAlignment: Text.AlignHCenter
                                        color: accentColor
                                        font.bold: true; font.pixelSize: 13
                                    }
                                }
                            }

                            // GÜNLER
                            GridLayout {
                                columns: 7; columnSpacing: 4; rowSpacing: 4
                                Repeater {
                                    model: backend.days
                                    Rectangle {
                                        width: 36; height: 36; radius: 18
                                        color: modelData.isToday ? accentColor : "transparent"
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            color: modelData.isToday ? "#1e1e2e" : (modelData.inMonth ? popupText : "#505050")
                                            font.bold: modelData.isToday
                                            font.family: "JetBrainsMono Nerd Font"
                                        }
                                    }
                                }
                            }
                            
                            Item { Layout.fillHeight: true }
                        }
                    }

                    // 2. COUNTDOWN VIEW
                    Countdown {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }


                }
            }
        }
        onVisibleChanged: {
            if (visible) {
                backend.toToday()
                repositionCalendar()
                calWindow.panelOpacity = 0.0
                calWindow.panelYOffset = -18
                Qt.callLater(function() {
                    calWindow.panelOpacity = 1.0
                    calWindow.panelYOffset = 0
                })
            } else {
                calWindow.panelOpacity = 0.0
                calWindow.panelYOffset = -14
            }
        }

        onWidthChanged: if (visible) repositionCalendar()
        onHeightChanged: if (visible) repositionCalendar()
    }

    onWidthChanged: if (calWindow.visible) calWindow.repositionCalendar()
    onHeightChanged: if (calWindow.visible) calWindow.repositionCalendar()

}
