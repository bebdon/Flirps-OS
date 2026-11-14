import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

// Desktop widgets on the bottom layer (above the wallpaper, below windows).
// Layout lives in panels/widgets.json. `qs -c panels ipc call desktop edit` toggles drag mode.
// Hidden while a window is fullscreen so it costs nothing during games/videos.
Scope {
    id: root
    property var cfg: ({})
    property bool editing: false
    signal contextMenu(real x, real y)   // right-click on the empty desktop (shell.qml opens DesktopMenu)

    function w(name) { return cfg[name] || {}; }
    function setPos(name, x, y) {
        const c = JSON.parse(JSON.stringify(cfg));
        if (!c[name]) c[name] = {};
        c[name].x = Math.round(x * 1000) / 1000;
        c[name].y = Math.round(y * 1000) / 1000;
        cfg = c;
        file.setText(JSON.stringify(c, null, 2) + "\n");
    }

    FileView {
        id: file
        path: Quickshell.shellDir + "/widgets.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.cfg = JSON.parse(text()); } catch (e) { console.warn("widgets.json: bad JSON"); } }
    }

    PanelWindow {
        id: win
        readonly property bool fullscreenApp: !!Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.hasFullscreen
        visible: !fullscreenApp
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.namespace: "qs-desktop"
        WlrLayershell.keyboardFocus: notesWidget.editingText ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        exclusionMode: ExclusionMode.Normal

        Component.onCompleted: SysInfo.active = Qt.binding(() => win.visible && root.w("system").enabled === true)

        // right-click anywhere the widgets don't cover (declared first, so widgets sit on top)
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            enabled: !root.editing
            onClicked: m => root.contextMenu(m.x, m.y)
        }

        // edit-mode hint
        Rectangle {
            visible: root.editing
            anchors.horizontalCenter: parent.horizontalCenter
            y: 16
            width: hint.width + 32; height: 40; radius: 20
            color: Theme.primary
            SText { id: hint; anchors.centerIn: parent; text: "Drag widgets to move them · click Done when finished"; color: Theme.fgPrimary; font.weight: Font.Bold }
        }
        Rectangle {
            visible: root.editing
            anchors.horizontalCenter: parent.horizontalCenter
            y: 64
            width: 100; height: 36; radius: 18
            color: Theme.surfaceHigh
            SText { anchors.centerIn: parent; text: "Done"; font.weight: Font.Bold }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.editing = false }
        }

        // ---------------- widgets ----------------
        WidgetFrame {
            id: clockFrame
            name: "clock"; desk: root
            Column {
                id: clockCol
                property date now: new Date()
                Timer { interval: 1000; running: win.visible; repeat: true; onTriggered: clockCol.now = new Date() }
                readonly property var c: root.w("clock")
                function pad(n) { return n < 10 ? "0" + n : "" + n; }
                spacing: -6
                Row {
                    spacing: 6
                    SText {
                        readonly property int h: clockCol.c.h24 === false ? ((clockCol.now.getHours() + 11) % 12 + 1) : clockCol.now.getHours()
                        text: clockCol.pad(h) + ":" + clockCol.pad(clockCol.now.getMinutes())
                        font.pixelSize: 110; font.weight: Font.Bold
                        color: Theme.primary
                        style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.35)
                    }
                    SText {
                        visible: clockCol.c.seconds === true
                        anchors.bottom: parent.bottom; anchors.bottomMargin: 22
                        text: clockCol.pad(clockCol.now.getSeconds())
                        font.pixelSize: 34; color: Theme.secondary
                    }
                }
                SText {
                    text: Qt.formatDate(clockCol.now, "dddd, d MMMM")
                    font.pixelSize: 24; color: Theme.text
                    style: Text.Raised; styleColor: Qt.rgba(0, 0, 0, 0.35)
                }
            }
        }

        WidgetFrame {
            id: weatherFrame
            name: "weather"; desk: root; card: true; after: clockFrame
            visible: isOn && Weather.ready
            Row {
                spacing: 16
                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    code: Weather.ready ? Weather.icon(Weather.current.weather_code, Weather.current.is_day) : 0
                    size: 54; color: Theme.primary
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    SText { text: Weather.ready ? Math.round(Weather.current.temperature_2m) + Weather.unitSym + "  " + Weather.label(Weather.current.weather_code) : ""; font.pixelSize: 22; font.weight: Font.Bold }
                    SText {
                        text: Weather.ready ? Weather.place + "  ·  H " + Math.round(Weather.daily.temperature_2m_max[0]) + "°  L " + Math.round(Weather.daily.temperature_2m_min[0]) + "°" : ""
                        dim: true; font.pixelSize: 13
                    }
                }
            }
        }

        WidgetFrame {
            id: systemFrame
            name: "system"; desk: root; card: true; after: weatherFrame
            Row {
                spacing: 6
                Ring { value: SysInfo.cpu; text: Math.round(SysInfo.cpu * 100) + "%"; label: "CPU" }
                Ring { value: SysInfo.ram; text: SysInfo.ramUsedGb.toFixed(1); label: "RAM GB"; color: Theme.secondary }
                Ring { value: Math.min(1, SysInfo.temp / 100); text: Math.round(SysInfo.temp) + "°"; label: "Temp"; color: SysInfo.temp > 80 ? Theme.error : Theme.tertiary }
                Ring { value: SysInfo.disk; text: Math.round(SysInfo.disk * 100) + "%"; label: "Disk"; color: Theme.primaryContainer }
            }
        }

        WidgetFrame {
            name: "music"; desk: root; card: true; after: systemFrame
            visible: isOn && (Media.active || root.editing)
            Row {
                spacing: 14
                Item {
                    width: 76; height: 76
                    RoundedImage { anchors.fill: parent; radius: 16; source: Media.art; visible: Media.art !== ""; sourceSize: Qt.size(160, 160) }
                    Rectangle { anchors.fill: parent; radius: 16; visible: Media.art === ""; color: Theme.surfaceHighest; Icon { anchors.centerIn: parent; code: 0xF075A; size: 30 } }
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 220
                    spacing: 6
                    SText { width: parent.width; text: Media.active ? Media.title : "Nothing playing"; font.weight: Font.Bold }
                    SText { width: parent.width; text: Media.artist; dim: true; font.pixelSize: 12 }
                    Row {
                        spacing: 4
                        Repeater {
                            model: [
                                { icon: 0xF04AE, act: () => Media.player.previous() },
                                { icon: Media.playing ? 0xF03E4 : 0xF040A, act: () => Media.player.togglePlaying(), main: true },
                                { icon: 0xF04AD, act: () => Media.player.next() }
                            ]
                            Rectangle {
                                required property var modelData
                                width: 34; height: 34; radius: modelData.main ? 12 : 17
                                color: modelData.main ? Theme.primary : (mm.containsMouse ? Theme.surfaceHighest : "transparent")
                                Icon { anchors.centerIn: parent; code: parent.modelData.icon; size: 16; color: parent.modelData.main ? Theme.fgPrimary : Theme.text }
                                MouseArea { id: mm; anchors.fill: parent; hoverEnabled: true; enabled: Media.active && !root.editing; cursorShape: Qt.PointingHandCursor; onClicked: parent.modelData.act() }
                            }
                        }
                    }
                }
            }
        }

        WidgetFrame {
            id: notesWidget
            name: "notes"; desk: root; card: true
            property bool editingText: notesEdit.activeFocus
            Column {
                width: 300
                spacing: 8
                SText { text: String.fromCodePoint(0xF082E) + "  Notes"; font.weight: Font.Bold; color: Theme.primary }
                TextEdit {
                    id: notesEdit
                    width: parent.width
                    height: Math.max(120, contentHeight)
                    wrapMode: TextEdit.Wrap
                    font.family: Theme.font; font.pixelSize: 13
                    color: Theme.text
                    selectionColor: Theme.primary
                    enabled: !root.editing
                    text: Notes.text
                    onTextChanged: if (activeFocus) Notes.save(text)
                    Keys.onEscapePressed: focus = false
                    SText { visible: !parent.text; text: "Click to write…"; dim: true }
                }
            }
        }
    }
}
