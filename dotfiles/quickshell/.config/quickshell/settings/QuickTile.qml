import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root
    property int icon
    property string title
    property string subtitle
    property bool on: false
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 84
    radius: 26
    color: on ? Theme.primary : Theme.surfaceHigh
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: badge
        anchors.left: parent.left; anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: 52; height: 52; radius: 26
        color: root.on ? Qt.rgba(Theme.fgPrimary.r, Theme.fgPrimary.g, Theme.fgPrimary.b, 0.15) : Theme.surfaceHighest
        Icon { anchors.centerIn: parent; code: root.icon; size: 22; color: root.on ? Theme.fgPrimary : Theme.text }
    }
    Column {
        anchors.left: badge.right; anchors.leftMargin: 14
        anchors.right: parent.right; anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        SText { width: parent.width; text: root.title; font.weight: Font.Bold; color: root.on ? Theme.fgPrimary : Theme.text }
        SText { width: parent.width; text: root.subtitle; font.pixelSize: 12; color: root.on ? Theme.fgPrimary : Theme.subtext; opacity: 0.85 }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
