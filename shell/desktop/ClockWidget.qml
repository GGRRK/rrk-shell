import QtQuick
import qs.services
import qs.components

// Analog clock with the digital time (24 h, seconds in primary) and the date beneath.
WidgetCard {
    spacing: 8
    AnalogClock { size: 140; anchors.horizontalCenter: parent.horizontalCenter }
    Row { anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
          Label { text: Time.time; font.pixelSize: 30; font.bold: true; font.letterSpacing: -1 }
          Label { text: Time.seconds; font.pixelSize: 13; font.bold: true; color: Theme.primary; anchors.bottom: parent.bottom; anchors.bottomMargin: 6 } }
    Label { text: Time.dateLong; font.pixelSize: 12; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
}
