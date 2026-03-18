import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string path: ""
    property string readBuffer: ""
    property string pendingText: ""

    signal loaded(string text)
    signal saved(string text)
    signal failed(string phase, int exitCode, string details)

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    function read() {
        if (root.path.length === 0 || readProc.running) return;
        root.readBuffer = "";
        readProc.running = true;
    }

    function write(text) {
        if (root.path.length === 0) return;
        root.pendingText = text;
        if (writeProc.running) writeProc.running = false;
        writeProc.running = true;
    }

    Process {
        id: readProc
        command: root.path.length > 0 ? ["sh", "-c", "cat " + root.shellQuote(root.path) + " 2>/dev/null || true"] : []
        running: false
        stdout: SplitParser { onRead: data => { root.readBuffer += data; } }
        onExited: exitCode => {
            if (exitCode !== 0) {
                root.failed("read", exitCode, "");
            }
            root.loaded(root.readBuffer);
            root.readBuffer = "";
        }
    }

    Process {
        id: writeProc
        command: root.path.length > 0 ? [
            "sh",
            "-c",
            "mkdir -p \"$(dirname " + root.shellQuote(root.path) + ")\" && printf '%s' " + root.shellQuote(root.pendingText) + " > " + root.shellQuote(root.path)
        ] : []
        running: false
        onExited: exitCode => {
            if (exitCode === 0) {
                root.saved(root.pendingText);
            } else {
                root.failed("write", exitCode, "");
            }
        }
    }
}
