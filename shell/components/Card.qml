import QtQuick
import qs.services

// Slightly lighter inset box inside a Panel.
Rectangle {
    radius: Theme.radiusSm + 4
    color: Theme.alpha(Theme.surfaceContainer, 0.7)
    border.width: 1
    border.color: Theme.alpha(Theme.outlineVariant, 0.35)
}
