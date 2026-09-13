import QtQuick
import qs.services

// Vertical slider: value 0..1 (0 = bottom). moved(v) while dragging / on wheel, resetRequested() on double-click.
// knobY = knob centre (animated) in this item's coordinates; the equalizer draws its curve through it.
Item {
    id: root
    property real value: 0.5
    property color color: Theme.primary
    property int trackWidth: 12
    property int knobSize: 18
    property real wheelStep: 1 / 24               // one notch (120 units of angleDelta) = this much of the range
    signal moved(real v)
    signal resetRequested()
    implicitWidth: 36; implicitHeight: 150

    readonly property bool pressed: mouse.pressed
    readonly property real travel: height - knobSize
    property real shown: value                     // animated copy of value (instant while dragging)
    Behavior on shown { enabled: !mouse.pressed; NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    readonly property real knobY: knobSize / 2 + (1 - Math.max(0, Math.min(1, shown))) * travel

    Rectangle { id: track; anchors.horizontalCenter: parent.horizontalCenter; y: root.knobSize / 2; height: root.travel
                width: root.trackWidth; radius: width / 2; color: Theme.alpha(Theme.surfaceHigh, 0.9) }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: track.y + track.height - height
                height: Math.max(root.trackWidth, track.y + track.height - root.knobY); width: root.trackWidth; radius: width / 2; color: root.color }
    Rectangle { anchors.horizontalCenter: parent.horizontalCenter; y: root.knobY - root.knobSize / 2
                width: root.knobSize; height: root.knobSize; radius: root.knobSize / 2; color: Theme.onSurface
                scale: mouse.pressed ? 1.15 : mouse.containsMouse ? 1.08 : 1
                Behavior on scale { NumberAnimation { duration: 100 } } }
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
        property real wheelAcc: 0                  // touchpads send many tiny deltas: step once per 120 units
        function upd(y) { root.moved(Math.max(0, Math.min(1, 1 - (y - root.knobSize / 2) / root.travel))) }
        onPressed: e => upd(e.y)
        onPositionChanged: e => { if (pressed) upd(e.y) }
        onDoubleClicked: root.resetRequested()
        onWheel: w => {
            wheelAcc += w.angleDelta.y
            const steps = Math.trunc(wheelAcc / 120)
            if (steps === 0) return
            wheelAcc -= steps * 120
            root.moved(Math.max(0, Math.min(1, root.value + steps * root.wheelStep)))
        }
    }
}
