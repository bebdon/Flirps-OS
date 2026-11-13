pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bar settings (bar.json next to this file; the settings app edits it).
Singleton {
    id: root
    readonly property string position: cfg.position
    readonly property int height: cfg.height
    readonly property int margin: cfg.margin
    property bool hidden: false                   // SUPER+A
    property bool nightlight: false               // hyprsunset running
    readonly property int reserved: hidden ? 0 : height + margin   // space the bar takes at its edge

    function refreshNightlight() { if (!nl.running) nl.running = true; }
    Process {
        id: nl
        command: ["pgrep", "-x", "hyprsunset"]
        onExited: code => root.nightlight = code === 0
    }
    Timer { interval: 5000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refreshNightlight() }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/panels/bar.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property string position: "top"
            property int height: 36
            property int margin: 6
        }
    }
}
