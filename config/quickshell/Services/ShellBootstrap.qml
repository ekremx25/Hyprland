import QtQuick
import Quickshell.Io
import Quickshell

Item {
    id: root

    visible: false
    width: 0
    height: 0

    readonly property string homeDir: Quickshell.env("HOME") || ""
    readonly property string monitorScriptPath: homeDir + "/.config/quickshell/scripts/apply_monitors.sh"

    Timer {
        id: monitorApplyDelay
        interval: 2000
        running: true
        repeat: false
        onTriggered: monitorApplyProc.running = true
    }

    Process {
        id: monitorApplyProc
        command: [root.monitorScriptPath]
        running: false
    }
}
