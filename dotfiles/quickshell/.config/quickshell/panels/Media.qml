pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// Picks the most relevant MPRIS player (playing first, otherwise the first one).
Singleton {
    id: root
    readonly property var players: Mpris.players.values.filter(p => !String(p.dbusName).includes("playerctld"))
    property int manualIndex: -1
    readonly property var player: {
        if (players.length === 0) return null;
        if (manualIndex >= 0 && manualIndex < players.length) return players[manualIndex];
        return players.find(p => p.playbackState === MprisPlaybackState.Playing) || players[0];
    }
    readonly property bool active: player !== null
    readonly property bool playing: !!player && player.playbackState === MprisPlaybackState.Playing
    readonly property string title: player ? (player.trackTitle || "Unknown title") : ""
    readonly property string artist: player ? (player.trackArtist || player.identity || "") : ""
    readonly property string art: player ? (player.trackArtUrl || "") : ""

    function cycle() { if (players.length > 1) manualIndex = (players.indexOf(player) + 1) % players.length; }
}
