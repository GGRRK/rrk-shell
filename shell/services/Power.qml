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
    // "Sleep" on this laptop = lock + backlight off. NOT systemctl suspend: nouveau cannot resume the RTX 3080 Ti
    // afterwards (black screen until reboot, 2026-09-13/14). The brightness keys bring the picture back.
    function screenOff() { run.command = ["sh", "-c", "pidof hyprlock >/dev/null || hyprlock & sleep 0.4; exec bash \"$1\"", "sh", Quickshell.env("HOME") + "/claude/rrk-shell/shell/scripts/screen-off.sh"]; run.running = true }
    function reboot()   { run.command = ["systemctl", "reboot"]; run.running = true }
    function shutdown() { run.command = ["systemctl", "poweroff"]; run.running = true }
}
