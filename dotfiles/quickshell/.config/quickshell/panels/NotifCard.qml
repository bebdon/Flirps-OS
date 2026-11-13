import QtQuick
import Quickshell
import Quickshell.Services.Notifications

// One notification, styled like the old swaync cards:
// surface_container @ 85%, 1px outline_variant @ 60%, radius 12, critical = error border.
Rectangle {
    id: card
    required property var notif
    property bool showTime: false        // the center shows "Now" / "5 min ago"; popups don't
    property bool hovered: hover.hovered
    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        if (!notif) return "";
        if (notif.image) return notif.image;
        if (notif.appIcon) return notif.appIcon.indexOf("/") >= 0 ? "file://" + notif.appIcon.replace(/^file:\/\//, "") : Quickshell.iconPath(notif.appIcon, true);
        return "";
    }
    readonly property var buttons: notif ? notif.actions.filter(a => a.identifier !== "default") : []

    implicitHeight: content.implicitHeight + 24
    radius: 12
    color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.85)
    border.width: 1
    border.color: critical ? Theme.error : Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)

    HoverHandler { id: hover }

    // click the card = the app's default action, if it has one
    Rectangle {
        anchors.fill: parent; radius: parent.radius
        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
        visible: !!Notifs.defaultAction(card.notif) && hover.hovered && !closeMa.containsMouse
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Notifs.defaultAction(card.notif) ? Qt.PointingHandCursor : Qt.ArrowCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: m => {
            if (m.button === Qt.MiddleButton) { Notifs.dismiss(card.notif); return; }
            const a = Notifs.defaultAction(card.notif);
            if (a) Notifs.invoke(card.notif, a);
        }
    }

    Column {
        id: content
        x: 11; y: 11
        width: parent.width - 22
        spacing: 8

        Row {
            width: parent.width
            spacing: 8

            Item {
                visible: icon.visible
                width: icon.width + 7; height: icon.height
                anchors.verticalCenter: parent.verticalCenter
                Image {
                id: icon
                x: 7
                visible: card.iconSource !== "" && status !== Image.Error
                width: Notifs.cfg.iconSize; height: width
                source: card.iconSource
                sourceSize: Qt.size(width * 2, height * 2)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                }
            }
            Column {
                width: parent.width - (icon.visible ? icon.width + 7 + parent.spacing : 0)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0
                Item {
                    width: parent.width; height: summary.height
                    Text {
                        id: summary
                        width: parent.width - (when.visible ? when.width + 12 : 28)
                        text: card.notif ? card.notif.summary : ""
                        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                        color: Theme.text
                        elide: Text.ElideRight
                    }
                    Text {
                        id: when
                        anchors.right: parent.right
                        visible: card.showTime && !card.hovered
                        text: card.notif ? Notifs.ago(card.notif) : ""
                        font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold
                        color: Theme.text
                    }
                }
                Text {
                    width: parent.width
                    visible: text !== ""
                    text: card.notif ? card.notif.body : ""
                    textFormat: Text.StyledText
                    font.family: Theme.font; font.pixelSize: 13
                    color: Theme.subtext
                    linkColor: Theme.primary
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    onLinkActivated: l => Qt.openUrlExternally(l)
                }
            }
        }

        // action buttons
        Row {
            visible: card.buttons.length > 0
            width: parent.width
            spacing: 6
            Repeater {
                model: card.buttons
                Rectangle {
                    required property var modelData
                    width: (parent.width - (card.buttons.length - 1) * 6) / card.buttons.length
                    height: 32; radius: 10
                    color: am.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04)
                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 12
                        horizontalAlignment: Text.AlignHCenter
                        text: parent.modelData.text
                        font.family: Theme.font; font.pixelSize: 13
                        color: Theme.text
                        elide: Text.ElideRight
                    }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.invoke(card.notif, parent.modelData) }
                }
            }
        }
    }

    // close button: small primary @ 20% pill, top-right, on hover
    Rectangle {
        visible: card.hovered
        anchors.top: parent.top; anchors.right: parent.right
        anchors.margins: 8
        width: 24; height: 24; radius: 12
        color: closeMa.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.35) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
        Icon { anchors.centerIn: parent; code: 0xF0156; size: 14 }
        MouseArea { id: closeMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.dismiss(card.notif) }
    }
}
