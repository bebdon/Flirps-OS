import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Clipboard history (SUPER+C). Type to filter, Enter to copy, Delete to remove an entry.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-clipboard"

    property var entries: []
    property int current: 0
    readonly property string script: Quickshell.shellDir + "/scripts/clip-list.sh"

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        return q ? entries.filter(e => e.text.toLowerCase().includes(q)) : entries;
    }

    function open() { input.text = ""; current = 0; loader.running = true; visible = true; input.forceActiveFocus(); }
    function close() { visible = false; }
    function toggle() { visible ? close() : open(); }

    function pick() {
        const e = results[current];
        if (!e) return;
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", e.id]);
        close();
    }
    function remove() {
        const e = results[current];
        if (!e) return;
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "sh", e.id]);
        entries = entries.filter(x => x.id !== e.id);
        current = Math.min(current, results.length - 1);
    }
    function move(d) {
        if (results.length === 0) return;
        current = (current + d + results.length) % results.length;
        list.positionViewAtIndex(current, ListView.Contain);
    }

    Process {
        id: loader
        command: [root.script]
        stdout: StdioCollector {
            onStreamFinished: root.entries = this.text.split("\n").filter(l => l).map(l => JSON.parse(l))
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        width: 720; height: 600
        anchors.centerIn: parent
        radius: 28
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        scale: root.visible ? 1 : 0.96
        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        MouseArea { anchors.fill: parent }

        Rectangle {
            id: field
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 16
            height: 56; radius: 28
            color: Theme.surfaceHigh
            Icon {
                id: ic
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                code: 0xF014C; size: 20; color: Theme.primary
            }
            TextInput {
                id: input
                anchors.left: ic.right; anchors.leftMargin: 14
                anchors.right: count.left; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 16
                color: Theme.text
                selectionColor: Theme.primary
                clip: true
                onTextChanged: root.current = 0
                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: root.pick()
                Keys.onEnterPressed: root.pick()
                Keys.onUpPressed: root.move(-1)
                Keys.onDownPressed: root.move(1)
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onDeletePressed: root.remove()
                SText { visible: !parent.text; anchors.verticalCenter: parent.verticalCenter; text: "Search clipboard…"; dim: true; font.pixelSize: 15 }
            }
            SText {
                id: count
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: root.results.length + " items · Del removes"
                dim: true; font.pixelSize: 11
            }
        }

        ListView {
            id: list
            anchors.top: field.bottom; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.bottomMargin: 12
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.results
            currentIndex: root.current

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool sel: index === root.current
                readonly property bool isImg: modelData.img !== ""
                width: list.width
                height: isImg ? 120 : 52
                radius: isImg ? 24 : 26
                color: sel ? Theme.primary
                     : hov.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"

                Image {
                    visible: row.isImg
                    anchors.left: parent.left; anchors.leftMargin: 12
                    anchors.top: parent.top; anchors.bottom: parent.bottom; anchors.margins: 10
                    width: 180
                    fillMode: Image.PreserveAspectFit
                    horizontalAlignment: Image.AlignLeft
                    asynchronous: true
                    sourceSize: Qt.size(360, 200)
                    source: row.isImg ? "file://" + row.modelData.img : ""
                }
                SText {
                    anchors.left: parent.left; anchors.leftMargin: row.isImg ? 206 : 22
                    anchors.right: parent.right; anchors.rightMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    text: row.isImg ? row.modelData.text.replace(/\[\[ binary data (.*) \]\]/, "Image · $1")
                                    : row.modelData.text.replace(/\s+/g, " ")
                    maximumLineCount: 1
                    textFormat: Text.PlainText
                    color: row.sel ? Theme.fgPrimary : Theme.text
                    font.weight: row.sel ? Font.Bold : Font.Normal
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = row.index
                    onClicked: { root.current = row.index; root.pick(); }
                }
            }

            SText {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: loader.running ? "Loading…" : "Clipboard is empty"
                dim: true
            }
        }
    }
}
