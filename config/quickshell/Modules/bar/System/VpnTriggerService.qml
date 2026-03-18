import QtQuick
import Quickshell.Io

Item {
    id: service
    visible: false
    width: 0
    height: 0

    signal triggerDetected()

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
        command: ["sh", "-c", "test -f /tmp/qs_vpn_open && echo 'yes' && rm /tmp/qs_vpn_open || echo 'no'"]
        property string buf: ""
        stdout: SplitParser { onRead: data => triggerCheckProc.buf = data.trim() }
        onExited: {
            if (triggerCheckProc.buf === "yes") {
                service.triggerDetected();
            }
            triggerCheckProc.buf = "";
        }
    }

    Process {
        id: refreshTriggerProc
        command: ["touch", "/tmp/qs_vpn_refresh"]
    }
}
