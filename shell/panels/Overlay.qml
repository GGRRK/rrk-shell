import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.components

// Full-screen transparent layer that hosts every popup panel. Click outside / Escape closes.
PanelWindow {
    id: win
    required property ShellScreen screen
    readonly property bool onFocusedMonitor: !Hyprland.focusedMonitor || Hyprland.focusedMonitor.name === screen.name
    visible: Panels.open !== "" && onFocusedMonitor
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "rrk-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { anchors.fill: parent; onClicked: Panels.close() }
    Item { anchors.fill: parent; focus: true; Keys.onEscapePressed: Panels.close() }

    readonly property int top: Theme.barHeight + 8
    Dashboard      { anchors.horizontalCenter: parent.horizontalCenter; y: win.top }
    NotifCenter    { x: parent.width - width - 8; y: win.top }
    Launcher       { anchors.horizontalCenter: parent.horizontalCenter; y: win.top + 40 }
    ClipboardPanel { anchors.horizontalCenter: parent.horizontalCenter; y: win.top + 40 }
    WallpaperPicker{ anchors.horizontalCenter: parent.horizontalCenter; y: win.top }
    MediaPanel     { x: 8; y: win.top }
    BluetoothPanel { x: parent.width - width - 8; y: win.top }
    NetworkPanel   { x: parent.width - width - 8; y: win.top }
    PowerMenu      { anchors.centerIn: parent }
}
