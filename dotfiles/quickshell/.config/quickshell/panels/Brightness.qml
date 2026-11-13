pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen brightness through brightnessctl. Writes are rate-limited.
Singleton {
    id: root
    property real value: 0.5          // 0..1
    property real pending: -1
    signal refreshed()                // after every read, even if the value didn't change

    function refresh() { if (!reader.running) reader.running = true; }
    function set(v) {
        value = Math.max(0.01, Math.min(1, v));
        pending = value;
        if (!writeTimer.running) writeTimer.start();
    }

    Process {
        id: reader
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.split(",");   // name,class,current,percent,max
                if (p.length >= 5) root.value = Number(p[2]) / Number(p[4]);
                root.refreshed();
            }
        }
    }
    Timer {
        id: writeTimer
        interval: 60
        onTriggered: {
            if (root.pending < 0) return;
            Quickshell.execDetached(["brightnessctl", "-q", "s", Math.round(root.pending * 100) + "%"]);
            root.pending = -1;
        }
    }
    Component.onCompleted: refresh()
}
