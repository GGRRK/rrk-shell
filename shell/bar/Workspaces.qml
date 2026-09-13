import Quickshell.Hyprland
import QtQuick
import qs.services
import qs.components

// Eight fixed workspace slots; the focused one is a filled accent square.
Rectangle {
    readonly property int focusedId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 1
    implicitWidth: row.implicitWidth + 8; implicitHeight: 30; radius: 15
    color: Theme.pillBg
    Row {
        id: row; anchors.centerIn: parent; spacing: 4
        Repeater {
            model: 8
            Rectangle {
                required property int index
                readonly property int wsId: index + 1
                readonly property bool focused: wsId === focusedId
                readonly property bool occupied: Hyprland.workspaces.values.some(w => w.id === wsId)
                width: 24; height: 22; radius: 7
                color: focused ? Theme.primary : occupied ? Theme.alpha(Theme.surfaceHighest, 0.9) : "transparent"
                Behavior on color { ColorAnimation { duration: 160 } }
                Label { anchors.centerIn: parent; text: wsId; font.bold: true; font.pixelSize: 12
                        color: focused ? Theme.onPrimary : occupied ? Theme.onSurface : Theme.onSurfaceVariant }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + wsId + " })") }
            }
        }
    }
    MouseArea {
        anchors.fill: parent; z: -1
        onWheel: w => Hyprland.dispatch("hl.dsp.focus({ workspace = \"" + (w.angleDelta.y < 0 ? "e+1" : "e-1") + "\" })")
    }
}
