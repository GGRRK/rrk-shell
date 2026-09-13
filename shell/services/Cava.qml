pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Audio spectrum for the desktop visualizer. Runs `cava -p scripts/cava.conf` (raw ASCII output: one line per
// frame, 40 values 0..100 separated by ';', 20 fps) and exposes the latest frame as `bars`.
// cava only runs while something is playing (MPRIS) AND the visualizer widget is actually on screen (enabled,
// not hidden, no window covering the desktop); it is stopped 3 s after playback pauses and restarted when the
// default audio output changes (cava captures the sink's monitor).
Singleton {
    id: root
    readonly property int count: 40
    readonly property var zeros: Array(count).fill(0)
    property var bars: zeros                       // int[count], 0..100
    property bool available: false                 // `cava` found in PATH (probed once at startup)
    readonly property bool running: proc.running
    // the card stays for a minute after playback pauses, then folds away (a paused browser tab would
    // otherwise keep a dead visualizer on the desktop for hours)
    property bool recent: false
    // add `|| Panels.open === "media"` here if a popup panel ever shows the visualizer too
    readonly property bool shouldRun: available && Media.playing && Widgets.enabled && Widgets.cava && Widgets.desktopVisible
    property int failures: 0

    // Quickshell emits no `exited` when a command cannot start at all, so a missing binary would otherwise
    // fail silently: probe once and keep the card hidden if cava is not installed (`sudo pacman -S cava`).
    Process {
        command: ["sh", "-c", "command -v cava"]
        running: true
        onExited: (code, status) => { root.available = code === 0; if (!root.available) console.warn("rrk-shell: cava not found — desktop visualizer disabled (sudo pacman -S cava)") }
    }

    onShouldRunChanged: {
        if (shouldRun) { failures = 0; stopDelay.stop(); if (!proc.running) proc.running = true }
        else stopDelay.restart()
    }
    Connections {
        target: Media
        function onPlayingChanged() { if (Media.playing) { root.recent = true; recentTimer.stop() } else recentTimer.restart() }
    }
    Timer { id: recentTimer;  interval: 60000; onTriggered: root.recent = Media.playing }
    Timer { id: stopDelay;    interval: 3000;  onTriggered: if (!root.shouldRun) proc.running = false }
    Timer { id: restartTimer; interval: 1500;  onTriggered: if (root.shouldRun && !proc.running) proc.running = true }
    Connections { target: Audio; function onSinkChanged() { if (proc.running) proc.running = false } }   // onExited restarts it

    Process {
        id: proc
        command: ["cava", "-p", Quickshell.shellDir + "/scripts/cava.conf"]
        stdout: SplitParser { onRead: data => root.parse(data) }
        onExited: (code, status) => {
            root.bars = root.zeros
            if (!root.shouldRun) return
            if (++root.failures <= 5) restartTimer.start()      // deliberate restarts count too; reset by the next good frame
            else console.warn("cava keeps exiting (exit " + code + ") — visualizer off until playback restarts")
        }
    }
    function parse(line) {
        const p = line.split(";")
        if (p.length < count) return
        const out = new Array(count)
        for (let i = 0; i < count; i++) { const v = parseInt(p[i]); out[i] = isNaN(v) ? 0 : Math.max(0, Math.min(100, v)) }
        bars = out; failures = 0
    }
}
