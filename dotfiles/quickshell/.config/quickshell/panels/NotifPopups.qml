import QtQuick
import Quickshell
import Quickshell.Wayland

// Notification popups (newest on top). Position, width and timeouts come from notifications.json.
PanelWindow {
    id: root
    readonly property var cfg: Notifs.cfg

    visible: Notifs.popups.length > 0 && !Notifs.centerOpen
    color: "transparent"
    anchors {
        top: cfg.y !== "bottom"
        bottom: cfg.y === "bottom"
        left: cfg.x === "left"
        right: cfg.x === "right"
    }
    margins { top: 12; bottom: 12; left: 19; right: 19 }
    implicitWidth: cfg.width - 38
    implicitHeight: Math.max(1, list.contentHeight)
    exclusionMode: ExclusionMode.Normal          // stay below the bar
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-notifs"

    ListView {
        id: list
        anchors.fill: parent
        interactive: false
        spacing: 24
        verticalLayoutDirection: root.cfg.y === "bottom" ? ListView.BottomToTop : ListView.TopToBottom
        model: Notifs.popups

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 180 }
                NumberAnimation { property: "x"; from: root.cfg.x === "left" ? -40 : 40; to: 0; duration: 220; easing.type: Easing.OutCubic }
            }
        }
        displaced: Transition { NumberAnimation { properties: "y"; duration: 200; easing.type: Easing.OutCubic } }

        delegate: NotifCard {
            id: card
            required property var modelData
            notif: modelData
            width: list.width

            Timer {
                readonly property int ms: Notifs.timeoutFor(card.notif)
                interval: ms
                running: ms > 0 && !card.hovered
                onTriggered: Notifs.hidePopup(card.notif)
            }
        }
    }
}
