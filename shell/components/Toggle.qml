import QtQuick
import qs.services

// Big quick-settings toggle tile: icon + title + subtitle.
Rectangle {
    id: root
    property string icon
    property string title
    property string subtitle: ""
    property bool active: false
    signal clicked()
    signal rightClicked()
    implicitHeight: 56
    radius: Theme.radiusSm + 4
    color: active ? Theme.primary : mouse.containsMouse ? Theme.pillHover : Theme.alpha(Theme.surfaceContainer, 0.8)
    Behavior on color { ColorAnimation { duration: 140 } }
    Row {
        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: 10 }
        spacing: 12
        Icon { name: root.icon; fill: root.active; font.pixelSize: 22; color: root.active ? Theme.onPrimary : Theme.onSurface; anchors.verticalCenter: parent.verticalCenter }
        Column {
            width: parent.width - 34; anchors.verticalCenter: parent.verticalCenter; spacing: 1
            Label { text: root.title; width: parent.width; font.bold: true; color: root.active ? Theme.onPrimary : Theme.onSurface }
            Label { text: root.subtitle; width: parent.width; font.pixelSize: 11; visible: text !== ""; color: root.active ? Theme.alpha(Theme.onPrimary, 0.8) : Theme.onSurfaceVariant }
        }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked() }
}
