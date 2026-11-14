import QtQuick
import Quickshell
import Quickshell.Wayland

// Right-click menu on the empty desktop. Same exclusion as the desktop layer, so the
// click position from Desktop.qml lines up. A click anywhere else, or Esc, closes it.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-desktop-menu"

    signal wallpapers()
    signal editWidgets()
    signal shortcuts()

    property real px: 0
    property real py: 0
    property int current: -1

    readonly property var items: [
        { label: "Open terminal",    icon: 0xF018D, act: () => root.run("kitty") },
        { label: "Change wallpaper", icon: 0xF02E9, act: () => root.wallpapers() },
        { label: "Shuffle wallpaper", icon: 0xF049D, act: () => root.run("~/.local/bin/wallpaper random") },
        { label: "Edit widgets",     icon: 0xF056E, act: () => root.editWidgets() },
        { sep: true },
        { label: "Keyboard shortcuts", icon: 0xF030C, act: () => root.shortcuts() },
        { label: "Settings",         icon: 0xF0493, act: () => root.run("~/.local/bin/settings") }
    ]
    readonly property var actionable: items.map((it, i) => it.sep ? -1 : i).filter(i => i >= 0)

    function openAt(x, y) {
        current = -1;
        visible = true;
        // keep the whole menu on screen
        px = Math.min(x, width - box.width - 8);
        py = Math.min(y, height - box.height - 8);
        keys.forceActiveFocus();
    }
    function close() { visible = false; }
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); }
    function pick(i) { const it = items[i]; close(); if (it && it.act) it.act(); }
    function move(d) {   // arrow keys step over the separator
        const a = actionable;
        let at = a.indexOf(current);
        if (at < 0) at = d > 0 ? -1 : 0;
        current = a[(at + d + a.length) % a.length];
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: root.close()
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onDownPressed: root.move(1)
        Keys.onUpPressed: root.move(-1)
        Keys.onTabPressed: root.move(1)
        Keys.onReturnPressed: if (root.current >= 0) root.pick(root.current)
        Keys.onEnterPressed: if (root.current >= 0) root.pick(root.current)
    }

    Rectangle {
        id: box
        x: root.px; y: root.py
        width: 230
        height: col.implicitHeight + 12
        radius: 14
        color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.96)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.8)
        MouseArea { anchors.fill: parent }   // swallow clicks between items

        Column {
            id: col
            x: 6; y: 6
            width: parent.width - 12
            Repeater {
                model: root.items
                Item {
                    id: entry
                    required property var modelData
                    required property int index
                    width: col.width
                    height: modelData.sep ? 9 : 34
                    Rectangle {
                        visible: !!entry.modelData.sep
                        anchors.verticalCenter: parent.verticalCenter
                        x: 8; width: parent.width - 16; height: 1
                        color: Theme.outlineVariant
                    }
                    Rectangle {
                        visible: !entry.modelData.sep
                        anchors.fill: parent
                        radius: 9
                        color: root.current === entry.index ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.18) : "transparent"
                        Icon {
                            x: 10; anchors.verticalCenter: parent.verticalCenter
                            code: entry.modelData.icon || 0
                            size: 16; color: Theme.primary
                        }
                        SText {
                            x: 38; anchors.verticalCenter: parent.verticalCenter
                            text: entry.modelData.label || ""
                            font.pixelSize: 13
                        }
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: root.current = entry.index
                            onClicked: root.pick(entry.index)
                        }
                    }
                }
            }
        }
    }
}
