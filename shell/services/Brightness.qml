pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness (bar OSD, notification-centre slider, XF86 keys via `osd brightness up|down`).
// Two modes — settings.json {"brightness": {"mode": "backlight" | "overlay"}}, default "backlight":
//   backlight  the normal way: brightnessctl.
//   overlay    software dimming: panels/DimLayer.qml puts a black full-screen layer over everything with opacity
//              1 − value (input passes through). Needed on this laptop: under nouveau the EC backlight takes values
//              but the panel never changes, and there is no gamma either (legacy DRM) — memory/fix-backlight-dead-nouveau.md.
//              It only darkens the picture (no power saving). The value is kept in ~/.local/state/rrk-shell/brightness
//              (written 1 s after the last change) and restored at startup.
Singleton {
    id: root
    property real value: 1                 // 0..1
    property bool available: false
    property string mode: "backlight"
    readonly property real minimum: mode === "overlay" ? 0.15 : 0.02   // a slider must never leave a black screen
    property bool ready: false

    function clamp(v) { return Math.max(minimum, Math.min(1, v)) }
    function set(v) {
        v = clamp(v); root.value = v
        if (mode === "overlay") saveTimer.restart()
        else { setProc.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]; setProc.running = true }
    }
    function step(d) { set(value + d) }

    // ── settings.json: mode ──
    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/rrk-shell/settings.json"
        watchChanges: true
        blockLoading: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: if (root.ready) root.applySettings(text())
    }
    function applySettings(txt) {
        let b = {}
        if (txt.trim() !== "") try { b = JSON.parse(txt).brightness || {} } catch (e) { console.warn("settings.json parse error", e) }
        const m = b.mode === "overlay" ? "overlay" : "backlight"
        if (m === mode && ready) return
        mode = m
        if (mode === "overlay") { const v = parseFloat(stateFile.text()); value = isNaN(v) ? 1 : clamp(v); available = true }
        else readProc.running = true
    }
    Component.onCompleted: { applySettings(settings.text()); ready = true }

    // ── backlight mode ──
    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 5) { const max = parseInt(p[4]); if (max > 0) { root.value = parseInt(p[2]) / max; root.available = true } }
            }
        }
    }
    Process { id: setProc }
    Timer { interval: 5000; running: root.mode === "backlight"; repeat: true; onTriggered: readProc.running = true }

    // ── overlay mode: only the persisted level lives here; the layer itself is panels/DimLayer.qml ──
    FileView { id: stateFile; path: Quickshell.env("HOME") + "/.local/state/rrk-shell/brightness"; blockLoading: true; printErrors: false }
    Timer { id: saveTimer; interval: 1000; onTriggered: stateFile.setText(root.value.toFixed(3)) }
}
