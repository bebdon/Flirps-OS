import QtQuick

// Positions one desktop widget from widgets.json (x/y are fractions of the screen)
// and makes it draggable in edit mode.
Item {
    id: root
    required property string name
    required property var desk
    property bool card: false
    default property alias content: inner.data
    readonly property var conf: desk.w(name)
    readonly property bool isOn: conf.enabled === true

    visible: isOn
    width: inner.childrenRect.width + (card ? 40 : 0)
    height: inner.childrenRect.height + (card ? 36 : 0)
    function bindPos() {
        x = Qt.binding(() => (conf.x !== undefined ? conf.x : 0.05) * (parent.width - width));
        y = Qt.binding(() => (conf.y !== undefined ? conf.y : 0.1) * (parent.height - height));
    }

    opacity: 0
    Component.onCompleted: { bindPos(); fadeIn.start(); }
    NumberAnimation { id: fadeIn; target: root; property: "opacity"; to: 1; duration: 500; easing.type: Easing.OutCubic }

    Rectangle {
        anchors.fill: parent
        visible: root.card
        radius: 26
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.72)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.5)
    }
    Rectangle {
        anchors.fill: parent; anchors.margins: -6
        visible: root.desk.editing
        radius: 30
        color: "transparent"
        border.width: 2
        border.color: Theme.primary
    }

    Item {
        id: inner
        x: root.card ? 20 : 0
        y: root.card ? 18 : 0
        width: childrenRect.width
        height: childrenRect.height
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        visible: root.desk.editing
        cursorShape: Qt.SizeAllCursor
        drag.target: root
        drag.axis: Drag.XAndYAxis
        drag.minimumX: 0; drag.maximumX: root.parent.width - root.width
        drag.minimumY: 0; drag.maximumY: root.parent.height - root.height
        onReleased: {
            root.desk.setPos(root.name, root.x / Math.max(1, root.parent.width - root.width), root.y / Math.max(1, root.parent.height - root.height));
            root.bindPos();
        }
    }
}
