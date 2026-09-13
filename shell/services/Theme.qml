pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Colour palette + design tokens. Colours come from ~/.config/rrk-shell/colors.json,
// which matugen regenerates from the wallpaper (see matugen/templates/colors.json).
Singleton {
    id: root

    property var c: ({})
    function pick(key, fallback) { return (c && c[key]) ? c[key] : fallback }

    readonly property color primary:          pick("primary", "#a8c7ff")
    readonly property color onPrimary:        pick("onPrimary", "#0b2a55")
    readonly property color primaryContainer: pick("primaryContainer", "#2d4a75")
    readonly property color secondary:        pick("secondary", "#bcc7dc")
    readonly property color tertiary:         pick("tertiary", "#d8bde6")
    readonly property color error:            pick("error", "#ffb4ab")
    readonly property color surface:          pick("surface", "#0f1116")
    readonly property color surfaceLow:       pick("surfaceLow", "#151820")
    readonly property color surfaceContainer: pick("surfaceContainer", "#1b1f28")
    readonly property color surfaceHigh:      pick("surfaceHigh", "#242932")
    readonly property color surfaceHighest:   pick("surfaceHighest", "#2e333d")
    readonly property color onSurface:        pick("onSurface", "#e1e2ea")
    readonly property color onSurfaceVariant: pick("onSurfaceVariant", "#aab2c2")
    readonly property color outline:          pick("outline", "#727a8a")
    readonly property color outlineVariant:   pick("outlineVariant", "#3a404b")
    readonly property string wallpaper:       pick("wallpaper", "")

    // Panels are drawn near-black and slightly translucent so Hyprland's blur shows through.
    readonly property color panelBg:   alpha(surfaceLow, 0.93)
    readonly property color panelBorder: alpha(outlineVariant, 0.55)
    readonly property color pillBg:    alpha(surfaceHigh, 0.75)
    readonly property color pillHover: alpha(surfaceHighest, 0.95)

    readonly property string font:     "JetBrainsMono Nerd Font"
    readonly property string iconFont: "Material Symbols Rounded"
    readonly property int    radius:   18
    readonly property int    radiusSm: 10
    readonly property int    barHeight: 44
    readonly property int    fontSize: 13

    function alpha(col, a) { return Qt.rgba(col.r, col.g, col.b, a) }

    FileView {
        path: Quickshell.env("HOME") + "/.config/rrk-shell/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { try { root.c = JSON.parse(text()) } catch (e) { console.warn("colors.json parse error", e) } }
    }
}
