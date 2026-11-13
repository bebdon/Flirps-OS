import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "CalculatorEngine.js" as Calc
import "Convert.js" as Convert
import "SearchProviders.js" as Search

// App launcher (SUPER+D).
//   type to search apps (most used first)     2*(3+4)  calculator      10 km to mi  conversion
//   :fire  emoji                              !yt lofi  web search     > cmd        run a command
// ↑/↓ or Tab to move, Enter to launch / copy, Esc to close.
PanelWindow {
    id: root
    visible: false
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "qs-launcher"

    property int current: 0
    property bool shown: false
    property var usage: ({})                 // desktop id -> launch count
    property var emojiList: null             // loaded on first ":"

    function open() { input.text = ""; current = 0; closeTimer.stop(); visible = true; shown = true; input.forceActiveFocus(); }
    function close() { if (!visible) return; shown = false; closeTimer.restart(); }
    function toggle() { shown ? close() : open(); }
    function setQuery(t) { open(); input.text = t; }    // used by IPC for testing
    Timer { id: closeTimer; interval: 160; onTriggered: root.visible = false }

    readonly property string q: input.text
    readonly property string mode: q.startsWith(">") ? "cmd" : q.startsWith(":") ? "emoji" : q.startsWith("!") ? "bang" : "apps"

    readonly property var apps: DesktopEntries.applications.values
        .filter(a => !a.noDisplay)
        .sort((a, b) => ((usage[b.id] || 0) - (usage[a.id] || 0)) || a.name.localeCompare(b.name))

    function calc(text) {
        const t = text.trim();
        if (!/\d/.test(t) || !/[-+*\/^×÷%()!]|sqrt|sin|cos|tan|log|ln|pi/.test(t) || /^-?\d+(\.\d+)?$/.test(t)) return null;
        try {
            const v = Calc.evaluate(t, false);
            if (typeof v !== "number" || !isFinite(v)) return null;
            const s = Calc.format(v).replace("−", "-");
            return { kind: "calc", title: s, subtitle: t + " =", copy: s, icon: 0xF00EC };
        } catch (e) { return null; }
    }

    readonly property var results: {
        const t = q.trim();
        if (mode === "cmd") {
            const cmd = t.slice(1).trim();
            return cmd ? [{ kind: "cmd", title: "Run: " + cmd, subtitle: "in sh", cmd: cmd, icon: 0xF018D }] : [];
        }
        if (mode === "bang") {
            const b = Search.parse(t);
            if (b) return [{ kind: "web", title: b.query ? "Search " + b.engine.name + " for “" + b.query + "”" : b.engine.name, subtitle: "!" + b.engine.bang + "  ·  opens in your browser", url: b.query ? Search.url(b.engine, b.query) : b.engine.url.replace(/\/[^\/]*$/, "/"), icon: 0xF059F }];
            return Search.BANGS.filter(e => ("!" + e.bang).startsWith(t.split(/\s/)[0]))
                .map(e => ({ kind: "hint", title: "!" + e.bang + "  " + e.name, subtitle: "type a search after it", fill: "!" + e.bang + " ", icon: 0xF059F }));
        }
        if (mode === "emoji") return [];

        const out = [];
        const c = calc(t);
        if (c) out.push(c);
        const conv = t ? Convert.run(t) : null;
        if (conv) out.push({ kind: "calc", title: conv.value, subtitle: conv.text, copy: conv.value, icon: 0xF1A5A });

        const ql = t.toLowerCase();
        if (!ql) return out.concat(apps.map(a => ({ kind: "app", app: a })));
        const scored = [];
        for (const a of apps) {
            const name = a.name.toLowerCase();
            const extra = [a.genericName, a.comment, (a.keywords || []).join(" "), a.id].join(" ").toLowerCase();
            let s = name.startsWith(ql) ? 4 : name.split(/\s+/).some(w => w.startsWith(ql)) ? 3 : name.includes(ql) ? 2 : extra.includes(ql) ? 1 : 0;
            if (s > 0) scored.push({ a, s: s + Math.min(2, (usage[a.id] || 0) / 10) });
        }
        scored.sort((x, y) => y.s - x.s || x.a.name.localeCompare(y.a.name));
        for (const x of scored) out.push({ kind: "app", app: x.a });
        if (!c && !conv) {
            const e = Search.find(Search.DEFAULT_BANG);
            out.push({ kind: "web", title: "Search the web for “" + t + "”", subtitle: e.name + "  ·  tip: !g !yt !w !gh !aw", url: Search.url(e, t), icon: 0xF059F });
        }
        return out;
    }

    readonly property var emojis: {
        if (mode !== "emoji") return [];
        if (!emojiList) return [];
        const t = q.slice(1).trim().toLowerCase();
        if (!t) return emojiList.slice(0, 120);
        const out = [];
        for (const e of emojiList) {
            if (e.name.includes(t) || e.keywords.some(k => k.startsWith(t))) { out.push(e); if (out.length >= 120) break; }
        }
        return out;
    }
    onModeChanged: if (mode === "emoji" && !emojiList) emojiLoader.active = true
    Loader {
        id: emojiLoader
        active: false
        sourceComponent: Item { Component.onCompleted: root.emojiList = EmojiStore.load() }
    }

    readonly property int count: mode === "emoji" ? emojis.length : results.length

    function bump(id) {
        const u = Object.assign({}, usage);
        u[id] = (u[id] || 0) + 1;
        usage = u;
        usageFile.setText(JSON.stringify(u));
    }
    function copy(text) { Quickshell.execDetached(["wl-copy", "--", text]); }

    function activate(i) {
        if (mode === "emoji") {
            const e = emojis[i];
            if (e) { copy(e.emoji); close(); }
            return;
        }
        const r = results[i];
        if (!r) return;
        if (r.kind === "app") { bump(r.app.id); r.app.execute(); }
        else if (r.kind === "calc") copy(r.copy);
        else if (r.kind === "cmd") Quickshell.execDetached(["sh", "-c", r.cmd]);
        else if (r.kind === "web") Quickshell.execDetached(["xdg-open", r.url]);
        else if (r.kind === "hint") { input.text = r.fill; return; }
        close();
    }

    function move(d) {
        if (count === 0) return;
        const step = mode === "emoji" && Math.abs(d) > 1 ? d : d;
        current = (current + step + count) % count;
        if (mode === "emoji") egrid.positionViewAtIndex(current, GridView.Contain);
        else list.positionViewAtIndex(current, ListView.Contain);
    }

    FileView {
        id: usageFile
        path: Quickshell.env("HOME") + "/.cache/quickshell/launcher.json"
        printErrors: false
        onLoaded: { try { root.usage = JSON.parse(text()); } catch (e) {} }
    }

    // dim backdrop, click to close
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.25)
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        MouseArea { anchors.fill: parent; onClicked: root.close() }
    }

    Rectangle {
        id: box
        width: 660
        height: 580
        anchors.horizontalCenter: parent.horizontalCenter
        y: (parent.height - height) / 2 + (root.shown ? 0 : 16)
        radius: 28
        color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.9)
        border.width: 1
        border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.6)
        opacity: root.shown ? 1 : 0
        scale: root.shown ? 1 : 0.97
        Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 150 } }
        Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        MouseArea { anchors.fill: parent }   // swallow clicks

        // ---- search field ----
        Rectangle {
            id: field
            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
            anchors.margins: 16
            height: 56; radius: 28
            color: Theme.surfaceHigh

            Icon {
                id: searchIcon
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                code: root.mode === "cmd" ? 0xF018D : root.mode === "emoji" ? 0xF0C79 : root.mode === "bang" ? 0xF059F : 0xF0349
                size: 20
                color: Theme.primary
            }
            TextInput {
                id: input
                anchors.left: searchIcon.right; anchors.leftMargin: 14
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font; font.pixelSize: 16
                color: Theme.text
                selectionColor: Theme.primary
                selectedTextColor: Theme.fgPrimary
                clip: true
                focus: true
                onTextChanged: root.current = 0
                Keys.onEscapePressed: root.close()
                Keys.onReturnPressed: root.activate(root.current)
                Keys.onEnterPressed: root.activate(root.current)
                Keys.onUpPressed: root.move(root.mode === "emoji" ? -egrid.cols : -1)
                Keys.onDownPressed: root.move(root.mode === "emoji" ? egrid.cols : 1)
                Keys.onTabPressed: root.move(1)
                Keys.onBacktabPressed: root.move(-1)
                Keys.onLeftPressed: event => { if (root.mode === "emoji" && cursorPosition === text.length) root.move(-1); else event.accepted = false; }
                Keys.onRightPressed: event => { if (root.mode === "emoji" && cursorPosition === text.length) root.move(1); else event.accepted = false; }
                SText {
                    visible: !parent.text
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Search " + Brand.name + "…  apps, 2+2, :emoji, !yt, > cmd"
                    dim: true
                    font.pixelSize: 15
                }
            }
        }

        // ---- list results ----
        ListView {
            id: list
            visible: root.mode !== "emoji"
            anchors.top: field.bottom; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.bottomMargin: 12
            clip: true
            spacing: 2
            boundsBehavior: Flickable.StopAtBounds
            model: root.mode !== "emoji" ? root.results : []
            currentIndex: root.current

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool sel: index === root.current
                readonly property bool isApp: modelData.kind === "app"
                width: list.width
                height: modelData.kind === "calc" ? 70 : 60
                radius: 30
                color: sel ? Theme.primary
                     : hov.containsMouse ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06) : "transparent"

                // first rows slide in a little (cheap, runs once per query)
                opacity: 0
                Component.onCompleted: if (index < 10) intro.start(); else opacity = 1
                SequentialAnimation {
                    id: intro
                    PauseAnimation { duration: row.index * 15 }
                    NumberAnimation { target: row; property: "opacity"; from: 0; to: 1; duration: 140 }
                }

                Image {
                    visible: row.isApp
                    anchors.left: parent.left; anchors.leftMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    width: 36; height: 36
                    sourceSize: Qt.size(72, 72)
                    asynchronous: true
                    source: row.isApp ? Quickshell.iconPath(row.modelData.app.icon, "application-x-executable") : ""
                }
                Icon {
                    visible: !row.isApp
                    anchors.left: parent.left; anchors.leftMargin: 22
                    anchors.verticalCenter: parent.verticalCenter
                    code: row.modelData.icon || 0xF018D
                    size: 22
                    color: row.sel ? Theme.fgPrimary : Theme.primary
                }
                Column {
                    anchors.left: parent.left; anchors.leftMargin: 66
                    anchors.right: parent.right; anchors.rightMargin: 20
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    SText {
                        width: parent.width
                        text: row.isApp ? row.modelData.app.name : row.modelData.title
                        font.pixelSize: row.modelData.kind === "calc" ? 22 : 14
                        font.weight: row.sel || row.modelData.kind === "calc" ? Font.Bold : Font.Normal
                        color: row.sel ? Theme.fgPrimary : Theme.text
                    }
                    SText {
                        width: parent.width
                        visible: text !== ""
                        text: row.isApp ? (row.modelData.app.genericName || row.modelData.app.comment || "")
                            : row.modelData.subtitle + (row.modelData.kind === "calc" ? "   ·   Enter copies" : "")
                        font.pixelSize: 12
                        color: row.sel ? Theme.fgPrimary : Theme.subtext
                        opacity: 0.85
                    }
                }
                MouseArea {
                    id: hov
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.current = row.index
                    onClicked: { root.current = row.index; root.activate(row.index); }
                }
            }

            SText {
                anchors.centerIn: parent
                visible: root.results.length === 0 && root.mode !== "emoji"
                text: root.mode === "cmd" ? "Type a command after >" : "No results"
                dim: true
            }
        }

        // ---- emoji grid ----
        GridView {
            id: egrid
            visible: root.mode === "emoji"
            readonly property int cols: Math.floor(width / cellWidth)
            anchors.top: field.bottom; anchors.topMargin: 10
            anchors.left: parent.left; anchors.right: parent.right
            anchors.bottom: emojiName.top
            anchors.leftMargin: 14; anchors.rightMargin: 14
            clip: true
            cellWidth: Math.floor(width / 10); cellHeight: cellWidth
            boundsBehavior: Flickable.StopAtBounds
            model: root.emojis
            currentIndex: root.current
            delegate: Rectangle {
                required property var modelData
                required property int index
                readonly property bool sel: index === root.current
                width: egrid.cellWidth - 4; height: width; radius: 16
                color: sel ? Theme.primary : em.containsMouse ? Theme.surfaceHigh : "transparent"
                Text { anchors.centerIn: parent; text: parent.modelData.emoji; font.pixelSize: 30 }
                MouseArea { id: em; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onEntered: root.current = parent.index; onClicked: root.activate(parent.index) }
            }
            SText { anchors.centerIn: parent; visible: root.emojis.length === 0; text: root.emojiList ? "No emoji match" : "Loading emoji…"; dim: true }
        }
        SText {
            id: emojiName
            visible: root.mode === "emoji"
            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
            anchors.margins: 16
            horizontalAlignment: Text.AlignHCenter
            text: root.emojis[root.current] ? root.emojis[root.current].name + "   ·   Enter copies" : ""
            dim: true; font.pixelSize: 12
        }
    }
}
