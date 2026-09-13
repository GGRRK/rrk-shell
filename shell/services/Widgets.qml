pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Desktop-widget switches. Per-widget on/off comes from settings.json:
//   {"widgets": {"clock": true, "cava": true, "sysmon": true, "weather": true}}   (missing key = default: on)
// The global hide/show (SUPER+SHIFT+D, `rrkshell widgets`, `qs -c rrk-shell ipc call widgets toggle`) is remembered
// in ~/.local/state/rrk-shell/widgets-hidden ("1" = hidden) so it survives a shell restart.
// Both files are read with blockLoading so the window never maps in the wrong state on startup (no fade in/out).
Singleton {
    id: root
    property bool hidden: stateFile.text().trim() === "1"
    readonly property bool enabled: !hidden
    property bool clock: true
    property bool cava: true
    property bool sysmon: true
    property bool weather: true
    readonly property int columnWidth: 300
    // The widgets sit on the Bottom layer: any window on the focused workspace covers the column, and every
    // commit of a Bottom-layer surface makes Hyprland re-render the whole screen. Services that animate
    // (cava, sysmon) pause while a window is open so nothing is drawn underneath for nothing.
    readonly property bool desktopVisible: !Hyprland.focusedWorkspace || Hyprland.focusedWorkspace.toplevels.values.length === 0

    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/rrk-shell/settings.json"
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onLoaded: root.apply(text())
    }
    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/rrk-shell/widgets-hidden"
        blockLoading: true
        printErrors: false                  // a missing file just means "never hidden"
        onSaveFailed: console.warn("rrk-shell: could not write " + path + " — widgets hide/show state will not persist")
    }
    Component.onCompleted: apply(settings.text())

    function apply(txt) {
        let w = {}
        try { w = JSON.parse(txt).widgets || {} } catch (e) { console.warn("settings.json parse error", e) }
        clock = w.clock !== false; cava = w.cava !== false; sysmon = w.sysmon !== false; weather = w.weather !== false
    }
    function show(on) { hidden = !on; stateFile.setText(hidden ? "1" : "0") }
    function toggle() { show(hidden) }
}
