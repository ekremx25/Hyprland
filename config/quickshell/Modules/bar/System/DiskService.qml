import QtQuick
import Quickshell.Io
import "../../../Services/core/Log.js" as Log

Item {
    id: service
    visible: false
    width: 0
    height: 0

    property var disks: []

    function refresh() {
        diskListProc.output = "";
        diskListProc.running = false;
        diskListProc.running = true;
    }

    function processDevices(devices, nextList) {
        for (var i = 0; i < devices.length; i++) {
            var dev = devices[i];
            if (dev.type === "part" || (dev.type === "disk" && !dev.children) || dev.type === "lvm") {
                nextList.push({
                    name: dev.name,
                    size: dev.size,
                    type: dev.type,
                    mountpoint: dev.mountpoint || "",
                    fstype: dev.fstype || "",
                    fsavail: dev.fsavail || "",
                    fsused: dev.fsused || "",
                    usePercent: dev["fsuse%"] || ""
                });
            }
            if (dev.children) processDevices(dev.children, nextList);
        }
    }

    Process {
        id: diskListProc
        property string output: ""
        command: ["lsblk", "-J", "-o", "NAME,SIZE,TYPE,MOUNTPOINT,FSTYPE,FSAVAIL,FSUSED,FSUSE%"]
        stdout: SplitParser { onRead: data => diskListProc.output += data }
        onExited: {
            try {
                if (diskListProc.output.trim() === "") return;
                var json = JSON.parse(diskListProc.output);
                var nextList = [];
                if (json.blockdevices) processDevices(json.blockdevices, nextList);
                service.disks = nextList;
            } catch (e) {
                Log.warn("DiskService", "JSON parse error: " + e);
            }
            diskListProc.output = "";
        }
    }

    Component.onCompleted: refresh()
}
