import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import qs.services
import qs.components

Row {
    spacing: 4
    visible: SystemTray.items.values.length > 0
    Repeater {
        model: SystemTray.items.values
        Item {
            required property var modelData
            width: 26; height: 26
            Image { anchors.centerIn: parent; width: 16; height: 16; source: modelData.icon; sourceSize: Qt.size(32, 32); smooth: true }
            MouseArea {
                anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton; cursorShape: Qt.PointingHandCursor
                onClicked: m => { if (m.button === Qt.LeftButton) modelData.activate(); else if (m.button === Qt.MiddleButton) modelData.secondaryActivate(); else if (modelData.hasMenu) menu.open() }
            }
            QsMenuAnchor { id: menu; menu: modelData.menu; anchor.item: parent; anchor.rect.y: parent.height + 6 }
        }
    }
}
