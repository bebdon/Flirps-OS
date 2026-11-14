import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Overview of every window, grouped by workspace (SUPER+Tab).
// Type to filter, arrows/Tab to move, Enter or click to switch. If nothing matches,
// Enter searches apps in the launcher instead.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-overview"

    signal searchApps(string text)

    property bool shown: false
    property int current: 0

    function open() {
        if (typeof Hyprland.refreshToplevels === "function") Hyprland.refreshToplevels();
        input.text = ""; current = 0;
        closeTimer.stop(); visible = true; shown = true;
        input.forceActiveFocus();
    }
    function close() { if (!visible) return; shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }
    Timer { id: closeTimer; interval: 160; onTriggered: root.visible = false }

    // ---- data: Hyprland's window list, read defensively (fields differ between Quickshell versions)
    function wsId(t) {
        if (t.workspace && t.workspace.id !== undefined) return t.workspace.id;
        const o = t.lastIpcObject;
        return o && o.workspace ? o.workspace.id : 0;
    }
    function appClass(t) {
        const o = t.lastIpcObject;
        if (o && o["class"]) return o["class"];
        return t.wayland ? (t.wayland.appId || "") : "";
    }
    function iconFor(cls) {
        const e = DesktopEntries.heuristicLookup(cls);
        return Quickshell.iconPath(e && e.icon ? e.icon : cls.toLowerCase(), "application-x-executable");
    }
    function appName(cls) {
        const e = DesktopEntries.heuristicLookup(cls);
        return e ? e.name : cls;
    }
    function focusWindow(t) {
        close();
        if (t.wayland) t.wayland.activate();
        else if (t.address) Hyprland.dispatch("focuswindow address:0x" + t.address);
    }

    readonly property int activeWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    // flat, filtered list sorted by workspace (special workspaces, which have negative ids, last)
    readonly property var wins: {
        if (!visible) return [];
        const ql = input.text.trim().toLowerCase();
        const out = [];
        for (const t of Hyprland.toplevels.values) {
            const cls = appClass(t);
            const title = t.title || "";
            if (!cls && !title) continue;
            const ws = wsId(t);
            if (ql && !(title.toLowerCase().includes(ql) || cls.toLowerCase().includes(ql) || appName(cls).toLowerCase().includes(ql))) continue;
            out.push({ t: t, ws: ws, cls: cls, title: title });
        }
        const key = w => w.ws < 0 ? 100000 - w.ws : w.ws;
        out.sort((a, b) => key(a) - key(b));
        return out;
    }
    // [{ ws, items: [{ w, i }] }] where i is the index in `wins`
    readonly property var groups: {
        const g = [];
        wins.forEach((w, i) => {
            if (!g.length || g[g.length - 1].ws !== w.ws) g.push({ ws: w.ws, items: [] });
            g[g.length - 1].items.push({ w: w, i: i });
        });
        return g;
    }

    function move(d) { if (wins.length) current = (current + d + wins.length) % wins.length; }
    function activate() {
        if (wins.length) focusWindow(wins[Math.min(current, wins.length - 1)].t);
        else if (input.text.trim()) { const q = input.text.trim(); close(); searchApps(q); }
    }

    // backdrop: nearly solid, so the windows behind don't compete with the cards; click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.94)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Item {
        anchors.fill: parent
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.98
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        // ---- search field ----
        Rectangle {
            id: field
            anchors.horizontalCenter: parent.horizontalCenter
            y: 80
            width: 440; height: 48; radius: 24
            color: Theme.surfaceHigh
            border.width: 1
            border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
            Icon {
                id: searchIcon
                anchors.left: parent.left; anchors.leftMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                code: 0xF0349; size: 18; color: Theme.primary
            }
            TextInput {
                id: input
                anchors.left: searchIcon.right; anchors.leftMargin: 12
                anchors.right: parent.right; anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 15
                color: Theme.text
                selectionColor: Theme.primary
                selectedTextColor: Theme.fgPrimary
                clip: true
                focus: true
                onTextChanged: root.current = 0
                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: root.activate()
                Keys.onEnterPressed: root.activate()
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onRightPressed: event => { if (cursorPosition === text.length) root.move(1); else event.accepted = false; }
                Keys.onLeftPressed: event => { if (cursorPosition === text.length && text.length === 0) root.move(-1); else event.accepted = false; }
                Keys.onDownPressed: root.move(1)
                Keys.onUpPressed: root.move(-1)
                SText {
                    visible: !parent.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Type to find a window, or an app"
                    dim: true; font.pixelSize: 14
                }
            }
        }

        // ---- windows, one row per workspace ----
        Flickable {
            id: flick
            anchors.top: field.bottom; anchors.topMargin: 36
            anchors.bottom: parent.bottom; anchors.bottomMargin: 40
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(parent.width - 120, 1400)
            contentHeight: col.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: col
                width: flick.width
                spacing: 26

                Repeater {
                    model: root.groups
                    Column {
                        id: grp
                        required property var modelData
                        width: col.width
                        spacing: 10
                        SText {
                            text: (grp.modelData.ws < 0 ? "Scratchpad" : "Workspace " + grp.modelData.ws)
                                + (grp.modelData.ws === root.activeWs ? "  ·  current" : "")
                            font.weight: Font.Bold; font.pixelSize: 13
                            color: grp.modelData.ws === root.activeWs ? Theme.primary : Theme.subtext
                        }
                        Flow {
                            width: parent.width
                            spacing: 14
                            Repeater {
                                model: grp.modelData.items
                                Rectangle {
                                    id: card
                                    required property var modelData
                                    readonly property var w: modelData.w
                                    readonly property bool sel: modelData.i === root.current
                                    width: 230; height: 150; radius: 22
                                    color: sel ? Theme.primary : Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.92)
                                    border.width: 1
                                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, sel ? 0 : 0.6)
                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    Image {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 26
                                        width: 56; height: 56
                                        sourceSize: Qt.size(112, 112)
                                        asynchronous: true
                                        source: root.iconFor(card.w.cls)
                                    }
                                    SText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 92
                                        width: parent.width - 28
                                        horizontalAlignment: Text.AlignHCenter
                                        text: root.appName(card.w.cls)
                                        font.weight: Font.Bold; font.pixelSize: 13
                                        color: card.sel ? Theme.fgPrimary : Theme.text
                                    }
                                    SText {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        y: 114
                                        width: parent.width - 28
                                        horizontalAlignment: Text.AlignHCenter
                                        text: card.w.title
                                        font.pixelSize: 11
                                        color: card.sel ? Theme.fgPrimary : Theme.subtext
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.current = card.modelData.i
                                        onClicked: root.focusWindow(card.w.t)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        SText {
            anchors.centerIn: parent
            visible: root.wins.length === 0
            text: input.text.trim() ? "No windows match. Press Enter to search apps." : "No open windows"
            dim: true
        }
    }
}
