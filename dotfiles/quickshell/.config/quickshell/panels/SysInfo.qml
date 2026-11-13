pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / RAM / temperature / disk. Polls every 2 s only while `active` is true.
Singleton {
    id: root
    property bool active: false
    property real cpu: 0          // 0..1
    property real ram: 0          // 0..1
    property real ramUsedGb: 0
    property real ramTotalGb: 0
    property real temp: 0         // °C
    property real disk: 0         // 0..1
    property string diskFree: ""
    property var _prev: null

    Timer { interval: 2000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: if (!proc.running) proc.running = true }

    Process {
        id: proc
        command: ["sh", "-c", "head -1 /proc/stat; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo; for z in /sys/class/thermal/thermal_zone*; do [ \"$(cat $z/type)\" = x86_pkg_temp ] && cat $z/temp && break; done; df -P / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const l = this.text.trim().split("\n");
                // cpu  user nice system idle iowait irq softirq ...
                const c = l[0].trim().split(/\s+/).slice(1).map(Number);
                const idle = c[3] + c[4], total = c.reduce((a, b) => a + b, 0);
                if (root._prev) {
                    const dt = total - root._prev.total, di = idle - root._prev.idle;
                    if (dt > 0) root.cpu = Math.max(0, Math.min(1, 1 - di / dt));
                }
                root._prev = { total, idle };
                const kb = s => Number((s.match(/(\d+)/) || [0, 0])[1]);
                const memTotal = kb(l[1]), memAvail = kb(l[2]);
                root.ram = memTotal ? 1 - memAvail / memTotal : 0;
                root.ramTotalGb = memTotal / 1048576;
                root.ramUsedGb = (memTotal - memAvail) / 1048576;
                root.temp = Number(l[3]) / 1000 || 0;
                const d = (l[4] || "").trim().split(/\s+/);   // fs blocks used avail cap mount
                if (d.length >= 5) {
                    root.disk = Number(d[4].replace("%", "")) / 100;
                    root.diskFree = (Number(d[3]) / 1048576).toFixed(0) + " GB free";
                }
            }
        }
    }
}
