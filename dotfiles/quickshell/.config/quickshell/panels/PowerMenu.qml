import QtQuick
import Quickshell
import Quickshell.Wayland

// Power menu (bar power button). ←/→ to move, Enter to pick, or press the letter shown.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-power"

    property int current: 0

    readonly property var actions: [
        { label: "Lock",      key: "L", icon: 0xF033E, cmd: "loginctl lock-session" },
        { label: "Suspend",   key: "S", icon: 0xF0904, cmd: "systemctl suspend" },
        { label: "Log out",   key: "E", icon: 0xF0343, cmd: "loginctl terminate-session \"$XDG_SESSION_ID\"" },
        { label: "Reboot",    key: "R", icon: 0xF0709, cmd: "systemctl reboot" },
        { label: "Shut down", key: "P", icon: 0xF0425, cmd: "systemctl poweroff" }
    ]

    function open() { current = 0; visible = true; keys.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }
    function run(i) {
        close();
        Quickshell.execDetached(["sh", "-c", "sleep 0.15; " + actions[i].cmd]);
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: root.close()
        Keys.onLeftPressed: root.current = (root.current + root.actions.length - 1) % root.actions.length
        Keys.onRightPressed: root.current = (root.current + 1) % root.actions.length
        Keys.onTabPressed: root.current = (root.current + 1) % root.actions.length
        Keys.onReturnPressed: root.run(root.current)
        Keys.onEnterPressed: root.run(root.current)
        Keys.onPressed: event => {
            for (let i = 0; i < root.actions.length; i++)
                if (event.text.toUpperCase() === root.actions[i].key) { root.run(i); event.accepted = true; return; }
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: row.width + 40
        height: row.height + 76
        radius: 32
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)

        scale: root.visible ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }

        SText {
            anchors.top: parent.top; anchors.topMargin: 18
            anchors.horizontalCenter: parent.horizontalCenter
            text: Brand.name + "  ·  Goodbye, " + Quickshell.env("USER")
            font.pixelSize: 15; font.weight: Font.Bold
            color: Theme.subtext
        }

        Row {
            id: row
            anchors.bottom: parent.bottom; anchors.bottomMargin: 20
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Repeater {
                model: root.actions
                Rectangle {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool sel: index === root.current
                    width: 128; height: 140
                    radius: sel ? 40 : 28
                    color: sel ? Theme.primary : Theme.surfaceHigh
                    Behavior on radius { NumberAnimation { duration: 140 } }
                    Behavior on color { ColorAnimation { duration: 120 } }

                    Icon {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 30
                        code: btn.modelData.icon
                        size: 38
                        color: btn.sel ? Theme.fgPrimary : Theme.text
                    }
                    SText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 86
                        text: btn.modelData.label
                        font.weight: Font.Bold
                        color: btn.sel ? Theme.fgPrimary : Theme.text
                    }
                    SText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 108
                        text: btn.modelData.key
                        font.pixelSize: 11
                        color: btn.sel ? Theme.fgPrimary : Theme.subtext
                        opacity: 0.7
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.current = btn.index
                        onClicked: root.run(btn.index)
                    }
                }
            }
        }
    }
}
