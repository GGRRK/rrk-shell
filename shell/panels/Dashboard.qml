import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.components

// Dashboard: calendar · clock inside a radial 24 h forecast (8 three-hour pills on a dashed ellipse, the current
// slot at the top and time running clockwise, like the reference) · current weather with stat rings; below:
// quick toggles + 5-day forecast.
Popup {
    id: root
    name: "dashboard"
    implicitWidth: 1200; implicitHeight: col.implicitHeight + 40

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 20 }
        spacing: 18

        RowLayout {
            spacing: 24
            Layout.fillWidth: true

            // ── calendar ──────────────────────────────────────────────────
            Card {
                Layout.preferredWidth: 270; Layout.preferredHeight: 330
                Calendar { anchors.fill: parent; anchors.margins: 14 }
            }

            // ── clock inside the radial forecast ──────────────────────────
            Item {
                id: ring
                Layout.fillWidth: true; Layout.preferredHeight: 330
                readonly property real cx: width / 2
                readonly property real cy: height / 2
                readonly property real rx: Math.min(250, width / 2 - 30)     // pill centres sit on this ellipse
                readonly property real ry: 118
                Shape {
                    anchors.fill: parent
                    ShapePath { strokeColor: Theme.alpha(Theme.outline, 0.55); strokeWidth: 1; fillColor: "transparent"
                                strokeStyle: ShapePath.DashLine; dashPattern: [3, 5]
                                PathAngleArc { centerX: ring.cx; centerY: ring.cy; radiusX: ring.rx; radiusY: ring.ry; startAngle: 0; sweepAngle: 360 } }
                }
                Column {
                    anchors.centerIn: parent; spacing: 2
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter; spacing: 4
                        Label { text: Time.time; font.pixelSize: 78; font.bold: true; font.letterSpacing: -2 }
                        Label { text: Time.seconds; font.pixelSize: 30; font.bold: true; color: Theme.primary; anchors.bottom: parent.bottom; anchors.bottomMargin: 14 }
                    }
                    Label { text: Time.dateLong; anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 15; color: Theme.onSurfaceVariant }
                }
                Repeater {
                    model: Weather.hourly.slice(0, 8)
                    Card {
                        required property var modelData
                        required property int index
                        readonly property real a: -Math.PI / 2 + index * Math.PI / 4       // slot 0 (now) at the top, clockwise
                        x: ring.cx + ring.rx * Math.cos(a) - width / 2
                        y: ring.cy + ring.ry * Math.sin(a) - height / 2
                        width: 56; height: 72
                        Column { anchors.centerIn: parent; spacing: 2
                            Label { text: modelData.time; font.pixelSize: 10; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
                            Icon { name: Weather.iconFor(modelData.code, true); fill: true; font.pixelSize: 17; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: modelData.temp.toFixed(1) + "°"; font.bold: true; font.pixelSize: 11; anchors.horizontalCenter: parent.horizontalCenter } }
                    }
                }
            }

            // ── current weather ───────────────────────────────────────────
            ColumnLayout {
                Layout.preferredWidth: 270; Layout.minimumWidth: 270; spacing: 4
                Row { Layout.alignment: Qt.AlignHCenter; spacing: 26
                    Icon { name: "chevron_left"; color: Theme.onSurfaceVariant }
                    Label { text: Time.weekday.toUpperCase(); font.bold: true; font.letterSpacing: 2 }
                    Icon { name: "chevron_right"; color: Theme.onSurfaceVariant } }
                Item { height: 10 }
                Label { text: Weather.ready ? Math.round(Weather.temp) + "°" : "--"; font.pixelSize: 72; font.bold: true; color: Theme.primary; Layout.alignment: Qt.AlignRight }
                Label { text: Weather.ready ? Weather.description : "Loading weather…"; font.pixelSize: 14; color: Theme.onSurfaceVariant; Layout.alignment: Qt.AlignRight }
                Label { text: Weather.city; font.pixelSize: 11; color: Theme.outline; Layout.alignment: Qt.AlignRight; visible: text !== "" }
                Item { height: 16 }
                Row {
                    Layout.alignment: Qt.AlignRight; spacing: 14
                    Repeater {
                        model: [
                            { v: Weather.wind.toFixed(0) + "m/s", r: Math.min(1, Weather.wind / 20), i: "air", t: "WIND" },
                            { v: Weather.humidity + "%", r: Weather.humidity / 100, i: "humidity_percentage", t: "HUMID" },
                            { v: Weather.rain + "%", r: Weather.rain / 100, i: "rainy", t: "RAIN" },
                            { v: Weather.feels.toFixed(1) + "°", r: Math.max(0, Math.min(1, (Weather.feels + 10) / 50)), i: "device_thermostat", t: "FEELS" } ]
                        Column { required property var modelData; spacing: 6
                            Ring { size: 58; thickness: 4; value: modelData.r; anchors.horizontalCenter: parent.horizontalCenter
                                   Label { anchors.centerIn: parent; text: modelData.v; font.pixelSize: 10; font.bold: true } }
                            Row { spacing: 3; anchors.horizontalCenter: parent.horizontalCenter
                                  Icon { name: modelData.i; font.pixelSize: 11; color: Theme.onSurfaceVariant }
                                  Label { text: modelData.t; font.pixelSize: 9; font.bold: true; color: Theme.onSurfaceVariant } } }
                    }
                }
            }
        }

        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.alpha(Theme.outlineVariant, 0.4) }

        // ── quick toggles + 5-day forecast ───────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 18
            GridLayout {
                columns: 3; columnSpacing: 10; rowSpacing: 10; Layout.preferredWidth: 620; Layout.maximumWidth: 620
                Toggle { Layout.fillWidth: true; icon: Network.icon; title: "Wi-Fi"; subtitle: Network.label; active: Network.wifiEnabled; onClicked: Network.toggleWifi(); onRightClicked: Panels.show("network") }
                Toggle { Layout.fillWidth: true; icon: Bluetooth.icon; title: "Bluetooth"; subtitle: Bluetooth.label; active: Bluetooth.enabled; onClicked: Bluetooth.toggle(); onRightClicked: Panels.show("bluetooth") }
                Toggle { Layout.fillWidth: true; icon: Notifs.dnd ? "notifications_off" : "notifications"; title: "Do Not Disturb"; subtitle: Notifs.dnd ? "On" : "Off"; active: Notifs.dnd; onClicked: Notifs.dnd = !Notifs.dnd }
                Toggle { Layout.fillWidth: true; icon: "wallpaper"; title: "Wallpapers"; subtitle: "Pick or shuffle"; onClicked: Panels.show("wallpapers"); onRightClicked: Wallpapers.random() }
                Toggle { Layout.fillWidth: true; icon: Power.icon; title: "Power Mode"; subtitle: Power.profile; active: Power.profile === "performance"; onClicked: Power.cycle() }
                Toggle { Layout.fillWidth: true; icon: "lock"; title: "Lock Screen"; subtitle: "hyprlock"; onClicked: { Panels.close(); Power.lock() } }
                Toggle { Layout.fillWidth: true; icon: "keyboard"; title: "Shortcuts"; subtitle: "Super + K"; onClicked: Panels.show("hotkeys") }
                Toggle { Layout.fillWidth: true; icon: "content_paste"; title: "Clipboard"; subtitle: "History"; onClicked: Panels.show("clipboard") }
                Toggle { Layout.fillWidth: true; icon: "graphic_eq"; title: "Media"; subtitle: Media.active ? Media.title : "Player & equalizer"; onClicked: Panels.show("media") }
            }
            Item { Layout.fillWidth: true }
            Row {
                Layout.alignment: Qt.AlignRight; spacing: 8
                Repeater {
                    model: Weather.daily
                    Card { required property var modelData; width: 66; height: 122
                        Column { anchors.centerIn: parent; spacing: 4
                            Label { text: modelData.day.toUpperCase(); font.pixelSize: 10; font.bold: true; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
                            Icon { name: Weather.iconFor(modelData.code, true); fill: true; font.pixelSize: 22; anchors.horizontalCenter: parent.horizontalCenter; color: Theme.primary }
                            Label { text: Math.round(modelData.hi) + "°"; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
                            Label { text: Math.round(modelData.lo) + "°"; font.pixelSize: 11; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter } } }
                }
            }
        }
    }
}
