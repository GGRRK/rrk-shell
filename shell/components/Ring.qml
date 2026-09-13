import QtQuick
import qs.services

// Circular progress ring. value 0..1
Item {
    id: root
    property real value: 0
    property int thickness: 6
    property color color: Theme.primary
    property color track: Theme.alpha(Theme.outlineVariant, 0.5)
    property int size: 64
    property bool animated: true     // false = jump straight to the new value (desktop widgets: no per-frame redraws)
    default property alias content: inner.data
    implicitWidth: size; implicitHeight: size

    property real _anim: value
    Behavior on _anim { enabled: root.animated; NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
    on_AnimChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackChanged: canvas.requestPaint()

    Canvas {
        id: canvas; anchors.fill: parent; antialiasing: true
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            const cx = width / 2, cy = height / 2, r = Math.min(cx, cy) - root.thickness / 2
            ctx.lineWidth = root.thickness; ctx.lineCap = "round"
            ctx.strokeStyle = root.track; ctx.beginPath(); ctx.arc(cx, cy, r, 0, Math.PI * 2); ctx.stroke()
            if (root._anim > 0) {
                ctx.strokeStyle = root.color; ctx.beginPath()
                ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * Math.min(1, root._anim)); ctx.stroke()
            }
        }
    }
    Item { id: inner; anchors.fill: parent }
}
