import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// On-screen popup for Caps Lock / Num Lock / Scroll Lock and keyboard layout changes.
// Lock keys trigger `qs -c panels ipc call osd locks` from non-consuming Hyprland binds;
// layout changes come straight from Hyprland's event stream.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { bottom: true }
    margins { bottom: 120 }
    implicitWidth: pill.width + 20
    implicitHeight: pill.height + 20
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-osd"
    mask: Region {}                 // never steals clicks

    property bool shown: false
    property int icon: 0
    property string title: ""
    property string detail: ""
    property bool on: false
    property var last: ({})

    function show(ic, t, d, isOn) {
        icon = ic; title = t; detail = d; on = isOn;
        hideTimer.restart();
        closeTimer.stop();
        visible = true;
        shown = true;
        bump.restart();
    }
    function checkLocks() { if (!reader.running) reader.running = true; }

    Timer { id: hideTimer; interval: 1400; onTriggered: { root.shown = false; closeTimer.restart(); } }
    Timer { id: closeTimer; interval: 220; onTriggered: root.visible = false }

    // read the real lock state (a few ms after the key, so the LED has flipped)
    Timer { id: delay; interval: 60; onTriggered: root.checkLocks() }
    Process {
        id: reader
        command: ["hyprctl", "devices", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let kb;
                try { const d = JSON.parse(this.text); kb = d.keyboards.find(k => k.main) || d.keyboards[0]; } catch (e) { return; }
                if (!kb) return;
                const prev = root.last;
                root.last = { caps: kb.capsLock, num: kb.numLock };
                if (prev.caps === undefined) { root.pendingKey = ""; return; }
                if (kb.capsLock !== prev.caps || root.pendingKey === "caps")
                    root.show(0xF0632, "Caps Lock", kb.capsLock ? "On" : "Off", kb.capsLock);
                else if (kb.numLock !== prev.num || root.pendingKey === "num")
                    root.show(0xF03A0, "Num Lock", kb.numLock ? "On" : "Off", kb.numLock);
                root.pendingKey = "";
            }
        }
    }
    property string pendingKey: ""
    function locks(key) { pendingKey = key || ""; delay.restart(); }
    Component.onCompleted: checkLocks()   // remember the starting state

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const layout = event.data.split(",").slice(1).join(",");
            if (layout) root.show(0xF030C, "Keyboard layout", layout, true);
        }
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: Math.max(260, row.width + 36)
        height: 64
        radius: 32
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.92)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        opacity: root.shown ? 1 : 0
        anchors.verticalCenterOffset: root.shown ? 0 : 14
        Behavior on opacity { NumberAnimation { duration: 160 } }
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 14
            Rectangle {
                id: badge
                width: 44; height: 44
                radius: root.on ? 16 : 22
                anchors.verticalCenter: parent.verticalCenter
                color: root.on ? Theme.primary : Theme.surfaceHighest
                Behavior on color { ColorAnimation { duration: 160 } }
                Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                Icon { anchors.centerIn: parent; code: root.icon; size: 22; color: root.on ? Theme.fgPrimary : Theme.subtext }
                SequentialAnimation {
                    id: bump
                    NumberAnimation { target: badge; property: "scale"; to: 1.15; duration: 90; easing.type: Easing.OutQuad }
                    NumberAnimation { target: badge; property: "scale"; to: 1.0; duration: 200; easing.type: Easing.OutBack }
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                SText { text: root.title; font.pixelSize: 14; font.weight: Font.Bold }
                SText { text: root.detail; font.pixelSize: 12; color: root.on ? Theme.primary : Theme.subtext }
            }
        }
    }
}
