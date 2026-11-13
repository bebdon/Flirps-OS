import QtQuick
import Quickshell
import Quickshell.Io

// Wallpaper rotation. Settings come from ~/.config/wallpaper.conf
// (ROTATE=on|off, ROTATE_MIN=minutes, ROTATE_ORDER=random|next, ROTATE_POOL=all|anime),
// written by the settings app. Runs `wallpaper rotate` on each tick.
Scope {
    id: root
    property bool enabled: false
    property int minutes: 30

    FileView {
        path: Quickshell.env("HOME") + "/.config/wallpaper.conf"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            const conf = {};
            for (const l of text().split("\n")) { const i = l.indexOf("="); if (i > 0) conf[l.slice(0, i).trim()] = l.slice(i + 1).trim(); }
            root.enabled = conf.ROTATE === "on";
            root.minutes = Math.max(1, parseInt(conf.ROTATE_MIN) || 30);
        }
        onLoadFailed: root.enabled = false
    }

    Timer {
        interval: root.minutes * 60 * 1000
        running: root.enabled
        repeat: true
        onTriggered: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/wallpaper", "rotate"])
    }
}
