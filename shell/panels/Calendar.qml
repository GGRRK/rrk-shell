import QtQuick
import qs.services
import qs.components

// Month grid, Monday first. Prev/next month arrows, today highlighted.
Item {
    id: root
    property int year: Time.now.getFullYear()
    property int month: Time.now.getMonth()
    readonly property var monthNames: ["JANUARY","FEBRUARY","MARCH","APRIL","MAY","JUNE","JULY","AUGUST","SEPTEMBER","OCTOBER","NOVEMBER","DECEMBER"]
    function shift(d) { let m = month + d; if (m < 0) { m = 11; year-- } else if (m > 11) { m = 0; year++ } month = m }
    function cells() {
        const first = new Date(year, month, 1); const offset = (first.getDay() + 6) % 7
        const days = new Date(year, month + 1, 0).getDate(); const prevDays = new Date(year, month, 0).getDate()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = i - offset + 1
            if (d < 1) out.push({ d: prevDays + d, cur: false }); else if (d > days) out.push({ d: d - days, cur: false }); else out.push({ d: d, cur: true })
        }
        return out
    }
    readonly property bool isThisMonth: year === Time.now.getFullYear() && month === Time.now.getMonth()

    Column {
        anchors.fill: parent; spacing: 6
        Row {
            width: parent.width; height: 28
            IconButton { icon: "chevron_left"; size: 26; iconSize: 18; color: "transparent"; onClicked: root.shift(-1) }
            Label { width: parent.width - 52 - 26; height: 26; horizontalAlignment: Text.AlignHCenter; text: monthNames[month] + " " + year; font.bold: true; font.letterSpacing: 1 }
            IconButton { icon: "chevron_right"; size: 26; iconSize: 18; color: "transparent"; onClicked: root.shift(1) }
            IconButton { icon: "today"; size: 26; iconSize: 16; color: "transparent"; onClicked: { root.year = Time.now.getFullYear(); root.month = Time.now.getMonth() } }
        }
        Grid {
            columns: 7; width: parent.width
            Repeater { model: ["Mo","Tu","We","Th","Fr","Sa","Su"]
                Label { required property string modelData; width: parent.width / 7; height: 24; horizontalAlignment: Text.AlignHCenter; text: modelData; font.bold: true; font.pixelSize: 11; color: Theme.onSurfaceVariant } }
        }
        Grid {
            columns: 7; width: parent.width
            Repeater {
                model: root.cells()
                Item {
                    required property var modelData
                    readonly property bool today: root.isThisMonth && modelData.cur && modelData.d === Time.now.getDate()
                    width: parent.width / 7; height: 36
                    Rectangle { anchors.centerIn: parent; width: 30; height: 30; radius: 8; color: today ? Theme.primary : "transparent"
                        Label { anchors.centerIn: parent; text: modelData.d; font.pixelSize: 12; font.bold: today
                                color: today ? Theme.onPrimary : modelData.cur ? Theme.onSurface : Theme.alpha(Theme.outline, 0.4) } }
                }
            }
        }
    }
}
