pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Application list for the launcher. Two views:
//   "apps" (default) — only programs the user installed on purpose: explicitly installed pacman packages, Flatpaks and
//                      ~/.local/share/applications entries (shell/scripts/user-apps.sh decides), minus terminal-only
//                      programs (Terminal=true, e.g. htop / vim);
//   "all"            — every menu entry, including tools that came along as dependencies (Avahi browsers, V4L tests, …).
// settings.json can correct the "apps" view: {"launcher": {"hide": ["qt6ct", "uuctl"], "show": ["nm-connection-editor"]}}
// (desktop-entry ids = file name without .desktop; picked up live). The launcher resets `mode` to "apps" each time it
// opens and re-runs the script (≈30 ms) so new installs show up.
Singleton {
    id: root
    property string mode: "apps"                    // "apps" | "all"
    property var userIds: ({})                      // desktop-entry id -> true, from user-apps.sh
    readonly property string repo: Quickshell.env("HOME") + "/claude/rrk-shell"
    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    property var hide: ({})                         // settings.json launcher.hide  (ids never shown under "apps")
    property var show: ({})                         // settings.json launcher.show  (ids always shown under "apps")
    readonly property var apps: all.filter(a => show[a.id] === true || (userIds[a.id] === true && !a.runInTerminal && hide[a.id] !== true))
    readonly property var current: mode === "all" ? all : apps

    Process {
        id: lister
        command: ["bash", root.repo + "/shell/scripts/user-apps.sh"]
        stdout: StdioCollector { onStreamFinished: root._loaded(text) }
    }
    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/rrk-shell/settings.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root._settings(text())
        printErrors: false                          // no settings.json = no corrections
    }
    function _settings(txt) {
        let l = {}
        if (txt.trim() !== "") try { l = JSON.parse(txt).launcher || {} } catch (e) { console.warn("settings.json parse error", e) }
        const toSet = ids => { const m = {}; for (const id of (Array.isArray(ids) ? ids : [])) m[String(id)] = true; return m }
        hide = toSet(l.hide); show = toSet(l.show)
    }
    function refresh() { lister.running = true }
    function _loaded(json) {
        let ids = []
        try { ids = JSON.parse(json) } catch (e) { console.warn("user-apps.sh output is not JSON:", e); return }
        const m = {}
        for (const id of ids) m[id] = true
        userIds = m
    }
    Component.onCompleted: refresh()

    // name-prefix matches first, then name / comment / generic-name substring matches; `list` defaults to the current view
    function search(q, list) {
        list = list || current
        q = q.trim().toLowerCase()
        if (!q) return list
        const starts = [], contains = []
        for (const a of list) {
            const n = a.name.toLowerCase()
            if (n.startsWith(q)) starts.push(a)
            else if (n.includes(q) || (a.comment || "").toLowerCase().includes(q) || (a.genericName || "").toLowerCase().includes(q)) contains.push(a)
        }
        return starts.concat(contains)
    }
    function launch(a) { a.execute() }
}
