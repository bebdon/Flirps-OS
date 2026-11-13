import QtQuick

// Pill switch matching the old swaync "Do not disturb" toggle.
Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool checked)

    width: 46; height: 25; radius: height / 2
    color: checked ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        width: 19; height: 19; radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? parent.width - width - 3 : 3
        color: Theme.text
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.toggled(!root.checked) }
}
