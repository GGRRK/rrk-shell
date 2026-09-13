import QtQuick
import qs.services
import qs.components

// System monitor: CPU / RAM / CPU-temperature rings (look: reference f094 "CPU LOAD / MEMORY / THERMALS"),
// disk bar for /, network down/up rates and RAM in GB. Data from the SysMon service (2 s polling while visible).
// Nothing here animates: every animated frame on the Bottom layer is a full-screen re-render in Hyprland.
WidgetCard {
    title: "System"; icon: "monitoring"
    spacing: 12

    // ── three rings ──
    Row {
        id: rings
        width: parent.width
        readonly property int cell: Math.floor(width / 3)
        Repeater {
            // constant model: delegates are built once; live values are bound by index below (a model that
            // contained SysMon values would rebuild the delegates every 2 s)
            model: [ { i: "memory", l: "CPU" }, { i: "memory_alt", l: "RAM" }, { i: "device_thermostat", l: "TEMP" } ]
            Column {
                id: cellCol
                required property var modelData
                required property int index
                readonly property real v: index === 0 ? SysMon.cpu : index === 1 ? SysMon.mem : Math.min(1, SysMon.temp / 100)
                readonly property string t: index === 2 ? SysMon.temp + "°" : Math.round(v * 100) + "%"
                readonly property color c: index === 0 ? Theme.primary : index === 1 ? Theme.tertiary : (SysMon.hot ? Theme.error : Theme.secondary)
                width: rings.cell; spacing: 6
                Ring {
                    size: 64; thickness: 5; value: cellCol.v; color: cellCol.c; animated: false; anchors.horizontalCenter: parent.horizontalCenter
                    Column { anchors.centerIn: parent; spacing: 0
                        Icon  { name: cellCol.modelData.i; font.pixelSize: 14; color: cellCol.c; anchors.horizontalCenter: parent.horizontalCenter }
                        Label { text: cellCol.t; font.pixelSize: 11; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter } }
                }
                Label { text: cellCol.modelData.l; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
            }
        }
    }

    // ── disk ──
    Column {
        width: parent.width; spacing: 6
        Item {
            width: parent.width; height: 12
            Row { spacing: 5; anchors.verticalCenter: parent.verticalCenter
                Icon  { name: "hard_drive"; font.pixelSize: 12; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                Label { text: "DISK  /"; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter } }
            Label { anchors { right: parent.right; verticalCenter: parent.verticalCenter } font.pixelSize: 10; color: Theme.onSurfaceVariant
                    text: SysMon.ready ? SysMon.fmtGB(SysMon.diskUsedGB) + " / " + SysMon.fmtGB(SysMon.diskTotalGB) + " GB (" + Math.round(SysMon.disk * 100) + "%)" : "…" }
        }
        Rectangle {
            width: parent.width; height: 4; radius: 2; color: Theme.alpha(Theme.outlineVariant, 0.5)
            Rectangle { width: Math.max(height, parent.width * SysMon.disk); height: parent.height; radius: 2; color: Theme.primary }
        }
    }

    // ── network + RAM ──
    Item {
        width: parent.width; height: 14
        Row { spacing: 14; anchors.verticalCenter: parent.verticalCenter
            Row { spacing: 4
                Icon  { name: "arrow_downward"; font.pixelSize: 12; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: SysMon.fmtRate(SysMon.rxRate); font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter } }
            Row { spacing: 4
                Icon  { name: "arrow_upward"; font.pixelSize: 12; color: Theme.tertiary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: SysMon.fmtRate(SysMon.txRate); font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter } } }
        Label { anchors { right: parent.right; verticalCenter: parent.verticalCenter } font.pixelSize: 10; color: Theme.onSurfaceVariant
                text: SysMon.ready ? SysMon.fmtGB(SysMon.memUsedGB) + " / " + SysMon.fmtGB(SysMon.memTotalGB) + " GB" : "" }
    }
}
