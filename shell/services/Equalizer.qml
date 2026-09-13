pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// 10-band equalizer on top of easyeffects 8.x (the Qt/Kirigami port — it has NO gsettings schema any more).
// The running service is driven over its local socket $XDG_RUNTIME_DIR/EasyEffectsServer with newline-terminated
// commands (get_property / set_property / load_preset — easyeffects src/local_server.cpp). The shell keeps its
// own state in ~/.config/rrk-shell/eq.json and pushes it; the EQ plugin is put into the output pipeline by
// loading a generated preset ~/.local/share/easyeffects/output/rrk-eq.json (rewritten on every setup pass;
// FileView creates the directory if needed). The DSP itself is LSP's para_equalizer (package lsp-plugins-lv2):
// without it easyeffects still answers every command but nothing is audible, so the probe checks the LV2
// bundle on disk before it even looks for the socket.
Singleton {
    id: root

    // ── constants ──────────────────────────────────────────────────────────
    readonly property var freqs:  [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property var labels: ["31", "62", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property int minDb: -12
    readonly property int maxDb: 12
    readonly property var presetNames: ["Flat", "Bass", "Treble", "Vocal", "Pop", "Rock", "Jazz", "Classic"]
    readonly property var presets: ({
        "Flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "Bass":    [5, 6, 5, 3, 1, 0, 0, 0, 0, 0],
        "Treble":  [0, 0, 0, 0, 0, 1, 3, 5, 6, 6],
        "Vocal":   [-2, -1, 0, 2, 4, 4, 3, 1, 0, -1],
        "Pop":     [-1, 0, 2, 4, 4, 2, 0, -1, -1, -1],
        "Rock":    [5, 4, 2, -1, -2, -1, 2, 4, 5, 5],
        "Jazz":    [4, 3, 1, 2, -1, -1, 0, 1, 3, 4],
        "Classic": [4, 3, 2, 0, -1, -1, 0, 2, 3, 4]
    })

    // ── user state (persisted in eq.json). `bands` is always REPLACED, never mutated in place ──
    property var bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]   // dB per band
    property bool enabled: true
    property string preset: "Flat"                       // a presetNames entry | "Saved" | "Custom"
    property var saved: null                             // the "Saved" slot: 10 numbers or null
    property bool expanded: true

    // ── backend state ──
    // not-installed (no easyeffects binary) | no-plugin (lsp-plugins-lv2 missing) | not-running | connecting
    // | setting-up (installing the preset) | ready | failed (setup gave up; click to retry)
    property string status: "not-running"
    readonly property bool ready: status === "ready"
    readonly property bool installed: status !== "not-installed" && status !== "no-plugin"
    readonly property string statusText: status === "not-installed" ? "easyeffects is not installed"
        : status === "no-plugin" ? "Equalizer plugin missing (lsp-plugins-lv2)"
        : status === "not-running" ? "easyeffects is not running"
        : status === "failed" ? "Could not set up easyeffects" : status === "ready" ? "" : "Connecting to easyeffects…"
    readonly property string statusHint: status === "not-installed" ? "Run install.sh again — it adds easyeffects and lsp-plugins-lv2."
        : status === "no-plugin" ? "Run install.sh again (it installs lsp-plugins-lv2), then re-open this panel."
        : status === "not-running" ? "Click to start it (it also starts with Hyprland)."
        : status === "failed" ? "Click to retry · details in `rrkshell log`" : ""
    property string socketPath: ""
    property var pending: []          // reply callbacks for get_property, FIFO (replies come back in order)
    property var dirty: ({})          // band index -> true, flushed by pushTimer
    property int setupTries: 0
    property int pollsLeft: 6         // remaining 10 s re-probes while easyeffects is off; re-armed by refresh()/startService()
    property int presetSeq: 0         // bumps the stamp inside rrk-eq.json so every install is a real write

    // ── helpers ──
    function clamp(v) { return Math.max(minDb, Math.min(maxDb, Math.round(v * 2) / 2)) }
    function same(a, b) { if (!a || !b || a.length !== b.length) return false; for (let i = 0; i < a.length; i++) if (Math.abs(a[i] - b[i]) > 0.01) return false; return true }
    function matchPreset(g) { for (const n of presetNames) if (same(presets[n], g)) return n; return (saved && same(saved, g)) ? "Saved" : "Custom" }
    function allDirty() { const d = {}; for (let i = 0; i < 10; i++) d[i] = true; return d }

    // ── actions (used by the panel) ──
    function setBand(i, db) {
        db = clamp(db); if (bands[i] === db) return
        const b = bands.slice(); b[i] = db; bands = b
        preset = matchPreset(b)
        const d = Object.assign({}, dirty); d[i] = true; dirty = d
        pushTimer.restart(); saveTimer.restart()
    }
    function applyPreset(name) {
        const g = name === "Saved" ? saved : presets[name]; if (!g) return
        bands = g.slice(); preset = name; dirty = allDirty()
        pushTimer.restart(); saveTimer.restart()
    }
    function saveCurrent() { saved = bands.slice(); preset = "Saved"; saveTimer.restart() }
    function clickSaved() { if (preset === "Custom" || !saved) saveCurrent(); else applyPreset("Saved") }
    function setEnabled(on) { enabled = on; send("set_property:output:equalizer:0:bypass:" + (on ? "false" : "true")); saveTimer.restart() }
    function toggleExpanded() { expanded = !expanded; saveTimer.restart() }
    // --service-mode: the window opens but closing it does not quit the backend (a running instance just gets show_window)
    function openGui() { Quickshell.execDetached(["easyeffects", "--service-mode"]); if (!ready) kickStart() }
    function startService() { Quickshell.execDetached(["easyeffects", "--hide-window", "--service-mode"]); kickStart() }
    // after a start click: easyeffects needs a moment to create its socket, so probe every 2.5 s for 10 s, then fall back to the 10 s poll
    function kickStart() { pollsLeft = 6; startDelay.left = 4; startDelay.restart() }
    function retry() { pending = []; sock.active = false; setupTries = 0; status = "not-running"; pollsLeft = 6; probe.running = true }
    // called when the media panel opens: re-probe if needed, else adopt whatever easyeffects currently has
    function refresh() {
        if (!ready) { pollsLeft = 6; if (status !== "connecting" && status !== "setting-up") probe.running = true; return }
        const got = []
        for (let i = 0; i < 10; i++) ask("get_property:output:equalizer:0:left:band" + i + "Gain", v => got.push(parseFloat(v)))
        ask("get_property:output:equalizer:0:bypass", v => {
            if (got.length !== 10 || got.some(isNaN) || pushTimer.running || Object.keys(dirty).length) return
            const g = got.map(clamp); let changed = false
            if (!same(g, bands)) { bands = g; preset = matchPreset(g); changed = true }
            const on = v !== "true"
            if (on !== enabled) { enabled = on; changed = true }
            if (changed) saveTimer.restart()
        })
    }

    // ── persistence: ~/.config/rrk-shell/eq.json ──
    FileView {
        id: store
        printErrors: false            // before `path`: the first read must be silent when eq.json does not exist yet
        atomicWrites: true
        path: Quickshell.env("HOME") + "/.config/rrk-shell/eq.json"
        onLoaded: {
            try {
                const j = JSON.parse(text())
                if (Array.isArray(j.bands) && j.bands.length === 10) root.bands = j.bands.map(root.clamp)
                if (typeof j.enabled === "boolean") root.enabled = j.enabled
                if (Array.isArray(j.saved) && j.saved.length === 10) root.saved = j.saved.map(root.clamp)
                if (typeof j.expanded === "boolean") root.expanded = j.expanded
                root.preset = (j.preset === "Saved" || j.preset === "Custom" || root.presets[j.preset]) ? j.preset : root.matchPreset(root.bands)
            } catch (e) { console.warn("eq.json parse error", e) }
            probe.running = true
        }
        onLoadFailed: probe.running = true
    }
    Timer { id: saveTimer; interval: 1000; onTriggered: store.setText(JSON.stringify({ enabled: root.enabled, preset: root.preset, bands: root.bands, saved: root.saved, expanded: root.expanded }, null, 2) + "\n") }

    // ── is easyeffects usable? prints "none" (no binary) | "noplugin" (no LSP LV2 bundle) | "off" | <socket path>.
    //    A live process is required: after a crash the socket file lingers and connecting to it would only log errors.
    //    Re-run every 10 s while it is off, at most `pollsLeft` times (panel open / start click re-arm it). ──
    Process {
        id: probe
        command: ["sh", "-c", [
            "command -v easyeffects >/dev/null 2>&1 || { echo none; exit 0; }",
            "(IFS=:; for d in ${LV2_PATH:-$HOME/.lv2:/usr/lib/lv2:/usr/local/lib/lv2}; do [ -d \"$d/lsp-plugins.lv2\" ] && exit 0; done; exit 1) || { echo noplugin; exit 0; }",
            "s=\"${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/EasyEffectsServer\"",
            "pgrep -x easyeffects >/dev/null 2>&1 && [ -S \"$s\" ] && echo \"$s\" || echo off"
        ].join("\n")]
        stdout: StdioCollector { onStreamFinished: root.onProbe(text.trim()) }
    }
    Timer { interval: 10000; repeat: true; running: root.status === "not-running" && root.pollsLeft > 0
            onTriggered: { root.pollsLeft--; probe.running = true } }
    Timer { id: startDelay; interval: 2500; repeat: true; property int left: 0; onTriggered: { probe.running = true; if (--left <= 0) stop() } }
    function onProbe(t) {
        if (t === "none") { status = "not-installed"; return }
        if (t === "noplugin") { status = "no-plugin"; return }
        if (!t.startsWith("/")) { if (status !== "ready") status = "not-running"; return }
        if (sock.active) return
        socketPath = t; status = "connecting"; sock.active = true
    }

    // ── socket to the running easyeffects. Quickshell 0.3.1's Socket cannot retry after a failed connect
    //    (a dead QLocalSocket stays attached), so a fresh one is created per attempt through the Loader.
    //    Handlers check `sock.item === conn` so a socket that is already being torn down cannot act on its successor. ──
    Loader {
        id: sock
        active: false
        sourceComponent: Socket {
            id: conn
            path: root.socketPath
            parser: SplitParser { onRead: line => { if (sock.item === conn) root.onReply(line) } }
            onConnectionStateChanged: { if (sock.item !== conn) return; if (connected) root.onConnected(); else root.onDisconnected(false) }
            onError: err => { if (sock.item === conn) root.onDisconnected(root.status === "connecting") }
        }
        onLoaded: item.connected = true      // connect only once the handlers above exist (a failed connect errors synchronously)
    }
    function send(msg) { const s = sock.item; if (s && s.connected) { s.write(msg + "\n"); s.flush() } }
    function ask(msg, cb) { const s = sock.item; if (!(s && s.connected)) return; const p = pending.slice(); p.push(cb); pending = p; send(msg); replyTimeout.restart() }
    function onReply(line) {
        if (pending.length === 0) return
        const p = pending.slice(); const cb = p.shift(); pending = p
        if (p.length === 0) replyTimeout.stop(); else replyTimeout.restart()
        cb(line.trim())
    }
    Timer { id: replyTimeout; interval: 2000; onTriggered: { console.warn("equalizer: easyeffects did not answer, reconnecting"); root.onDisconnected(false) } }
    // a unix-socket connect normally succeeds or fails synchronously; this only guards the EAGAIN retry path so "connecting" can never stick
    Timer { id: connectTimeout; interval: 5000; running: root.status === "connecting"; onTriggered: { console.warn("equalizer: connecting to easyeffects timed out"); root.onDisconnected(true) } }
    function onConnected() { status = "setting-up"; setupTries = 0; verify() }
    // connectFailed = the socket file exists but nobody answers: stop polling until the panel is opened again
    function onDisconnected(connectFailed) {
        pending = []; sock.active = false; verifyDelay.stop(); replyTimeout.stop()
        if (connectFailed) pollsLeft = 0
        if (installed) status = "not-running"
    }

    // ── make sure the output pipeline is [equalizer#0] with our 10 bands, then push the shell state.
    //    (The plugin DBs are created on demand and live until easyeffects exits, so this only checks the layout.) ──
    function verify() {
        let nb = ""
        ask("get_property:output:equalizer:0:numBands", v => { nb = v })
        ask("get_property:output:equalizer:0:left:band9Frequency", v => {
            if (nb === "10" && Math.abs(parseFloat(v) - 16000) < 1) { pushAll(); status = "ready" }
            else if (setupTries < 2) { setupTries++; installPreset() }
            else { status = "failed"; console.warn("equalizer: easyeffects setup failed (numBands=" + nb + ", band9Frequency=" + v + ")") }
        })
    }
    // always a real write (the "rrk-shell.written" stamp changes every time): FileView.setText() is a no-op for
    // unchanged text and would never emit `saved` — e.g. after the user deleted rrk-eq.json
    function installPreset() { presetFile.setText(JSON.stringify(makePreset(), null, 2) + "\n") }
    FileView {
        id: presetFile
        printErrors: false
        preload: false
        atomicWrites: true
        path: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/easyeffects/output/rrk-eq.json"
        onSaved: { root.send("load_preset:output:rrk-eq"); verifyDelay.restart() }
        onSaveFailed: { root.status = "failed"; console.warn("equalizer: cannot write " + path) }
    }
    Timer { id: verifyDelay; interval: 300; onTriggered: root.verify() }
    function makePreset() {
        const ch = {}
        for (let i = 0; i < 10; i++)
            ch["band" + i] = { type: "Bell", mode: "RLC (BT)", slope: "x1", solo: false, mute: false, gain: bands[i], frequency: freqs[i], q: 1.41, width: 4 }
        return { "rrk-shell": { written: Date.now(), seq: ++presetSeq }, output: { blocklist: [], plugins_order: ["equalizer#0"], "equalizer#0": {
            bypass: !enabled, "input-gain": 0, "output-gain": 0, mode: "IIR", decramp: "Off", "split-channels": false,
            balance: 0, "pitch-left": 0, "pitch-right": 0, "num-bands": 10, left: ch, right: ch } } }
    }
    function pushAll() {
        for (let i = 0; i < 10; i++) send("set_property:output:equalizer:0:left:band" + i + "Gain:" + bands[i].toFixed(1))
        send("set_property:output:equalizer:0:bypass:" + (enabled ? "false" : "true"))
        dirty = ({})
    }
    Timer { id: pushTimer; interval: 60; onTriggered: root.flushPush() }
    function flushPush() {
        if (ready) for (const k of Object.keys(dirty)) send("set_property:output:equalizer:0:left:band" + k + "Gain:" + bands[k].toFixed(1))
        dirty = ({})
    }
}
