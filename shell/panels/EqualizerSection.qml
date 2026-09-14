import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import qs.services
import qs.components

// Equalizer block at the bottom of the media panel: divider · header (Equalizer · tune · Saved · preset · ON/OFF)
// · 10 vertical sliders with a lightning bolt through the knobs (preset = glowing sweep) · 2×4 preset grid. Shows a status card instead of the
// sliders while easyeffects is not usable. Height is implicit; MediaPanel animates the panel around it.
// NOTE: never bind a positioner child's size to the positioner's own width (Grid/Row) — a hidden Grid falls back
// to its implicit width and the binding loops forever, freezing the whole shell. Sizes come from `root` here.
Item {
    id: root
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: 12

        Rectangle { Layout.fillWidth: true; implicitHeight: 1; Layout.bottomMargin: 4; color: Theme.alpha(Theme.outlineVariant, 0.4) }

        // ── header ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true; spacing: 10
            Label { text: "Equalizer"; font.pixelSize: 15; font.bold: true; color: Theme.primary }
            Item { Layout.fillWidth: true }
            IconButton { icon: "tune"; size: 28; iconSize: 16; visible: Equalizer.installed; onClicked: { Panels.close(); Equalizer.openGui() } }
            Pill { id: savedPill; padding: 12; implicitHeight: 28; radius: Theme.radiusSm; enabled: Equalizer.ready; opacity: enabled ? 1 : 0.5
                   active: Equalizer.preset === "Saved"
                   onClicked: m => m.button === Qt.RightButton ? Equalizer.saveCurrent() : Equalizer.clickSaved()
                   Label { text: "Saved"; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; color: savedPill.active ? Theme.onPrimary : Theme.onSurface } }
            Label { text: Equalizer.preset; font.pixelSize: 14; font.bold: true; Layout.preferredWidth: 64; horizontalAlignment: Text.AlignRight }
            Pill { id: onPill; padding: 12; implicitHeight: 28; radius: Theme.radiusSm; enabled: Equalizer.ready; opacity: enabled ? 1 : 0.5
                   active: Equalizer.enabled && Equalizer.ready
                   onClicked: Equalizer.setEnabled(!Equalizer.enabled)
                   Label { text: Equalizer.enabled ? "ON" : "OFF"; font.pixelSize: 12; font.bold: true; anchors.verticalCenter: parent.verticalCenter; color: onPill.active ? Theme.onPrimary : Theme.onSurface } }
        }

        // ── sliders + lightning ─────────────────────────────────────────────
        // A preset click runs a "sweep" (like the reference): a glowing ball crosses the bands 31 Hz → 16 kHz in
        // ~0.65 s, every knob snaps to its new value as the ball passes it, and a jagged bolt is redrawn behind it.
        // Afterwards the bolt keeps flickering (re-rolled ~9×/s) — only while the media panel is open and the EQ is
        // not flat, so the shell stays idle otherwise. The bolt is a Shape polyline; its halo is the same polyline
        // (plus the ball) in a blurred layer.
        Item {
            id: sliders
            visible: Equalizer.ready
            Layout.fillWidth: true; implicitHeight: 170
            property var pts: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]     // knob centre y per band (animated)
            function setPoint(i, y) { const p = pts.slice(); p[i] = y; pts = p }
            readonly property bool shaped: Equalizer.bands.some(b => b !== 0)
            readonly property real colW: root.width / 10

            property real sweep: -1                              // ball position in bands (0 … 9); -1 = no sweep running
            readonly property bool sweeping: sweep >= 0
            property var oldBands: Equalizer.bands               // knobs the ball has not reached yet still show these
            property var bolt: []                                // jagged polyline (points) through the knobs, up to the ball
            property real ballX: 0
            property real ballY: 0
            readonly property real glowOpacity: (shaped || sweeping ? 1 : 0) * (Equalizer.enabled ? 0.8 : 0.3)
            function shownDb(i) { return sweeping && i > sweep ? oldBands[i] : Equalizer.bands[i] }

            Connections { target: Equalizer; function onPresetApplying() { sliders.oldBands = Equalizer.bands.slice(); sweepAnim.restart() } }
            NumberAnimation { id: sweepAnim; target: sliders; property: "sweep"; from: 0; to: 9; duration: 650; easing.type: Easing.OutSine
                              onFinished: sliders.sweep = -1 }

            // straight knots = knob centres up to the ball, then each segment gets a few randomly displaced points
            function rebuild() {
                const knots = []
                const last = sweeping ? Math.min(9, Math.floor(sweep)) : 9
                for (let i = 0; i <= last; i++) knots.push(Qt.point((i + 0.5) * colW, pts[i]))
                if (sweeping && sweep < 9) { const t = sweep - last; knots.push(Qt.point((sweep + 0.5) * colW, pts[last] + (pts[last + 1] - pts[last]) * t)) }
                const tip = knots[knots.length - 1]; ballX = tip.x; ballY = tip.y
                const out = []
                for (let k = 0; k < knots.length - 1; k++) {
                    const a = knots[k], b = knots[k + 1]
                    const dx = b.x - a.x, dy = b.y - a.y, len = Math.hypot(dx, dy) || 1
                    const nx = -dy / len, ny = dx / len, segs = Math.max(2, Math.round(len / 9))
                    out.push(a)
                    for (let j = 1; j < segs; j++) { const t = j / segs, off = (Math.random() * 2 - 1) * 3; out.push(Qt.point(a.x + dx * t + nx * off, a.y + dy * t + ny * off)) }
                }
                out.push(tip)
                bolt = out
            }
            onPtsChanged: rebuild()
            onSweepChanged: rebuild()
            onWidthChanged: rebuild()
            Timer { interval: 110; repeat: true; onTriggered: sliders.rebuild()
                    running: Panels.open === "media" && Equalizer.expanded && sliders.visible && sliders.shaped && !sliders.sweeping }

            Row {
                anchors.fill: parent
                Repeater {
                    model: 10
                    Item {
                        id: column
                        required property int index
                        width: sliders.colW; height: 170
                        VSlider {
                            id: s
                            anchors.horizontalCenter: parent.horizontalCenter; y: 0; height: 150
                            value: (sliders.shownDb(column.index) - Equalizer.minDb) / (Equalizer.maxDb - Equalizer.minDb)
                            opacity: Equalizer.enabled ? 1 : 0.55
                            onMoved: v => Equalizer.setBand(column.index, Equalizer.minDb + v * (Equalizer.maxDb - Equalizer.minDb))
                            onResetRequested: Equalizer.setBand(column.index, 0)
                            onKnobYChanged: sliders.setPoint(column.index, knobY)
                            Component.onCompleted: sliders.setPoint(column.index, knobY)
                        }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; y: 156; text: Equalizer.labels[column.index]; font.pixelSize: 11; font.bold: true }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; y: Math.max(0, s.knobY - 26); visible: s.pressed
                                text: (Equalizer.bands[column.index] > 0 ? "+" : "") + Equalizer.bands[column.index].toFixed(1); font.pixelSize: 10; font.bold: true; color: Theme.primary }
                    }
                }
            }
            // halo: bolt + ball, blurred
            Item {
                anchors.fill: parent
                opacity: sliders.glowOpacity
                Behavior on opacity { NumberAnimation { duration: 200 } }
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 0.9; blurMax: 24 }
                Shape {
                    anchors.fill: parent
                    ShapePath { strokeColor: Theme.primary; strokeWidth: 5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                                PathPolyline { path: sliders.bolt } }
                }
                Rectangle { x: sliders.ballX - 26; y: sliders.ballY - 26; width: 52; height: 52; radius: 26; color: Theme.primary
                            opacity: sliders.sweeping ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } } }
                Rectangle { x: sliders.ballX - 12; y: sliders.ballY - 12; width: 24; height: 24; radius: 12; color: Theme.onSurface
                            opacity: sliders.sweeping ? 0.9 : 0; Behavior on opacity { NumberAnimation { duration: 250 } } }
            }
            // crisp core
            Shape {
                anchors.fill: parent
                opacity: sliders.glowOpacity
                ShapePath { strokeColor: Theme.alpha(Theme.onSurface, 0.9); strokeWidth: 1.5; fillColor: "transparent"; capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                            PathPolyline { path: sliders.bolt } }
            }
            Rectangle { x: sliders.ballX - 6; y: sliders.ballY - 6; width: 12; height: 12; radius: 6; color: Theme.onSurface
                        opacity: sliders.sweeping ? 1 : 0; Behavior on opacity { NumberAnimation { duration: 250 } } }
        }

        // ── status card (replaces sliders + presets while easyeffects is not usable) ──
        Card {
            id: statusCard
            visible: !Equalizer.ready
            Layout.fillWidth: true; implicitHeight: 96
            readonly property bool clickable: Equalizer.status === "not-running" || Equalizer.status === "failed"
            Column {
                anchors.centerIn: parent; width: parent.width - 40; spacing: 4
                Icon { name: Equalizer.installed && Equalizer.status !== "failed" ? "equalizer" : "error"; font.pixelSize: 26; color: Theme.onSurfaceVariant; anchors.horizontalCenter: parent.horizontalCenter }
                Label { text: Equalizer.statusText; font.bold: true; width: parent.width; horizontalAlignment: Text.AlignHCenter }
                Label { text: Equalizer.statusHint; font.pixelSize: 11; color: Theme.onSurfaceVariant; width: parent.width; horizontalAlignment: Text.AlignHCenter; visible: text !== "" }
            }
            MouseArea {
                anchors.fill: parent
                enabled: statusCard.clickable
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: Equalizer.status === "not-running" ? Equalizer.startService() : Equalizer.retry()
            }
        }

        // ── presets ─────────────────────────────────────────────────────────
        Grid {
            visible: Equalizer.ready
            Layout.fillWidth: true; columns: 4; columnSpacing: 10; rowSpacing: 8
            Repeater {
                model: Equalizer.presetNames
                Pill {
                    id: pp
                    required property string modelData
                    width: (root.width - 30) / 4; implicitHeight: 30; radius: Theme.radiusSm    // root.width, NOT the Grid's (binding loop)
                    active: Equalizer.preset === modelData
                    onClicked: Equalizer.applyPreset(modelData)
                    Label { text: pp.modelData; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter; color: pp.active ? Theme.onPrimary : Theme.onSurface }
                }
            }
        }
    }
}
