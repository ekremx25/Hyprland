import QtQuick
import Quickshell
import Quickshell.Io
import "../../../Services"
import "../../../Services/core" as Core
import "../../../Services/core/Log.js" as Log

Item {
    id: backend
    visible: false
    width: 0
    height: 0

    property var outputs: []
    property int selectedIdx: 0
    property var selectedOutput: outputs.length > selectedIdx ? outputs[selectedIdx] : null
    property var savedConfig: ({})

    readonly property var riskyColorModes: ["dcip3", "dp3", "adobe"]
    readonly property var hdrColorModes: ["hdr", "hdredid", "hdrp3", "hdrapple", "hdradobe"]
    readonly property var colorModeOptions: [
        { value: "default", label: "Default" },
        { value: "srgb", label: "sRGB" },
        { value: "dcip3", label: "DCI P3" },
        { value: "dp3", label: "Apple P3" },
        { value: "adobe", label: "Adobe RGB" },
        { value: "wide", label: "Wide Color" },
        { value: "edid", label: "EDID" },
        { value: "hdr", label: "HDR" },
        { value: "hdrp3", label: "HDR + P3 (Test)" },
        { value: "hdrapple", label: "HDR + Apple P3 (Test)" },
        { value: "hdradobe", label: "HDR + Adobe RGB (Test)" },
        { value: "hdredid", label: "HDR (EDID)" }
    ]
    readonly property var colorModeLabels: ({
        "default": "Default",
        "srgb": "sRGB",
        "dcip3": "DCI P3",
        "dp3": "Apple P3",
        "adobe": "Adobe RGB",
        "wide": "Wide Color (BT2020)",
        "edid": "EDID (Inaccurate)",
        "hdr": "HDR",
        "hdrp3": "HDR + P3 (Test)",
        "hdrapple": "HDR + Apple P3 (Test)",
        "hdradobe": "HDR + Adobe RGB (Test)",
        "hdredid": "HDR (EDID)"
    })

    signal refreshRequested()

    function isHdrColorMode(mode) {
        return backend.hdrColorModes.indexOf(mode) >= 0;
    }

    function isRiskyColorMode(mode) {
        return backend.riskyColorModes.indexOf(mode) >= 0;
    }

    function parseOutputs(text) {
        if (CompositorService.isHyprland) parseHyprland(text);
        else if (CompositorService.isMango) parseMango(text);
        else parseAll(text);
    }

    function applySavedOverlay(outObj) {
        var saved = backend.savedConfig[outObj.name];
        if (!saved) return;
        if (saved.vrr !== undefined) outObj.vrr = saved.vrr;
        if (saved.hdr !== undefined) outObj.hdr = saved.hdr;
        if (saved.bitdepth !== undefined) outObj.bitdepth = saved.bitdepth;
        if (saved.sdrLuminance !== undefined) outObj.sdrLuminance = saved.sdrLuminance;
        if (saved.sdrBrightness !== undefined) outObj.sdrBrightness = saved.sdrBrightness;
        if (saved.sdrSaturation !== undefined) outObj.sdrSaturation = saved.sdrSaturation;
        if (saved.colorManagement !== undefined) outObj.colorManagement = saved.colorManagement;
        if (saved.sdrEotf !== undefined) outObj.sdrEotf = saved.sdrEotf;
    }

    function finalizeOutputs(outs) {
        backend.outputs = outs;
        if (backend.selectedIdx >= outs.length) backend.selectedIdx = 0;
    }

    function parseHyprland(text) {
        try {
            var data = JSON.parse(text);
            var outs = [];
            for (var i = 0; i < data.length; i++) {
                var info = data[i];
                var outObj = {
                    name: info.name,
                    desc: (info.make || "") + " " + (info.model || ""),
                    res: info.width + "x" + info.height,
                    hz: info.refreshRate ? info.refreshRate.toFixed(3) : "60.000",
                    scale: info.scale ? info.scale.toFixed(2) : "1.00",
                    posX: info.x || 0,
                    posY: info.y || 0,
                    hdr: (info.colorManagementPreset === "hdr" || info.colorManagement === "hdr" || info.cm === "hdr") ? true : false,
                    bitdepth: (info.currentFormat && info.currentFormat.indexOf("2101010") >= 0) ? 10 : (info.bitdepth || 8),
                    vrr: (info.vrr === true) ? 1 : ((info.vrr === false) ? 0 : (info.vrr || 0)),
                    sdrLuminance: info.sdrMaxLuminance || info.sdr_max_luminance || 450,
                    sdrBrightness: info.sdrBrightness || info.sdrbrightness || 1.0,
                    sdrSaturation: info.sdrSaturation || info.sdrsaturation || 1.0,
                    colorManagement: info.colorManagementPreset || info.cm || info.colorManagement || "srgb",
                    sdrEotf: info.sdr_eotf || info.sdreotf || 1,
                    modes: []
                };

                if (info.availableModes) {
                    for (var m = 0; m < info.availableModes.length; m++) {
                        var modeStr = info.availableModes[m];
                        var parts = modeStr.split("@");
                        if (parts.length !== 2) continue;
                        var res = parts[0];
                        var hz = parts[1].replace("Hz", "");
                        var formattedHz = parseFloat(hz).toFixed(3);
                        var isCur = (res === outObj.res && Math.abs(parseFloat(hz) - parseFloat(outObj.hz)) < 1.0);
                        outObj.modes.push({ res: res, hz: formattedHz, current: isCur });
                        if (isCur) outObj.hz = formattedHz;
                    }
                }

                applySavedOverlay(outObj);
                outs.push(outObj);
            }
            finalizeOutputs(outs);
        } catch (e) {
            Log.warn("MonitorsBackend", "Hyprland outputs parse error: " + e);
        }
    }

    function parseAll(text) {
        try {
            var data = JSON.parse(text);
            var outs = [];
            var keys = Object.keys(data);
            for (var i = 0; i < keys.length; i++) {
                var name = keys[i];
                var info = data[name];
                var outObj = {
                    name: name,
                    desc: (info.make || "") + " " + (info.model || ""),
                    res: "",
                    hz: "",
                    scale: "1.0",
                    posX: 0,
                    posY: 0,
                    modes: []
                };

                if (info.logical) {
                    outObj.posX = info.logical.x;
                    outObj.posY = info.logical.y;
                    outObj.scale = info.logical.scale.toFixed(2);
                }

                if (info.modes) {
                    for (var m = 0; m < info.modes.length; m++) {
                        var mode = info.modes[m];
                        var res = mode.width + "x" + mode.height;
                        var hz = (mode.refresh_rate / 1000.0).toFixed(3);
                        var isCur = (m === info.current_mode);
                        outObj.modes.push({ res: res, hz: hz, current: isCur });
                        if (isCur) {
                            outObj.res = res;
                            outObj.hz = hz;
                        }
                    }
                }
                outs.push(outObj);
            }
            finalizeOutputs(outs);
        } catch (e) {
            Log.warn("MonitorsBackend", "Niri outputs parse error: " + e);
        }
    }

    function parseMango(text) {
        try {
            var outs = [];
            var lines = text.split("\n");
            var current = null;
            var inModes = false;

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i];
                var trimmed = line.trim();
                if (trimmed === "") continue;

                if (line.length > 0 && line[0] !== " " && line[0] !== "\t") {
                    if (current) outs.push(current);
                    var nameEnd = trimmed.indexOf(" ");
                    var outName = nameEnd > 0 ? trimmed.substring(0, nameEnd) : trimmed;
                    var descPart = nameEnd > 0 ? trimmed.substring(nameEnd + 1) : "";
                    descPart = descPart.replace(/^"|"$/g, "").trim();
                    descPart = descPart.replace(/\s*\([^)]*\)\s*$/, "").trim();
                    current = {
                        name: outName,
                        desc: descPart || outName,
                        res: "",
                        hz: "",
                        scale: "1.00",
                        posX: 0,
                        posY: 0,
                        modes: []
                    };
                    inModes = false;
                    continue;
                }

                if (!current) continue;
                if (trimmed === "Modes:") {
                    inModes = true;
                    continue;
                }
                if (inModes && trimmed.indexOf("px,") > 0) {
                    var modeMatch = trimmed.match(/(\d+)x(\d+)\s+px,\s+([\d.]+)\s+Hz(.*)/);
                    if (modeMatch) {
                        var res = modeMatch[1] + "x" + modeMatch[2];
                        var hz = parseFloat(modeMatch[3]).toFixed(3);
                        var isCurrent = (modeMatch[4] || "").indexOf("current") >= 0;
                        current.modes.push({ res: res, hz: hz, current: isCurrent });
                        if (isCurrent) {
                            current.res = res;
                            current.hz = hz;
                        }
                    }
                    continue;
                }
                if (trimmed.startsWith("Position:")) {
                    inModes = false;
                    var posParts = trimmed.substring("Position:".length).trim().split(",");
                    if (posParts.length >= 2) {
                        current.posX = parseInt(posParts[0]) || 0;
                        current.posY = parseInt(posParts[1]) || 0;
                    }
                    continue;
                }
                if (trimmed.startsWith("Scale:")) {
                    inModes = false;
                    var scaleVal = parseFloat(trimmed.substring("Scale:".length).trim());
                    if (!isNaN(scaleVal)) current.scale = scaleVal.toFixed(2);
                    continue;
                }
                if (trimmed.startsWith("Enabled:") || trimmed.startsWith("Transform:") || trimmed.startsWith("Physical size:")) {
                    inModes = false;
                }
            }
            if (current) outs.push(current);
            finalizeOutputs(outs);
        } catch (e) {
            Log.warn("MonitorsBackend", "Mango wlr-randr parse error: " + e);
        }
    }

    function getUniqueRes(selectedOutput) {
        if (!selectedOutput) return [];
        var seen = {};
        var result = [];
        for (var i = 0; i < selectedOutput.modes.length; i++) {
            var res = selectedOutput.modes[i].res;
            if (!seen[res]) {
                seen[res] = true;
                result.push(res);
            }
        }
        return result;
    }

    function getRefreshRates(selectedOutput, selRes) {
        if (!selectedOutput) return [];
        var rates = [];
        for (var i = 0; i < selectedOutput.modes.length; i++) {
            if (selectedOutput.modes[i].res === selRes) rates.push({ hz: selectedOutput.modes[i].hz, current: selectedOutput.modes[i].current });
        }
        rates.sort(function(a, b) { return parseFloat(b.hz) - parseFloat(a.hz); });
        var unique = [];
        var seen = {};
        for (var j = 0; j < rates.length; j++) {
            var key = parseFloat(rates[j].hz).toFixed(2);
            if (!seen[key]) {
                seen[key] = true;
                unique.push(rates[j]);
            }
        }
        return unique;
    }

    function monitorSettingChanged(mon, monRes, monHz, monScale, monPosX, monPosY, monHdr, monBitdepth, monVrr, monSdrBri, monSdrSat, monCm, monEotf) {
        var currentHdr = mon.hdr || false;
        var currentBitdepth = mon.bitdepth || 8;
        var currentVrr = (mon.vrr !== undefined) ? mon.vrr : 0;
        var currentBri = mon.sdrBrightness || 1.0;
        var currentSat = mon.sdrSaturation || 1.0;
        var currentCm = mon.colorManagement || "srgb";
        var currentEotf = (mon.sdrEotf !== undefined) ? mon.sdrEotf : 1;

        if (monRes !== mon.res) return true;
        if (Math.abs(parseFloat(monHz) - parseFloat(mon.hz)) >= 0.01) return true;
        if (Math.abs(parseFloat(monScale) - parseFloat(mon.scale)) >= 0.01) return true;
        if (monPosX !== Math.round(mon.posX)) return true;
        if (monPosY !== Math.round(mon.posY)) return true;
        if (monHdr !== currentHdr) return true;
        if (monBitdepth !== currentBitdepth) return true;
        if (monVrr !== currentVrr) return true;
        if (Math.abs(monSdrBri - currentBri) >= 0.01) return true;
        if (Math.abs(monSdrSat - currentSat) >= 0.01) return true;
        if (monCm !== currentCm) return true;
        if (monEotf !== currentEotf) return true;
        return false;
    }

    function recalcPositions(outputs, selectedOutputName, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf) {
        if (outputs.length === 0) return outputs;
        var updated = [];
        for (var i = 0; i < outputs.length; i++) {
            var isSel = (outputs[i].name === selectedOutputName);
            updated.push({
                name: outputs[i].name,
                desc: outputs[i].desc,
                res: isSel ? selRes : outputs[i].res,
                hz: isSel ? selHz : outputs[i].hz,
                scale: isSel ? selScale : parseFloat(outputs[i].scale),
                posX: outputs[i].posX,
                posY: outputs[i].posY,
                hdr: isSel ? selHdr : (outputs[i].hdr || false),
                bitdepth: isSel ? selBitdepth : (outputs[i].bitdepth || 8),
                vrr: isSel ? selVrr : ((outputs[i].vrr !== undefined) ? outputs[i].vrr : 0),
                sdrLuminance: isSel ? selSdrLuminance : (outputs[i].sdrLuminance || 450),
                sdrBrightness: isSel ? selSdrBrightness : (outputs[i].sdrBrightness || 1.0),
                sdrSaturation: isSel ? selSdrSaturation : (outputs[i].sdrSaturation || 1.0),
                colorManagement: isSel ? selColorManagement : (outputs[i].colorManagement || "srgb"),
                sdrEotf: isSel ? selSdrEotf : ((outputs[i].sdrEotf !== undefined) ? outputs[i].sdrEotf : 1),
                modes: outputs[i].modes
            });
        }

        updated.sort(function(a, b) { return a.posX - b.posX; });
        var currentX = 0;
        for (var j = 0; j < updated.length; j++) {
            var parts = updated[j].res.split("x");
            var width = parseInt(parts[0]);
            var scale = parseFloat(updated[j].scale);
            updated[j].posX = currentX;
            updated[j].posY = 0;
            currentX += Math.round(width / scale);
        }
        return updated;
    }

    function buildApplyCommand(outputs, selectedOutputName, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf) {
        var updatedOutputs = recalcPositions(outputs, selectedOutputName, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf);
        var cmds = [];
        var saveCmds = [];

        saveCmds.push("mkdir -p ~/.config/quickshell && ([ -s ~/.config/quickshell/monitor_config.json ] || echo '{}' > ~/.config/quickshell/monitor_config.json)");

        for (var i = 0; i < updatedOutputs.length; i++) {
            var mon = updatedOutputs[i];
            var isSelected = (mon.name === selectedOutputName);
            var monRes = isSelected ? selRes : mon.res;
            var monHz = isSelected ? parseFloat(selHz).toFixed(2) : parseFloat(mon.hz).toFixed(2);
            var monScale = String(parseFloat(isSelected ? selScale : mon.scale));
            var monPosX = Math.round(mon.posX);
            var monPosY = Math.round(mon.posY);

            if (CompositorService.isHyprland) {
                var monHdr = isSelected ? selHdr : (mon.hdr || false);
                var monBitdepth = isSelected ? selBitdepth : (mon.bitdepth || 8);
                var monVrr = isSelected ? selVrr : (mon.vrr || 0);
                var monSdrBri = isSelected ? selSdrBrightness : (mon.sdrBrightness || 1.0);
                var monSdrSat = isSelected ? selSdrSaturation : (mon.sdrSaturation || 1.0);
                var monCm = isSelected ? selColorManagement : (mon.colorManagement || "srgb");
                var monEotf = isSelected ? selSdrEotf : ((mon.sdrEotf !== undefined) ? mon.sdrEotf : 1);
                var monCmd = "hyprctl keyword monitor " + mon.name + "," + monRes + "@" + monHz + "," + monPosX + "x" + monPosY + "," + monScale;

                if (isRiskyColorMode(monCm)) monVrr = 0;

                if (monHdr || isHdrColorMode(monCm)) {
                    var appliedCm = (monCm === "hdredid") ? "hdredid" : "hdr";
                    monCmd += ",bitdepth," + monBitdepth + ",vrr," + monVrr + ",cm," + appliedCm + ",sdrbrightness," + monSdrBri.toFixed(1) + ",sdrsaturation," + monSdrSat.toFixed(1);
                } else if (monCm === "default") {
                    monCmd += ",bitdepth," + monBitdepth + ",vrr," + monVrr;
                } else {
                    monCmd += ",bitdepth," + monBitdepth + ",vrr," + monVrr + ",cm," + monCm;
                }

                var changed = monitorSettingChanged(mon, monRes, monHz, monScale, monPosX, monPosY, monHdr, monBitdepth, monVrr, monSdrBri, monSdrSat, monCm, monEotf);
                if (isSelected && monCm !== (mon.colorManagement || "srgb")) {
                    var resetCmd = "hyprctl keyword monitor " + mon.name + "," + monRes + "@" + monHz + "," + monPosX + "x" + monPosY + "," + monScale + ",bitdepth,10,vrr,0,cm,srgb";
                    monCmd = resetCmd + " && sleep 0.2 && " + monCmd;
                }
                if (isSelected || changed) cmds.push(monCmd);
            } else if (CompositorService.isMango) {
                var resParts = monRes.split("x");
                var monRefresh = Math.round(parseFloat(monHz));
                var ruleStr = "monitorrule=name:" + mon.name + ",width:" + resParts[0] + ",height:" + resParts[1] + ",refresh:" + monRefresh + ",x:" + monPosX + ",y:" + monPosY + ",scale:" + monScale;
                cmds.push("sed -i '/^monitorrule=name:" + mon.name + "/d' ~/.config/mango/config.conf && sed -i '/^# Monitor Rules$/a " + ruleStr + "' ~/.config/mango/config.conf");
            } else {
                var applyHz6 = isSelected ? parseFloat(selHz).toFixed(6) : parseFloat(mon.hz).toFixed(6);
                var niriConf = "$HOME/.config/niri/config.kdl";
                var newMode = monRes + "@" + applyHz6;
                cmds.push("python3 -c \"\n"
                    + "import re, os\n"
                    + "conf = os.path.expanduser('" + niriConf + "')\n"
                    + "with open(conf) as f: text = f.read()\n"
                    + "pattern = r'(output\\\\s+\\\"" + mon.name + "\\\"\\\\s*\\\\{)[^}]*(\\\\})'\n"
                    + "replacement = r'\\\\1\\n    mode \\\"" + newMode + "\\\"\\n    position x=" + monPosX + " y=" + monPosY + "\\n    scale " + monScale + "\\n\\\\2'\n"
                    + "if re.search(pattern, text):\n"
                    + "    new_text = re.sub(pattern, replacement, text, flags=re.DOTALL)\n"
                    + "else:\n"
                    + "    new_text = text.rstrip() + '\\n\\noutput \\\"" + mon.name + "\\\" {\\n    mode \\\"" + newMode + "\\\"\\n    position x=" + monPosX + " y=" + monPosY + "\\n    scale " + monScale + "\\n}\\n'\n"
                    + "with open(conf, 'w') as f: f.write(new_text)\n"
                    + "print('Updated ' + conf)\n"
                    + "\"");
            }

            var monHdrSave = isSelected ? selHdr : (mon.hdr || false);
            var monBdSave = isSelected ? selBitdepth : (mon.bitdepth || 8);
            var monVrrSave = isSelected ? selVrr : (mon.vrr || 0);
            var monLumSave = isSelected ? selSdrLuminance : (mon.sdrLuminance || 450);
            var monBriSave = isSelected ? selSdrBrightness : (mon.sdrBrightness || 1.0);
            var monSatSave = isSelected ? selSdrSaturation : (mon.sdrSaturation || 1.0);
            var monCmSave = isSelected ? selColorManagement : (mon.colorManagement || "srgb");
            var monEotfSave = isSelected ? selSdrEotf : ((mon.sdrEotf !== undefined) ? mon.sdrEotf : 1);
            saveCmds.push("jq '.\"" + mon.name + "\" = {\"res\": \"" + monRes + "\", \"hz\": \"" + monHz + "\", \"scale\": \"" + monScale + "\", \"posX\": \"" + monPosX + "\", \"posY\": \"" + monPosY + "\", \"hdr\": " + (monHdrSave ? "true" : "false") + ", \"bitdepth\": " + monBdSave + ", \"vrr\": " + monVrrSave + ", \"sdrLuminance\": " + monLumSave + ", \"sdrBrightness\": " + monBriSave.toFixed(1) + ", \"sdrSaturation\": " + monSatSave.toFixed(1) + ", \"colorManagement\": \"" + monCmSave + "\", \"sdrEotf\": " + monEotfSave + "}' ~/.config/quickshell/monitor_config.json > ~/.config/quickshell/monitor_config.tmp && mv ~/.config/quickshell/monitor_config.tmp ~/.config/quickshell/monitor_config.json");
        }

        var fullCmd = cmds.join(" && ") + " && " + saveCmds.join(" && ");
        if (CompositorService.isMango) fullCmd += " && mmsg -d reload_config";
        return { command: fullCmd, updatedOutputs: updatedOutputs };
    }

    function applySettings(outputs, selectedOutputName, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf) {
        var applyData = buildApplyCommand(outputs, selectedOutputName, selRes, selHz, selScale, selHdr, selBitdepth, selVrr, selSdrLuminance, selSdrBrightness, selSdrSaturation, selColorManagement, selSdrEotf);
        backend.outputs = applyData.updatedOutputs;
        Log.debug("MonitorsBackend", "Running: " + applyData.command);
        applyProc.running = false;
        applyProc.command = ["sh", "-c", applyData.command];
        applyProc.running = true;
    }

    function refresh() {
        configStore.load();
    }

    Connections {
        target: CompositorService
        function onCompositorChanged() {
            if (CompositorService.compositor === "mango") {
                Log.debug("MonitorsBackend", "Mango detected, refreshing monitors");
                refresh();
            }
        }
    }

    Process {
        id: randrProc
        command: CompositorService.isHyprland ? ["hyprctl", "monitors", "all", "-j"] : (CompositorService.isMango ? ["wlr-randr"] : ["niri", "msg", "-j", "outputs"])
        property string buf: ""
        stdout: SplitParser { onRead: data => randrProc.buf += data + "\n" }
        onExited: {
            if (randrProc.buf.trim() !== "") parseOutputs(randrProc.buf);
            randrProc.buf = "";
            backend.refreshRequested();
        }
    }

    Process {
        id: applyProc
        command: []
        running: false
        stdout: SplitParser { onRead: data => Log.debug("MonitorsBackend", "[monitor apply stdout] " + data) }
        stderr: SplitParser { onRead: data => Log.warn("MonitorsBackend", "[monitor apply stderr] " + data) }
        onExited: refreshTimer.start()
    }

    Timer {
        id: refreshTimer
        interval: 500
        repeat: false
        onTriggered: backend.refresh()
    }

    Component.onCompleted: configStore.load()

    Core.JsonDataStore {
        id: configStore
        path: Quickshell.env("HOME") + "/.config/quickshell/monitor_config.json"
        defaultValue: ({})
        onLoadedValue: function(value) {
            backend.savedConfig = value || {};
            randrProc.buf = "";
            randrProc.running = true;
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("MonitorsBackend", "Saved config parse error: " + details);
            backend.savedConfig = {};
            randrProc.buf = "";
            randrProc.running = true;
        }
    }
}
