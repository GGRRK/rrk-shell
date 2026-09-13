import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.components

// Small pill at the bottom-center showing volume / brightness after a key press.
PanelWindow {
    required property ShellScreen screen
    visible: Osd.visible
    anchors { bottom: true }
    margins { bottom: 60 }
    implicitWidth: 300; implicitHeight: 56
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "rrk-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    readonly property real v: Osd.kind === "brightness" ? Brightness.value : Osd.kind === "mic" ? Audio.micVolume : Audio.volume
    readonly property string ic: Osd.kind === "brightness" ? "brightness_6" : Osd.kind === "mic" ? (Audio.micMuted ? "mic_off" : "mic") : Audio.icon
    Panel {
        anchors.fill: parent
        Row { anchors { fill: parent; leftMargin: 18; rightMargin: 18 } spacing: 14
            Icon { name: ic; fill: true; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary }
            HSlider { width: parent.width - 90; anchors.verticalCenter: parent.verticalCenter; value: v; enabled: false }
            Label { text: Math.round(v * 100); font.bold: true; width: 30; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter } }
    }
}
