import QtQuick
import qs.services
import qs.components

// One satellite chip of the radial Bluetooth view: icon + title + subtitle.
// Positioned by its CENTRE (tx, ty). Motion is explicit so the radial can choose between
//   flyIn(x, y) — entrance: starts small + faded a bit outside the panel centre (ox, oy), after `delay` ms
//   moveTo(x, y) — slide from wherever the chip is now to a new slot (device list churn while scanning)
// `t` runs 0 → 1 for either; (fx, fy, fs, fo) is where the motion starts.
Card {
    id: chip
    property string icon: "bluetooth"
    property string title: ""
    property string subtitle: ""
    property int    titleSize: 13
    property bool   accent: false      // primary-tinted border + icon (paired / connected / action chips)
    property bool   dim: false         // busy: greyed title
    property real   ox: 0              // panel centre, where fly-ins come from
    property real   oy: 0
    property int    delay: 0           // stagger before the fly-in, ms
    property real   tx: 0              // target centre
    property real   ty: 0
    property real   fx: 0              // motion start: centre, scale, opacity
    property real   fy: 0
    property real   fs: 1
    property real   fo: 1
    property real   t: 1
    signal clicked()

    function flyIn(nx, ny) {
        move.stop(); enter.stop()
        tx = nx; ty = ny
        fx = ox + (nx - ox) * 0.55; fy = oy + (ny - oy) * 0.55; fs = 0.6; fo = 0
        t = 0
        enter.start()
    }
    function moveTo(nx, ny) {
        if (nx === tx && ny === ty) return
        move.stop(); enter.stop()
        // continue from the current place / size / opacity (also mid fly-in)
        fx = fx + (tx - fx) * t; fy = fy + (ty - fy) * t; fs = fs + (1 - fs) * t; fo = fo + (1 - fo) * t
        tx = nx; ty = ny
        t = 0
        move.start()
    }

    width: 168; height: 60; radius: 12
    color: mouse.containsMouse ? Theme.alpha(Theme.surfaceContainer, 0.95) : Theme.alpha(Theme.surfaceLow, 0.92)
    border.width: 1
    border.color: mouse.containsMouse ? Theme.alpha(Theme.primary, 0.7)
                : accent ? Theme.alpha(Theme.primary, 0.35) : Theme.alpha(Theme.outlineVariant, 0.5)
    Behavior on color { ColorAnimation { duration: 140 } }
    Behavior on border.color { ColorAnimation { duration: 140 } }

    x: fx + (tx - fx) * t - width / 2
    y: fy + (ty - fy) * t - height / 2
    opacity: fo + (1 - fo) * t
    scale: (fs + (1 - fs) * t) * (mouse.containsMouse ? 1.04 : 1)
    Behavior on scale { enabled: chip.t >= 1; NumberAnimation { duration: 120 } }
    SequentialAnimation {
        id: enter
        PauseAnimation { duration: chip.delay }
        NumberAnimation { target: chip; property: "t"; from: 0; to: 1; duration: 280; easing.type: Easing.OutCubic }
    }
    NumberAnimation { id: move; target: chip; property: "t"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }

    Icon { x: 12; anchors.verticalCenter: parent.verticalCenter; name: chip.icon; fill: chip.accent; font.pixelSize: 22
           color: chip.accent ? Theme.primary : Theme.onSurfaceVariant }
    Column {
        x: 42; width: parent.width - 48; anchors.verticalCenter: parent.verticalCenter; spacing: 2   // 120 px: 15-char names fit at 13 px
        Label { text: chip.title; width: parent.width; font.pixelSize: chip.titleSize; font.bold: true
                color: chip.dim ? Theme.onSurfaceVariant : Theme.onSurface }
        Label { text: chip.subtitle; width: parent.width; font.pixelSize: 11; color: Theme.onSurfaceVariant; visible: text !== "" }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: chip.clicked() }
}
