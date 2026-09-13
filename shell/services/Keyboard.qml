pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Current keyboard layout, abbreviated ("English (US)" -> "EN").
Singleton {
    id: root
    property string layout: "EN"
    Process {
        id: q
        command: ["hyprctl", "-j", "devices"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { const k = JSON.parse(text).keyboards.find(k => k.main) || JSON.parse(text).keyboards[0]; if (k) root.layout = abbr(k.active_keymap) } catch (e) {} } }
    }
    Connections { target: Hyprland; function onRawEvent(e) { if (e.name === "activelayout") root.layout = root.abbr(e.data.split(",").slice(1).join(",")) } }
    function abbr(s) { const m = { "English": "EN", "Russian": "RU", "German": "DE", "French": "FR", "Spanish": "ES", "Ukrainian": "UA", "Arabic": "AR" }; const w = (s || "").split(" ")[0]; return m[w] || (w.slice(0, 2).toUpperCase() || "??") }
}
