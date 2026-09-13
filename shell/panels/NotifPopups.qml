import Quickshell
import Quickshell.Wayland
import QtQuick
import qs.services
import qs.components

// Toasts in the top-right corner for new notifications (auto-hide after 6 s).
PanelWindow {
    required property ShellScreen screen
    visible: Notifs.popups.length > 0 && Panels.open !== "notifications"
    anchors { top: true; right: true }
    margins { top: Theme.barHeight + 8; right: 8 }
    implicitWidth: 360; implicitHeight: Math.max(1, list.implicitHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "rrk-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    Column {
        id: list; width: parent.width; spacing: 8
        Repeater {
            model: Notifs.popups
            Panel {
                required property var modelData
                width: parent.width; implicitHeight: item.implicitHeight + 16
                NotifItem { id: item; notif: modelData; compact: true; anchors { fill: parent; margins: 8 } color: "transparent"; border.width: 0 }
                Timer { interval: modelData.urgency === 2 ? 15000 : 6000; running: true; onTriggered: Notifs.hidePopup(modelData) }
                MouseArea { anchors.fill: parent; z: -1; onClicked: { Panels.show("notifications"); Notifs.hidePopup(modelData) } }
            }
        }
    }
}
