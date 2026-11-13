import QtQuick
import QtQuick.Layouts

// A rounded card row: icon + title (+ description) on the left, a control on the right.
Rectangle {
    id: root
    property int icon: 0xF0493
    property string title
    property string description: ""
    default property alias control: slot.data

    Layout.fillWidth: true
    implicitHeight: Math.max(description ? 76 : 64, slot.childrenRect.height + 24)
    radius: Theme.radius
    color: Theme.surfaceLow

    Icon {
        id: ic
        anchors.left: parent.left; anchors.leftMargin: 22
        anchors.verticalCenter: parent.verticalCenter
        code: root.icon
        size: 20
        color: Theme.subtext
    }

    Column {
        anchors.left: ic.right; anchors.leftMargin: 20
        anchors.right: slot.left; anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3
        SText { width: parent.width; text: root.title; font.pixelSize: 15 }
        SText { width: parent.width; visible: text !== ""; text: root.description; dim: true; font.pixelSize: 12; wrapMode: Text.Wrap; maximumLineCount: 2 }
    }

    Item {
        id: slot
        anchors.right: parent.right; anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
