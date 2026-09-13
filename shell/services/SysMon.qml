pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU / RAM / CPU temperature / disk / network for the desktop system-monitor widget.
// scripts/sysmon.sh prints one line of raw counters; it is run every 2 s while the widget is actually on
// screen (Widgets.enabled && Widgets.sysmon && no window covering the desktop) and rates are derived here
// from consecutive samples.
Singleton {
    id: root
    property real cpu: 0            // 0..1
    property real mem: 0            // 0..1  (used / total)
    property real memUsedGB: 0
    property real memTotalGB: 0
    property int  temp: 0           // °C, smoothed (0 = unknown)
    property bool hot: false        // temp >= 85 °C, released below 80 °C (hysteresis so the colour doesn't flicker)
    property real disk: 0           // 0..1  (used / size of /)
    property real diskUsedGB: 0
    property real diskTotalGB: 0
    property real rxRate: 0         // bytes per second, every interface except lo
    property real txRate: 0
    property bool ready: false
    readonly property bool active: Widgets.enabled && Widgets.sysmon && Widgets.desktopVisible
    property var _last: null        // previous sample { busy, total, rx, tx, t }

    Process {
        id: sample
        command: ["sh", Quickshell.shellDir + "/scripts/sysmon.sh"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { interval: 2000; running: root.active; repeat: true; triggeredOnStart: true; onTriggered: sample.running = true }
    onActiveChanged: if (!active) _last = null     // no bogus rate spike after a pause

    function parse(txt) {
        const f = txt.trim().split(/\s+/).map(Number)
        if (f.length < 9 || f.some(isNaN)) return
        const now = Date.now()
        const s = { busy: f[0], total: f[1], rx: f[7], tx: f[8], t: now }
        if (_last && s.total > _last.total) {
            cpu = Math.max(0, Math.min(1, (s.busy - _last.busy) / (s.total - _last.total)))
            const dt = Math.max(0.5, (now - _last.t) / 1000)
            rxRate = Math.max(0, (s.rx - _last.rx) / dt)
            txRate = Math.max(0, (s.tx - _last.tx) / dt)
        }
        _last = s
        memTotalGB = f[2] / 1048576; memUsedGB = (f[2] - f[3]) / 1048576; mem = f[2] > 0 ? (f[2] - f[3]) / f[2] : 0
        // the package sensor swings 10-20 °C within a second under load: smooth it, then apply hysteresis for `hot`
        const newTemp = Math.round(f[4] / 1000)
        temp = temp ? Math.round(temp * 0.6 + newTemp * 0.4) : newTemp
        hot = hot ? temp >= 80 : temp >= 85
        diskUsedGB = f[5] / 1e9; diskTotalGB = f[6] / 1e9; disk = f[6] > 0 ? f[5] / f[6] : 0
        ready = true
    }
    function fmtRate(b) {
        if (b < 1024) return Math.round(b) + " B/s"
        if (b < 1048576) return (b / 1024).toFixed(b < 10240 ? 1 : 0) + " KB/s"
        return (b / 1048576).toFixed(1) + " MB/s"
    }
    function fmtGB(g) { return g >= 100 ? Math.round(g) : g.toFixed(1) }
}
