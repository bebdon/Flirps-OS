import QtQuick
import Quickshell
import Quickshell.Wayland

// Small draggable floating card (calculator / timer / notes). Drag by the header.
PanelWindow {
    id: root
    property string title
    property int icon
    property real startX: 200
    property real startY: 120
    default property alias content: body.data
    property bool shown: false

    visible: false
    color: "transparent"
    anchors { top: true; left: true }
    margins { left: startX; top: startY }
    implicitWidth: card.width
    implicitHeight: card.height
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-tool"

    function open() { closeTimer.stop(); visible = true; shown = true; opened(); }
    function close() { shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }
    signal opened()
    Timer { id: closeTimer; interval: 170; onTriggered: root.visible = false }

    Rectangle {
        id: card
        width: body.childrenRect.width + 28
        height: header.height + body.childrenRect.height + 30
        radius: 24
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.94)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.94
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

        Item {
            id: header
            width: parent.width; height: 44
            Icon { x: 18; anchors.verticalCenter: parent.verticalCenter; code: root.icon; size: 16; color: Theme.primary }
            SText { x: 44; anchors.verticalCenter: parent.verticalCenter; text: root.title; font.weight: Font.Bold; font.pixelSize: 13 }
            MouseArea {
                anchors.fill: parent
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                property real px: 0
                property real py: 0
                onPressed: m => { px = m.x; py = m.y; }
                onPositionChanged: m => {
                    if (!pressed) return;
                    root.margins.left = Math.max(0, root.margins.left + m.x - px);
                    root.margins.top = Math.max(0, root.margins.top + m.y - py);
                }
            }
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 30; height: 30; radius: 15
                color: xm.containsMouse ? Theme.surfaceHigh : "transparent"
                Icon { anchors.centerIn: parent; code: 0xF0156; size: 16 }
                MouseArea { id: xm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.close() }
            }
        }
        Item {
            id: body
            x: 14; y: header.height + 2
            width: childrenRect.width; height: childrenRect.height
        }
    }
}
