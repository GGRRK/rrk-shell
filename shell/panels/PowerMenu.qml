import QtQuick
import qs.services
import qs.components

Popup {
    name: "power"
    implicitWidth: row.implicitWidth + 40; implicitHeight: 130
    Row {
        id: row; anchors.centerIn: parent; spacing: 14
        Repeater {
            model: [ { i: "lock", t: "Lock", f: () => Power.lock() }, { i: "logout", t: "Log out", f: () => Power.logout() }, { i: "bedtime", t: "Sleep", f: () => Power.suspend() },
                     { i: "restart_alt", t: "Reboot", f: () => Power.reboot() }, { i: "power_settings_new", t: "Shut down", f: () => Power.shutdown() } ]
            Column { required property var modelData; spacing: 8
                IconButton { icon: modelData.i; size: 64; iconSize: 28; anchors.horizontalCenter: parent.horizontalCenter; activeColor: Theme.error; active: modelData.i === "power_settings_new"
                             onClicked: { Panels.close(); modelData.f() } }
                Label { text: modelData.t; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.onSurfaceVariant } }
        }
    }
}
