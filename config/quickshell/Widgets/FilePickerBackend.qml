import QtQuick
import Qt.labs.platform
import Quickshell.Io
import "../Services/core/Log.js" as Log

Item {
    id: backend

    visible: false
    width: 0
    height: 0

    property string currentPath: StandardPaths.writableLocation(StandardPaths.HomeLocation).toString().replace("file://", "")
    property var extensions: []
    property var directoryEntries: []

    function refresh() {
        if (lsProcess.running) return;
        lsProcess.buf = "";
        lsProcess.command = ["ls", "-1", "-p", "--group-directories-first", backend.currentPath];
        lsProcess.running = true;
    }

    function getParentPath(path) {
        if (path === "/") return "/";
        var parts = path.split("/");
        parts.pop();
        var parent = parts.join("/");
        return parent === "" ? "/" : parent;
    }

    function canIncludeFile(name) {
        if (backend.extensions.length === 0) return true;
        var ext = name.split(".").pop().toLowerCase();
        for (var i = 0; i < backend.extensions.length; i++) {
            if (String(backend.extensions[i]).toLowerCase() === ext) return true;
        }
        return false;
    }

    function parseDirectoryEntries(output) {
        var lines = String(output || "").split("\n");
        var entries = [];

        if (backend.currentPath !== "/") {
            entries.push({ name: "..", isDir: true, path: getParentPath(backend.currentPath) });
        }

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim();
            if (line === "") continue;

            var isDir = line.endsWith("/");
            var name = isDir ? line.slice(0, -1) : line;
            var fullPath = (backend.currentPath === "/" ? "" : backend.currentPath) + "/" + name;
            if (!isDir && !canIncludeFile(name)) continue;
            entries.push({ name: name, isDir: isDir, path: fullPath });
        }

        backend.directoryEntries = entries;
    }

    function openEntry(entry) {
        if (!entry || !entry.isDir) return;
        backend.currentPath = entry.name === ".." ? entry.path : ((backend.currentPath === "/" ? "" : backend.currentPath) + "/" + entry.name);
        refresh();
    }

    Process {
        id: lsProcess
        command: []
        property string buf: ""
        stdout: SplitParser { onRead: data => { lsProcess.buf += data + "\n"; } }
        onExited: {
            try {
                backend.parseDirectoryEntries(lsProcess.buf);
            } catch (e) {
                Log.warn("FilePickerBackend", "Directory parse error: " + e);
            }
            lsProcess.buf = "";
        }
    }

    onCurrentPathChanged: refresh()
    onExtensionsChanged: refresh()

    Component.onCompleted: refresh()
}
