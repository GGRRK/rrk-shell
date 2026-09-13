import QtQuick
import qs.services
import qs.components

// Current weather from the Weather service: icon, temperature, condition, city, today's high / low.
WidgetCard {
    Item {
        width: parent.width; height: 64
        Icon { id: ic; name: Weather.icon; fill: true; font.pixelSize: 40; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
        Column {
            anchors { left: ic.right; leftMargin: 14; right: hilo.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            Label { text: Weather.ready ? Math.round(Weather.temp) + "°" : "--"; font.pixelSize: 30; font.bold: true; font.letterSpacing: -1 }
            Label { text: Weather.ready ? Weather.description : "Loading weather…"; font.pixelSize: 11; color: Theme.onSurfaceVariant; width: parent.width }
            Label { text: Weather.city; visible: text !== ""; font.pixelSize: 10; color: Theme.outline; width: parent.width }
        }
        Column {
            id: hilo
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 2
            readonly property var today: Weather.daily.length ? Weather.daily[0] : null
            Row { spacing: 2; anchors.right: parent.right
                Icon  { name: "arrow_drop_up"; font.pixelSize: 16; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
                Label { text: hilo.today ? Math.round(hilo.today.hi) + "°" : "--"; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter } }
            Row { spacing: 2; anchors.right: parent.right
                Icon  { name: "arrow_drop_down"; font.pixelSize: 16; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
                Label { text: hilo.today ? Math.round(hilo.today.lo) + "°" : "--"; font.pixelSize: 12; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter } }
        }
    }
}
