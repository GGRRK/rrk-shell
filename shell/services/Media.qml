pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root
    readonly property var players: Mpris.players.values
    // prefer whichever player is actually playing, else the first one
    readonly property var player: players.find(p => p.playbackState === MprisPlaybackState.Playing) || (players.length ? players[0] : null)
    readonly property bool active: player !== null
    readonly property bool playing: player ? player.playbackState === MprisPlaybackState.Playing : false
    readonly property string title:  player ? (player.trackTitle || "Unknown") : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string artUrl: player ? (player.trackArtUrl || "") : ""
    readonly property string app:    player ? (player.identity || "") : ""
    readonly property real length:   player ? player.length : 0
    readonly property real position: player ? player.position : 0

    // MPRIS position doesn't tick on its own; poke it once a second while playing
    Timer { interval: 1000; running: root.playing; repeat: true; onTriggered: root.player.positionChanged() }

    function toggle()   { if (player && player.canTogglePlaying) player.togglePlaying() }
    function next()     { if (player && player.canGoNext) player.next() }
    function previous() { if (player && player.canGoPrevious) player.previous() }
    function seek(s)    { if (player && player.canSeek) player.position = s }
    function fmt(s) { s = Math.max(0, Math.floor(s)); return Math.floor(s / 60) + ":" + (s % 60 < 10 ? "0" : "") + (s % 60) }
}
