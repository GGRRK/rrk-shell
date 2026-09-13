pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Lists images in the wallpaper folder (with a cached dominant colour per image for the colour filter)
// and switches wallpapers through `rrkshell wallpaper <file>` so colours regenerate everywhere.
Singleton {
    id: root
    property var list: []            // [{path, name, hue, color}]
    property string current: ""
    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string repo: Quickshell.env("HOME") + "/claude/rrk-shell"

    FileView {
        path: Quickshell.env("HOME") + "/.config/rrk-shell/settings.json"
        onLoaded: { try { const d = JSON.parse(text()).wallpaperDir; if (d) root.dir = d.replace(/^~/, Quickshell.env("HOME")) } catch (e) {} ; root.refresh() }
        onLoadFailed: root.refresh()
    }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/rrk-shell/wallpaper"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.current = text().trim()
    }
    Process {
        id: indexer
        stdout: StdioCollector { onStreamFinished: { try { root.list = JSON.parse(text) } catch (e) { root.list = [] } } }
    }
    Process { id: setter }

    function refresh() { indexer.command = [repo + "/shell/scripts/wallpaper-index.sh", dir]; indexer.running = true }
    function set(path) { setter.command = [repo + "/bin/rrkshell", "wallpaper", path]; setter.running = true }
    function random() { setter.command = [repo + "/bin/rrkshell", "wallpaper", "random"]; setter.running = true }
}
