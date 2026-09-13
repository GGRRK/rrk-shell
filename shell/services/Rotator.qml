pragma Singleton
import Quickshell
import QtQuick

// Automatic wallpaper rotation.
Singleton {
    property bool enabled: false
    property int minutes: 15
    Timer { interval: minutes * 60 * 1000; running: enabled; repeat: true; onTriggered: Wallpapers.random() }
}
