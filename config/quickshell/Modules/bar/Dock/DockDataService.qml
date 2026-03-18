import QtQuick
import Qt.labs.platform
import Quickshell.Io
import "../../../Services" as S
import "../../../Services/core" as Core
import "../../../Services/core/Log.js" as Log

Item {
    id: service
    visible: false
    width: 0
    height: 0

    property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/dock_config.json"
    property string desktopIconScript: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/scripts/desktop_icons.sh"
    property string initDockScript: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/scripts/init_dock.sh"

    property var dockConfigData: null
    property var pinnedApps: []
    property var leftModules: []
    property var rightModules: []
    property var runningWindows: []
    property bool suspendHotReload: false

    property var desktopIcons: ({})
    property var desktopCommands: ({})
    property var desktopEntries: ({})
    property string lastDockConfigContent: ""
    property bool windowRefreshRunning: false

    function parseDesktopMetadata(raw) {
        var parts = [];
        var depth = 0;
        var startIdx = -1;

        for (var ci = 0; ci < raw.length; ci++) {
            if (raw[ci] === "{") {
                if (depth === 0) startIdx = ci;
                depth++;
            } else if (raw[ci] === "}") {
                depth--;
                if (depth === 0 && startIdx >= 0) {
                    parts.push(raw.substring(startIdx, ci + 1));
                    startIdx = -1;
                }
            }
        }

        if (parts.length === 0) {
            return {
                icons: JSON.parse(raw),
                commands: {},
                entries: {}
            };
        }

        return {
            icons: JSON.parse(parts[0]),
            commands: parts.length > 1 ? JSON.parse(parts[1]) : {},
            entries: parts.length > 2 ? JSON.parse(parts[2]) : {}
        };
    }

    function cloneDockConfig() {
        var obj = {};
        if (!service.dockConfigData) return obj;

        var keys = Object.keys(service.dockConfigData);
        for (var i = 0; i < keys.length; i++) obj[keys[i]] = service.dockConfigData[keys[i]];
        return obj;
    }

    function applyDockConfig(cfg, rawContent) {
        service.lastDockConfigContent = rawContent || service.lastDockConfigContent;
        service.dockConfigData = cfg;
        service.pinnedApps = cfg.pinned || [];
        service.leftModules = cfg.leftModules || [];
        service.rightModules = cfg.rightModules || [];

        var showBg = cfg.showBackground !== undefined ? cfg.showBackground : true;
        if (service.dockConfigData.showBackground !== showBg) service.dockConfigData.showBackground = showBg;
    }

    function handleDockConfigText(content) {
        if (service.suspendHotReload) return;
        var trimmed = (content || "").trim();
        if (trimmed === "" && service.lastDockConfigContent === "") {
            initDockProc.running = true;
            return;
        }
        if (trimmed === "" || trimmed === service.lastDockConfigContent) return;

        try {
            applyDockConfig(JSON.parse(trimmed), trimmed);
        } catch (e) {
            Log.warn("DockDataService", "Dock config parse error: " + e);
        }
    }

    function windowQueryCommand() {
        return S.CompositorService.isHyprland
            ? ["hyprctl", "clients", "-j"]
            : ["niri", "msg", "-j", "windows"];
    }

    function normalizeRunningWindows(parsed) {
        if (!S.CompositorService.isHyprland) return parsed;

        var normalized = [];
        for (var i = 0; i < parsed.length; i++) {
            normalized.push({
                app_id: parsed[i].class || "",
                id: parsed[i].address || ""
            });
        }
        return normalized;
    }

    function persistDockState(nextPinnedApps, nextLeftModules, nextRightModules) {
        var obj = cloneDockConfig();
        obj.pinned = nextPinnedApps || [];
        obj.leftModules = nextLeftModules || [];
        obj.rightModules = nextRightModules || [];

        service.dockConfigData = obj;
        service.pinnedApps = obj.pinned;
        service.leftModules = obj.leftModules;
        service.rightModules = obj.rightModules;
        service.lastDockConfigContent = JSON.stringify(obj, null, 2);
        dockConfigStore.write(service.lastDockConfigContent);
    }

    function refreshWindows() {
        if (winProc.running) return;
        service.windowRefreshRunning = true;
        winProc.command = windowQueryCommand();
        winProc.running = true;
    }

    Process {
        id: initDockProc
        command: ["bash", service.initDockScript]
        onExited: dockConfigStore.load()
    }

    Core.JsonDataStore {
        id: dockConfigStore
        path: service.configPath
        defaultValue: ({})
        onLoadedValue: (_, rawText) => service.handleDockConfigText(rawText)
        onFailed: (phase, exitCode, details) => Log.warn("DockDataService", phase + " failed (" + exitCode + "): " + details)
    }

    Core.FileChangeWatcher {
        id: dockConfigWatcher
        path: service.configPath
        interval: 800
        active: !service.suspendHotReload
        onChanged: dockConfigStore.load()
    }

    Process {
        id: desktopIconProc
        command: ["bash", service.desktopIconScript]
        property string outputBuffer: ""
        stdout: SplitParser { onRead: data => desktopIconProc.outputBuffer += data + "\n" }
        onExited: {
            if (desktopIconProc.outputBuffer.trim() !== "") {
                try {
                    var parsed = parseDesktopMetadata(desktopIconProc.outputBuffer.trim());
                    service.desktopIcons = parsed.icons;
                    service.desktopCommands = parsed.commands;
                    service.desktopEntries = parsed.entries;
                } catch (e) {
                    Log.warn("DockDataService", "Desktop icons parse error: " + e);
                }
            }
            desktopIconProc.outputBuffer = "";
        }
        Component.onCompleted: running = true
    }

    Process {
        id: winProc
        command: service.windowQueryCommand()
        property string outputBuffer: ""
        stdout: SplitParser { onRead: data => winProc.outputBuffer += data }
        onExited: {
            if (winProc.outputBuffer.trim() !== "") {
                try {
                    service.runningWindows = service.normalizeRunningWindows(JSON.parse(winProc.outputBuffer));
                } catch (e) {
                    Log.warn("DockDataService", "Running windows parse error: " + e);
                }
            }
            winProc.outputBuffer = "";
            service.windowRefreshRunning = false;
        }
    }

    Timer {
        interval: 1500
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: service.refreshWindows()
    }

    Component.onCompleted: dockConfigStore.load()
}
