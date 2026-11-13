import QtQuick
import Quickshell

// Hover tooltip under a bar module, styled like the old waybar tooltips:
// surface_container @ 95%, 1px outline_variant, radius 10.
PopupWindow {
    id: tip
    required property Item target
    property string text: ""
    property Component content: null          // optional custom content instead of text
    property bool hovered: false

    visible: hovered && (text !== "" || content !== null) && delay.done
    color: "transparent"
    anchor.item: target
    anchor.rect.x: (target.width - implicitWidth) / 2
    anchor.rect.y: BarCfg.position === "bottom" ? -implicitHeight - 8 : target.height + 8
    implicitWidth: box.width
    implicitHeight: box.height

    onHoveredChanged: { delay.done = false; if (hovered) delay.restart(); else delay.stop(); }
    Timer { id: delay; property bool done: false; interval: 500; onTriggered: done = true }
    Component.onCompleted: if (hovered) delay.restart()

    Rectangle {
        id: box
        width: inner.implicitWidth + 20
        height: inner.implicitHeight + 14
        radius: 10
        color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.95)
        border.width: 1
        border.color: Theme.outlineVariant
        Loader {
            id: inner
            x: 10; y: 7
            sourceComponent: tip.content !== null ? tip.content : textComp
        }
        Component {
            id: textComp
            Text {
                text: tip.text
                font.family: Theme.font; font.pixelSize: 13
                color: Theme.text
                lineHeight: 1.1
            }
        }
    }
}
