import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

PanelWindow {
    id: bar
    required property ShellScreen screen
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "rrk-bar"
    WlrLayershell.layer: WlrLayer.Top

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Qt.darker(Theme.surface, 1.3), 0.88)
        Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.outlineVariant, 0.35) }
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 8

        // ── left ────────────────────────────────────────────────────────────
        IconButton { icon: "search"; size: 30; iconSize: 19; active: Panels.open === "launcher"; onClicked: Panels.toggle("launcher") }
        Workspaces {}
        MediaModule {}
        Item { Layout.fillWidth: true }

        // ── center ──────────────────────────────────────────────────────────
        ClockModule {}
        Pill {
            visible: Weather.ready
            active: Panels.open === "dashboard"
            onClicked: Panels.toggle("dashboard")
            Icon { name: Weather.icon; fill: true; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
            Label { text: Weather.temp.toFixed(1) + "°C"; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
        }
        Item { Layout.fillWidth: true }

        // ── right ───────────────────────────────────────────────────────────
        Tray {}
        Pill { padding: 10
            Icon { name: "keyboard"; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter }
            Label { text: Keyboard.layout; font.bold: true; anchors.verticalCenter: parent.verticalCenter }
            onClicked: Quickshell.execDetached(["hyprctl", "switchxkblayout", "all", "next"])
        }
        Pill {
            active: Panels.open === "network"; onClicked: Panels.toggle("network")
            Icon { name: Network.icon; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
            Label { text: Network.label; font.bold: true; width: Math.min(implicitWidth, 110); anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
        }
        Pill {
            visible: Bluetooth.available
            active: Panels.open === "bluetooth"; onClicked: Panels.toggle("bluetooth")
            Icon { name: Bluetooth.icon; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
            Label { text: Bluetooth.label; font.bold: true; width: Math.min(implicitWidth, 110); anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
        }
        Pill {
            active: Panels.open === "media"
            onClicked: m => m.button === Qt.RightButton ? Audio.toggleMute() : Panels.toggle("media")
            onWheel: w => { Audio.step(w.angleDelta.y > 0 ? 0.05 : -0.05); Osd.show("volume") }
            Icon { name: Audio.icon; fill: true; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
            Label { text: Math.round(Audio.volume * 100) + "%"; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
        }
        Pill {
            visible: Battery.present
            active: Panels.open === "notifications"; onClicked: Panels.toggle("notifications")
            Icon { name: Battery.icon; fill: true; font.pixelSize: 17; anchors.verticalCenter: parent.verticalCenter
                   color: parent.active ? Theme.onPrimary : Battery.percent <= 15 && !Battery.charging ? Theme.error : Theme.onSurface }
            Label { text: Battery.percent + "%"; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
        }
        Rectangle {
            width: 26; height: 26; radius: 13
            color: pm.containsMouse ? Qt.lighter(Theme.error, 1.15) : Theme.error
            Icon { anchors.centerIn: parent; name: "power_settings_new"; font.pixelSize: 15; color: Qt.darker(Theme.error, 3) ; font.variableAxes: ({ "wght": 700, "FILL": 0, "opsz": 24 }) }
            MouseArea { id: pm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("power") }
        }
    }
}
