import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.services
import qs.components

// Equalizer block at the bottom of the media panel: divider · header (Equalizer · tune · Saved · preset · ON/OFF)
// · 10 vertical sliders with a curve through the knobs · 2×4 preset grid. Shows a status card instead of the
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

        // ── sliders ─────────────────────────────────────────────────────────
        Item {
            id: sliders
            visible: Equalizer.ready
            Layout.fillWidth: true; implicitHeight: 170
            property var pts: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]     // knob centre y per band (animated)
            function setPoint(i, y) { const p = pts.slice(); p[i] = y; pts = p }
            readonly property bool shaped: Equalizer.bands.some(b => b !== 0)
            Row {
                anchors.fill: parent
                Repeater {
                    model: 10
                    Item {
                        id: column
                        required property int index
                        width: root.width / 10; height: 170
                        VSlider {
                            id: s
                            anchors.horizontalCenter: parent.horizontalCenter; y: 0; height: 150
                            value: (Equalizer.bands[column.index] - Equalizer.minDb) / (Equalizer.maxDb - Equalizer.minDb)
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
            // curve through the knobs (the "lightning" line of the reference); geometry only, no per-frame repaints
            Shape {
                anchors.fill: parent
                opacity: (sliders.shaped ? 1 : 0) * (Equalizer.enabled ? 0.55 : 0.25)
                Behavior on opacity { NumberAnimation { duration: 200 } }
                ShapePath {
                    strokeColor: Theme.primary; strokeWidth: 2; fillColor: "transparent"
                    capStyle: ShapePath.RoundCap; joinStyle: ShapePath.RoundJoin
                    PathPolyline { path: sliders.pts.map((y, i) => Qt.point((i + 0.5) * root.width / 10, y)) }
                }
            }
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
