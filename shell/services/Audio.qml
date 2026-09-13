pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root
    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source].filter(n => n !== null) }

    readonly property real volume: (sink && sink.audio) ? sink.audio.volume : 0
    readonly property bool muted:  (sink && sink.audio) ? sink.audio.muted : false
    readonly property real micVolume: (source && source.audio) ? source.audio.volume : 0
    readonly property bool micMuted:  (source && source.audio) ? source.audio.muted : false
    readonly property string sinkName: sink ? (sink.description || sink.name) : "No output"
    readonly property string icon: muted || volume === 0 ? "volume_off" : volume < 0.4 ? "volume_down" : "volume_up"

    function setVolume(v) { if (sink && sink.audio) sink.audio.volume = Math.max(0, Math.min(1, v)) }
    function step(d)      { setVolume(volume + d) }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted }
    function toggleMicMute() { if (source && source.audio) source.audio.muted = !source.audio.muted }
}
