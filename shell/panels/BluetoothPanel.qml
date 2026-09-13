import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Bluetooth: radial device view (BtRadial — connected device in the centre, chips around it)
// with a plain list fallback (top-right button switches). Bottom row: Wi-Fi | Bluetooth, settings, power.
Popup {
    id: root
    name: "bluetooth"
    implicitWidth: 900; implicitHeight: 700
    property bool listMode: false
    onShownChanged: {
        if (shown) { radial.reset(); if (Bluetooth.enabled && !Bluetooth.primary) Bluetooth.setDiscovering(true) }
        else Bluetooth.setDiscovering(false)
    }

    BtRadial { id: radial; anchors.fill: parent; visible: !root.listMode; onOpenList: root.listMode = true }

    // ---- list fallback ----
    ColumnLayout {
        visible: root.listMode
        anchors { fill: parent; margins: 24; bottomMargin: 100 }
        spacing: 12
        RowLayout {
            Layout.fillWidth: true; Layout.rightMargin: 40
            Label { text: "Devices"; font.pixelSize: 16; font.bold: true }
            Label { text: Bluetooth.discovering ? "scanning…" : ""; font.pixelSize: 11; color: Theme.onSurfaceVariant }
            Item { Layout.fillWidth: true }
            Pill { id: scanPill; active: Bluetooth.discovering; padding: 12; enabled: Bluetooth.enabled; onClicked: Bluetooth.setDiscovering(!Bluetooth.discovering)
                   Label { text: Bluetooth.discovering ? "Stop" : "Scan"; font.bold: true; anchors.verticalCenter: parent.verticalCenter
                           color: scanPill.active ? Theme.onPrimary : Theme.onSurface } }
        }
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
            model: Bluetooth.enabled ? BtInfo.sorted : []
            delegate: BtListItem { required property var modelData; width: ListView.view.width; dev: modelData }
            Label { anchors.centerIn: parent; visible: list.count === 0; color: Theme.outline
                    text: !Bluetooth.enabled ? "Bluetooth is off" : Bluetooth.discovering ? "Scanning…" : "No devices found" }
        }
    }

    // ---- view switch (top-right) ----
    IconButton {
        anchors { top: parent.top; right: parent.right; margins: 16 }
        icon: root.listMode ? "hub" : "view_list"; size: 30; iconSize: 17
        onClicked: root.listMode = !root.listMode
    }

    // ---- bottom row: Wi-Fi | Bluetooth segmented pill (centred), settings + power (right) ----
    Rectangle {
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 24 }
        width: 358; height: 52; radius: 14; color: Theme.alpha(Theme.surfaceHigh, 0.9)
        Row {
            anchors.centerIn: parent; spacing: 4
            Rectangle {
                width: 170; height: 44; radius: 10
                color: wifiMouse.containsMouse ? Theme.pillHover : Theme.alpha(Theme.surfaceHighest, 0.8)
                Behavior on color { ColorAnimation { duration: 140 } }
                Row { anchors.centerIn: parent; spacing: 8
                      Icon { name: "wifi"; font.pixelSize: 18; anchors.verticalCenter: parent.verticalCenter }
                      Label { text: "Wi-Fi"; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
                MouseArea { id: wifiMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Panels.show("network") }
            }
            Rectangle { width: 1; height: 20; anchors.verticalCenter: parent.verticalCenter; color: Theme.alpha(Theme.outlineVariant, 0.6) }
            Rectangle {
                width: 170; height: 44; radius: 10; color: Theme.primary
                Row { anchors.centerIn: parent; spacing: 8
                      Icon { name: "bluetooth"; font.pixelSize: 18; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter }
                      Label { text: "Bluetooth"; font.bold: true; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter } }
            }
        }
    }
    Row {
        anchors { right: parent.right; bottom: parent.bottom; margins: 24 }
        spacing: 10
        IconButton { icon: "settings"; size: 52; iconSize: 24; radius: 26; onClicked: { Panels.close(); BtInfo.openManager() } }
        IconButton { icon: "power_settings_new"; size: 52; iconSize: 24; radius: 26; active: Bluetooth.enabled; fill: false
                     enabled: Bluetooth.available; onClicked: Bluetooth.toggle() }
    }
}
