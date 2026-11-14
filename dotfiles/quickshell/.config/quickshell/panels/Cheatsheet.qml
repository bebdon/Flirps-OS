import QtQuick
import Quickshell
import Quickshell.Wayland

// Keyboard shortcuts overlay (SUPER+K). Esc, SUPER+K again or a click closes it.
// Keep in step with hypr/config/keybinds.lua when adding or changing binds.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-cheatsheet"

    property bool shown: false
    function open() { closeTimer.stop(); visible = true; shown = true; keys.forceActiveFocus(); }
    function close() { if (!visible) return; shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }
    Timer { id: closeTimer; interval: 160; onTriggered: root.visible = false }

    readonly property var sections: [
        { title: "Apps", binds: [
            ["Super", "D", "Launcher"],
            ["Super", "Enter", "Terminal"],
            ["Super", "F", "Browser"],
            ["Super", "E", "Files"],
            ["Super", "I", "Settings"]
        ]},
        { title: "Windows", binds: [
            ["Super", "Tab", "Overview of all windows"],
            ["Super", "Q", "Close window"],
            ["Super Shift", "F", "Float window"],
            ["Super Alt", "F", "Maximize window"],
            ["Super", "Arrows", "Move focus"],
            ["Super Ctrl", "Arrows", "Move window"],
            ["Super Shift", "Arrows", "Resize window"],
            ["Super", "1 … 0", "Go to workspace"],
            ["Super Shift", "1 … 0", "Send window to workspace"]
        ]},
        { title: "Desktop", binds: [
            ["Super", "W", "Wallpaper picker"],
            ["Super", "N", "Wi-Fi"],
            ["Super", "V", "Sound"],
            ["Super", "M", "Notifications"],
            ["Super", "C", "Clipboard history"],
            ["Super", "A", "Show or hide the bar"],
            ["Super", "L", "Lock"],
            ["Super", "R", "Restart the shell"],
            ["Super", "Space", "Play / pause media"]
        ]},
        { title: "Tools", binds: [
            ["", "Print", "Screenshot an area"],
            ["Shift", "Print", "Screenshot and edit"],
            ["Super", "Print", "Screenshot the screen"],
            ["Super Shift", "T", "Copy text from the screen"],
            ["Super", "=", "Calculator"],
            ["Super", "T", "Timer"],
            ["Super Alt", "N", "Notes"],
            ["Super", "K", "This list"]
        ]}
    ]

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onPressed: event => { if (event.key === Qt.Key_K) { root.close(); event.accepted = true; } }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 + (root.shown ? 0 : 16)
        width: grid.width + 64
        height: grid.height + 108
        radius: 28
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.92)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        opacity: root.shown ? 1 : 0
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        MouseArea { anchors.fill: parent }   // swallow clicks

        SText {
            x: 32; y: 26
            text: "Keyboard shortcuts"
            font.pixelSize: 20; font.weight: Font.Bold
        }
        SText {
            anchors.right: parent.right; anchors.rightMargin: 32; y: 32
            text: "Esc to close"
            dim: true; font.pixelSize: 12
        }

        Grid {
            id: grid
            x: 32; y: 76
            columns: 2
            columnSpacing: 40
            rowSpacing: 22

            Repeater {
                model: root.sections
                Column {
                    id: sec
                    required property var modelData
                    width: 400
                    spacing: 6
                    SText { text: sec.modelData.title; color: Theme.primary; font.weight: Font.Bold; font.pixelSize: 13 }
                    Repeater {
                        model: sec.modelData.binds
                        Item {
                            id: line
                            required property var modelData
                            width: sec.width; height: 28
                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Repeater {
                                    // "Super Shift" + "F" -> [Super] [Shift] [F]
                                    model: (line.modelData[0] ? line.modelData[0].split(" ") : []).concat([line.modelData[1]])
                                    Rectangle {
                                        required property var modelData
                                        width: Math.max(28, keyText.implicitWidth + 16); height: 24; radius: 8
                                        color: Theme.surfaceHigh
                                        border.width: 1
                                        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.8)
                                        SText { id: keyText; anchors.centerIn: parent; text: parent.modelData; font.pixelSize: 11; font.weight: Font.Bold }
                                    }
                                }
                            }
                            SText {
                                x: 200; width: parent.width - 200
                                anchors.verticalCenter: parent.verticalCenter
                                text: line.modelData[2]
                                font.pixelSize: 13
                            }
                        }
                    }
                }
            }
        }
    }
}
