pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Lists images and videos in the wallpaper folder (with a cached dominant colour per entry for the colour filter)
// and switches wallpapers through `rrkshell wallpaper <file>` so colours regenerate everywhere.
// A video (live wallpaper) is played by mpvpaper (started by rrkshell); this service pauses it over mpv's IPC socket
// whenever a window covers the desktop and resumes it when the workspace is empty again — decoding 30 fps for a
// wallpaper nobody can see is wasted heat on this laptop (software decode on nouveau).
Singleton {
    id: root
    property var list: []            // [{path, name, hue, color, poster}]  (poster = frame of a video, "" for images)
    property string current: ""
    readonly property bool live: /\.(mp4|webm|mkv|mov)$/i.test(current)
    property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string repo: Quickshell.env("HOME") + "/claude/rrk-shell"
    readonly property string mpvSock: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/rrk-mpvpaper.sock"
    readonly property bool shouldPlay: live && Widgets.desktopVisible

    onShouldPlayChanged: { retries = 0; pauseTimer.restart() }
    onLiveChanged: if (live) { retries = 0; pauseTimer.restart() }
    Timer { id: pauseTimer; interval: 400; onTriggered: root.syncPause() }   // let window switches settle first
    function syncPause() { mpv({ command: ["set_property", "pause", !shouldPlay] }) }
    // one-shot connection per command (mpv takes one JSON line per request). The socket only exists while mpvpaper
    // runs — right after `rrkshell wallpaper <video>` it may not be there yet, so a failed connect is retried a few times.
    property string mpvMsg: ""
    property int retries: 0
    Loader {
        id: mpvLink
        active: false
        sourceComponent: Socket {
            id: conn
            path: root.mpvSock
            onConnectionStateChanged: if (connected) { write(root.mpvMsg); flush(); closeTimer.restart() }
            onError: { mpvLink.active = false; if (root.live && root.retries++ < 5) retryTimer.restart() }
        }
        onLoaded: item.connected = true
    }
    Timer { id: closeTimer; interval: 150; onTriggered: mpvLink.active = false }
    Timer { id: retryTimer; interval: 1500; onTriggered: root.syncPause() }
    function mpv(obj) { mpvMsg = JSON.stringify(obj) + "\n"; mpvLink.active = false; mpvLink.active = true }

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
