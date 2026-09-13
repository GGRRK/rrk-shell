pragma Singleton
import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property bool discovering: adapter ? adapter.discovering : false
    readonly property var devices: Bluetooth.devices.values
    readonly property var connectedDevices: devices.filter(d => d.connected)
    readonly property var pairedDevices: devices.filter(d => d.paired && !d.connected)
    readonly property var otherDevices: devices.filter(d => !d.paired && d.name)
    readonly property var primary: connectedDevices.length ? connectedDevices[0] : null
    readonly property string label: !enabled ? "Off" : primary ? primary.name : "No device"
    readonly property string icon: !enabled ? "bluetooth_disabled" : primary ? "bluetooth_connected" : "bluetooth"

    function toggle() { if (adapter) adapter.enabled = !adapter.enabled }
    function setDiscovering(on) { if (adapter) adapter.discovering = on }
}
