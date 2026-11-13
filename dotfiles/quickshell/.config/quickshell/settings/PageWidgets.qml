import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

// Desktop widgets + floating tools (all live in the "panels" Quickshell process).
Page {
    id: page
    property var cfg: ({})

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/panels/widgets.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { page.cfg = JSON.parse(text()); } catch (e) {} }
    }
    function get(w, k, d) { return cfg[w] && cfg[w][k] !== undefined ? cfg[w][k] : d; }
    function put(w, k, v) {
        const c = JSON.parse(JSON.stringify(cfg));
        if (!c[w]) c[w] = {};
        c[w][k] = v;
        cfg = c;
        file.setText(JSON.stringify(c, null, 2) + "\n");
    }
    function ipc(target, fn) { Quickshell.execDetached(["qs", "-c", "panels", "ipc", "call", target, fn]); }

    SectionTitle { text: "Desktop widgets" }
    OptionRow {
        icon: 0xF01DB; title: "Edit layout"; description: "Shows outlines so you can drag widgets around. Look at an empty workspace to see them."
        PillButton { text: "Toggle edit mode"; icon: 0xF03EB; onClicked: page.ipc("desktop", "edit") }
    }
    Repeater {
        model: [
            { id: "clock", label: "Clock", icon: 0xF0954, desc: "Big time and date" },
            { id: "weather", label: "Weather", icon: 0xF0599, desc: "Current conditions (location is on the Display page)" },
            { id: "system", label: "System usage", icon: 0xF035B, desc: "CPU, RAM, temperature and disk" },
            { id: "music", label: "Music", icon: 0xF075A, desc: "Shows while something is playing" },
            { id: "notes", label: "Notes", icon: 0xF082E, desc: "Sticky note, shared with the notes tool" }
        ]
        OptionRow {
            required property var modelData
            icon: modelData.icon; title: modelData.label; description: modelData.desc
            Toggle { checked: page.get(parent.parent.modelData.id, "enabled", false); onToggled: v => page.put(parent.parent.modelData.id, "enabled", v) }
        }
    }
    OptionRow {
        icon: 0xF0954; title: "Clock: 24-hour"
        Toggle { checked: page.get("clock", "h24", true); onToggled: v => page.put("clock", "h24", v) }
    }
    OptionRow {
        icon: 0xF0954; title: "Clock: show seconds"
        Toggle { checked: page.get("clock", "seconds", false); onToggled: v => page.put("clock", "seconds", v) }
    }

    SectionTitle { text: "Floating tools" }
    OptionRow {
        icon: 0xF00EC; title: "Calculator"; description: "SUPER + ="
        PillButton { text: "Open"; filled: false; color: Theme.surfaceHigh; onClicked: page.ipc("calculator", "toggle") }
    }
    OptionRow {
        icon: 0xF051B; title: "Timer & stopwatch"; description: "SUPER + T"
        PillButton { text: "Open"; filled: false; color: Theme.surfaceHigh; onClicked: page.ipc("timer", "toggle") }
    }
    OptionRow {
        icon: 0xF082E; title: "Notes"; description: "SUPER + ALT + N"
        PillButton { text: "Open"; filled: false; color: Theme.surfaceHigh; onClicked: page.ipc("notes", "toggle") }
    }
}
