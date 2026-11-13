import QtQuick

// Thin slider with a round knob, matching the old swaync volume/backlight widgets.
Item {
    id: root
    property real value: 0               // 0..1
    signal moved(real value)

    implicitHeight: 24
    readonly property real shown: drag.pressed ? drag.live : value

    Rectangle {
        id: trough
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width; height: 4; radius: 2
        color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.15)
        Rectangle { width: parent.width * root.shown; height: parent.height; radius: 2; color: Theme.primary }
    }
    Rectangle {
        width: 20; height: 20; radius: 10
        anchors.verticalCenter: parent.verticalCenter
        x: Math.max(0, Math.min(parent.width - width, root.shown * parent.width - width / 2))
        color: "#e6e6e6"
        border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.2)
    }
    MouseArea {
        id: drag
        property real live: 0
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function upd(mx) { live = Math.max(0, Math.min(1, mx / width)); root.moved(live); }
        onPressed: m => upd(m.x)
        onPositionChanged: m => { if (pressed) upd(m.x); }
        onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
