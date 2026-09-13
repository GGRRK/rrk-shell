import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// Now playing: round album art, title/artist, output device, seek bar, transport; audio output volume below.
Popup {
    name: "media"
    implicitWidth: 640; implicitHeight: 330
    ColumnLayout {
        anchors { fill: parent; margins: 22 }
        spacing: 16
        RowLayout {
            spacing: 24; Layout.fillWidth: true
            Rectangle {
                width: 150; height: 150; radius: 75; color: Theme.surfaceHighest; border.width: 3; border.color: Theme.primary
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
            ColumnLayout {
                Layout.fillWidth: true; spacing: 6
                Label { text: Media.active ? Media.title : "Nothing playing"; font.pixelSize: 18; font.bold: true; Layout.fillWidth: true }
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
}
