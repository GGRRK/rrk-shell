import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// Now playing: spinning round album art with a cava ring around it, marquee title/artist, output device, seek bar,
// transport; audio output volume below; collapsible 10-band equalizer (easyeffects) at the bottom — the panel
// grows/shrinks with it. The album art, blurred, is the panel's backdrop (masked to the rounded corners).
Popup {
    id: media
    name: "media"
    implicitWidth: 640
    implicitHeight: 44 + col.implicitHeight + (Equalizer.expanded ? 16 + eq.implicitHeight : 0)
    Behavior on implicitHeight { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    onShownChanged: if (shown) Equalizer.refresh()
    // ── backdrop: album art, oversized (so the blur has no fading edge inside the panel), blurred, masked ──
    Item {
        anchors.fill: parent; anchors.margins: -64          // declared first = under the content, over the panel fill
        visible: Media.artUrl !== ""
        Image { id: bgArt; anchors.fill: parent; source: Media.artUrl; sourceSize.width: 160; fillMode: Image.PreserveAspectCrop
                asynchronous: true; visible: false; layer.enabled: true }
        Item { id: bgMask; anchors.fill: parent; visible: false; layer.enabled: true
               Rectangle { anchors.fill: parent; anchors.margins: 64; radius: Theme.radius } }
        MultiEffect { source: bgArt; anchors.fill: parent; blurEnabled: true; blur: 1.0; blurMax: 64; blurMultiplier: 2; autoPaddingEnabled: false
                      maskEnabled: true; maskSource: bgMask; opacity: 0.3 }
    }
    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 22 }
        spacing: 16
        RowLayout {
            spacing: 24; Layout.fillWidth: true
            Item {
                width: 150; height: 150
                // cava ring: 40 spectrum values mirrored into 80 short bars around the art (low frequencies at the top),
                // slightly blurred so it reads as a breathing halo; repainted at cava's 20 fps only while playing
                Canvas {
                    id: ring
                    anchors.centerIn: parent; width: 214; height: 214
                    visible: Media.artUrl !== ""
                    opacity: Media.playing ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    layer.enabled: true
                    layer.effect: MultiEffect { blurEnabled: true; blur: 0.6; blurMax: 12 }
                    property var bars: Cava.bars
                    onBarsChanged: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d"), n = Cava.count
                        ctx.clearRect(0, 0, width, height)
                        ctx.lineWidth = 3; ctx.lineCap = "round"
                        const cx = width / 2, cy = height / 2, r0 = 79, maxLen = 22
                        for (let i = 0; i < 2 * n; i++) {
                            const v = (bars[i < n ? i : 2 * n - 1 - i] || 0) / 100
                            const a = -Math.PI / 2 + (i + 0.5) / n * Math.PI, len = 1.5 + v * maxLen   // right half top→bottom, then mirrored
                            ctx.strokeStyle = Theme.alpha(Theme.primary, 0.3 + 0.7 * v)
                            ctx.beginPath()
                            ctx.moveTo(cx + Math.cos(a) * r0, cy + Math.sin(a) * r0)
                            ctx.lineTo(cx + Math.cos(a) * (r0 + len), cy + Math.sin(a) * (r0 + len))
                            ctx.stroke()
                        }
                    }
                }
                Rectangle {
                    anchors.fill: parent; radius: 75; color: Theme.surfaceHighest; border.width: 3; border.color: Theme.primary
                    RotationAnimation on rotation { from: 0; to: 360; duration: 12000; loops: Animation.Infinite; running: Media.playing && Media.artUrl !== "" }
                    Item {
                        anchors.fill: parent; anchors.margins: 6; visible: Media.artUrl !== ""
                        Image { id: artImg; anchors.fill: parent; source: Media.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false; layer.enabled: true }
                        Item { id: artMask; anchors.fill: parent; layer.enabled: true; visible: false; Rectangle { anchors.fill: parent; radius: width / 2 } }
                        MultiEffect { source: artImg; anchors.fill: artImg; maskEnabled: true; maskSource: artMask; maskThresholdMin: 0.5; maskSpreadAtMin: 1.0 }
                    }
                    Rectangle { anchors.centerIn: parent; width: 26; height: 26; radius: 13; color: Theme.surface; border.width: 2; border.color: Theme.outlineVariant; visible: Media.artUrl !== "" }
                    Icon { anchors.centerIn: parent; name: "music_note"; font.pixelSize: 44; visible: Media.artUrl === ""; color: Theme.onSurfaceVariant }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                RowLayout { Layout.fillWidth: true; spacing: 8
                    Marquee { text: Media.active ? Media.title : "Nothing playing"; font.pixelSize: 18; font.bold: true; Layout.fillWidth: true; running: media.shown }
                    IconButton { icon: "equalizer"; size: 30; iconSize: 18; active: Equalizer.expanded; onClicked: Equalizer.toggleExpanded() } }
                Label { text: Media.artist ? "BY " + Media.artist.toUpperCase() : ""; font.pixelSize: 12; color: Theme.onSurfaceVariant; Layout.fillWidth: true }
                Row { spacing: 8
                    Pill { padding: 8; implicitHeight: 24
                           Icon { name: Bluetooth.primary ? "bluetooth" : "speaker"; font.pixelSize: 14; anchors.verticalCenter: parent.verticalCenter }
                           Label { text: Bluetooth.primary ? Bluetooth.primary.name : Audio.sinkName; font.pixelSize: 11; width: Math.min(implicitWidth, 200); anchors.verticalCenter: parent.verticalCenter } }
                    Label { text: Media.app ? "VIA " + Media.app : ""; font.italic: true; font.pixelSize: 11; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter } }
                Item { height: 6 }
                HSlider { Layout.fillWidth: true; value: Media.length > 0 ? Media.position / Media.length : 0; onMoved: v => Media.seek(v * Media.length) }
                RowLayout { Layout.fillWidth: true
                    Label { text: Media.fmt(Media.position); font.pixelSize: 11; color: Theme.onSurfaceVariant }
                    Item { Layout.fillWidth: true }
                    Label { text: Media.fmt(Media.length); font.pixelSize: 11; color: Theme.onSurfaceVariant } }
                Row { Layout.alignment: Qt.AlignHCenter; spacing: 26
                    IconButton { icon: "skip_previous"; fill: true; size: 40; iconSize: 26; color: "transparent"; onClicked: Media.previous() }
                    IconButton { icon: Media.playing ? "pause" : "play_arrow"; fill: true; size: 48; iconSize: 34; active: true; onClicked: Media.toggle() }
                    IconButton { icon: "skip_next"; fill: true; size: 40; iconSize: 26; color: "transparent"; onClicked: Media.next() } }
            }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: Theme.alpha(Theme.outlineVariant, 0.4) }
        RowLayout { Layout.fillWidth: true; spacing: 16
            HSlider { Layout.fillWidth: true; icon: Audio.icon; value: Audio.volume; onMoved: v => Audio.setVolume(v) }
            HSlider { Layout.fillWidth: true; icon: Audio.micMuted ? "mic_off" : "mic"; value: Audio.micVolume; color: Theme.tertiary; onMoved: v => { if (Audio.source && Audio.source.audio) Audio.source.audio.volume = v } }
            IconButton { icon: "settings"; size: 32; iconSize: 18; onClicked: { Panels.close(); Runner.run("pavucontrol") } } }
    }
    EqualizerSection {
        id: eq
        anchors { top: col.bottom; topMargin: 16; left: parent.left; right: parent.right; leftMargin: 22; rightMargin: 22 }
        opacity: Equalizer.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 160 } }
        visible: opacity > 0
    }
}
