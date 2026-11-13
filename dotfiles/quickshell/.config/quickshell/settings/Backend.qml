pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Talks to scripts/ctl.sh, which reads and edits the real config files.
Singleton {
    id: root

    property var s: ({})
    property bool ready: false
    readonly property string home: Quickshell.env("HOME")
    readonly property string ctl: Quickshell.env("HOME") + "/.config/quickshell/settings/scripts/ctl.sh"
    property var queue: []

    function get(section, key, fallback) {
        const sec = s[section];
        return (sec && sec[key] !== undefined) ? sec[key] : fallback;
    }

    function refresh() {
        if (!stateProc.running) stateProc.running = true;
    }

    // Update the UI right away, then write the change in the background.
    function set(section, key, value) {
        const n = JSON.parse(JSON.stringify(s));
        if (!n[section]) n[section] = {};
        n[section][key] = value;
        s = n;
        queue = queue.concat([[ctl, "set", section, key, String(value)]]);
        runNext();
    }

    function runNext() {
        if (setProc.running) return;
        if (queue.length === 0) { refresh(); return; }
        setProc.command = queue[0];
        queue = queue.slice(1);
        setProc.running = true;
    }

    Process {
        id: stateProc
        command: [root.ctl, "state"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.s = JSON.parse(this.text); root.ready = true; }
                catch (e) { console.warn("settings: bad state JSON", e); }
            }
        }
    }

    Process {
        id: setProc
        onExited: root.runNext()
    }

    Component.onCompleted: refresh()
}
