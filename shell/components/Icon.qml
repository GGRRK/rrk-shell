import QtQuick
import qs.services

// A Material Symbols glyph, e.g. Icon { name: "settings" }
Text {
    property string name
    property bool fill: false
    text: name
    font.family: Theme.iconFont
    font.pixelSize: 18
    font.variableAxes: ({ "FILL": fill ? 1 : 0, "wght": 400, "opsz": 24 })
    color: Theme.onSurface
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
    renderType: Text.NativeRendering
}
