import QtQuick
import Quickshell

// Floating timer / stopwatch (SUPER+T). Rings and notifies when a timer ends.
ToolWindow {
    id: root
    title: stopwatch ? "Stopwatch" : "Timer"
    icon: 0xF051B
    startX: 1500; startY: 600

    property bool stopwatch: false
    property bool running: false
    property real total: 5 * 60 * 1000     // timer length (ms)
    property real elapsed: 0
    property real startedAt: 0
    property real base: 0
    readonly property real remaining: Math.max(0, total - elapsed)

    function fmt(ms) {
        const s = Math.floor(ms / 1000), h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), r = s % 60;
        const p = n => (n < 10 ? "0" : "") + n;
        return (h ? h + ":" + p(m) : p(m)) + ":" + p(r) + (stopwatch ? "." + Math.floor(ms % 1000 / 100) : "");
    }
    function start() { startedAt = Date.now(); base = elapsed; running = true; }
    function pause() { running = false; }
    function reset() { running = false; elapsed = 0; }
    function setMinutes(m) { reset(); total = m * 60000; }

    Timer {
        interval: root.stopwatch ? 100 : 250
        repeat: true
        running: root.running
        onTriggered: {
            root.elapsed = root.base + (Date.now() - root.startedAt);
            if (!root.stopwatch && root.elapsed >= root.total) {
                root.running = false;
                root.elapsed = root.total;
                Quickshell.execDetached(["sh", "-c", "notify-send -u critical -i alarm-symbolic 'Timer finished' \"$0 is up\"; pw-play ~/.local/share/sounds/notification.wav", root.fmt(root.total)]);
                if (!root.shown) root.open();
            }
        }
    }

    Column {
        spacing: 12
        width: 300

        // mode switch
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Repeater {
                model: [{ l: "Timer", sw: false }, { l: "Stopwatch", sw: true }]
                Rectangle {
                    required property var modelData
                    readonly property bool sel: root.stopwatch === modelData.sw
                    width: 110; height: 32; radius: 16
                    color: sel ? Theme.primary : Theme.surfaceHigh
                    SText { anchors.centerIn: parent; text: parent.modelData.l; font.pixelSize: 12; font.weight: Font.Bold; color: parent.sel ? Theme.fgPrimary : Theme.text }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { root.reset(); root.stopwatch = parent.modelData.sw; } }
                }
            }
        }

        // ring + time
        Item {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 200; height: 200
            Canvas {
                id: ring
                anchors.fill: parent
                readonly property real p: root.stopwatch ? (root.elapsed % 60000) / 60000 : (root.total ? root.remaining / root.total : 0)
                readonly property color fg: Theme.primary
                readonly property color bg: Theme.surfaceHighest
                onPChanged: requestPaint()
                onFgChanged: requestPaint()
                onPaint: {
                    const ctx = getContext("2d"); ctx.reset();
                    const r = width / 2 - 10;
                    ctx.lineWidth = 12; ctx.lineCap = "round";
                    ctx.strokeStyle = bg; ctx.beginPath(); ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2); ctx.stroke();
                    ctx.strokeStyle = fg; ctx.beginPath(); ctx.arc(width / 2, height / 2, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.max(0.001, p)); ctx.stroke();
                }
            }
            SText { anchors.centerIn: parent; text: root.fmt(root.stopwatch ? root.elapsed : root.remaining); font.pixelSize: root.stopwatch ? 30 : 36; font.weight: Font.Bold }
        }

        // presets (timer only)
        Row {
            visible: !root.stopwatch
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            Repeater {
                model: [1, 5, 10, 25, 45]
                Rectangle {
                    required property int modelData
                    width: 50; height: 30; radius: 15
                    color: root.total === modelData * 60000 ? Theme.secondaryContainer : (pm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh)
                    SText { anchors.centerIn: parent; text: parent.modelData + "m"; font.pixelSize: 12 }
                    MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.setMinutes(parent.modelData) }
                }
            }
        }

        // controls
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10
            Rectangle {
                width: 52; height: 52; radius: 26
                color: rm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                Icon { anchors.centerIn: parent; code: 0xF0450; size: 20 }
                MouseArea { id: rm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.reset() }
            }
            Rectangle {
                width: 96; height: 52
                radius: root.running ? 18 : 26
                Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
                color: Theme.primary
                Icon { anchors.centerIn: parent; code: root.running ? 0xF03E4 : 0xF040A; size: 24; color: Theme.fgPrimary }
                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: root.running ? root.pause() : (!root.stopwatch && root.remaining <= 0 ? (root.reset(), root.start()) : root.start())
                }
            }
            Rectangle {
                visible: !root.stopwatch
                width: 52; height: 52; radius: 26
                color: am.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
                SText { anchors.centerIn: parent; text: "+1m"; font.pixelSize: 12; font.weight: Font.Bold }
                MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.total += 60000 }
            }
        }
    }
}
