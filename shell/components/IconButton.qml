import QtQuick
import qs.services

// Square-ish button with a Material icon. Optional `label` text underneath the icon row.
Rectangle {
    id: root
    property string icon
    property bool active: false
    property bool fill: active
    property int size: 36
    property int iconSize: 20
    property color activeColor: Theme.primary
    signal clicked()
    implicitWidth: size; implicitHeight: size
    radius: Theme.radiusSm
    color: active ? activeColor : mouse.containsMouse ? Theme.pillHover : Theme.pillBg
    Behavior on color { ColorAnimation { duration: 140 } }
    Icon { anchors.centerIn: parent; name: root.icon; fill: root.fill; font.pixelSize: root.iconSize; color: root.active ? Theme.onPrimary : Theme.onSurface }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
}
