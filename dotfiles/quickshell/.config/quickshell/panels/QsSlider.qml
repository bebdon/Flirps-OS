import QtQuick

// Thick Material slider with an icon button (mute) on the left. Reports changes live.
Item {
    id: root
    property int icon
    property real value: 0          // 0..1
    property bool muted: false
    signal moved(real value)
    signal iconClicked()

    height: 48

    Rectangle {
        id: btn
        width: 48; height: 48; radius: 24
        color: root.muted ? Theme.surfaceHighest : Theme.surfaceHigh
        Icon { anchors.centerIn: parent; code: root.icon; size: 20; color: root.muted ? Theme.subtext : Theme.text }
        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.iconClicked() }
    }

    Rectangle {
        id: track
        anchors.left: btn.right; anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 40; radius: 20
        color: Theme.surfaceHigh

        Rectangle {
            readonly property real v: drag.pressed ? drag.live : root.value
            width: Math.max(height, v * parent.width)
            height: parent.height; radius: 20
            color: root.muted ? Theme.outline : Theme.primary
            Behavior on width { enabled: !drag.pressed; NumberAnimation { duration: 120 } }
        }
        SText {
            anchors.right: parent.right; anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((drag.pressed ? drag.live : root.value) * 100) + "%"
            font.pixelSize: 12; font.weight: Font.Bold
            color: ((drag.pressed ? drag.live : root.value) > 0.85 && !root.muted ? Theme.fgPrimary : Theme.subtext)
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
}
