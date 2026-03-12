import QtQuick
import Qt.labs.platform
import Quickshell
import "../../Services" as S
import "../../Services/core" as Core
import "../../Services/core/Log.js" as Log

Item {
    id: backend

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
    property bool isVertical: barPosition === "left" || barPosition === "right"
    property var workspacesConfig: barLayout.workspaces || { format: "arabic", style: "fill", transparent: false }
    property bool configLoaded: false
    readonly property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/bar_config.json"
    property string lastConfigContent: ""

    function normalizeLayout(cfg) {
        if (!cfg.workspaces) {
            cfg.workspaces = { format: "arabic", style: "fill", transparent: false };
        }
        return cfg;
    }

    function applyConfig(cfg) {
        var normalized = normalizeLayout(cfg);
        if (normalized.barPosition) {
            backend.barPosition = normalized.barPosition;
        }
        backend.barLayout = normalized;
        backend.workspacesConfig = normalized.workspaces;
        backend.configLoaded = true;
        if (normalized.theme && normalized.theme.name) {
            Theme.setTheme(normalized.theme.name);
        }
    }

    function refreshConfig() {
        configStore.load();
    }

    Component.onCompleted: backend.refreshConfig()

    Core.JsonDataStore {
        id: configStore
        path: backend.configPath
        defaultValue: backend.barLayout
        onLoadedValue: function(cfg, rawText) {
            var content = rawText.trim();
            if (content.length === 0) return;
            if (content === backend.lastConfigContent && backend.configLoaded) return;
            backend.lastConfigContent = content;
            backend.applyConfig(cfg);
        }
        onFailed: function(phase, exitCode, details) {
            if (phase === "parse") Log.warn("BarBackend", "Config parse error: " + details);
        }
    }

    Core.FileChangeWatcher {
        path: backend.configPath
        interval: 500
        onChanged: backend.refreshConfig()
    }
}
