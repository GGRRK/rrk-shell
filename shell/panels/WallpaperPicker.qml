import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

// Wallpaper carousel: colour-filter dots, search, skewed cards. Drag or mouse-wheel to scroll, click a card to apply.
Popup {
    id: root
    name: "wallpapers"
    implicitWidth: 1500; implicitHeight: 392
    property int hueFilter: -1           // -1 = all
    property string query: ""
    readonly property var hues: [ { c: "#ff3b30", lo: 345, hi: 15 }, { c: "#ff9500", lo: 15, hi: 45 }, { c: "#ffd60a", lo: 45, hi: 70 }, { c: "#34c759", lo: 70, hi: 170 },
                                  { c: "#0a84ff", lo: 170, hi: 260 }, { c: "#8e44ff", lo: 260, hi: 300 }, { c: "#ff2d92", lo: 300, hi: 345 } ]
    readonly property var items: Wallpapers.list.filter(w => {
        if (query && !w.name.toLowerCase().includes(query.toLowerCase())) return false
        if (hueFilter < 0) return true
        const h = hues[hueFilter]; return h.lo < h.hi ? (w.hue >= h.lo && w.hue < h.hi) : (w.hue >= h.lo || w.hue < h.hi)
    })
    onShownChanged: if (shown) { Wallpapers.refresh(); search.forceActiveFocus() }

    Column {
        anchors { fill: parent; margins: 16 }
        spacing: 14
        // ── control bar ──
        Card {
            anchors.horizontalCenter: parent.horizontalCenter; width: bar.implicitWidth + 28; height: 46
            Row { id: bar; anchors.centerIn: parent; spacing: 10
                Pill { padding: 10; onClicked: Wallpapers.random()
                       Icon { name: "shuffle"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                       Label { text: "Shuffle"; anchors.verticalCenter: parent.verticalCenter } }
                Pill { padding: 10; active: Rotator.enabled; onClicked: Rotator.enabled = !Rotator.enabled
                       Icon { name: "autoplay"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface }
                       Label { text: Rotator.enabled ? "Auto " + Rotator.minutes + "m" : "Auto"; anchors.verticalCenter: parent.verticalCenter; color: parent.active ? Theme.onPrimary : Theme.onSurface } }
                Rectangle { width: 1; height: 24; color: Theme.outlineVariant; anchors.verticalCenter: parent.verticalCenter }
                Repeater { model: root.hues
                    Rectangle { required property var modelData; required property int index
                        width: 22; height: 22; radius: 6; color: modelData.c; anchors.verticalCenter: parent.verticalCenter
                        border.width: root.hueFilter === index ? 2 : 0; border.color: "white"; scale: hm.containsMouse ? 1.15 : 1
                        MouseArea { id: hm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.hueFilter = root.hueFilter === index ? -1 : index } } }
                Rectangle { width: 22; height: 22; radius: 6; color: "#9a9a9a"; anchors.verticalCenter: parent.verticalCenter; border.width: root.hueFilter < 0 ? 2 : 0; border.color: "white"
                            Icon { anchors.centerIn: parent; name: "apps"; font.pixelSize: 14; color: "#222" }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.hueFilter = -1 } }
                Rectangle { width: 1; height: 24; color: Theme.outlineVariant; anchors.verticalCenter: parent.verticalCenter }
                Rectangle { width: 260; height: 30; radius: 15; color: Theme.pillBg; anchors.verticalCenter: parent.verticalCenter
                    Row { anchors { fill: parent; leftMargin: 10 } spacing: 6
                        Icon { name: "search"; font.pixelSize: 16; anchors.verticalCenter: parent.verticalCenter }
                        TextField { id: search; width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; background: null
                                    placeholderText: "search wallpapers"; placeholderTextColor: Theme.outline; font.family: Theme.font; font.pixelSize: 12; color: Theme.onSurface
                                    onTextChanged: root.query = text; Keys.onEscapePressed: Panels.close()
                                    Keys.onReturnPressed: if (root.items.length) Wallpapers.set(root.items[0].path) } } }
                Label { text: root.items.length + " / " + Wallpapers.list.length; color: Theme.onSurfaceVariant; anchors.verticalCenter: parent.verticalCenter }
            }
        }
        // ── carousel ──
        ListView {
            id: strip
            width: parent.width; height: 300; orientation: ListView.Horizontal; spacing: -30; clip: true
            model: root.items
            leftMargin: 40; rightMargin: 40
            flickDeceleration: 4000; maximumFlickVelocity: 6000
            // Mouse wheel / two-finger vertical scroll moves the strip sideways: a horizontal Flickable only
            // reacts to horizontal wheel deltas, so a plain mouse wheel did nothing here. One notch = half a card.
            WheelHandler {
                orientation: Qt.Vertical
                target: null
                onWheel: ev => {
                    const min = strip.originX - strip.leftMargin
                    const max = Math.max(min, strip.originX + strip.contentWidth + strip.rightMargin - strip.width)
                    strip.contentX = Math.max(min, Math.min(max, strip.contentX - ev.angleDelta.y * 1.125))
                }
            }
            delegate: Item {
                required property var modelData
                width: 300; height: 300
                readonly property bool current: modelData.path === Wallpapers.current
                Rectangle {
                    id: card
                    anchors.centerIn: parent; width: 260; height: 280; radius: 4; clip: true
                    color: modelData.color
                    border.width: current ? 3 : (cm.containsMouse ? 2 : 0); border.color: current ? Theme.primary : Theme.onSurface
                    transform: Matrix4x4 { matrix: Qt.matrix4x4(1, -0.22, 0, 30,  0, 1, 0, 0,  0, 0, 1, 0,  0, 0, 0, 1) }
                    scale: cm.containsMouse ? 1.05 : 1
                    Behavior on scale { NumberAnimation { duration: 150 } }
                    Image { anchors.fill: parent; source: "file://" + (modelData.poster || modelData.path); fillMode: Image.PreserveAspectCrop; asynchronous: true; sourceSize: Qt.size(400, 400); cache: true }
                    // live (video) wallpaper badge
                    Rectangle { visible: !!modelData.poster; anchors { top: parent.top; right: parent.right; margins: 10 } width: 28; height: 28; radius: 14; color: "#99000000"
                                Icon { anchors.centerIn: parent; name: "play_arrow"; fill: true; font.pixelSize: 18; color: "white" } }
                    Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 44; gradient: Gradient { GradientStop { position: 0; color: "transparent" } GradientStop { position: 1; color: "#cc000000" } } }
                    Label { anchors { left: parent.left; leftMargin: 40; bottom: parent.bottom; bottomMargin: 10 } text: modelData.name; font.pixelSize: 11; color: "white"; width: parent.width - 60 }
                    MouseArea { id: cm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Wallpapers.set(modelData.path) }
                }
            }
            Label { anchors.centerIn: parent; visible: root.items.length === 0; color: Theme.outline
                    text: Wallpapers.list.length === 0 ? "No images in " + Wallpapers.dir : "No matches" }
        }
    }
}
