import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit

// Password dialog for apps that need admin rights (replaces hyprpolkitagent).
// Same card style as the power menu; wrong passwords shake and show the error.
Scope {
    id: root

    PolkitAgent { id: agent }
    readonly property var flow: agent.flow

    PanelWindow {
        id: win
        visible: agent.isActive && !!root.flow
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        WlrLayershell.namespace: "qs-polkit"

        // polkit starts a fresh request after a failure, which clears its own message,
        // so remember the failure until the user types again
        property bool wrong: false
        onVisibleChanged: if (visible) { pw.text = ""; wrong = false; pw.forceActiveFocus(); }

        function submit() {
            if (!root.flow || !root.flow.isResponseRequired) return;
            root.flow.submit(pw.text);
            pw.text = "";
        }
        function cancel() { if (root.flow) root.flow.cancelAuthenticationRequest(); }

        Connections {
            target: root.flow
            function onAuthenticationFailed() { win.wrong = true; shake.restart(); pw.forceActiveFocus(); }
            function onIsResponseRequiredChanged() { if (root.flow && root.flow.isResponseRequired) pw.forceActiveFocus(); }
        }

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.25)
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 440
            height: col.implicitHeight + 48
            radius: 32
            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.88)
            border.width: 1
            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)

            SequentialAnimation {
                id: shake
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -10; duration: 50 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 10; duration: 70 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: -6; duration: 60 }
                NumberAnimation { target: card; property: "anchors.horizontalCenterOffset"; to: 0; duration: 50 }
            }

            Column {
                id: col
                x: 24; y: 24
                width: parent.width - 48
                spacing: 14

                Row {
                    spacing: 14
                    Rectangle {
                        width: 52; height: 52; radius: 18
                        color: Theme.primary
                        Icon { anchors.centerIn: parent; code: 0xF033E; size: 24; color: Theme.fgPrimary }
                    }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: col.width - 66
                        SText { text: "Authentication required"; font.pixelSize: 15; font.weight: Font.Bold }
                        SText { text: Brand.name; dim: true; font.pixelSize: 12 }
                    }
                }

                Text {
                    width: parent.width
                    text: root.flow ? root.flow.message : ""
                    wrapMode: Text.Wrap
                    font.family: Theme.font; font.pixelSize: 13
                    color: Theme.text
                }

                // password field (same look as the Wi-Fi password field)
                Rectangle {
                    width: parent.width; height: 46; radius: 23
                    color: Theme.surfaceHigh
                    border.width: win.wrong || (root.flow && root.flow.supplementaryIsError) ? 1 : 0
                    border.color: Theme.error
                    opacity: root.flow && root.flow.isResponseRequired ? 1 : 0.5
                    TextInput {
                        id: pw
                        anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 18
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        enabled: !!root.flow && root.flow.isResponseRequired
                        font.family: Theme.font; font.pixelSize: 14
                        color: Theme.text
                        onTextChanged: if (text) win.wrong = false
                        Keys.onReturnPressed: win.submit()
                        Keys.onEnterPressed: win.submit()
                        Keys.onEscapePressed: win.cancel()
                        SText {
                            visible: !parent.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.flow && root.flow.isResponseRequired
                                  ? (root.flow.inputPrompt || "Password").replace(/:\s*$/, "") + " for " + Quickshell.env("USER")
                                  : "Checking…"
                            dim: true
                        }
                    }
                }

                SText {
                    visible: text !== ""
                    width: parent.width
                    text: win.wrong ? "Wrong password, try again" : root.flow ? root.flow.supplementaryMessage : ""
                    color: win.wrong || (root.flow && root.flow.supplementaryIsError) ? Theme.error : Theme.subtext
                    font.pixelSize: 12
                    wrapMode: Text.Wrap
                }

                Row {
                    anchors.right: parent.right
                    spacing: 8
                    Repeater {
                        model: ["Cancel", "Authenticate"]
                        Rectangle {
                            id: b
                            required property string modelData
                            readonly property bool main: modelData === "Authenticate"
                            width: lbl.implicitWidth + 36; height: 40; radius: 20
                            color: main ? (bm.containsMouse ? Qt.lighter(Theme.primary, 1.08) : Theme.primary)
                                        : (bm.containsMouse ? Theme.surfaceHighest : Theme.surfaceHigh)
                            SText { id: lbl; anchors.centerIn: parent; text: b.modelData; font.pixelSize: 13; font.weight: Font.Bold; color: b.main ? Theme.fgPrimary : Theme.text }
                            MouseArea { id: bm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: b.main ? win.submit() : win.cancel() }
                        }
                    }
                }
            }
        }
    }
}
