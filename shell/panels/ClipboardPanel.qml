import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.services
import qs.components

// Clipboard history (cliphist): search on top, newest-first list with a type badge / colour swatch / image thumbnail.
// Enter or click copies the highlighted entry and closes; ↑ ↓ move; each row has a ✕ that deletes it;
// Shift+Delete deletes the highlighted row; the bin button clears everything after an inline confirmation.
Popup {
    id: root
    name: "clipboard"
    implicitWidth: 640; implicitHeight: 600
    property bool confirmWipe: false
    property int keepIndex: 0                       // row to re-highlight after a delete
    readonly property string query: input.text.trim().toLowerCase()
    // depends on entries + query only (never on Clipboard.texts, which changes after every lazy decode and would rebuild the list)
    readonly property var results: query === "" ? Clipboard.entries : Clipboard.entries.filter(e => root.matches(e, query))
    onShownChanged: {
        if (shown) { Clipboard.refresh(); input.text = ""; confirmWipe = false; keepIndex = 0; list.currentIndex = 0; input.forceActiveFocus() }
        else Clipboard.cancelAll()
    }

    function matches(e, q) { return (e.preview + " " + e.kind + " " + (e.format || "")).toLowerCase().includes(q) }
    function activate() {
        const e = results[list.currentIndex]
        if (e) { Clipboard.copy(e.id, e.kind === "image" ? "image/" + e.format : ""); Panels.close() }
    }
    function removeAt(i) { const e = results[i]; if (e) { keepIndex = i; Clipboard.remove(e.id) } }
    Connections {
        target: Clipboard
        function onEntriesChanged() { Qt.callLater(() => { list.currentIndex = Math.max(0, Math.min(root.keepIndex, root.results.length - 1)); root.keepIndex = 0 }) }
    }

    ColumnLayout {
        anchors { fill: parent; margins: 16 }
        spacing: 12

        // ── search bar ──
        Card {
            Layout.fillWidth: true; Layout.preferredHeight: 46
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                spacing: 10
                Icon { name: "search"; color: Theme.primary }
                TextField {
                    id: input; Layout.fillWidth: true
                    placeholderText: "Search clipboard…"; placeholderTextColor: Theme.outline
                    font.family: Theme.font; font.pixelSize: 14; color: Theme.onSurface
                    background: null
                    onTextChanged: list.currentIndex = 0
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.activate()
                    Keys.onEnterPressed: root.activate()
                    Keys.onEscapePressed: { if (root.confirmWipe) root.confirmWipe = false; else Panels.close() }
                    // key-specific handlers (up/down/return/escape) run first and swallow their keys; everything else lands here.
                    // Do not add Keys.onDeletePressed — it would take Delete away from this handler.
                    Keys.onPressed: e => { if (e.key === Qt.Key_Delete && (e.modifiers & Qt.ShiftModifier)) { root.removeAt(list.currentIndex); e.accepted = true } }
                }
                Label { text: root.results.length + " / " + Clipboard.entries.length; font.pixelSize: 11; color: Theme.onSurfaceVariant }
                IconButton { icon: "delete_sweep"; size: 30; iconSize: 17; active: root.confirmWipe; activeColor: Theme.error
                             visible: Clipboard.entries.length > 0; onClicked: root.confirmWipe = !root.confirmWipe }
            }
        }

        // ── clear-all confirmation ──
        Card {
            Layout.fillWidth: true; Layout.preferredHeight: 40; visible: root.confirmWipe
            RowLayout {
                anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                spacing: 10
                Icon { name: "delete_sweep"; font.pixelSize: 18; color: Theme.error }
                Label { text: "Delete all " + Clipboard.entries.length + " entries from the clipboard history?"; Layout.fillWidth: true }
                Pill { padding: 12; implicitHeight: 26; onClicked: root.confirmWipe = false
                       Label { text: "Cancel"; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter } }
                Pill { padding: 12; implicitHeight: 26; color: hovered ? Qt.lighter(Theme.error, 1.15) : Theme.error
                       onClicked: { root.confirmWipe = false; Clipboard.wipe() }
                       Label { text: "Delete all"; font.pixelSize: 11; font.bold: true; color: Theme.onPrimary; anchors.verticalCenter: parent.verticalCenter } }
            }
        }

        // ── entries ──
        ListView {
            id: list
            Layout.fillWidth: true; Layout.fillHeight: true; clip: true; spacing: 6
            model: root.results
            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                readonly property bool isImage: modelData.kind === "image"
                readonly property string kind: modelData.kind
                // real first lines once decoded; the collapsed preview until then (or if the decode failed / came back empty)
                readonly property string body: { const t = Clipboard.texts[modelData.id]; return (t === undefined || t === null || t === "") ? modelData.preview : t }
                width: ListView.view.width
                height: Math.max(inner.implicitHeight, 40) + 20
                radius: Theme.radiusSm + 4
                color: current ? Theme.alpha(Theme.primary, 0.18) : ma.containsMouse ? Theme.alpha(Theme.surfaceHighest, 0.5) : Theme.alpha(Theme.surfaceContainer, 0.7)
                border.width: 1
                border.color: current ? Theme.alpha(Theme.primary, 0.6) : Theme.alpha(Theme.outlineVariant, 0.35)
                Behavior on color { ColorAnimation { duration: 120 } }
                Component.onCompleted: if (!isImage) Clipboard.fetchText(modelData.id)
                Component.onDestruction: if (Clipboard) Clipboard.cancel(modelData.id)   // row gone (filter / refresh): drop its pending decode

                Row {
                    id: inner
                    anchors { left: parent.left; leftMargin: 12; right: parent.right; rightMargin: 46; verticalCenter: parent.verticalCenter }
                    spacing: 12
                    // leading tile: thumbnail / colour swatch / type icon
                    Rectangle {
                        id: lead
                        anchors.verticalCenter: parent.verticalCenter
                        width: row.isImage ? 88 : 40; height: row.isImage ? 60 : 40
                        radius: Theme.radiusSm
                        color: row.kind === "color" ? row.modelData.preview : Theme.pillBg
                        border.width: row.kind === "color" ? 1 : 0; border.color: Theme.alpha(Theme.outline, 0.6)
                        Image { id: thumb; anchors.fill: parent; anchors.margins: 3; visible: row.isImage; source: row.isImage ? "file://" + row.modelData.file : ""
                                fillMode: Image.PreserveAspectFit; asynchronous: true; sourceSize: Qt.size(176, 120); cache: true }
                        Icon { anchors.centerIn: parent; visible: row.kind !== "color" && (!row.isImage || thumb.status !== Image.Ready); font.pixelSize: 20; color: Theme.primary
                               name: row.isImage ? "image" : row.kind === "url" ? "link" : row.kind === "path" ? "folder" : "notes" }
                    }
                    Column {
                        width: parent.width - lead.width - 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Label { visible: !row.isImage; text: row.body; width: parent.width; wrapMode: Text.Wrap; maximumLineCount: 3; font.pixelSize: 12 }
                        Label { visible: row.isImage; text: "Image"; font.bold: true; width: parent.width }
                        Row {
                            spacing: 8
                            Rectangle {
                                height: 18; width: badge.implicitWidth + 14; radius: 9; color: Theme.alpha(Theme.primary, 0.15)
                                Label { id: badge; anchors.centerIn: parent; font.pixelSize: 9; font.bold: true; font.letterSpacing: 1; color: Theme.primary
                                        text: row.isImage ? row.modelData.format.toUpperCase() : row.kind === "color" ? row.modelData.preview.toUpperCase() : row.kind.toUpperCase() }
                            }
                            Label { visible: row.isImage; text: row.modelData.w + " × " + row.modelData.h + " · " + row.modelData.size; font.pixelSize: 10; color: Theme.outline; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }
                }
                // delete button: always visible (dim), brighter while the pointer is over the row, red while over the button itself.
                // Drawn only — the row's single MouseArea decides whether a click hit it (no nested MouseAreas).
                Rectangle {
                    id: del
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    width: 28; height: 28; radius: Theme.radiusSm
                    readonly property bool hot: ma.containsMouse && del.contains(del.mapFromItem(ma, ma.mouseX, ma.mouseY))
                    opacity: ma.containsMouse ? 1 : 0.45
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                    color: hot ? Theme.error : Theme.pillBg
                    Icon { anchors.centerIn: parent; name: "close"; font.pixelSize: 15; color: del.hot ? Theme.onPrimary : Theme.onSurfaceVariant }
                }
                MouseArea {
                    id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: m => {
                        if (del.contains(del.mapFromItem(ma, m.x, m.y))) root.removeAt(row.index)
                        else { list.currentIndex = row.index; root.activate() }
                    }
                }
            }
            Label {
                anchors.centerIn: parent; color: Theme.outline; visible: root.results.length === 0
                text: Clipboard.loading && Clipboard.entries.length === 0 ? "Loading…" : Clipboard.entries.length === 0 ? "Clipboard history is empty" : "No matches"
            }
        }
    }
}
