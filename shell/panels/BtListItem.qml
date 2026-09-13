import QtQuick
import qs.services
import qs.components

// One row of the Bluetooth list view: device icon, name, state, action pill (Pair / Connect / Disconnect).
Card {
    id: row
    property var dev: null
    height: 48
    Row {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 12
        Icon { name: row.dev ? BtInfo.icon(row.dev) : "bluetooth"; anchors.verticalCenter: parent.verticalCenter
               color: row.dev && row.dev.connected ? Theme.primary : Theme.onSurfaceVariant }
        Column {
            anchors.verticalCenter: parent.verticalCenter; width: parent.width - 130
            Label { text: row.dev ? row.dev.name : ""; font.bold: !!row.dev && row.dev.connected; width: parent.width }
            Label { font.pixelSize: 11; color: Theme.onSurfaceVariant; width: parent.width
                    text: !row.dev ? "" : row.dev.connected ? "Connected" + (row.dev.batteryAvailable ? " · " + Math.round(row.dev.battery * 100) + "%" : "")
                        : row.dev.paired ? "Paired" : "Available" }
        }
        Pill {
            anchors.verticalCenter: parent.verticalCenter; padding: 10; implicitHeight: 26
            enabled: !BtInfo.busy(row.dev)
            onClicked: BtInfo.act(row.dev)
            Label { font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter
                    text: BtInfo.busy(row.dev) ? "…" : row.dev && row.dev.connected ? "Disconnect" : BtInfo.stateText(row.dev) }
        }
    }
}
