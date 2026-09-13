import QtQuick
import qs.services

// Wrapper for a popup panel: fades + slides in when Panels.open === name.
Item {
    id: root
    property string name
    readonly property bool shown: Panels.open === name
    default property alias content: panel.data
    implicitWidth: panel.implicitWidth; implicitHeight: panel.implicitHeight
    width: implicitWidth; height: implicitHeight
    visible: opacity > 0.01
    opacity: shown ? 1 : 0
    transform: Translate { y: root.shown ? 0 : -18; Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } } }
    Behavior on opacity { NumberAnimation { duration: 180 } }
    Panel { id: panel; anchors.fill: parent
            // swallow clicks so they don't reach the close-on-click backdrop
            MouseArea { anchors.fill: parent; z: -1; onClicked: {} } }
}
