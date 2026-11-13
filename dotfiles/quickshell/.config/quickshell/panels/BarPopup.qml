import QtQuick
import Quickshell
import Quickshell.Wayland

// Base for popups that drop down from the bar. Set `align` to "left", "center" or "right".
// Click outside or press Esc to close. Slide + fade in/out.
PanelWindow {
    id: root
    default property alias content: card.data
    property string align: "right"
    property real cardWidth: 420
    property real cardHeight: card.childrenRect.height + 24
    property real barOffset: BarCfg.reserved + 6   // below the bar (height + margin) + gap
    property bool shown: false
    property string ns: "qs-popup"
    signal opened()

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: ns

    function open() { closeTimer.stop(); visible = true; shown = true; keys.forceActiveFocus(); opened(); }
    function close() { if (!visible) return; shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }

    Timer { id: closeTimer; interval: 190; onTriggered: root.visible = false }

    MouseArea { anchors.fill: parent; onClicked: root.close() }

    Item {
        id: keys
        focus: true
        Keys.onEscapePressed: root.close()
    }

    Rectangle {
        id: frame
        width: root.cardWidth
        height: root.cardHeight
        y: root.barOffset + (root.shown ? 0 : -14)
        x: root.align === "left" ? 8 : root.align === "center" ? (parent.width - width) / 2 : parent.width - width - 8
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        transformOrigin: root.align === "left" ? Item.TopLeft : root.align === "center" ? Item.Top : Item.TopRight
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 170 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        radius: 26
        clip: true
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.9)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Item {
            id: card
            x: 12; y: 12
            width: parent.width - 24
        }
    }
}
