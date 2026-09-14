pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Screen brightness (bar OSD, notification-centre slider, XF86 keys via `osd brightness up|down`).
// Two modes — settings.json {"brightness": {"mode": "backlight" | "shader"}}, default "backlight":
//   backlight  the normal way: brightnessctl.
//   shader     software dimming with a Hyprland screen shader: every frame is multiplied by `value` in a tiny GLSL program
//              written to ~/.cache/rrk-shell/dim-{a,b}.frag (two names, alternated, so Hyprland notices the change) and
//              applied with `hyprctl eval 'hl.config({ decoration = { screen_shader = ... } })'`; at 100 % the shader is
//              removed again (no cost). Needed on this laptop: under nouveau the EC backlight takes values but the panel
//              never changes, and there is no gamma either (legacy DRM) — memory/fix-backlight-dead-nouveau.md.
//              It only darkens the picture (no power saving); the value is kept in ~/.local/state/rrk-shell/brightness
//              and re-applied at startup. Drag events are coalesced (one shader swap per 50 ms, never two at once).
Singleton {
    id: root
    property real value: 1                 // 0..1
    property bool available: false
    property string mode: "backlight"
    readonly property real minimum: mode === "shader" ? 0.15 : 0.02   // a slider must never leave a black screen
    property bool dirty: false
    property int flip: 0
    property bool ready: false

    function clamp(v) { return Math.max(minimum, Math.min(1, v)) }
    function set(v) {
        v = clamp(v); root.value = v
        if (mode === "shader") { dirty = true; applyTimer.restart() }
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
        const m = b.mode === "shader" ? "shader" : "backlight"
        if (m === mode && ready) return
        mode = m
        if (mode === "shader") { const v = parseFloat(stateFile.text()); value = isNaN(v) ? 1 : clamp(v); available = true; dirty = true; apply() }
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

    // ── shader mode ──
    FileView { id: stateFile; path: Quickshell.env("HOME") + "/.local/state/rrk-shell/brightness"; blockLoading: true; printErrors: false }
    Timer { id: applyTimer; interval: 50; onTriggered: if (!hypr.running) root.apply() }
    Process { id: hypr; onExited: if (root.dirty && root.mode === "shader") root.apply() }
    function apply() {
        dirty = false
        const factor = value.toFixed(3)
        const cache = Quickshell.env("HOME") + "/.cache/rrk-shell"
        flip ^= 1
        const file = cache + "/dim-" + (flip ? "a" : "b") + ".frag"
        const shader = "#version 300 es\nprecision highp float;\nin vec2 v_texcoord;\nuniform sampler2D tex;\nout vec4 fragColor;\n"
                     + "void main() { vec4 c = texture(tex, v_texcoord); fragColor = vec4(c.rgb * " + factor + ", c.a); }\n"
        const lua = value >= 0.995 ? 'hl.config({ decoration = { screen_shader = "" } })'
                                   : 'hl.config({ decoration = { screen_shader = "' + file + '" } })'
        hypr.command = ["sh", "-c", 'mkdir -p "$4" && printf "%s" "$1" > "$2" && hyprctl eval "$3" >/dev/null', "sh", shader, file, lua, cache]
        hypr.running = true
        stateFile.setText(factor)
    }
}
