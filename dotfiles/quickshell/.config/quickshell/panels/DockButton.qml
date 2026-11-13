import QtQuick
import Quickshell

// One dock button, laid out like nwg-dock: padding 4, icon, then the running-indicator image
// (single / multiple dots). Focused app: 2px primary line along the bottom. Hover: primary @ 15%.
// Left click: launch, focus, or cycle through the app's windows. Middle: new window. Right: menu.
Item {
    id: btn
    property string appId: ""
    property var wins: []
    property var entry: null
    property bool pinned: false
    property bool launcher: false
    property int iconSize: 44
    property bool vertical: false
    property string edge: "bottom"
    property bool menuOpen: menu.visible
    readonly property bool running: wins.length > 0
    readonly property bool active: wins.some(w => w.activated)
    // nwg-dock draws its 48x9 indicator image at half the icon width, in a 7px slot under the icon
    readonly property int indicator: Math.round(iconSize * 7 / 44)
    readonly property real indLong: iconSize / 2
    readonly property real indShort: indLong * 9 / 48
    signal launch()
    signal focused()
    signal togglePin()

    implicitWidth: vertical ? iconSize + indicator + 8 : iconSize + 8
    implicitHeight: vertical ? iconSize + 8 : iconSize + indicator + 8

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: ma.containsMouse || menu.visible ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
    }

    Image {
        id: icon
        x: btn.vertical && btn.edge === "right" ? 4 + btn.indicator : 4
        y: !btn.vertical && btn.edge === "top" ? 4 + btn.indicator : 4
        width: btn.iconSize; height: btn.iconSize
        sourceSize: Qt.size(btn.iconSize * 2, btn.iconSize * 2)
        source: btn.launcher ? Qt.resolvedUrl("dock/grid.svg")
              : btn.entry && btn.entry.icon ? Quickshell.iconPath(btn.entry.icon, "application-x-executable")
              : Quickshell.iconPath(btn.appId.toLowerCase(), "application-x-executable")
        asynchronous: true
    }

    // running indicator, between icon and the dock's outer edge
    Image {
        visible: btn.running
        width: btn.vertical ? btn.indShort : btn.indLong
        height: btn.vertical ? btn.indLong : btn.indShort
        x: btn.vertical ? (btn.edge === "right" ? 4 + btn.indicator - 3.5 - width : 4 + btn.iconSize + 3.5) : 4 + (btn.iconSize - width) / 2
        y: btn.vertical ? 4 + (btn.iconSize - height) / 2 : (btn.edge === "top" ? 4 + btn.indicator - 3.5 - height : 4 + btn.iconSize + 3.5)
        sourceSize: Qt.size(width * 2, height * 2)
        source: Qt.resolvedUrl("dock/task-" + (btn.wins.length > 1 ? "multiple" : "single") + (btn.vertical ? "-vertical" : "") + ".svg")
    }

    // focused app: 2px primary line along the bottom (nwg-dock's #active border-bottom)
    Rectangle {
        visible: btn.active
        color: Theme.primary
        width: parent.width; height: 2
        y: parent.height - 2
    }

    MouseArea {
        id: ma
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: m => {
            if (btn.launcher) { btn.launch(); return; }
            if (m.button === Qt.RightButton) { menu.visible = !menu.visible; return; }
            if (m.button === Qt.MiddleButton || !btn.running) { btn.launch(); return; }
            // focus; if one of its windows is already focused, go to the next one
            const i = btn.wins.findIndex(w => w.activated);
            btn.wins[(i + 1) % btn.wins.length].activate();
            btn.focused();
        }
    }

    BarTooltip {
        target: btn
        edge: btn.edge
        text: btn.launcher ? "Applications" : btn.entry ? btn.entry.name : btn.appId
        hovered: ma.containsMouse && !menu.visible
    }

    // right-click menu, styled like the tooltips
    PopupWindow {
        id: menu
        visible: false
        color: "transparent"
        anchor.item: btn
        anchor.rect.x: btn.edge === "left" ? 8 : btn.edge === "right" ? -8 : 0
        anchor.rect.y: btn.edge === "top" ? 8 : btn.edge === "bottom" ? -8 : 0
        anchor.rect.width: btn.width
        anchor.rect.height: btn.height
        anchor.edges: btn.edge === "top" ? Edges.Bottom : btn.edge === "bottom" ? Edges.Top : btn.edge === "left" ? Edges.Right : Edges.Left
        anchor.gravity: anchor.edges
        implicitWidth: menuBox.width
        implicitHeight: menuBox.height

        readonly property var items: [
            { label: "New window", act: () => btn.launch() },
            { label: btn.pinned ? "Unpin" : "Pin", act: () => btn.togglePin() }
        ].concat(btn.running ? [{ label: btn.wins.length > 1 ? "Close all windows" : "Close window", act: () => btn.wins.slice().forEach(w => w.close()) }] : [])

        Rectangle {
            id: menuBox
            width: 180
            height: col.implicitHeight + 12
            radius: 10
            color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.95)
            border.width: 1
            border.color: Theme.outlineVariant
            HoverHandler { id: menuHover; onHoveredChanged: if (!hovered) menuClose.restart(); else menuClose.stop() }
            Timer { id: menuClose; interval: 600; onTriggered: menu.visible = false }
            Column {
                id: col
                x: 6; y: 6
                width: parent.width - 12
                Repeater {
                    model: menu.items.length
                    Rectangle {
                        required property int index
                        width: col.width; height: 32; radius: 8
                        color: im.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                        Text {
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            text: menu.items[parent.index].label
                            font.family: Theme.font; font.pixelSize: 13; color: Theme.text
                        }
                        MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { menu.items[parent.index].act(); menu.visible = false; } }
                    }
                }
            }
        }
    }
}
