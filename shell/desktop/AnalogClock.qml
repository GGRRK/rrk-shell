import QtQuick
import qs.services

// Minimal analog face: 60 ticks, hour + minute hands in onSurface, thin primary seconds hand with a short tail.
// No Canvas: ticks and hands are rotated Rectangles, so the only per-second work is a transform update.
// The seconds hand ticks (no sweep animation) on purpose — one frame per second, nothing more.
Item {
    id: root
    property int size: 140
    readonly property int h: Time.now.getHours()
    readonly property int m: Time.now.getMinutes()
    readonly property int s: Time.now.getSeconds()
    width: size; height: size

    Rectangle { anchors.fill: parent; radius: width / 2; color: Theme.alpha(Theme.surfaceContainer, 0.5); border.width: 1; border.color: Theme.alpha(Theme.outlineVariant, 0.7) }

    Repeater {
        model: 60
        Item {
            required property int index
            readonly property bool major: index % 5 === 0
            width: root.size; height: root.size; rotation: index * 6          // rotates about the centre (default transformOrigin)
            Rectangle { x: (root.size - width) / 2; y: 6; width: major ? 2 : 1; height: major ? 8 : 4; radius: 1; antialiasing: true
                        color: major ? Theme.alpha(Theme.onSurface, 0.7) : Theme.alpha(Theme.outline, 0.45) }
        }
    }
    // hands: each lives in a full-size Item rotated about the centre; the Rectangle's foot sits on the centre
    Item { width: root.size; height: root.size; rotation: (root.h % 12) * 30 + root.m * 0.5
           Rectangle { x: (root.size - width) / 2; y: root.size / 2 - height; width: 4; height: root.size * 0.27; radius: 2; antialiasing: true; color: Theme.onSurface } }
    Item { width: root.size; height: root.size; rotation: root.m * 6 + root.s * 0.1
           Rectangle { x: (root.size - width) / 2; y: root.size / 2 - height; width: 3; height: root.size * 0.38; radius: 1.5; antialiasing: true; color: Theme.onSurface } }
    Item { width: root.size; height: root.size; rotation: root.s * 6
           Rectangle { x: (root.size - width) / 2; y: root.size / 2 - root.size * 0.42; width: 2; height: root.size * 0.42 + 10; radius: 1; antialiasing: true; color: Theme.primary } }
    Rectangle { anchors.centerIn: parent; width: 8; height: 8; radius: 4; color: Theme.primary
                Rectangle { anchors.centerIn: parent; width: 3; height: 3; radius: 1.5; color: Theme.surface } }
}
