pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default speaker + microphone from PipeWire, plus the device and app lists
// Quick Settings shows (what pavucontrol used to be for).
Singleton {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    function setVolume(v) { if (sink && sink.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function setMic(v) { if (source && source.audio) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1, v)); } }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var apps: nodes.filter(n => n.audio && n.isStream && n.isSink)    // apps playing sound

    function deviceName(n) { return n ? (n.description || n.nickname || n.name) : ""; }
    function appName(n) {
        if (!n) return "";
        const p = n.properties || {};
        return p["application.name"] || n.description || n.name;
    }
    function useOutput(n) { Pipewire.preferredDefaultAudioSink = n; }
    function useInput(n) { Pipewire.preferredDefaultAudioSource = n; }

    PwObjectTracker { objects: [root.sink, root.source].concat(root.apps) }
}
