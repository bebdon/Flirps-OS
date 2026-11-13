import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// App dock (replaces nwg-dock-hyprland), same look: pinned apps, then running ones,
// a dot under running apps, a 2px primary line under the focused one, launcher grid at the end.
// Settings + pinned apps live in dock.json (the settings app and the right-click menu edit it).
Scope {
    id: root

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/quickshell/panels/dock.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property var pinned: ["kitty", "thunar", "waterfox"]
            property string mode: "autohide"          // autohide | resident (always visible)
            property string position: "bottom"        // bottom | top | left | right
            property int size: 44
            property int margin: 6
        }
    }

    function norm(id) { return String(id || "").toLowerCase(); }
    function entryFor(id) { return DesktopEntries.heuristicLookup(id); }
    function isPinned(id) { return cfg.pinned.some(p => norm(p) === norm(id)); }
    function setPinned(id, on) {
        cfg.pinned = on ? cfg.pinned.concat([id]) : cfg.pinned.filter(p => norm(p) !== norm(id));
        file.writeAdapter();
    }
    function launch(id) {
        const e = entryFor(id);
        if (e) e.execute(); else Quickshell.execDetached(["sh", "-c", id]);
    }

    // one entry per app: pinned first (in order), then running apps that aren't pinned
    readonly property var windows: ToplevelManager.toplevels.values
    readonly property var apps: {
        const out = cfg.pinned.map(p => ({ id: p, wins: [] }));
        for (const w of windows) {
            const id = w.appId || "";
            if (!id) continue;
            let a = out.find(x => norm(x.id) === norm(id));
            if (!a) { a = { id: id, wins: [] }; out.push(a); }
            a.wins.push(w);
        }
        return out;
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen
            required property var modelData
            readonly property bool vertical: cfg.position === "left" || cfg.position === "right"
            property bool hotspotHovered: false
            property bool dockHovered: false
            property bool menuOpen: false
            property bool forcedHidden: false            // after a click, until the pointer leaves
            readonly property bool show: cfg.mode !== "autohide" || ((hotspotHovered || dockHovered || menuOpen) && !forcedHidden)
            onDockHoveredChanged: if (!dockHovered && !hotspotHovered) forcedHidden = false
            onHotspotHoveredChanged: if (!dockHovered && !hotspotHovered) forcedHidden = false

            // thin strip at the screen edge that reveals the dock (autohide mode)
            PanelWindow {
                screen: perScreen.modelData
                visible: cfg.mode === "autohide"
                color: "transparent"
                anchors {
                    bottom: cfg.position === "bottom"; top: cfg.position === "top"
                    left: cfg.position === "left" || !perScreen.vertical; right: cfg.position === "right" || !perScreen.vertical
                }
                implicitHeight: perScreen.vertical ? 0 : 2
                implicitWidth: perScreen.vertical ? 2 : 0
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-dock-hotspot"
                Item {
                    anchors.fill: parent
                    HoverHandler {
                        onHoveredChanged: hotTimer.restart()
                        id: hotHover
                    }
                    Timer { id: hotTimer; interval: 20; onTriggered: perScreen.hotspotHovered = hotHover.hovered }
                }
            }

            PanelWindow {
                id: dockWin
                screen: perScreen.modelData
                visible: perScreen.show || hideDelay.running
                color: "transparent"
                anchors {
                    bottom: cfg.position === "bottom"; top: cfg.position === "top"
                    left: cfg.position === "left"; right: cfg.position === "right"
                }
                margins { bottom: cfg.margin; top: cfg.margin; left: cfg.margin; right: cfg.margin }
                implicitWidth: box.width
                implicitHeight: box.height
                exclusionMode: ExclusionMode.Ignore
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "qs-dock"

                // keep mapped briefly so leaving the hotspot for the dock doesn't flicker
                Timer { id: hideDelay; interval: 200 }
                Connections { target: perScreen; function onShowChanged() { if (!perScreen.show) hideDelay.restart(); } }

                HoverHandler { onHoveredChanged: perScreen.dockHovered = hovered }

                // box: surface_container @ 75%, 1px outline_variant @ 50%, radius 14, padding 4 6
                Rectangle {
                    id: box
                    width: grid.implicitWidth + (perScreen.vertical ? 8 : 12) + 2
                    height: grid.implicitHeight + (perScreen.vertical ? 12 : 8) + 2
                    radius: 14
                    color: Qt.rgba(Theme.surfaceMid.r, Theme.surfaceMid.g, Theme.surfaceMid.b, 0.75)
                    border.width: 1
                    border.color: Qt.rgba(Theme.outlineVariant.r, Theme.outlineVariant.g, Theme.outlineVariant.b, 0.5)

                    Grid {
                        id: grid
                        x: 1 + (perScreen.vertical ? 4 : 6)
                        y: 1 + (perScreen.vertical ? 6 : 4)
                        columns: perScreen.vertical ? 1 : root.apps.length + 1
                        spacing: 0

                        Repeater {
                            model: root.apps
                            DockButton {
                                required property var modelData
                                appId: modelData.id
                                wins: modelData.wins
                                entry: root.entryFor(modelData.id)
                                pinned: root.isPinned(modelData.id)
                                iconSize: cfg.size
                                vertical: perScreen.vertical
                                edge: cfg.position
                                onLaunch: { root.launch(appId); perScreen.forcedHidden = true; }
                                onFocused: perScreen.forcedHidden = true
                                onTogglePin: root.setPinned(appId, !pinned)
                                onMenuOpenChanged: perScreen.menuOpen = menuOpen
                            }
                        }

                        // launcher grid (nwg-dock's -c button)
                        DockButton {
                            launcher: true
                            iconSize: cfg.size
                            vertical: perScreen.vertical
                            edge: cfg.position
                            onLaunch: {
                                Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/qs-panel", "launcher"]);
                                perScreen.forcedHidden = true;
                            }
                        }
                    }
                }
            }
        }
    }
}
