import Quickshell
import Quickshell.Io
import QtQuick
import qs.services
import qs.bar
import qs.panels
import qs.desktop

ShellRoot {
    Variants {
        model: Quickshell.screens
        Scope {
            required property ShellScreen modelData
            Bar         { screen: modelData }
            Overlay     { screen: modelData }
            NotifPopups { screen: modelData }
            OsdWindow   { screen: modelData }
            DesktopWidgets { screen: modelData }
        }
    }

    // `qs -c rrk-shell ipc call panels toggle dashboard` (used by bin/rrkshell + Hyprland keybinds)
    IpcHandler {
        target: "panels"
        function toggle(name: string): void { Panels.toggle(name) }
        function close(): void { Panels.close() }
    }
    // `qs -c rrk-shell ipc call osd volume up|down|mute` etc. — media keys route through here so the OSD shows
    IpcHandler {
        target: "osd"
        function volume(dir: string): void { if (dir === "mute") Audio.toggleMute(); else Audio.step(dir === "up" ? 0.05 : -0.05); Osd.show("volume") }
        function brightness(dir: string): void { Brightness.step(dir === "up" ? 0.05 : -0.05); Osd.show("brightness") }
        function mic(): void { Audio.toggleMicMute(); Osd.show("mic") }
    }
    // `qs -c rrk-shell ipc call widgets toggle` — hide / show the desktop widgets (SUPER+SHIFT+D, `rrkshell widgets`)
    IpcHandler { target: "widgets"; function toggle(): void { Widgets.toggle() } function show(on: bool): void { Widgets.show(on) } }
    // force singletons that do background work to instantiate at startup
    Component.onCompleted: { Weather.ready; Network.connected; Notifs.count; Keyboard.layout; Power.profile; Wallpapers.list }
}
