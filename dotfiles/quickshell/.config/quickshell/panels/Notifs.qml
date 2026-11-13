pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// The desktop's notification server (replaces swaync).
// Popups: NotifPopups.qml. History + controls: NotifCenter.qml (its toggle IPC is in shell.qml).
// Settings live in notifications.json next to this file (edited by the settings app).
Singleton {
    id: root

    property bool dnd: false
    property bool centerOpen: false      // popups hide while the center is open, like swaync
    property var popups: []              // notifications currently shown as popups, newest first
    property var received: ({})          // notification id -> Date it arrived
    readonly property var history: server.trackedNotifications.values.slice().reverse()   // newest first

    readonly property alias cfg: cfg

    function timeoutFor(n) {
        if (n.urgency === NotificationUrgency.Critical) return cfg.timeoutCritical * 1000;
        if (n.expireTimeout > 0) return n.expireTimeout * 1000;
        return (n.urgency === NotificationUrgency.Low ? cfg.timeoutLow : cfg.timeout) * 1000;
    }
    function hidePopup(n) { popups = popups.filter(p => p !== n); }
    function dismiss(n) { hidePopup(n); n.dismiss(); }
    function clearAll() {
        popups = [];
        for (const n of server.trackedNotifications.values.slice()) n.dismiss();
    }
    function invoke(n, action) {
        action.invoke();
        if (!n.resident) dismiss(n); else hidePopup(n);
    }
    // the action a click on the card runs ("default"), if the app offers one
    function defaultAction(n) { return n.actions.find(a => a.identifier === "default") || null; }

    function ago(n) {
        const t = received[n.id];
        if (!t) return "";
        const s = Math.floor((clock.now - t) / 1000);
        if (s < 60) return "Now";
        if (s < 3600) return Math.floor(s / 60) + " min ago";
        if (s < 86400) return Math.floor(s / 3600) + " h ago";
        return Qt.formatDate(t, "d MMM");
    }
    QtObject { id: clock; property date now: new Date() }
    Timer { interval: 30000; running: true; repeat: true; onTriggered: clock.now = new Date() }

    NotificationServer {
        id: server
        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true

        onNotification: n => {
            n.tracked = true;
            const r = Object.assign({}, root.received); r[n.id] = new Date(); root.received = r;
            clock.now = new Date();
            const critical = n.urgency === NotificationUrgency.Critical;
            if (root.dnd && !critical) return;              // kept in the center, no popup
            root.popups = [n].concat(root.popups.filter(p => p !== n));
            if (root.cfg.sound && !n.hints["suppress-sound"]) sound.running = true;
        }
    }
    Connections {
        target: server.trackedNotifications
        // drop popups whose notification was closed by the app
        function onValuesChanged() {
            const live = server.trackedNotifications.values;
            if (root.popups.some(p => live.indexOf(p) < 0)) root.popups = root.popups.filter(p => live.indexOf(p) >= 0);
        }
    }

    Process {
        id: sound
        command: ["sh", "-c", "f=\"$HOME/.local/share/sounds/notification.wav\"; [ -f \"$f\" ] && exec pw-play \"$f\""]
    }

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/panels/notifications.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: cfg
            property string x: "right"           // left | center | right
            property string y: "top"             // top | bottom
            property int width: 380
            property int iconSize: 42
            property int timeout: 6              // seconds, normal urgency
            property int timeoutLow: 4
            property int timeoutCritical: 0      // 0 = stays until closed
            property bool sound: true
        }
    }

    IpcHandler {
        target: "notifications"
        function clear(): void { root.clearAll(); }
        function getDnd(): bool { return root.dnd; }
        function setDnd(on: bool): void { root.dnd = on; }
        function toggleDnd(): void { root.dnd = !root.dnd; }
    }
}
