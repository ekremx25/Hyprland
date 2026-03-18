import QtQuick
import Qt.labs.platform
import "."
import "../BarDefaults.js" as BarDefaults
import "../../../Services/core" as Core
import "../../../Services/core/Log.js" as Log

Item {
    id: backend

    readonly property var initialBarConfig: BarDefaults.createBarConfig()

    property var barConfig: BarDefaults.clone(initialBarConfig)
    property var dockConfig: ({})
    property string configPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/bar_config.json"
    property string dockConfigPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/dock_config.json"
    property string customPresetPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/presets/custom.json"
    property string defaultsPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "") + "/.config/quickshell/Modules/bar/BarDefaults.js"
    property var dockLeftModulesList: []
    property var dockRightModulesList: []

    property var leftModel: null
    property var centerModel: null
    property var rightModel: null
    property var inactiveModel: null
    property var dockLeftModel: null
    property var dockRightModel: null

    readonly property var moduleInfo: ({
        "Launcher": { icon: "\ue7e6", label: "Launcher", color: "#1e66f5" },
        "Calendar": { icon: "", label: "Calendar", color: "#f5c2e7" },
        "Notepad": { icon: "󰠮", label: "Notepad", color: "#f9e2af" },
        "Workspaces": { icon: "", label: "Workspaces", color: "#cba6f7" },
        "Notifications": { icon: "󰂚", label: "Notifications", color: "#fab387" },
        "Weather": { icon: "󰖕", label: "Weather", color: "#f9e2af" },
        "Volume": { icon: "󰕾", label: "Volume", color: "#89b4fa" },
        "Equalizer": { icon: "󱞙", label: "Equalizer", color: "#89dceb" },
        "Tray": { icon: "󰇚", label: "Tray", color: "#a6adc8" },
        "Clipboard": { icon: "󰅍", label: "Clipboard", color: "#fab387" },
        "Power": { icon: "⏻", label: "Power", color: "#f38ba8" },
        "PowerGroup": { icon: "", label: "Power Group", color: "#a6e3a1" },
        "SysInfoGroup": { icon: "", label: "System Group", color: "#f9e2af" },
        "RamModule": { icon: "󰘚", label: "Memory", color: "#a6e3a1" },
        "Media": { icon: "♫", label: "Media", color: "#f5c2e7" }
    })

    readonly property var allModuleNames: [
        "Launcher", "Calendar", "Notepad",
        "Workspaces", "Notifications", "Weather", "Volume", "Equalizer",
        "Tray", "Clipboard", "Power",
        "PowerGroup", "SysInfoGroup", "RamModule", "Media"
    ]

    JsonFileStore {
        id: barConfigStore
        path: backend.configPath
        onLoaded: function(text) {
            var raw = (text || "").trim();
            if (raw === "") {
                var seeded = backend.normalizeBarConfig(BarDefaults.clone(backend.initialBarConfig));
                backend.applyBarConfig(seeded);
                barConfigStore.write(JSON.stringify(seeded, null, 2));
                customPresetStore.write(JSON.stringify(seeded, null, 2));
                defaultsStore.write(backend.renderBarDefaults(seeded));
                return;
            }

            backend.applyBarConfig(backend.parseJsonObject(text, BarDefaults.clone(backend.initialBarConfig)));
        }
    }

    JsonFileStore {
        id: dockConfigStore
        path: backend.dockConfigPath
        onLoaded: function(text) {
            backend.applyDockModuleLists(backend.parseJsonObject(text, {}));
            barConfigStore.read();
        }
    }

    JsonFileStore {
        id: customPresetStore
        path: backend.customPresetPath
    }

    Core.TextDataStore {
        id: defaultsStore
        path: backend.defaultsPath
    }

    function parseJsonObject(text, fallback) {
        var raw = (text || "").trim();
        if (raw === "") return fallback;
        try {
            return JSON.parse(raw);
        } catch (e) {
            Log.warn("SettingsBackend", "Settings parse error: " + e);
            return fallback;
        }
    }

    function renderBarDefaults(cfg) {
        var normalized = normalizeBarConfig(cfg);
        var workspaces = normalized.workspaces || BarDefaults.createWorkspacesConfig();
        var workspaceText = JSON.stringify(workspaces, null, 4).replace(/\n/g, "\n    ");

        return ".pragma library\n\n"
            + "// Fallback only. Runtime bar changes are saved to ~/.config/quickshell/bar_config.json.\n\n"
            + "function createWorkspacesConfig() {\n"
            + "    return " + workspaceText + ";\n"
            + "}\n\n"
            + "function createBarConfig() {\n"
            + "    return {\n"
            + "        left: " + JSON.stringify(normalized.left) + ",\n"
            + "        center: " + JSON.stringify(normalized.center) + ",\n"
            + "        right: " + JSON.stringify(normalized.right) + ",\n"
            + "        inactive: " + JSON.stringify(normalized.inactive) + ",\n"
            + "        workspaces: createWorkspacesConfig(),\n"
            + "        theme: " + JSON.stringify(normalized.theme || "") + ",\n"
            + "        barPosition: " + JSON.stringify(normalized.barPosition || "top") + "\n"
            + "    };\n"
            + "}\n\n"
            + "function clone(value) {\n"
            + "    return JSON.parse(JSON.stringify(value));\n"
            + "}\n";
    }

    function syncListModel(model, names) {
        if (!model) return;
        model.clear();
        for (var i = 0; i < names.length; ++i) {
            model.append({ name: names[i] });
        }
    }

    function getModelNames(model) {
        var names = [];
        if (!model) return names;
        for (var i = 0; i < model.count; ++i) {
            names.push(model.get(i).name);
        }
        return names;
    }

    function applyDockModuleLists(cfg) {
        var leftModules = cfg.leftModules || [];
        var rightModules = cfg.rightModules || [];
        syncListModel(dockLeftModel, leftModules);
        syncListModel(dockRightModel, rightModules);
        dockLeftModulesList = leftModules.slice();
        dockRightModulesList = rightModules.slice();
        dockConfig = cfg;
    }

    function normalizeBarConfig(cfg) {
        var normalized = BarDefaults.clone(cfg || initialBarConfig);
        if (!Array.isArray(normalized.left)) normalized.left = [];
        if (!Array.isArray(normalized.center)) normalized.center = [];
        if (!Array.isArray(normalized.right)) normalized.right = [];
        if (!Array.isArray(normalized.inactive)) normalized.inactive = [];
        if (!normalized.workspaces) normalized.workspaces = BarDefaults.createWorkspacesConfig();
        if (!normalized.barPosition) normalized.barPosition = initialBarConfig.barPosition || "top";

        var allDockMods = dockLeftModulesList.concat(dockRightModulesList);
        var filterDockModules = function(list) {
            var out = [];
            for (var i = 0; i < list.length; ++i) {
                if (allDockMods.indexOf(list[i]) === -1) out.push(list[i]);
            }
            return out;
        };

        normalized.left = filterDockModules(normalized.left);
        normalized.center = filterDockModules(normalized.center);
        normalized.right = filterDockModules(normalized.right);

        var cleanInactive = [];
        for (var k = 0; k < normalized.inactive.length; ++k) {
            if (allDockMods.indexOf(normalized.inactive[k]) === -1) cleanInactive.push(normalized.inactive[k]);
        }
        normalized.inactive = cleanInactive;

        var activeModules = normalized.left.concat(normalized.center).concat(normalized.right).concat(normalized.inactive).concat(allDockMods);
        for (var i = 0; i < allModuleNames.length; ++i) {
            var moduleName = allModuleNames[i];
            if (activeModules.indexOf(moduleName) === -1) normalized.inactive.push(moduleName);
        }
        return normalized;
    }

    function applyBarConfig(cfg) {
        var normalized = normalizeBarConfig(cfg);
        barConfig = normalized;
        syncListModel(leftModel, normalized.left);
        syncListModel(centerModel, normalized.center);
        syncListModel(rightModel, normalized.right);
        syncListModel(inactiveModel, normalized.inactive);
    }

    function buildBarConfigFromModels() {
        var cfg = JSON.parse(JSON.stringify(barConfig));
        cfg.left = getModelNames(leftModel);
        cfg.center = getModelNames(centerModel);
        cfg.right = getModelNames(rightModel);
        cfg.inactive = getModelNames(inactiveModel);
        return cfg;
    }

    function buildDockConfigFromModels() {
        var cfg = JSON.parse(JSON.stringify(dockConfig || {}));
        cfg.leftModules = getModelNames(dockLeftModel);
        cfg.rightModules = getModelNames(dockRightModel);
        delete cfg.modules;
        return cfg;
    }

    function loadConfig() {
        dockConfigStore.read();
    }

    function saveConfig(onSaved) {
        var cfg = buildBarConfigFromModels();
        Log.debug("SettingsBackend", "Saving config to " + configPath);
        barConfig = cfg;
        barConfigStore.write(JSON.stringify(cfg, null, 2));
        customPresetStore.write(JSON.stringify(cfg, null, 2));
        defaultsStore.write(backend.renderBarDefaults(cfg));

        var dockCfg = buildDockConfigFromModels();
        dockConfig = dockCfg;
        dockConfigStore.write(JSON.stringify(dockCfg, null, 2));

        if (onSaved) onSaved(cfg);
    }
}
