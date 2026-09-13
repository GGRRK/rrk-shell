import QtQuick
import qs.services
import qs.components

// Spectrum bars from the Cava service (40 rounded bars in primary; idle = a row of dim 3 px dots).
// The card itself is only shown while something plays (+ a 60 s grace period) — see DesktopWidgets.qml.
WidgetCard {
    title: "Now playing"; icon: "graphic_eq"
    subtitle: Media.artist ? Media.title + " · " + Media.artist : Media.title
    Item {
        id: area
        width: parent.width; height: 48
        readonly property real gap: 2
        readonly property real barW: (width - (Cava.count - 1) * gap) / Cava.count
        Repeater {
            model: Cava.count
            Rectangle {
                required property int index
                readonly property real v: (Cava.bars[index] || 0) / 100
                x: index * (area.barW + area.gap); width: area.barW
                height: Math.max(3, v * area.height); y: area.height - height
                radius: width / 2
                color: Theme.alpha(Theme.primary, 0.3 + 0.7 * v)
            }
        }
    }
}
