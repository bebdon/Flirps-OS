import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Mpris

// Notification center (SUPER+M / B / S, right-click the clock), laid out like the old swaync
// control center: title + Clear, Do not disturb, media, volume, brightness, then the history.
PanelWindow {
    id: root
    property bool shown: false

    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal          // starts below the bar
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-notifcenter"

    onShownChanged: Notifs.centerOpen = shown
    function open() { closeTimer.stop(); Brightness.refresh(); visible = true; shown = true; keys.forceActiveFocus(); }
    function close() { if (!visible) return; shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }
    Timer { id: closeTimer; interval: 190; onTriggered: root.visible = false }

    MouseArea { anchors.fill: parent; onClicked: root.close() }
    Item { id: keys; focus: true; Keys.onEscapePressed: root.close() }

    Rectangle {
        id: panel
        width: 420
        height: Math.min(600, parent.height - 16)
        anchors.top: parent.top; anchors.topMargin: 8
        x: parent.width - width - 8 + (root.shown ? 0 : 24)
        opacity: root.shown ? 1 : 0
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 170 } }

        radius: 12
        color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.85)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)

        MouseArea { anchors.fill: parent }   // swallow clicks inside

        Column {
            id: header
            x: 11; y: 19
            width: parent.width - 22
            spacing: 0

            // title + Clear
            Item {
                width: parent.width; height: 48
                Text {
                    x: 17; anchors.verticalCenter: parent.verticalCenter
                    text: "Notifications"
                    font.family: Theme.font; font.pixelSize: 13
                    color: Theme.text
                }
                Rectangle {
                    anchors.right: parent.right; anchors.rightMargin: 17
                    anchors.verticalCenter: parent.verticalCenter
                    width: 72; height: 31; radius: height / 2
                    color: clearMa.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.3) : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                    Text { anchors.centerIn: parent; text: "Clear"; font.family: Theme.font; font.pixelSize: 13; font.weight: Font.Bold; color: Theme.text }
                    MouseArea { id: clearMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Notifs.clearAll() }
                }
            }

            Item { width: 1; height: 18 }

            // do not disturb
            Item {
                width: parent.width; height: 40
                Text {
                    x: 17; anchors.verticalCenter: parent.verticalCenter
                    text: "Do not disturb"
                    font.family: Theme.font; font.pixelSize: 13
                    color: Theme.text
                }
                GtkSwitch {
                    anchors.right: parent.right; anchors.rightMargin: 17
                    anchors.verticalCenter: parent.verticalCenter
                    checked: Notifs.dnd
                    onToggled: v => Notifs.dnd = v
                }
            }

            Item { width: 1; height: 22 }

            // media (same layout as the swaync mpris widget)
            Rectangle {
                visible: Media.active
                width: parent.width; height: 144; radius: 10
                color: Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.7)
                Rectangle {
                    anchors.fill: parent; anchors.margins: 8
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.35)
                    RoundedImage {
                        x: 12; y: 12
                        width: 64; height: 64; radius: 10
                        source: Media.art
                        visible: Media.art !== ""
                    }
                    Rectangle {
                        visible: Media.art === ""
                        x: 12; y: 12
                        width: 64; height: 64; radius: 10
                        color: Qt.rgba(Theme.surfaceHighest.r, Theme.surfaceHighest.g, Theme.surfaceHighest.b, 0.6)
                        Icon { anchors.centerIn: parent; code: 0xF075A; size: 26 }
                    }
                    Column {
                        x: 88; y: 18
                        width: parent.width - 100
                        spacing: 2
                        SText { width: parent.width; text: Media.title; font.pixelSize: 13; font.weight: Font.Bold }
                        SText { width: parent.width; text: Media.artist; dim: true; font.pixelSize: 13 }
                    }
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 8
                        spacing: 10
                        Repeater {
                            model: ["shuffle", "prev", "play", "next", "loop"]
                            Rectangle {
                                id: ctl
                                required property string modelData
                                readonly property var p: Media.player
                                readonly property bool active: !!p && ((modelData === "shuffle" && p.shuffle) || (modelData === "loop" && p.loopState !== MprisLoopState.None))
                                width: 30; height: 30; radius: 15
                                color: pm.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15) : "transparent"
                                Icon {
                                    anchors.centerIn: parent; size: 16
                                    color: ctl.active ? Theme.primary : Theme.text
                                    code: ctl.modelData === "shuffle" ? 0xF049D
                                        : ctl.modelData === "prev" ? 0xF04AE
                                        : ctl.modelData === "next" ? 0xF04AD
                                        : ctl.modelData === "loop" ? (ctl.p && ctl.p.loopState === MprisLoopState.Track ? 0xF0458 : 0xF0456)
                                        : (Media.playing ? 0xF03E4 : 0xF040A)
                                }
                                MouseArea {
                                    id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = ctl.p; if (!p) return;
                                        switch (ctl.modelData) {
                                        case "shuffle": if (p.shuffleSupported) p.shuffle = !p.shuffle; break;
                                        case "prev": p.previous(); break;
                                        case "next": p.next(); break;
                                        case "play": p.togglePlaying(); break;
                                        case "loop": if (p.loopSupported) p.loopState = p.loopState === MprisLoopState.None ? MprisLoopState.Playlist : p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None; break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Item { visible: Media.active; width: 1; height: 22 }

            // volume + brightness
            Repeater {
                model: ["volume", "brightness"]
                Item {
                    id: sliderCard
                    required property string modelData
                    readonly property bool vol: modelData === "volume"
                    width: header.width; height: 58
                    Rectangle {
                        width: parent.width; height: 48; radius: 10
                        color: Qt.rgba(Theme.surfaceHigh.r, Theme.surfaceHigh.g, Theme.surfaceHigh.b, 0.7)
                    }
                    Icon { x: 12; y: 0; height: 48; code: sliderCard.vol ? 0xF057E : 0xF00DF; size: 14 }
                    GtkSlider {
                        x: 36; y: 12
                        width: parent.width - 56
                        value: sliderCard.vol ? Audio.volume : Brightness.value
                        onMoved: v => sliderCard.vol ? Audio.setVolume(v) : Brightness.set(v)
                    }
                }
            }
        }

        // history
        ListView {
            id: hist
            anchors.top: header.bottom; anchors.topMargin: 25
            anchors.bottom: parent.bottom; anchors.bottomMargin: 10
            x: 47; width: parent.width - 94
            clip: true
            spacing: 28
            model: Notifs.history
            boundsBehavior: Flickable.StopAtBounds
            delegate: NotifCard {
                required property var modelData
                notif: modelData
                showTime: true
                width: hist.width
            }
            remove: Transition { NumberAnimation { property: "opacity"; to: 0; duration: 150 } }
            displaced: Transition { NumberAnimation { properties: "y"; duration: 180; easing.type: Easing.OutCubic } }

            Text {
                visible: hist.count === 0
                anchors.centerIn: parent
                text: "No notifications"
                font.family: Theme.font; font.pixelSize: 13
                color: Theme.subtext
            }
        }
    }
}
