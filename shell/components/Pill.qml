import QtQuick
import qs.services

// Rounded module background used all over the bar. Put content inside `content`.
Rectangle {
    id: root
    property bool hovered: mouse.containsMouse
    property bool active: false
    property int padding: 12
    default property alias content: inner.data
    signal clicked(var mouse)
    signal wheel(var wheel)

    implicitWidth: inner.implicitWidth + padding * 2
    implicitHeight: 30
    radius: height / 2
    color: active ? Theme.primary : hovered ? Theme.pillHover : Theme.pillBg
    Behavior on color { ColorAnimation { duration: 140 } }

    Row { id: inner; anchors.centerIn: parent; spacing: 6 }
    MouseArea {
        id: mouse; anchors.fill: parent; hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: m => root.clicked(m)
        onWheel: w => root.wheel(w)
        cursorShape: Qt.PointingHandCursor
    }
}
