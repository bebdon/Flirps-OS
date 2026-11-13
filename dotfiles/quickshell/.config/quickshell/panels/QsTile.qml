import QtQuick

// Quick-settings toggle tile. Optional chevron (expand) area on the right.
Rectangle {
    id: root
    property int icon
    property string title
    property string subtitle
    property bool on: false
    property bool expandable: false
    property bool expanded: false
    signal clicked()
    signal expandClicked()

    height: 66
    radius: on ? 22 : 33
    color: on ? Theme.primary : Theme.surfaceHigh
    Behavior on color { ColorAnimation { duration: 160 } }
    Behavior on radius { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

    Rectangle {
        id: badge
        anchors.left: parent.left; anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: 46; height: 46; radius: 23
        color: root.on ? Qt.rgba(Theme.fgPrimary.r, Theme.fgPrimary.g, Theme.fgPrimary.b, 0.15) : Theme.surfaceHighest
        Icon { anchors.centerIn: parent; code: root.icon; size: 20; color: root.on ? Theme.fgPrimary : Theme.text }
    }
    Column {
        anchors.left: badge.right; anchors.leftMargin: 10
        anchors.right: chev.visible ? chev.left : parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1
        SText { width: parent.width; text: root.title; font.pixelSize: 13; font.weight: Font.Bold; color: root.on ? Theme.fgPrimary : Theme.text }
        SText { width: parent.width; text: root.subtitle; font.pixelSize: 11; color: root.on ? Theme.fgPrimary : Theme.subtext; opacity: 0.85 }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
        scale: pressed ? 0.97 : 1
    }
    Rectangle {
        id: chev
        visible: root.expandable
        anchors.right: parent.right; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 34; height: 34; radius: 17
        color: chm.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.12) : "transparent"
        Icon {
            anchors.centerIn: parent
            code: 0xF0142
            rotation: root.expanded ? 90 : 0
            Behavior on rotation { NumberAnimation { duration: 180 } }
            color: root.on ? Theme.fgPrimary : Theme.subtext
        }
        MouseArea { id: chm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expandClicked() }
    }
}
