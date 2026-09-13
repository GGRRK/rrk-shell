import QtQuick
import qs.services
import qs.components

// Now-playing pill: album art, title / position, transport buttons.
Pill {
    visible: Media.active
    padding: 6
    active: Panels.open === "media"
    onClicked: Panels.toggle("media")
    Rectangle {
        width: 22; height: 22; radius: 5; color: Theme.surfaceHighest; anchors.verticalCenter: parent.verticalCenter; clip: true
        Image { anchors.fill: parent; source: Media.artUrl; fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: status === Image.Ready }
        Icon { anchors.centerIn: parent; name: "music_note"; font.pixelSize: 14; visible: Media.artUrl === "" }
    }
    Column {
        anchors.verticalCenter: parent.verticalCenter; spacing: -1
        Label { text: Media.title; font.bold: true; font.pixelSize: 11; width: 150; elide: Text.ElideRight; color: parent.parent.active ? Theme.onPrimary : Theme.onSurface }
        Label { text: Media.fmt(Media.position) + " / " + Media.fmt(Media.length); font.pixelSize: 9; color: parent.parent.active ? Theme.onPrimary : Theme.onSurfaceVariant }
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter; spacing: 0
        Repeater {
            model: [ { i: "skip_previous", f: () => Media.previous() }, { i: Media.playing ? "pause" : "play_arrow", f: () => Media.toggle() }, { i: "skip_next", f: () => Media.next() } ]
            Item { required property var modelData; width: 22; height: 22
                Icon { anchors.centerIn: parent; name: modelData.i; fill: true; font.pixelSize: 18; color: ma.containsMouse ? Theme.primary : Theme.onSurface }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.f() } }
        }
    }
}
