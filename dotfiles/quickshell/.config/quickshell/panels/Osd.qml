import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// On-screen popup for volume, microphone, brightness, Caps Lock / Num Lock and keyboard layout.
// Volume and mic changes come straight from PipeWire (whatever changed them);
// brightness keys run brightnessctl, then `qs -c panels ipc call osd brightness`;
// lock keys trigger `qs -c panels ipc call osd locks` from non-consuming Hyprland binds;
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
    property real level: -1          // 0..1 shows a level bar; -1 hides it
    property var last: ({})

    function show(ic, t, d, isOn, lvl) {
        icon = ic; title = t; detail = d; on = isOn;
        level = (lvl === undefined) ? -1 : lvl;
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

    // PipeWire reports the starting volume once at startup; don't pop up for that.
    property bool ready: false
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    function volumeOsd() {
        if (!ready || !Audio.sink) return;
        const v = Audio.volume;
        const ic = Audio.muted ? 0xF075F : v > 0.5 ? 0xF057E : v > 0.15 ? 0xF0580 : 0xF057F;
        show(ic, "Volume", Audio.muted ? "Muted" : Math.round(v * 100) + "%", !Audio.muted, Audio.muted ? 0 : v);
    }
    function brightness() { wantBrightness = true; Brightness.refresh(); }
    property bool wantBrightness: false

    Connections {
        target: Audio
        function onVolumeChanged() { root.volumeOsd(); }
        function onMutedChanged() { root.volumeOsd(); }
        function onMicMutedChanged() {
            if (!root.ready || !Audio.source) return;
            root.show(Audio.micMuted ? 0xF036D : 0xF036C, "Microphone", Audio.micMuted ? "Muted" : "On", !Audio.micMuted);
        }
    }
    Connections {
        target: Brightness
        function onRefreshed() {
            if (!root.wantBrightness) return;
            root.wantBrightness = false;
            root.show(0xF00DF, "Brightness", Math.round(Brightness.value * 100) + "%", true, Brightness.value);
        }
    }

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
                Row {
                    spacing: 10
                    Rectangle {
                        visible: root.level >= 0
                        anchors.verticalCenter: parent.verticalCenter
                        width: 140; height: 6; radius: 3
                        color: Theme.surfaceHighest
                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, root.level))
                            height: parent.height; radius: 3
                            color: root.on ? Theme.primary : Theme.subtext
                            Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }
                    }
                    SText { text: root.detail; font.pixelSize: 12; color: root.on ? Theme.primary : Theme.subtext }
                }
            }
        }
    }
}
