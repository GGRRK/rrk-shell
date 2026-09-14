import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services

// Software brightness (Brightness mode "overlay"): a full-screen black layer whose opacity is
// 1 − brightness, on the Overlay layer above everything, letting all input through. Blending black at alpha a
// darkens exactly like multiplying the frame by 1 − a, but changing an opacity costs nothing (no shader compile, no
// config reload). Namespace deliberately does not match the "rrk-.*" blur layer rule (look.lua) and has its own
// no-blur/no-anim rule. The hardware cursor is not covered by it.
PanelWindow {
    required property ShellScreen screen
    visible: Brightness.mode === "overlay" && Brightness.value < 0.995
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region {}                                    // empty = every click/key goes to what is underneath
    WlrLayershell.namespace: "rrkdim"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Rectangle { anchors.fill: parent; color: "black"; opacity: 1 - Brightness.value }
}
