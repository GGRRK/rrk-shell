pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property real value: 0.5      // 0..1
    property bool available: false

    Process {
        id: readProc
        command: ["brightnessctl", "-m"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(",")
                if (p.length >= 5) { const max = parseInt(p[4]); if (max > 0) { root.value = parseInt(p[2]) / max; root.available = true } }
            }
        }
    }
    Process { id: setProc }
    Timer { interval: 5000; running: true; repeat: true; onTriggered: readProc.running = true }

    function set(v) {
        v = Math.max(0.02, Math.min(1, v)); root.value = v
        setProc.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"]; setProc.running = true
    }
    function step(d) { set(value + d) }
}
