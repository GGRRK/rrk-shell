import QtQuick
import qs.services

// Floating panel surface: dark, translucent, rounded, thin border.
Rectangle {
    radius: Theme.radius
    color: Theme.panelBg
    border.width: 1
    border.color: Theme.panelBorder
    clip: true
}
