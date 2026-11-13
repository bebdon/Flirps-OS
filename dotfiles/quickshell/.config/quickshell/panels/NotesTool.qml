import QtQuick

// Floating quick notes (SUPER+ALT+N). Same text as the desktop notes widget.
ToolWindow {
    id: root
    title: "Notes"
    icon: 0xF082E
    startX: 1300; startY: 120
    onOpened: edit.forceActiveFocus()

    Rectangle {
        width: 380; height: 360; radius: 16
        color: Theme.surfaceLow
        Flickable {
            id: fl
            anchors.fill: parent; anchors.margins: 14
            contentHeight: edit.contentHeight
            clip: true
            TextEdit {
                id: edit
                width: fl.width
                wrapMode: TextEdit.Wrap
                font.family: Theme.font; font.pixelSize: 14
                color: Theme.text
                selectionColor: Theme.primary
                text: Notes.text
                onTextChanged: if (activeFocus) Notes.save(text)
                Keys.onEscapePressed: root.close()
                SText { visible: !parent.text; text: "Write something… (saved automatically)"; dim: true }
            }
        }
    }
}
