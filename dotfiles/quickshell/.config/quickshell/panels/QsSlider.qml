import QtQuick

// Thick Material slider with an icon button (mute) on the left. Reports changes live.
Item {
    id: root
    property int icon
    property real value: 0          // 0..1
    property bool muted: false
    property bool expandable: false     // round chevron button on the right
    property bool expanded: false
    signal moved(real value)
    signal iconClicked()
    signal expandClicked()

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
        anchors.right: chev.visible ? chev.left : parent.right
        anchors.rightMargin: chev.visible ? 10 : 0
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

    Rectangle {
        id: chev
        visible: root.expandable
        anchors.right: parent.right
        width: 48; height: 48; radius: 24
        color: root.expanded ? Theme.secondaryContainer : chm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh
        Icon {
            anchors.centerIn: parent; code: 0xF0142; size: 20
            color: root.expanded ? Theme.fgSecondaryContainer : Theme.text
            rotation: root.expanded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 160 } }
        }
        MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expandClicked() }
    }
}
