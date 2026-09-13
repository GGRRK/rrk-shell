import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Bluetooth: big status ring with the connected device, then paired / nearby device lists.
Popup {
    name: "bluetooth"
    implicitWidth: 560; implicitHeight: 520
    onShownChanged: Bluetooth.setDiscovering(shown)

    ColumnLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 14
        RowLayout {
            Layout.fillWidth: true
            Label { text: "Bluetooth"; font.pixelSize: 18; font.bold: true }
            Item { Layout.fillWidth: true }
            Label { text: Bluetooth.discovering ? "scanning…" : ""; font.pixelSize: 11; color: Theme.onSurfaceVariant }
            Pill { active: Bluetooth.enabled; padding: 12; onClicked: Bluetooth.toggle()
                   Label { text: Bluetooth.enabled ? "ON" : "OFF"; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface } }
        }
        Ring {
            Layout.alignment: Qt.AlignHCenter; size: 170; thickness: 8
            value: Bluetooth.primary && Bluetooth.primary.batteryAvailable ? Bluetooth.primary.battery : (Bluetooth.primary ? 1 : 0)
            Column { anchors.centerIn: parent; spacing: 4
                Icon { name: Bluetooth.primary ? (Bluetooth.primary.icon.includes("headset") || Bluetooth.primary.icon.includes("headphone") ? "headphones" : "bluetooth_connected") : "bluetooth"; fill: true; font.pixelSize: 40; color: Theme.primary; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: Bluetooth.primary ? Bluetooth.primary.name : (Bluetooth.enabled ? "Not connected" : "Off"); font.bold: true; anchors.horizontalCenter: parent.horizontalCenter; width: 140; horizontalAlignment: Text.AlignHCenter }
                Label { text: Bluetooth.primary && Bluetooth.primary.batteryAvailable ? Math.round(Bluetooth.primary.battery * 100) + "% battery" : ""; font.pixelSize: 11; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter } }
        }
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
            model: Bluetooth.enabled ? Bluetooth.connectedDevices.concat(Bluetooth.pairedDevices, Bluetooth.otherDevices) : []
            delegate: Card {
                required property var modelData
                width: ListView.view.width; height: 48
                Row { anchors { fill: parent; leftMargin: 12; rightMargin: 12 } spacing: 12
                    Icon { name: modelData.connected ? "bluetooth_connected" : "bluetooth"; anchors.verticalCenter: parent.verticalCenter; color: modelData.connected ? Theme.primary : Theme.onSurfaceVariant }
                    Column { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130
                        Label { text: modelData.name; font.bold: modelData.connected; width: parent.width }
                        Label { text: modelData.connected ? "Connected" + (modelData.batteryAvailable ? " · " + Math.round(modelData.battery * 100) + "%" : "") : modelData.paired ? "Paired" : "Available"; font.pixelSize: 11; color: Theme.onSurfaceVariant } }
                    Pill { anchors.verticalCenter: parent.verticalCenter; padding: 10; implicitHeight: 26
                           onClicked: modelData.connected ? modelData.disconnect() : (modelData.paired ? modelData.connect() : modelData.pair())
                           Label { text: modelData.connected ? "Disconnect" : modelData.paired ? "Connect" : "Pair"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } } }
            }
            Label { anchors.centerIn: parent; visible: parent.count === 0; text: Bluetooth.enabled ? "No devices found" : "Bluetooth is off"; color: Theme.outline }
        }
    }
}
