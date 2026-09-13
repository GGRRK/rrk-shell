import QtQuick
import qs.services

// Horizontal slider with an icon on the left. value 0..1; emits moved(v) while dragging.
Item {
    id: root
    property real value: 0
    property string icon: ""
    property color color: Theme.primary
    signal moved(real v)
    implicitHeight: 28
    implicitWidth: 200

    Icon { id: ic; name: root.icon; visible: root.icon !== ""; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: 20; color: root.color; fill: true }
    Rectangle {
        id: track
        anchors { left: ic.visible ? ic.right : parent.left; leftMargin: ic.visible ? 12 : 0; right: parent.right; verticalCenter: parent.verticalCenter }
        height: 10; radius: 5; color: Theme.alpha(Theme.outlineVariant, 0.5)
        Rectangle { width: Math.max(height, parent.width * Math.max(0, Math.min(1, root.value))); height: parent.height; radius: 5; color: root.color
                    Behavior on width { enabled: !mouse.pressed; NumberAnimation { duration: 120 } } }
        MouseArea {
            id: mouse; anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor
            function upd(x) { root.moved(Math.max(0, Math.min(1, (x - 8) / track.width))) }
            onPressed: e => upd(e.x); onPositionChanged: e => { if (pressed) upd(e.x) }
            onWheel: w => root.moved(Math.max(0, Math.min(1, root.value + (w.angleDelta.y > 0 ? 0.05 : -0.05))))
        }
    }
}
