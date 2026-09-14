import QtQuick
import qs.services

// One line of text that scrolls sideways when it does not fit (2 s pause, slow loop with a gap); static otherwise.
// Give it a width (Layout.fillWidth / anchors); the animation only runs while `running` (bind it to the panel being shown).
Item {
    id: root
    property alias text: t1.text
    property alias font: t1.font
    property alias color: t1.color
    property bool running: true
    property int gap: 48
    property real speed: 40                      // px per second
    implicitHeight: t1.implicitHeight
    clip: true
    readonly property bool overflow: t1.implicitWidth > width + 1

    Row {
        id: row
        spacing: root.gap
        Label { id: t1; elide: Text.ElideNone }
        Label { text: t1.text; font: t1.font; color: t1.color; elide: Text.ElideNone; visible: root.overflow }
    }
    SequentialAnimation {
        running: root.overflow && root.running && root.visible
        loops: Animation.Infinite
        onRunningChanged: if (!running) row.x = 0
        PauseAnimation { duration: 2000 }
        NumberAnimation { target: row; property: "x"; from: 0; to: -(t1.implicitWidth + root.gap)
                          duration: (t1.implicitWidth + root.gap) / root.speed * 1000 }
    }
    onTextChanged: row.x = 0
}
