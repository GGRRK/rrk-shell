import QtQuick
import qs.services
import qs.components

// Glassy card for a desktop widget: translucent dark surface, thin border, optional small-caps header
// (icon + title left, subtitle right). Children go into a vertical Column (`spacing`).
// No blur behind it (the window's namespace is kept out of look.lua's blur rule on purpose), so the fill is
// fairly opaque to keep 9-11 px captions readable over busy wallpapers.
Rectangle {
    id: root
    property string title: ""
    property string icon: ""
    property string subtitle: ""
    property int pad: 16
    property alias spacing: body.spacing
    default property alias content: body.data

    implicitHeight: (header.visible ? root.pad + 14 + 10 : root.pad) + body.implicitHeight + root.pad
    radius: Theme.radius
    color: Theme.alpha(Theme.surfaceLow, 0.85)
    border.width: 1
    border.color: Theme.alpha(Theme.outlineVariant, 0.5)
    clip: true

    // faint glass highlight along the top edge
    Rectangle { anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 1; leftMargin: root.radius; rightMargin: root.radius }
                height: 1; color: Theme.alpha(Theme.onSurface, 0.06) }

    Item {
        id: header
        visible: root.title !== ""
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: root.pad; leftMargin: root.pad; rightMargin: root.pad }
        height: visible ? 14 : 0
        Row { id: headerRow; spacing: 6; anchors.verticalCenter: parent.verticalCenter
            Icon  { name: root.icon; visible: root.icon !== ""; font.pixelSize: 14; color: Theme.primary; anchors.verticalCenter: parent.verticalCenter }
            Label { text: root.title.toUpperCase(); font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter } }
        Label { anchors { right: parent.right; verticalCenter: parent.verticalCenter } text: root.subtitle; visible: text !== ""
                font.pixelSize: 10; color: Theme.onSurfaceVariant; horizontalAlignment: Text.AlignRight
                width: Math.min(implicitWidth, Math.max(0, header.width - headerRow.width - 10)) }
    }
    Column {
        id: body
        anchors { top: header.visible ? header.bottom : parent.top; topMargin: header.visible ? 10 : root.pad
                  left: parent.left; right: parent.right; leftMargin: root.pad; rightMargin: root.pad }
        spacing: 10
    }
}
