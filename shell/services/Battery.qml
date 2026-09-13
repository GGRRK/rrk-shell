pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev ? dev.isLaptopBattery : false
    readonly property int percent: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: dev ? (dev.state === UPowerDeviceState.Charging || dev.state === UPowerDeviceState.PendingCharge) : false
    readonly property bool full: dev ? dev.state === UPowerDeviceState.FullyCharged : false
    readonly property bool onBattery: UPower.onBattery
    readonly property string stateText: !present ? "NO BATTERY" : charging ? "CHARGING" : full ? "FULL" : onBattery ? "DISCHARGING" : "NOT CHARGING"
    // seconds remaining (0 when unknown)
    readonly property int timeLeft: dev ? (charging ? dev.timeToFull : dev.timeToEmpty) : 0
    readonly property string icon: !present ? "battery_unknown"
        : charging ? "battery_charging_full"
        : percent > 90 ? "battery_full" : percent > 60 ? "battery_5_bar" : percent > 40 ? "battery_4_bar"
        : percent > 20 ? "battery_2_bar" : "battery_alert"
}
