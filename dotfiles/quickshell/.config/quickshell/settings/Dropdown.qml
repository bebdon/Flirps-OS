import QtQuick
import QtQuick.Controls

// Pill button with a pop-out list, like the "Dashboard animation" picker.
Item {
    id: root
    property var options: []          // [{ label, value }]
    property var value
    signal picked(var value)

    width: 260; height: 44

    function labelFor(v) {
        for (const o of options) if (o.value === v) return o.label;
        return v === undefined ? "" : String(v);
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: popup.visible ? Theme.surfaceHighest : Theme.surfaceHigh
        SText {
            anchors.left: parent.left; anchors.leftMargin: 18
            anchors.right: chev.left; anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelFor(root.value)
        }
        Icon {
            id: chev
            anchors.right: parent.right; anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            code: popup.visible ? 0xF0143 : 0xF0140
            color: Theme.subtext
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: popup.visible ? popup.close() : popup.open()
        }
    }

    Popup {
        id: popup
        y: root.height + 6
        width: root.width
        padding: 6
        background: Rectangle { radius: 20; color: Theme.secondaryContainer }

        enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 120 } }

        contentItem: Column {
            spacing: 2
            Repeater {
                model: root.options
                Rectangle {
                    required property var modelData
                    readonly property bool sel: modelData.value === root.value
                    width: popup.width - 12; height: 42; radius: 21
                    color: sel ? Theme.primary
                         : hov.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.08) : "transparent"
                    SText {
                        anchors.left: parent.left; anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.label
                        color: sel ? Theme.fgPrimary : Theme.fgSecondaryContainer
                        font.weight: sel ? Font.Bold : Font.Normal
                    }
                    MouseArea {
                        id: hov
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { popup.close(); if (!parent.sel) root.picked(parent.modelData.value); }
                    }
                }
            }
        }
    }
}
