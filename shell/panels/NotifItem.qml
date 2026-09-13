import QtQuick
import qs.services
import qs.components

// One notification row: accent stripe, summary, body, app name, dismiss, action buttons.
Card {
    id: root
    property var notif
    property bool compact: false
    implicitHeight: col.implicitHeight + 22
    Rectangle { width: 3; height: parent.height - 16; y: 8; x: 0; radius: 2; color: notif.urgency === 2 ? Theme.error : Theme.primary }
    Column {
        id: col
        anchors { left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 4
        Row { width: parent.width; spacing: 8
            Image { width: 20; height: 20; visible: source !== ""; anchors.verticalCenter: parent.verticalCenter; asynchronous: true; fillMode: Image.PreserveAspectFit
                    source: notif.image || (notif.appIcon ? (notif.appIcon.startsWith("/") ? "file://" + notif.appIcon : "image://icon/" + notif.appIcon) : "") }
            Label { text: notif.summary; font.bold: true; width: parent.width - 36 - (parent.children[0].visible ? 28 : 0); anchors.verticalCenter: parent.verticalCenter }
            Icon { name: "close"; font.pixelSize: 15; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter
                   MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: root.compact ? Notifs.hidePopup(notif) : notif.dismiss() } } }
        Label { text: notif.body.replace(/<[^>]+>/g, ""); visible: text !== ""; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: compact ? 3 : 6; font.pixelSize: 12; color: Theme.onSurfaceVariant }
        Label { text: notif.appName.toUpperCase(); visible: text !== ""; font.pixelSize: 9; font.letterSpacing: 1; color: Theme.outline }
        Row { spacing: 6; visible: notif.actions.length > 0
            Repeater { model: notif.actions
                Rectangle { required property var modelData; height: 24; width: t.implicitWidth + 20; radius: 12; color: am.containsMouse ? Theme.primary : Theme.pillBg
                    Label { id: t; anchors.centerIn: parent; text: modelData.text; font.pixelSize: 11; color: am.containsMouse ? Theme.onPrimary : Theme.onSurface }
                    MouseArea { id: am; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.invoke() } } } }
    }
}
