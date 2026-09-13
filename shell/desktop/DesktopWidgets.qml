import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Desktop widgets drawn on the wallpaper: one layer-shell window per screen on the Bottom layer (above awww's
// Background wallpaper, beneath every window). Right-hand column, fully click-through, never takes focus.
// No exclusive zone on purpose: a Bottom-layer zone would be arranged before the bar's and truncate it;
// if a reserved column is ever wanted, do it with per-side gaps_out in hypr/config/look.lua instead.
PanelWindow {
    id: win
    required property ShellScreen screen
    visible: Widgets.enabled
    anchors { top: true; right: true; bottom: true }
    margins { top: Theme.barHeight + 16; right: 16; bottom: 16 }
    implicitWidth: Widgets.columnWidth
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}                                // empty region: nothing is clickable, every click falls through to the desktop
    // deliberately NOT "rrk-…": look.lua blurs every rrk-* layer, and blur under a live visualizer is too costly on nouveau
    WlrLayershell.namespace: "desktop-widgets"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 12
        ClockWidget   { width: parent.width; visible: Widgets.clock }
        CavaWidget    { width: parent.width; visible: Widgets.cava && Cava.available && Media.active && (Media.playing || Cava.recent) }
        SysMonWidget  { width: parent.width; visible: Widgets.sysmon }
        WeatherWidget { width: parent.width; visible: Widgets.weather }
    }
}
