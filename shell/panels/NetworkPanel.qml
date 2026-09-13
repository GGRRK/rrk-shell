import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

Popup {
    name: "network"
    implicitWidth: 380; implicitHeight: 480
    onShownChanged: if (shown) { Network.rescan(); Network.refresh() }
    ColumnLayout {
        anchors { fill: parent; margins: 18 }
        spacing: 12
        RowLayout { Layout.fillWidth: true
            Label { text: "Wi-Fi"; font.pixelSize: 18; font.bold: true }
            Item { Layout.fillWidth: true }
            IconButton { icon: "refresh"; size: 30; iconSize: 17; onClicked: { Network.rescan(); Network.refresh() } }
            Pill { active: Network.wifiEnabled; padding: 12; onClicked: Network.toggleWifi()
                   Label { text: Network.wifiEnabled ? "ON" : "OFF"; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface } } }
        Card { Layout.fillWidth: true; height: 56; visible: Network.connected
            Row { anchors { fill: parent; leftMargin: 14 } spacing: 12
                Icon { name: Network.icon; font.pixelSize: 24; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Column { anchors.verticalCenter: parent.verticalCenter
                    Label { text: Network.label; font.bold: true }
                    Label { text: Network.kind === "wifi" ? "Connected · " + Network.signal + "%" : "Connected · wired"; font.pixelSize: 11; color: Theme.onSurfaceVariant } } } }
        ListView {
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 4
            model: Network.wifiEnabled ? Network.networks.filter(n => !n.inUse) : []
            delegate: Rectangle {
                required property var modelData
                width: ListView.view.width; height: 44; radius: Theme.radiusSm; color: m.containsMouse ? Theme.alpha(Theme.surfaceHighest, 0.6) : "transparent"
                Row { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 12
                    Icon { name: modelData.signal > 75 ? "signal_wifi_4_bar" : modelData.signal > 50 ? "network_wifi_3_bar" : modelData.signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: modelData.ssid; width: parent.width - 70; anchors.verticalCenter: parent.verticalCenter }
                    Icon { name: modelData.security ? "lock" : "lock_open"; font.pixelSize: 14; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Network.connect(modelData.ssid) }
            }
            Label { anchors.centerIn: parent; visible: parent.count === 0; text: Network.wifiEnabled ? "No other networks" : "Wi-Fi is off"; color: Theme.outline }
        }
        Label { text: "New networks that need a password: connect once via nmtui in a terminal."; font.pixelSize: 10; color: Theme.outline; Layout.fillWidth: true; wrapMode: Text.Wrap }
    }
}
