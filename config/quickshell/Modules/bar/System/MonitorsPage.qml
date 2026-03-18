import QtQuick
import QtQuick.Layouts
import Quickshell
import "."
import "../../../Widgets"
import "../../../Services"
import "../../../Services/core/Log.js" as Log

Item {
    id: page

    MonitorsBackend {
        id: backend
        onRefreshRequested: page.syncSelection()
    }

    // ═══ STATE ═══
    property alias outputs: backend.outputs
    property alias selectedIdx: backend.selectedIdx
    property alias selectedOutput: backend.selectedOutput
    property alias colorModeOptions: backend.colorModeOptions
    property alias colorModeLabels: backend.colorModeLabels

    // Seçim state (uygula denmeden değişmez)
    property string selRes: ""
    property string selHz: ""
    property real selScale: 1.0

    // HDR state
    property bool selHdr: false
    property int selBitdepth: 10
    property int selVrr: 2
    property int selSdrLuminance: 450
    property real selSdrBrightness: 1.1
    property real selSdrSaturation: 1.3

    // Color Management state
    property string selColorManagement: "srgb"
    property bool colorDropdownOpen: false
    property int selSdrEotf: 1
    property bool eotfDropdownOpen: false

    function syncSelection() {
        if (!selectedOutput) return;
        selRes = selectedOutput.res;
        selHz = selectedOutput.hz;
        selScale = parseFloat(selectedOutput.scale);
        selHdr = selectedOutput.hdr || false;
        selBitdepth = selectedOutput.bitdepth || 10;
        selVrr = (selectedOutput.vrr !== undefined) ? selectedOutput.vrr : 0;
        selSdrLuminance = selectedOutput.sdrLuminance || 450;
        selSdrBrightness = selectedOutput.sdrBrightness || 1.1;
        selSdrSaturation = selectedOutput.sdrSaturation || 1.3;
        selColorManagement = selectedOutput.colorManagement || "srgb";
        selSdrEotf = (selectedOutput.sdrEotf !== undefined) ? selectedOutput.sdrEotf : 1;
    }

    function isHdrColorMode(mode) {
        return backend.isHdrColorMode(mode);
    }

    function isRiskyColorMode(mode) {
        return backend.isRiskyColorMode(mode);
    }

    function getUniqueRes() {
        return backend.getUniqueRes(selectedOutput);
    }

    function getRefreshRates() {
        return backend.getRefreshRates(selectedOutput, selRes);
    }

    function applySettings() {
        if (!selectedOutput) return;
        if (!selRes || !selHz) {
            Log.warn("MonitorsPage", "Cannot apply settings without resolution and refresh rate");
            return;
        }
        backend.applySettings(outputs, selectedOutput.name, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf);
    }

    function refresh() { backend.refresh(); }

    onSelectedOutputChanged: syncSelection()

    // ═══ UI ═══
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // ── Başlık ──
        RowLayout {
            Layout.fillWidth: true
            Text { text: "󰍹"; font.pixelSize: 20; font.family: "JetBrainsMono Nerd Font"; color: Theme.primary }
            Text { text: "Monitor Settings"; font.bold: true; font.pixelSize: 18; color: Theme.text }
            Item { Layout.fillWidth: true }
            Rectangle {
                width: 30; height: 30; radius: 8
                color: refreshMA.containsMouse ? Theme.surface : "transparent"
                Text { anchors.centerIn: parent; text: "󰑐"; font.pixelSize: 16; font.family: "JetBrainsMono Nerd Font"; color: Theme.subtext }
                MouseArea { id: refreshMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: refresh() }
            }
        }

        // ══════════════════════════════
        // ── MONITOR ARRANGEMENT AREA ──
        // ══════════════════════════════
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 180
            color: Qt.rgba(49/255, 50/255, 68/255, 0.3)
            radius: 12
            border.color: Qt.rgba(255,255,255,0.04)
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "󰹑"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; color: Theme.subtext }
                    Text { text: "Monitor Layout"; color: Theme.subtext; font.pixelSize: 12; font.bold: true }
                }

                // Monitör kutuları
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Row {
                        anchors.centerIn: parent
                        spacing: 12

                        Repeater {
                            model: page.outputs

                            Rectangle {
                                required property var modelData
                                required property int index

                                // Proportional sizing: en büyük çözünürlüğe göre oranla
                                property var resParts: modelData.res.split("x")
                                property real resW: resParts.length > 0 ? parseInt(resParts[0]) : 1920
                                property real resH: resParts.length > 1 ? parseInt(resParts[1]) : 1080
                                property real ratio: resW / resH
                                property real boxH: 90
                                property real boxW: boxH * ratio

                                width: boxW
                                height: boxH
                                radius: 10
                                color: page.selectedIdx === index
                                    ? Qt.rgba(137/255, 180/255, 250/255, 0.15)
                                    : Qt.rgba(49/255, 50/255, 68/255, 0.6)
                                border.color: page.selectedIdx === index ? Theme.primary : Qt.rgba(255,255,255,0.08)
                                border.width: page.selectedIdx === index ? 2 : 1

                                Behavior on color { ColorAnimation { duration: 150 } }
                                Behavior on border.color { ColorAnimation { duration: 150 } }

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        text: modelData.name
                                        color: page.selectedIdx === index ? Theme.primary : Theme.text
                                        font.pixelSize: 16
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Text {
                                        text: {
                                            var d = modelData.desc;
                                            // Kısa göster
                                            if (d.length > 30) d = d.substring(0, 30) + "…";
                                            return d;
                                        }
                                        color: Theme.overlay
                                        font.pixelSize: 9
                                        Layout.alignment: Qt.AlignHCenter
                                        Layout.maximumWidth: parent.parent.width - 16
                                        elide: Text.ElideRight
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { page.selectedIdx = index; }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ══════════════════════════════════
        // ── MONITOR CONFIGURATION ──
        // ══════════════════════════════════
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: configCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: configCol
                width: parent.width
                spacing: 14

                // Seçili monitör bilgisi
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    color: Theme.surface
                    radius: 10

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            width: 36; height: 36; radius: 8
                            color: Qt.rgba(137/255, 180/255, 250/255, 0.12)
                            Text { anchors.centerIn: parent; text: "󰍹"; font.pixelSize: 18; font.family: "JetBrainsMono Nerd Font"; color: Theme.primary }
                        }

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: page.selectedOutput ? (page.selectedOutput.name + "  —  " + page.selectedOutput.desc) : "—"
                                color: Theme.text; font.bold: true; font.pixelSize: 13; elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: page.selectedOutput ? (page.selectedOutput.res + " @ " + parseFloat(page.selectedOutput.hz).toFixed(1) + "Hz • Scale: " + page.selectedOutput.scale + "x") : "—"
                                color: Theme.subtext; font.pixelSize: 11
                            }
                        }
                    }
                }

                // ── Çözünürlük ──
                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255,255,255,0.04) }

                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Resolution"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                    Item { Layout.fillWidth: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: page.getUniqueRes()

                            Rectangle {
                                required property string modelData
                                width: rText.implicitWidth + 20
                                height: 32
                                radius: 8
                                color: page.selRes === modelData
                                    ? Qt.rgba(137/255, 180/255, 250/255, 0.2)
                                    : (rMA.containsMouse ? Theme.surface : Qt.rgba(49/255, 50/255, 68/255, 0.5))
                                border.color: page.selRes === modelData ? Theme.primary : "transparent"
                                border.width: page.selRes === modelData ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: rText; anchors.centerIn: parent
                                    text: modelData.replace("x", "×")
                                    color: page.selRes === modelData ? Theme.primary : Theme.text
                                    font.pixelSize: 12; font.bold: page.selRes === modelData
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                MouseArea {
                                    id: rMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: { 
                                        page.selRes = modelData; 
                                        var rates = page.getRefreshRates();
                                        // Prefer highest Hz (rates are sorted descending)
                                        var safe = rates[0];
                                        page.selHz = safe ? safe.hz : page.selHz;
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Yenileme Hızı ──
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: "Refresh Rate"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                    Item { Layout.fillWidth: true }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 6
                        layoutDirection: Qt.RightToLeft

                        Repeater {
                            model: page.getRefreshRates()

                            Rectangle {
                                required property var modelData
                                width: hText.implicitWidth + 20
                                height: 32
                                radius: 8
                                color: page.selHz === modelData.hz
                                    ? Qt.rgba(137/255, 180/255, 250/255, 0.2)
                                    : (hMA.containsMouse ? Theme.surface : Qt.rgba(49/255, 50/255, 68/255, 0.5))
                                border.color: page.selHz === modelData.hz ? Theme.primary : "transparent"
                                border.width: page.selHz === modelData.hz ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 100 } }

                                Text {
                                    id: hText; anchors.centerIn: parent
                                    text: parseFloat(modelData.hz).toFixed(1) + " Hz"
                                    color: page.selHz === modelData.hz ? Theme.primary : Theme.text
                                    font.pixelSize: 12; font.bold: page.selHz === modelData.hz
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                MouseArea {
                                    id: hMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: page.selHz = modelData.hz
                                }
                            }
                        }
                    }
                }

                // ── Scale Slider ──
                Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(255,255,255,0.04) }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text { text: "Scale"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 50 }

                    // === The real slider ===
                    Item {
                        Layout.fillWidth: true
                        height: 36

                        // Track background
                        Rectangle {
                            id: sliderTrack
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width
                            height: 8
                            radius: 4
                            color: Qt.rgba(49/255, 50/255, 68/255, 0.8)

                            // Fill
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, (page.selScale - 0.5) / 1.5))
                                height: parent.height
                                radius: 4
                                color: Theme.primary
                                Behavior on width { NumberAnimation { duration: 30 } }
                            }
                        }

                        // Handle
                        Rectangle {
                            id: sliderHandle
                            width: 18; height: 18; radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            x: parent.width * Math.max(0, Math.min(1, (page.selScale - 0.5) / 1.5)) - 9
                            color: sliderMA.pressed ? Qt.lighter(Theme.primary, 1.2) : Theme.primary
                            border.color: Qt.lighter(Theme.primary, 1.4)
                            border.width: 2

                            Behavior on x { NumberAnimation { duration: 30 } }
                        }

                        MouseArea {
                            id: sliderMA
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            function setVal(mx) {
                                var ratio = mx / width;
                                if (ratio < 0) ratio = 0;
                                if (ratio > 1) ratio = 1;
                                var raw = 0.5 + ratio * 1.5;
                                
                                if (CompositorService.isHyprland) {
                                    var allScales = [0.5, 0.75, 0.8, 1.0, 1.2, 1.25, 1.333333, 1.5, 1.6, 1.75, 2.0];
                                    // Seçili çözünürlüğe göre geçerli scale'leri filtrele
                                    var resParts = page.selRes.split("x");
                                    var resW = resParts.length > 0 ? parseInt(resParts[0]) : 1920;
                                    var resH = resParts.length > 1 ? parseInt(resParts[1]) : 1080;
                                    var scales = [];
                                    for (var s = 0; s < allScales.length; s++) {
                                        var effW = resW / allScales[s];
                                        var effH = resH / allScales[s];
                                        if (Math.abs(effW - Math.round(effW)) < 0.01 && Math.abs(effH - Math.round(effH)) < 0.01) {
                                            scales.push(allScales[s]);
                                        }
                                    }
                                    if (scales.length === 0) scales = [1.0]; // Fallback
                                    var best = scales[0];
                                    var minDist = Math.abs(raw - best);
                                    for (var i = 1; i < scales.length; i++) {
                                        var dist = Math.abs(raw - scales[i]);
                                        if (dist < minDist) {
                                            minDist = dist;
                                            best = scales[i];
                                        }
                                    }
                                    page.selScale = best;
                                } else {
                                    // Niri or others handle fine-grained steps (e.g. 1.40) without issues
                                    page.selScale = Math.round(raw * 20) / 20;  // 0.05 step
                                }
                            }
                            onPressed: (mouse) => setVal(mouse.x)
                            onPositionChanged: (mouse) => { if (pressed) setVal(mouse.x); }
                        }
                    }

                    Text {
                        text: page.selScale.toFixed(2) + "x"
                        color: Theme.primary
                        font.pixelSize: 13
                        font.bold: true
                        font.family: "JetBrainsMono Nerd Font"
                        Layout.preferredWidth: 48
                        horizontalAlignment: Text.AlignRight
                    }

                    Text {
                        property var parts: page.selRes.split("x")
                        property real w: parts.length > 0 ? parseInt(parts[0]) : 0
                        property real h: parts.length > 1 ? parseInt(parts[1]) : 0
                        property real effW: Math.round(w / page.selScale)
                        property real effH: Math.round(h / page.selScale)
                        
                        text: "(~" + effW + "x" + effH + ")"
                        color: Theme.subtext
                        font.pixelSize: 12
                        font.family: "JetBrainsMono Nerd Font"
                    }
                }

                // ══════════════════════════════════
                // ── HDR SETTINGS (Hyprland only) ──
                // ══════════════════════════════════
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(255,255,255,0.04)
                    visible: CompositorService.isHyprland
                }

                // HDR Toggle
                RowLayout {
                    Layout.fillWidth: true
                    visible: CompositorService.isHyprland
                    spacing: 12

                    Text { text: "HDR"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 48; height: 26; radius: 13
                        color: page.selHdr ? Theme.primary : Qt.rgba(49/255, 50/255, 68/255, 0.8)
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 20; height: 20; radius: 10
                            anchors.verticalCenter: parent.verticalCenter
                            x: page.selHdr ? parent.width - width - 3 : 3
                            color: "white"
                            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                page.selHdr = !page.selHdr;
                                // Sync color management when toggling HDR
                                if (page.selHdr) {
                                    page.selColorManagement = "hdr";
                                } else if (page.isHdrColorMode(page.selColorManagement) && page.selColorManagement !== "hdredid") {
                                    page.selColorManagement = "srgb";
                                }
                            }
                        }
                    }
                }

                // ── Bit Depth (always visible for Hyprland) ──
                RowLayout {
                    Layout.fillWidth: true
                    visible: CompositorService.isHyprland
                    Text { text: "Bit Depth"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [8, 10]
                            Rectangle {
                                required property int modelData
                                width: 52; height: 32; radius: 8
                                color: page.selBitdepth === modelData
                                    ? Qt.rgba(137/255, 180/255, 250/255, 0.2)
                                    : (bdMA.containsMouse ? Theme.surface : Qt.rgba(49/255, 50/255, 68/255, 0.5))
                                border.color: page.selBitdepth === modelData ? Theme.primary : "transparent"
                                border.width: page.selBitdepth === modelData ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData + "-bit"
                                    color: page.selBitdepth === modelData ? Theme.primary : Theme.text
                                    font.pixelSize: 12; font.bold: page.selBitdepth === modelData
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                MouseArea {
                                    id: bdMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: page.selBitdepth = modelData
                                }
                            }
                        }
                    }
                }

                // ── VRR (always visible for Hyprland) ──
                RowLayout {
                    Layout.fillWidth: true
                    visible: CompositorService.isHyprland
                    Text { text: "VRR"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                    Item { Layout.fillWidth: true }
                    Row {
                        spacing: 6
                        Repeater {
                            model: [
                                { value: 0, label: "Off" },
                                { value: 1, label: "On" },
                                { value: 2, label: "Fullscreen" }
                            ]
                            Rectangle {
                                required property var modelData
                                width: vrrText.implicitWidth + 20; height: 32; radius: 8
                                color: page.selVrr === modelData.value
                                    ? Qt.rgba(137/255, 180/255, 250/255, 0.2)
                                    : (vrrMA.containsMouse ? Theme.surface : Qt.rgba(49/255, 50/255, 68/255, 0.5))
                                border.color: page.selVrr === modelData.value ? Theme.primary : "transparent"
                                border.width: page.selVrr === modelData.value ? 1 : 0
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text {
                                    id: vrrText; anchors.centerIn: parent
                                    text: modelData.label
                                    color: page.selVrr === modelData.value ? Theme.primary : Theme.text
                                    font.pixelSize: 12; font.bold: page.selVrr === modelData.value
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                                MouseArea {
                                    id: vrrMA; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: page.selVrr = modelData.value
                                }
                            }
                        }
                    }
                }

                // HDR sub-settings (visible when HDR is on)
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: CompositorService.isHyprland && page.selHdr

                    // ── SDR Max Luminance ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text { text: "SDR Luminance"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                        Item {
                            Layout.fillWidth: true
                            height: 36
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 8; radius: 4
                                color: Qt.rgba(49/255, 50/255, 68/255, 0.8)
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (page.selSdrLuminance - 100) / 500.0))
                                    height: parent.height; radius: 4; color: Theme.primary
                                    Behavior on width { NumberAnimation { duration: 30 } }
                                }
                            }
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.width * Math.max(0, Math.min(1, (page.selSdrLuminance - 100) / 500.0)) - 9
                                color: lumMA.pressed ? Qt.lighter(Theme.primary, 1.2) : Theme.primary
                                border.color: Qt.lighter(Theme.primary, 1.4); border.width: 2
                                Behavior on x { NumberAnimation { duration: 30 } }
                            }
                            MouseArea {
                                id: lumMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function setVal(mx) {
                                    var ratio = Math.max(0, Math.min(1, mx / width));
                                    page.selSdrLuminance = Math.round(100 + ratio * 500);
                                }
                                onPressed: (mouse) => setVal(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) setVal(mouse.x); }
                            }
                        }
                        Text {
                            text: page.selSdrLuminance + " nits"
                            color: Theme.primary; font.pixelSize: 12; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.preferredWidth: 70; horizontalAlignment: Text.AlignRight
                        }
                    }

                    // ── SDR Brightness ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text { text: "SDR Brightness"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                        Item {
                            Layout.fillWidth: true
                            height: 36
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 8; radius: 4
                                color: Qt.rgba(49/255, 50/255, 68/255, 0.8)
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (page.selSdrBrightness - 0.5) / 1.5))
                                    height: parent.height; radius: 4; color: Theme.primary
                                    Behavior on width { NumberAnimation { duration: 30 } }
                                }
                            }
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.width * Math.max(0, Math.min(1, (page.selSdrBrightness - 0.5) / 1.5)) - 9
                                color: briMA.pressed ? Qt.lighter(Theme.primary, 1.2) : Theme.primary
                                border.color: Qt.lighter(Theme.primary, 1.4); border.width: 2
                                Behavior on x { NumberAnimation { duration: 30 } }
                            }
                            MouseArea {
                                id: briMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function setVal(mx) {
                                    var ratio = Math.max(0, Math.min(1, mx / width));
                                    page.selSdrBrightness = Math.round((0.5 + ratio * 1.5) * 10) / 10;
                                }
                                onPressed: (mouse) => setVal(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) setVal(mouse.x); }
                            }
                        }
                        Text {
                            text: page.selSdrBrightness.toFixed(1) + "x"
                            color: Theme.primary; font.pixelSize: 12; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight
                        }
                    }

                    // ── SDR Saturation ──
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16
                        Text { text: "SDR Saturation"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 100 }
                        Item {
                            Layout.fillWidth: true
                            height: 36
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width; height: 8; radius: 4
                                color: Qt.rgba(49/255, 50/255, 68/255, 0.8)
                                Rectangle {
                                    width: parent.width * Math.max(0, Math.min(1, (page.selSdrSaturation - 0.5) / 1.5))
                                    height: parent.height; radius: 4; color: Theme.primary
                                    Behavior on width { NumberAnimation { duration: 30 } }
                                }
                            }
                            Rectangle {
                                width: 18; height: 18; radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.width * Math.max(0, Math.min(1, (page.selSdrSaturation - 0.5) / 1.5)) - 9
                                color: satMA.pressed ? Qt.lighter(Theme.primary, 1.2) : Theme.primary
                                border.color: Qt.lighter(Theme.primary, 1.4); border.width: 2
                                Behavior on x { NumberAnimation { duration: 30 } }
                            }
                            MouseArea {
                                id: satMA; anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                function setVal(mx) {
                                    var ratio = Math.max(0, Math.min(1, mx / width));
                                    page.selSdrSaturation = Math.round((0.5 + ratio * 1.5) * 10) / 10;
                                }
                                onPressed: (mouse) => setVal(mouse.x)
                                onPositionChanged: (mouse) => { if (pressed) setVal(mouse.x); }
                            }
                        }
                        Text {
                            text: page.selSdrSaturation.toFixed(1) + "x"
                            color: Theme.primary; font.pixelSize: 12; font.bold: true
                            font.family: "JetBrainsMono Nerd Font"
                            Layout.preferredWidth: 48; horizontalAlignment: Text.AlignRight
                        }
                    }
                }

                // ══════════════════════════════════
                // ── COLOR SETTINGS (Hyprland only) ──
                // ══════════════════════════════════
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(255,255,255,0.04)
                    visible: CompositorService.isHyprland
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: CompositorService.isHyprland

                    // Section header
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "󰏘"; font.pixelSize: 14; font.family: "JetBrainsMono Nerd Font"; color: Theme.primary }
                        Text { text: "Color Settings"; color: Theme.primary; font.pixelSize: 13; font.bold: true }
                    }

                    // Color Management dropdown
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text { text: "Color Management"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 140 }
                        Item { Layout.fillWidth: true }

                        // Dropdown button
                        Rectangle {
                            id: cmDropdown
                            width: 120; height: 34; radius: 8
                            color: cmDropdownMA.containsMouse ? Qt.rgba(69/255, 71/255, 90/255, 0.8) : Qt.rgba(49/255, 50/255, 68/255, 0.6)
                            border.color: page.colorDropdownOpen ? Theme.primary : Qt.rgba(255,255,255,0.08)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 6
                                Text {
                                    text: {
                                        return page.colorModeLabels[page.selColorManagement] || page.selColorManagement;
                                    }
                                    color: Theme.text; font.pixelSize: 12; font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: page.colorDropdownOpen ? "" : ""
                                    color: Theme.subtext; font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            MouseArea {
                                id: cmDropdownMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: page.colorDropdownOpen = !page.colorDropdownOpen
                            }
                        }
                    }

                    // Dropdown options
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: 160
                        Layout.maximumWidth: 200
                        Layout.leftMargin: parent.width - 200
                        implicitHeight: cmOptionsCol.implicitHeight + 8
                        visible: page.colorDropdownOpen
                        color: Qt.rgba(49/255, 50/255, 68/255, 0.95)
                        radius: 10
                        border.color: Qt.rgba(255,255,255,0.08)
                        border.width: 1

                        Column {
                            id: cmOptionsCol
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top; anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: page.colorModeOptions

                                Rectangle {
                                    required property var modelData
                                    width: cmOptionsCol.width - 8; height: 34; radius: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: page.selColorManagement === modelData.value
                                        ? Qt.rgba(137/255, 180/255, 250/255, 0.15)
                                        : (cmOptMA.containsMouse ? Qt.rgba(69/255, 71/255, 90/255, 0.5) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        Text {
                                            text: modelData.label
                                            color: page.selColorManagement === modelData.value ? Theme.primary : Theme.text
                                            font.pixelSize: 12
                                            font.bold: page.selColorManagement === modelData.value
                                            font.family: "JetBrainsMono Nerd Font"
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: page.selColorManagement === modelData.value ? "✓" : ""
                                            color: Theme.primary; font.pixelSize: 12; font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: cmOptMA; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.selColorManagement = modelData.value;
                                            // HDR seçilince selHdr'yi de senkronize et
                                            if (page.isHdrColorMode(modelData.value)) {
                                                page.selHdr = true;
                                            } else if (page.selHdr && !page.isHdrColorMode(modelData.value)) {
                                                page.selHdr = false;
                                            }
                                            page.colorDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // SDR EOTF dropdown is hidden for now.
                    // We don't pass this setting to Hyprland yet, so exposing it only causes
                    // unnecessary monitor re-apply churn and fullscreen instability.
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: false
                        Text { text: "SDR EOTF"; color: Theme.subtext; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 140 }
                        Item { Layout.fillWidth: true }

                        Rectangle {
                            id: eotfDropdown
                            width: 160; height: 34; radius: 8
                            color: eotfDropdownMA.containsMouse ? Qt.rgba(69/255, 71/255, 90/255, 0.8) : Qt.rgba(49/255, 50/255, 68/255, 0.6)
                            border.color: page.eotfDropdownOpen ? Theme.primary : Qt.rgba(255,255,255,0.08)
                            border.width: 1
                            Behavior on color { ColorAnimation { duration: 100 } }
                            Behavior on border.color { ColorAnimation { duration: 100 } }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 10
                                spacing: 6
                                Text {
                                    text: {
                                        var labels = { 0: "Default (0)", 1: "Piecewise sRGB (1)", 2: "Gamma 2.2 (2)" };
                                        return labels[page.selSdrEotf] || "Unknown";
                                    }
                                    color: Theme.text; font.pixelSize: 12; font.bold: true
                                    font.family: "JetBrainsMono Nerd Font"
                                    Layout.fillWidth: true
                                }
                                Text {
                                    text: page.eotfDropdownOpen ? "" : ""
                                    color: Theme.subtext; font.pixelSize: 10
                                    font.family: "JetBrainsMono Nerd Font"
                                }
                            }

                            MouseArea {
                                id: eotfDropdownMA; anchors.fill: parent; hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { page.eotfDropdownOpen = !page.eotfDropdownOpen; page.colorDropdownOpen = false; }
                            }
                        }
                    }

                    // EOTF Dropdown options
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        Layout.preferredWidth: 160
                        Layout.maximumWidth: 220
                        Layout.leftMargin: parent.width - 220
                        implicitHeight: eotfOptionsCol.implicitHeight + 8
                        visible: false
                        color: Qt.rgba(49/255, 50/255, 68/255, 0.95)
                        radius: 10
                        border.color: Qt.rgba(255,255,255,0.08)
                        border.width: 1

                        Column {
                            id: eotfOptionsCol
                            anchors.left: parent.left; anchors.right: parent.right
                            anchors.top: parent.top; anchors.margins: 4
                            spacing: 2

                            Repeater {
                                model: [
                                    { value: 0, label: "Default" },
                                    { value: 1, label: "Piecewise sRGB" },
                                    { value: 2, label: "Gamma 2.2" }
                                ]

                                Rectangle {
                                    required property var modelData
                                    width: eotfOptionsCol.width - 8; height: 34; radius: 6
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: page.selSdrEotf === modelData.value
                                        ? Qt.rgba(137/255, 180/255, 250/255, 0.15)
                                        : (eotfOptMA.containsMouse ? Qt.rgba(69/255, 71/255, 90/255, 0.5) : "transparent")
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 12
                                        Text {
                                            text: modelData.label
                                            color: page.selSdrEotf === modelData.value ? Theme.primary : Theme.text
                                            font.pixelSize: 12
                                            font.bold: page.selSdrEotf === modelData.value
                                            font.family: "JetBrainsMono Nerd Font"
                                            Layout.fillWidth: true
                                        }
                                        Text {
                                            text: page.selSdrEotf === modelData.value ? "✓" : ""
                                            color: Theme.primary; font.pixelSize: 12; font.bold: true
                                        }
                                    }

                                    MouseArea {
                                        id: eotfOptMA; anchors.fill: parent; hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            page.selSdrEotf = modelData.value;
                                            page.eotfDropdownOpen = false;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Uygula ──
                Item { height: 4 }

                Rectangle {
                    Layout.fillWidth: true
                    height: 42
                    radius: 10
                    color: applyMA.containsMouse ? Qt.lighter(Theme.primary, 1.15) : Theme.primary
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Text {
                        anchors.centerIn: parent
                        text: "✓  Apply"
                        color: "#1e1e2e"
                        font.pixelSize: 14
                        font.bold: true
                    }

                    MouseArea {
                        id: applyMA; anchors.fill: parent; hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.applySettings()
                    }
                }
            }
        }
    }
}
