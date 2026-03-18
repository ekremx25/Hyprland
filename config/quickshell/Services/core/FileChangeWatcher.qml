import QtQuick
import Quickshell.Io

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property string path: ""
    property int interval: 1000
    property bool active: true
    property string lastToken: ""

    signal changed()

    function shellQuote(text) {
        return "'" + String(text).replace(/'/g, "'\\''") + "'";
    }

    function poll() {
        if (!active || path.length === 0 || statProc.running) return;
        statProc.output = "";
        statProc.running = true;
    }

    Timer {
        id: pollTimer
        interval: root.interval
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.poll()
    }

    Process {
        id: statProc
        command: root.path.length > 0 ? [
            "sh",
            "-c",
            "test -f " + root.shellQuote(root.path) + " && stat -c %Y " + root.shellQuote(root.path) + " || echo missing"
        ] : []
        running: false
        property string output: ""
        stdout: SplitParser { onRead: data => { statProc.output += data; } }
        onExited: {
            var token = statProc.output.trim();
            statProc.output = "";
            if (token.length === 0) return;
            if (token !== root.lastToken) {
                root.lastToken = token;
                root.changed();
            }
        }
    }
}
