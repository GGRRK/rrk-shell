pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Power profiles (power-profiles-daemon) + session actions.
Singleton {
    id: root
    property string profile: "balanced"
    readonly property string icon: profile === "performance" ? "bolt" : profile === "power-saver" ? "energy_savings_leaf" : "speed"
    Process { id: get; command: ["powerprofilesctl", "get"]; running: true; stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p) root.profile = p } } }
    Process { id: set; onExited: get.running = true }
    Process { id: run }
    function cycle() { const order = ["power-saver", "balanced", "performance"]; setProfile(order[(order.indexOf(profile) + 1) % 3]) }
    function setProfile(p) { set.command = ["powerprofilesctl", "set", p]; set.running = true }
    function lock()     { run.command = ["hyprlock"]; run.running = true }
    function logout()   { run.command = ["uwsm", "stop"]; run.running = true }
    function suspend()  { run.command = ["systemctl", "suspend"]; run.running = true }
    function reboot()   { run.command = ["systemctl", "reboot"]; run.running = true }
    function shutdown() { run.command = ["systemctl", "poweroff"]; run.running = true }
}
