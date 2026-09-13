import QtQuick
import qs.services
import qs.components

// Time (12h with seconds) over the date, opens the dashboard.
Item {
    implicitWidth: col.implicitWidth + 16; implicitHeight: 30
    Column {
        id: col; anchors.centerIn: parent; spacing: -2
        Label { text: Time.time12; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter
                color: Panels.open === "dashboard" ? Theme.primary : Theme.onSurface }
        Label { text: Time.dateLong; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.onSurfaceVariant }
    }
    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Panels.toggle("dashboard") }
}
