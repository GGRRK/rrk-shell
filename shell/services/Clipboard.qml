pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Clipboard history front-end for cliphist. The entry list (newest first) comes from shell/scripts/clip-list.sh,
// which also makes a small thumbnail for every image entry in ~/.cache/rrk-shell/clip/<id>.png. Text snippets
// (first 3 lines of the real content — `cliphist list` previews collapse whitespace) are decoded lazily for the
// rows that are on screen, one Process at a time, and cached in `texts` for the rest of the session.
Singleton {
    id: root
    property var entries: []        // [{id, kind: "text"|"url"|"path"|"color"|"image", preview, file?, format?, w?, h?, size?}] (file = thumbnail path or null)
    property var texts: ({})        // id -> snippet string; null = decode failed (rows fall back to the preview)
    property bool loading: false
    readonly property string repo: Quickshell.env("HOME") + "/claude/rrk-shell"
    property var _queue: []         // ids waiting for a text decode (mutated in place, nothing binds to it)
    property int _fetching: -1      // id being decoded right now, -1 = idle

    Process {
        id: lister
        command: ["bash", root.repo + "/shell/scripts/clip-list.sh"]
        stdout: StdioCollector { onStreamFinished: root._loaded(text) }
    }
    Process {
        id: fetcher
        stdout: StdioCollector { id: fetched }
        // streamFinished (text complete) is emitted before exited, and `running` is already false here.
        // `sh -c 'a | head'` exits with head's status (0 even when cliphist failed), so empty output = failure
        // (cliphist never stores whitespace-only content). No pipefail: head closing the pipe early would make
        // every entry longer than 2000 bytes look like a failure.
        onExited: (code, status) => root._fetched(code === 0 && fetched.text.trim().length > 0 ? fetched.text : null)
    }
    Process { id: act; onExited: root.refresh() }

    function refresh() { loading = true; lister.running = true }   // setting running while it runs queues one more run

    function _loaded(json) {
        loading = false
        if (json.trim() === "") return          // script exit 1: `cliphist list` failed although the DB exists — keep what we have
        let list = []
        try { list = JSON.parse(json) } catch (e) { console.warn("clip-list.sh output is not JSON:", e); return }
        if (!Array.isArray(list)) return
        entries = list.map(e => root.classify(e))
        const keep = {}                          // forget snippets of entries that are gone
        for (const e of entries) if (texts[e.id] !== undefined) keep[e.id] = texts[e.id]
        texts = keep
    }

    function classify(e) {
        if (e.kind === "image") return e
        const p = e.preview
        if (/^#([0-9a-f]{3}|[0-9a-f]{6})$/i.test(p)) e.kind = "color"
        else if (/^(https?|ftp|file|ssh|git):\/\/\S+$/i.test(p) || /^www\.\S+$/i.test(p)) e.kind = "url"
        else if (/^(\/|~\/)\S+$/.test(p)) e.kind = "path"
        else e.kind = "text"
        return e
    }

    // ── lazy text snippets ──
    function fetchText(id) {
        if (texts[id] !== undefined || _fetching === id || _queue.indexOf(id) >= 0) return
        _queue.push(id); _next()
    }
    function cancel(id) { const i = _queue.indexOf(id); if (i >= 0) _queue.splice(i, 1) }   // row went away
    function cancelAll() { _queue = [] }                                                    // panel closed
    function _next() {
        if (_fetching >= 0 || _queue.length === 0) return
        _fetching = _queue.shift()
        fetcher.command = ["sh", "-c", "cliphist decode \"$1\" | head -c 2000", "sh", String(_fetching)]
        fetcher.running = true
    }
    function _fetched(t) {
        // drop leading blank lines and trailing whitespace (a trailing "\n" would render as an empty 2nd line), keep 3 lines
        const snippet = t === null ? null : t.replace(/^\s*\n/, "").replace(/\s+$/, "").split(/\r?\n/).slice(0, 3).join("\n").slice(0, 300)
        const next = Object.assign({}, texts); next[_fetching] = snippet; texts = next   // new object so bindings re-evaluate
        _fetching = -1
        _next()
    }

    // ── actions ──
    // copy: decode into a temp file (in the private $XDG_RUNTIME_DIR) and hand it to wl-copy only if there is data
    // (never clobber the clipboard with nothing); images get an explicit MIME type so wl-copy does not have to guess
    // (that needs xdg-utils). wl-copy's background child inherits the open file descriptor, so unlinking the file
    // right after is safe (the data stays readable until that descriptor is closed).
    function copy(id, mime) {
        Quickshell.execDetached(["sh", "-c",
            "t=$(mktemp -p \"${XDG_RUNTIME_DIR:-/tmp}\") && cliphist decode \"$1\" > \"$t\" && [ -s \"$t\" ] && { if [ -n \"$2\" ]; then wl-copy -t \"$2\" < \"$t\"; else wl-copy < \"$t\"; fi; }; rm -f -- \"$t\"",
            "sh", String(id), mime || ""])
    }
    // remove: `cliphist delete` takes ids on stdin — NOT delete-query, which removes every entry containing the text
    function remove(id) { act.command = ["sh", "-c", "printf '%s\\n' \"$1\" | cliphist delete", "sh", String(id)]; act.running = true }
    function wipe()     { act.command = ["cliphist", "wipe"]; act.running = true }
}
