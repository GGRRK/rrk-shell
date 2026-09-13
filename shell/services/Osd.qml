pragma Singleton
import Quickshell
import QtQuick

// On-screen display for volume / brightness key presses.
Singleton {
    id: root
    property string kind: ""        // "volume" | "brightness" | "mic"
    property bool visible: false
    function show(k) { kind = k; visible = true; hide.restart() }
    Timer { id: hide; interval: 1500; onTriggered: root.visible = false }
}
