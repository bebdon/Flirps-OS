import QtQuick

// Material 3 style switch.
Rectangle {
    id: root
    property bool checked: false
    signal toggled(bool value)

    width: 54; height: 32; radius: 16
    color: checked ? Theme.primary : Theme.surfaceHighest
    border.width: checked ? 0 : 2
    border.color: Theme.outline
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        width: root.checked ? 24 : 16; height: width; radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 4 : 8
        color: root.checked ? Theme.fgPrimary : Theme.outline
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 160 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.checked)
    }
}
