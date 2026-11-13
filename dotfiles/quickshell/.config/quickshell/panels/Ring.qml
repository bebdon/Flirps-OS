import QtQuick

// Small circular gauge (repaints only when the value changes).
Item {
    id: root
    property real value: 0
    property string label
    property string text
    property color color: Theme.primary
    width: 84; height: 104

    Canvas {
        id: c
        width: 84; height: 84
        readonly property real v: root.value
        readonly property color track: Theme.surfaceHighest
        readonly property color fg: root.color
        onVChanged: requestPaint()
        onFgChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = width / 2 - 6, cx = width / 2, cy = height / 2;
            const a0 = Math.PI * 0.75, span = Math.PI * 1.5;
            ctx.lineCap = "round";
            ctx.lineWidth = 8;
            ctx.strokeStyle = track;
            ctx.beginPath(); ctx.arc(cx, cy, r, a0, a0 + span); ctx.stroke();
            ctx.strokeStyle = fg;
            ctx.beginPath(); ctx.arc(cx, cy, r, a0, a0 + span * Math.max(0.001, Math.min(1, v))); ctx.stroke();
        }
    }
    SText { anchors.centerIn: c; text: root.text; font.pixelSize: 15; font.weight: Font.Bold }
    SText { anchors.horizontalCenter: c.horizontalCenter; anchors.top: c.bottom; anchors.topMargin: -6; text: root.label; dim: true; font.pixelSize: 11 }
}
