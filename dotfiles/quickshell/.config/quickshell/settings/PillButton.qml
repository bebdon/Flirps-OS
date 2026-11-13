import QtQuick

Rectangle {
    id: root
    property string text
    property int icon: 0
    property bool filled: true
    signal clicked()

    implicitWidth: row.width + 36
    height: 42; radius: 21
    color: filled ? Theme.primary : Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85)
    opacity: mouse.pressed ? 0.8 : 1

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10
        Icon { visible: root.icon !== 0; code: root.icon; size: 17; color: root.filled ? Theme.fgPrimary : Theme.text }
        SText { text: root.text; font.weight: Font.Bold; font.pixelSize: 13; color: root.filled ? Theme.fgPrimary : Theme.text }
    }
    MouseArea { id: mouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
