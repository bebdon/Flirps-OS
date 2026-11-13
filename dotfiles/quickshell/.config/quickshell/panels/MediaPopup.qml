import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.Mpris

// Media player popup (click the song in the bar).
BarPopup {
    id: root
    ns: "qs-media"
    align: "left"
    cardWidth: 460

    readonly property var p: Media.player
    property real pos: 0

    // MPRIS doesn't push position updates, so poll once a second while visible.
    Timer {
        interval: 1000; repeat: true; triggeredOnStart: true
        running: root.visible && !!root.p
        onTriggered: { if (root.p) { root.p.positionChanged(); root.pos = root.p.position; } }
    }
    function fmt(s) {
        if (!s || s < 0 || !isFinite(s)) return "0:00";
        s = Math.floor(s);
        const m = Math.floor(s / 60), r = s % 60;
        return m + ":" + (r < 10 ? "0" : "") + r;
    }

    Item {
        width: parent.width
        height: root.p ? 470 : 120

        SText {
            visible: !root.p
            anchors.centerIn: parent
            text: "Nothing is playing"
            dim: true
        }

        // blurred cover as the background (rendered once per track)
        Item {
            id: bg
            visible: !!root.p && Media.art !== ""
            anchors.fill: parent
            Image { id: bgImg; anchors.fill: parent; source: Media.art; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(200, 200); visible: false; asynchronous: true }
            Rectangle { id: bgMask; anchors.fill: parent; radius: 18; visible: false; layer.enabled: true }
            MultiEffect {
                anchors.fill: parent
                source: bgImg
                blurEnabled: true; blur: 1.0; blurMax: 48
                saturation: 0.2
                brightness: -0.35
                maskEnabled: true; maskSource: bgMask
            }
        }

        Column {
            visible: !!root.p
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // cover
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 240; height: 240
                RoundedImage {
                    anchors.fill: parent
                    radius: 22
                    source: Media.art
                    sourceSize: Qt.size(480, 480)
                    visible: Media.art !== ""
                    scale: Media.playing ? 1 : 0.92
                    Behavior on scale { NumberAnimation { duration: 350; easing.type: Easing.OutBack } }
                }
                Rectangle {
                    visible: Media.art === ""
                    anchors.fill: parent; radius: 22
                    color: Theme.surfaceHigh
                    Icon { anchors.centerIn: parent; code: 0xF075A; size: 72; color: Theme.subtext }
                }
            }

            Column {
                width: parent.width
                spacing: 2
                SText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Media.title; font.pixelSize: 17; font.weight: Font.Bold; color: "white" }
                SText { width: parent.width; horizontalAlignment: Text.AlignHCenter; text: Media.artist + (root.p && root.p.trackAlbum ? " — " + root.p.trackAlbum : ""); font.pixelSize: 12; color: Qt.rgba(1, 1, 1, 0.75) }
            }

            // seek bar
            Item {
                width: parent.width; height: 30
                readonly property real len: root.p ? root.p.length : 0
                readonly property bool seekable: !!root.p && root.p.canSeek && len > 0
                Rectangle {
                    id: seekTrack
                    y: 4; width: parent.width; height: 6; radius: 3
                    color: Qt.rgba(1, 1, 1, 0.2)
                    Rectangle {
                        width: parent.parent.len > 0 ? Math.min(1, (seekMa.pressed ? seekMa.live : root.pos) / parent.parent.len) * parent.width : 0
                        height: parent.height; radius: 3
                        color: Theme.primary
                    }
                    MouseArea {
                        id: seekMa
                        property real live: 0
                        enabled: parent.parent.seekable
                        anchors.fill: parent; anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onPressed: m => live = Math.max(0, Math.min(1, m.x / width)) * parent.parent.len
                        onPositionChanged: m => { if (pressed) live = Math.max(0, Math.min(1, m.x / width)) * parent.parent.len; }
                        onReleased: { root.p.position = live; root.pos = live; }
                    }
                }
                SText { anchors.left: parent.left; anchors.bottom: parent.bottom; text: root.fmt(seekMa.pressed ? seekMa.live : root.pos); font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.7) }
                SText { anchors.right: parent.right; anchors.bottom: parent.bottom; text: root.fmt(parent.len); font.pixelSize: 10; color: Qt.rgba(1, 1, 1, 0.7) }
            }

            // controls
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12
                Repeater {
                    model: [
                        { icon: 0xF049D, act: () => { root.p.shuffle = !root.p.shuffle; }, on: !!root.p && root.p.shuffle, ok: !!root.p && root.p.shuffleSupported, small: true },
                        { icon: 0xF04AE, act: () => root.p.previous(), ok: !!root.p && root.p.canGoPrevious },
                        { icon: Media.playing ? 0xF03E4 : 0xF040A, act: () => root.p.togglePlaying(), ok: !!root.p && root.p.canTogglePlaying, main: true },
                        { icon: 0xF04AD, act: () => root.p.next(), ok: !!root.p && root.p.canGoNext },
                        { icon: root.p && root.p.loopState === MprisLoopState.Track ? 0xF0458 : 0xF0456,
                          act: () => { root.p.loopState = root.p.loopState === MprisLoopState.None ? MprisLoopState.Playlist : root.p.loopState === MprisLoopState.Playlist ? MprisLoopState.Track : MprisLoopState.None; },
                          on: !!root.p && root.p.loopState !== MprisLoopState.None, ok: !!root.p && root.p.loopSupported, small: true }
                    ]
                    Rectangle {
                        required property var modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: modelData.main ? 64 : modelData.small ? 40 : 48
                        height: width
                        radius: modelData.main ? (Media.playing ? 22 : 32) : width / 2
                        Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
                        opacity: modelData.ok ? 1 : 0.35
                        color: modelData.main ? Theme.primary : modelData.on ? Theme.secondaryContainer : (cb.containsMouse ? Qt.rgba(1, 1, 1, 0.15) : Qt.rgba(1, 1, 1, 0.06))
                        Icon { anchors.centerIn: parent; code: parent.modelData.icon; size: parent.modelData.main ? 28 : 20; color: parent.modelData.main ? Theme.fgPrimary : "white" }
                        MouseArea { id: cb; anchors.fill: parent; hoverEnabled: true; enabled: parent.modelData.ok; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                    }
                }
            }

            // player switcher
            Row {
                visible: Media.players.length > 1
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6
                Repeater {
                    model: Media.players
                    Rectangle {
                        required property var modelData
                        required property int index
                        readonly property bool sel: modelData === root.p
                        width: pl.implicitWidth + 20; height: 26; radius: 13
                        color: sel ? Theme.primary : Qt.rgba(1, 1, 1, 0.1)
                        SText { id: pl; anchors.centerIn: parent; text: parent.modelData.identity; font.pixelSize: 11; color: parent.sel ? Theme.fgPrimary : "white" }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Media.manualIndex = parent.index }
                    }
                }
            }
        }
    }
}
