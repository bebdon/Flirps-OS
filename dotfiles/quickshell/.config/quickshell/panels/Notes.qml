pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Shared notes text for the desktop widget and the floating notes tool.
Singleton {
    id: root
    property string text: ""
    property bool loaded: false
    function save(t) { if (t === text) return; text = t; saver.restart(); }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.local/share/quickshell/notes.md"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: { if (!saver.running) root.text = text(); root.loaded = true; }
        onLoadFailed: root.loaded = true
    }
    Timer { id: saver; interval: 600; onTriggered: file.setText(root.text) }
}
