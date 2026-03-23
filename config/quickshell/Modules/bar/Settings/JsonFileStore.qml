import QtQuick
import Quickshell
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
    signal saved()
    signal failed(string phase, int exitCode)

    Process {
        id: readProc
        command: root.path.length > 0 ? ["sh", "-c", "cat \"" + root.path + "\" 2>/dev/null || true"] : []
        running: false
        stdout: SplitParser { onRead: data => { root.readBuffer += data; } }
        onExited: (exitCode) => {
            if (exitCode !== 0) {
                root.failed("read", exitCode);
            }
            root.loaded(root.readBuffer);
            root.readBuffer = "";
        }
    }

    Process {
        id: writeProc
        command: root.path.length > 0 ? ["sh", "-c", "mkdir -p \"$(dirname \"" + root.path + "\")\" && printf '%s' '" + root.pendingText.replace(/'/g, "'\\''") + "' > \"" + root.path + "\""] : []
        running: false
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.saved();
            } else {
                root.failed("write", exitCode);
            }
        }
    }

    function read() {
        if (readProc.running || root.path.length === 0) return;
        root.readBuffer = "";
        readProc.running = true;
    }

    function write(text) {
        if (writeProc.running || root.path.length === 0) return;
        root.pendingText = text;
        writeProc.running = true;
    }
}
