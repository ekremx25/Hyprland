import QtQuick
import Quickshell.Io
import "../../../Services/core" as Core

Item {
    id: service
    visible: false
    width: 0
    height: 0

    signal triggerDetected()

    readonly property string triggerPath: Core.PathService.runtimePath("qs_vpn_open")
    readonly property string refreshTriggerPath: Core.PathService.runtimePath("qs_vpn_refresh")

    function notifyNetworkRefresh() {
        refreshTriggerProc.running = true;
    }

    Timer {
        id: triggerWatcher
        interval: 600
        running: true
        repeat: true
        onTriggered: {
            triggerCheckProc.running = false;
            triggerCheckProc.running = true;
        }
    }

    Process {
        id: triggerCheckProc
        command: ["/usr/bin/test", "-f", service.triggerPath]
        onExited: function(exitCode) {
            if (exitCode === 0) {
                triggerRemoveProc.running = true;
                service.triggerDetected();
            }
        }
    }

    Process {
        id: triggerRemoveProc
        command: ["/usr/bin/rm", "-f", service.triggerPath]
    }

    Process {
        id: refreshTriggerProc
        command: ["/usr/bin/touch", service.refreshTriggerPath]
    }
}
