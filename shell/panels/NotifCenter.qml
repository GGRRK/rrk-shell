import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Notification list on the left; battery ring, brightness/volume sliders and session buttons on the right.
Popup {
    name: "notifications"
    implicitWidth: 800; implicitHeight: 640

    RowLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 18

        ColumnLayout {
            Layout.preferredWidth: 330; Layout.fillHeight: true; spacing: 10
            RowLayout {
                Layout.fillWidth: true
                Label { text: "Notifications"; font.pixelSize: 18; font.bold: true }
                Item { Layout.fillWidth: true }
                IconButton { icon: Notifs.dnd ? "notifications_off" : "notifications"; size: 30; iconSize: 17; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
                IconButton { icon: "delete_sweep"; size: 30; iconSize: 17; onClicked: Notifs.clearAll() }
            }
            ListView {
                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 8
                model: Notifs.list
                delegate: NotifItem { required property var modelData; notif: modelData; width: ListView.view.width }
                Label { anchors.centerIn: parent; visible: Notifs.count === 0; text: "Nothing new"; color: Theme.outline }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true; Layout.fillHeight: true; spacing: 16
            Row {
                Layout.alignment: Qt.AlignHCenter; spacing: 10
                Repeater {
                    model: [ { v: Math.floor(Battery.timeLeft / 3600), l: "HR" }, { v: Math.floor((Battery.timeLeft % 3600) / 60), l: "MIN" } ]
                    Card { required property var modelData; width: 52; height: 46; visible: Battery.timeLeft > 0
                        Column { anchors.centerIn: parent; spacing: 0
                            Label { text: (modelData.v < 10 ? "0" : "") + modelData.v; font.bold: true; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: modelData.l; font.pixelSize: 8; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter } } }
                }
            }
            Ring {
                Layout.alignment: Qt.AlignHCenter; size: 230; thickness: 12
                value: Battery.present ? Battery.percent / 100 : 0
                color: Battery.percent <= 15 && !Battery.charging ? Theme.error : Theme.primary
                Column { anchors.centerIn: parent; spacing: 2
                    Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 2
                          Icon { name: Battery.icon; fill: true; font.pixelSize: 26; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary }
                          Label { text: Battery.percent + "%"; font.pixelSize: 44; font.bold: true } }
                    Label { text: Battery.stateText; font.pixelSize: 11; font.letterSpacing: 2; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter } }
            }
            Card {
                Layout.fillWidth: true; implicitHeight: 84
                Column { anchors { fill: parent; margins: 14 } spacing: 12
                    HSlider { width: parent.width; icon: "brightness_6"; value: Brightness.value; onMoved: v => Brightness.set(v) }
                    HSlider { width: parent.width; icon: Audio.icon; value: Audio.volume; color: Theme.tertiary; onMoved: v => Audio.setVolume(v) } }
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Repeater {
                    model: [ { i: "lock", f: () => Power.lock() }, { i: "bedtime", f: () => Power.screenOff() }, { i: "restart_alt", f: () => Power.reboot() }, { i: "power_settings_new", f: () => Power.shutdown() } ]
                    IconButton { required property var modelData; Layout.fillWidth: true; size: 60; iconSize: 24; icon: modelData.i; onClicked: { Panels.close(); modelData.f() } }
                }
            }
            Item { Layout.fillHeight: true }
        }
    }
}
