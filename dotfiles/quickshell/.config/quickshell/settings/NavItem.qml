import QtQuick

// Sidebar entry. Selected = filled primary pill like the old Serpantinum app.
Rectangle {
    id: root
    property string label
    property int icon
    property bool selected: false
    property bool child: false
    property bool expandable: false
    property bool expanded: false
    signal clicked()

    height: child ? 46 : 54
    radius: height / 2
    color: selected ? Theme.primary
         : mouse.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.07) : "transparent"
    Behavior on color { ColorAnimation { duration: 150 } }

    Rectangle {
        id: badge
        visible: root.selected
        anchors.left: parent.left; anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 16; height: width; radius: width / 2
        color: Qt.rgba(Theme.fgPrimary.r, Theme.fgPrimary.g, Theme.fgPrimary.b, 0.18)
    }

    Icon {
        id: ic
        x: root.selected ? badge.x + (badge.width - width) / 2 : 22
        anchors.verticalCenter: parent.verticalCenter
        code: root.icon
        size: root.child ? 16 : 19
        color: root.selected ? Theme.fgPrimary : Theme.text
    }

    SText {
        anchors.left: parent.left; anchors.leftMargin: root.selected ? badge.width + 20 : 56
        anchors.right: chev.left; anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        font.pixelSize: root.child ? 13 : 14
        font.weight: root.selected ? Font.Bold : Font.Normal
        color: root.selected ? Theme.fgPrimary : Theme.text
    }

    Icon {
        id: chev
        visible: root.expandable
        anchors.right: parent.right; anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        code: root.expanded ? 0xF0143 : 0xF0140
        size: 18
        color: root.selected ? Theme.fgPrimary : Theme.subtext
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
