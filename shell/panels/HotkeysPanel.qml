import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components

// Keyboard cheat sheet (SUPER+K): every Hyprland keybind, grouped by the sections of hypr/config/keybinds.lua
// (see services/Hotkeys.qml for how the file is read). Sections are dealt into three columns of roughly equal height,
// in file order, once from the full list — while typing in the search box cards only hide, never change column.
// The panel hangs from the top edge (Overlay.qml) so the search box stays put while the bottom edge moves; empty
// columns disappear and the remaining ones are centred. Taller than the screen → the columns scroll (mouse wheel).
// Esc / click outside / SUPER+K again closes.
Popup {
    id: root
    name: "hotkeys"
    implicitWidth: 1300; implicitHeight: col.implicitHeight + 40
    readonly property string query: input.text.trim().toLowerCase()
    readonly property var columns: root.split(Hotkeys.sections)
    readonly property int matchCount: query === "" ? Hotkeys.rowCount
                                     : Hotkeys.sections.reduce((n, s) => n + s.rows.filter(r => r.search.includes(root.query)).length, 0)
    readonly property int colWidth: Math.floor((implicitWidth - 40 - 2 * 16) / 3)
    // room on screen below the bar: the sheet never grows past it, the column block scrolls instead
    readonly property int maxHeight: (parent ? parent.height : 1080) - (Theme.barHeight + 8) - 16
    onShownChanged: if (shown) { input.text = ""; flick.contentY = 0; input.forceActiveFocus() }

    function matches(s) { return root.query === "" || s.rows.some(r => r.search.includes(root.query)) }
    // cut the ordered section list into 3 columns whose heights are as equal as possible (a title counts ~1.6 rows)
    function split(list) {
        const cols = [[], [], []]
        if (list.length <= 3) { list.forEach((s, i) => cols[i].push(s)); return cols }
        const pre = [0]
        list.forEach(s => pre.push(pre[pre.length - 1] + s.rows.length + 1.6))
        let best = null
        for (let i = 1; i < list.length - 1; i++)
            for (let j = i + 1; j < list.length; j++) {
                const h = Math.max(pre[i], pre[j] - pre[i], pre[list.length] - pre[j])
                if (!best || h < best.h) best = { h: h, i: i, j: j }
            }
        cols[0] = list.slice(0, best.i); cols[1] = list.slice(best.i, best.j); cols[2] = list.slice(best.j)
        return cols
    }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: 20 }
        spacing: 16

        // ── title + search ──
        RowLayout {
            id: header
            Layout.fillWidth: true; spacing: 14
            Icon { name: "keyboard"; font.pixelSize: 26; color: Theme.primary }
            Column {
                spacing: 2
                Label { text: "Keyboard shortcuts"; font.pixelSize: 18; font.bold: true }
                Label { font.pixelSize: 11; color: Theme.onSurfaceVariant
                        text: root.query === "" ? Hotkeys.rowCount + " shortcuts  ·  Super is the Windows key"
                                                : root.matchCount + " of " + Hotkeys.rowCount + " shortcuts match" }
            }
            Item { Layout.fillWidth: true }
            Card {
                Layout.preferredWidth: 320; Layout.preferredHeight: 42
                RowLayout {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 12 }
                    spacing: 10
                    Icon { name: "search"; font.pixelSize: 17; color: Theme.primary }
                    TextField {
                        id: input; Layout.fillWidth: true
                        placeholderText: "Search shortcuts…"; placeholderTextColor: Theme.outline
                        font.family: Theme.font; font.pixelSize: 14; color: Theme.onSurface
                        background: null
                        Keys.onEscapePressed: Panels.close()
                    }
                }
            }
        }

        // ── three columns of section cards (scroll when taller than the screen) ──
        // Hidden entirely when nothing matches: a Qt 6.11 RowLayout whose children are all invisible keeps its old
        // implicitHeight, which would leave a blank block the size of the full sheet.
        Flickable {
            id: flick
            visible: root.matchCount > 0
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(cols.implicitHeight, root.maxHeight - 40 - header.implicitHeight - footer.implicitHeight - 2 * col.spacing)
            contentWidth: width; contentHeight: cols.implicitHeight
            clip: true; boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: flick.contentHeight > flick.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff }
            RowLayout {
                id: cols
                x: Math.max(0, (flick.width - width) / 2); width: implicitWidth
                spacing: 16
                Repeater {
                    model: root.columns
                    ColumnLayout {
                        id: column
                        required property var modelData
                        visible: modelData.some(s => root.matches(s))
                        Layout.preferredWidth: root.colWidth; Layout.minimumWidth: root.colWidth; Layout.maximumWidth: root.colWidth
                        Layout.alignment: Qt.AlignTop
                        spacing: 16
                        Repeater {
                            model: column.modelData
                            Card {
                                id: card
                                required property var modelData
                                readonly property var rows: root.query === "" ? modelData.rows : modelData.rows.filter(r => r.search.includes(root.query))
                                readonly property bool hasLocked: rows.some(r => r.locked)
                                visible: rows.length > 0
                                Layout.fillWidth: true
                                implicitHeight: body.implicitHeight + 26
                                Column {
                                    id: body
                                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13; leftMargin: 16; rightMargin: 16 }
                                    spacing: 1
                                    Label { text: card.modelData.title.toUpperCase(); font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5; color: Theme.primary; bottomPadding: 7 }
                                    Repeater {
                                        model: card.rows
                                        // description left, keycaps right; a very wide key combination moves under the description instead
                                        Item {
                                            id: row
                                            required property var modelData
                                            readonly property bool twoLine: keys.implicitWidth > width * 0.62
                                            width: parent.width
                                            height: twoLine ? desc.height + keys.height + 8 : Math.max(27, desc.height + 8)
                                            Label {
                                                id: desc
                                                text: row.modelData.desc; font.pixelSize: 12
                                                wrapMode: Text.Wrap; maximumLineCount: 2     // a long description wraps once, then elides
                                                x: 0; width: row.twoLine ? row.width : row.width - keys.width - 14
                                                y: row.twoLine ? 2 : (row.height - height) / 2
                                            }
                                            Row {
                                                id: keys
                                                anchors.right: parent.right
                                                y: row.twoLine ? desc.height + 4 : (row.height - height) / 2
                                                spacing: 4
                                                Icon { visible: row.modelData.locked; name: "lock"; font.pixelSize: 12; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter; rightPadding: 3 }
                                                Repeater {
                                                    model: row.modelData.tokens
                                                    // one keycap (face + a darker 2 px "edge" under it) or a "+" / "/" / "or" separator
                                                    Item {
                                                        id: tok
                                                        required property var modelData
                                                        readonly property bool cap: modelData.t === "cap"
                                                        anchors.verticalCenter: parent.verticalCenter
                                                        width: cap ? Math.max(24, capText.implicitWidth + 14) : capText.implicitWidth + 4
                                                        height: 24
                                                        Rectangle { visible: tok.cap; x: 0; y: 2; width: parent.width; height: 20; radius: 6; color: Theme.alpha(Theme.outline, 0.45) }
                                                        Rectangle {
                                                            visible: tok.cap; width: parent.width; height: 20; radius: 6
                                                            color: Theme.alpha(Theme.surfaceHighest, 0.97)
                                                            border.width: 1; border.color: Theme.alpha(Theme.outline, 0.35)
                                                        }
                                                        Label {
                                                            id: capText; anchors.centerIn: parent; anchors.verticalCenterOffset: tok.cap ? -1 : 0
                                                            text: tok.cap ? tok.modelData.v : tok.modelData.t === "plus" ? "+" : tok.modelData.t === "alt" ? "/" : "or"
                                                            font.pixelSize: tok.cap ? 11 : 10; font.bold: tok.cap
                                                            color: tok.cap ? Theme.onSurface : Theme.outline
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    // legend right where the icons are, only in a section that has them
                                    Row {
                                        visible: card.hasLocked; spacing: 4; topPadding: 6
                                        Icon { name: "lock"; font.pixelSize: 11; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter }
                                        Label { text: "also works on the lock screen"; font.pixelSize: 10; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        Label { visible: root.matchCount === 0; Layout.alignment: Qt.AlignHCenter; Layout.topMargin: 20; Layout.bottomMargin: 20; color: Theme.outline
                text: Hotkeys.rowCount === 0 ? "No keybinds found in hypr/config/keybinds.lua" : "Nothing matches “" + input.text.trim() + "”" }

        // ── footer ──
        Label { id: footer; Layout.fillWidth: true; font.pixelSize: 11; color: Theme.outline
                text: "Esc closes  ·  the shortcuts live in  ~/claude/rrk-shell/hypr/config/keybinds.lua  — change them there and this list updates by itself" }
    }
}
