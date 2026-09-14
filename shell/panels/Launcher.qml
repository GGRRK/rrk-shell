import QtQuick
import Quickshell
import QtQuick.Controls
import qs.services
import qs.components

// App launcher: type to filter, Enter launches, arrows move. Also a ">" prefix runs a shell command.
// "Apps" / "All" buttons (or Tab) switch between the programs the user installed and every menu entry; opens on "Apps".
Popup {
    id: root
    name: "launcher"
    implicitWidth: 620; implicitHeight: 500
    property var results: Apps.search(input.text)
    // matches hidden by the "Apps" view, so the empty state can say "press Tab" instead of a dead end
    readonly property int hiddenMatches: Apps.mode === "apps" && input.text.trim() !== "" ? Apps.search(input.text, Apps.all).length : 0
    onShownChanged: if (shown) { Apps.mode = "apps"; Apps.refresh(); input.text = ""; input.forceActiveFocus(); list.currentIndex = 0 }

    function activate() {
        const q = input.text.trim()
        if (q.startsWith(">")) { Runner.run(q.slice(1).trim()); Panels.close(); return }
        const a = results[list.currentIndex]; if (a) { Apps.launch(a); Panels.close() }
    }
    function switchMode() { Apps.mode = Apps.mode === "apps" ? "all" : "apps"; list.currentIndex = 0 }

    Column {
        anchors { fill: parent; margins: 16 }
        spacing: 12
        Card {
            width: parent.width; height: 46
            Row { anchors { fill: parent; leftMargin: 14; rightMargin: 8 } spacing: 10
                Icon { name: "search"; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary }
                TextField {
                    id: input; width: parent.width - 30 - seg.width - 20; anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Search apps…  ( > to run a command )"; placeholderTextColor: Theme.outline
                    font.family: Theme.font; font.pixelSize: 14; color: Theme.onSurface
                    background: null
                    onTextChanged: list.currentIndex = 0
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.activate()
                    Keys.onEscapePressed: Panels.close()
                    Keys.onTabPressed: root.switchMode()
                }
                // ── Apps | All ──
                Rectangle {
                    id: seg
                    anchors.verticalCenter: parent.verticalCenter
                    width: segRow.implicitWidth + 6; height: 30; radius: 15
                    color: Theme.pillBg
                    Row {
                        id: segRow; anchors.centerIn: parent; spacing: 2
                        Repeater {
                            model: [ { k: "apps", t: "Apps" }, { k: "all", t: "All" } ]
                            Rectangle {
                                id: segItem
                                required property var modelData
                                readonly property bool on: Apps.mode === modelData.k
                                width: segLabel.implicitWidth + 22; height: 24; radius: 12
                                color: on ? Theme.primary : segMouse.containsMouse ? Theme.pillHover : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Label { id: segLabel; anchors.centerIn: parent; text: segItem.modelData.t; font.pixelSize: 11; font.bold: true
                                        color: segItem.on ? Theme.onPrimary : Theme.onSurfaceVariant }
                                MouseArea { id: segMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { Apps.mode = segItem.modelData.k; list.currentIndex = 0; input.forceActiveFocus() } }
                            }
                        }
                    }
                }
            }
        }
        ListView {
            id: list; width: parent.width; height: parent.height - 58; clip: true; spacing: 2
            model: root.results
            highlightMoveDuration: 80
            delegate: Rectangle {
                required property var modelData; required property int index
                width: ListView.view.width; height: 48; radius: Theme.radiusSm
                color: ListView.isCurrentItem ? Theme.alpha(Theme.primary, 0.18) : ma.containsMouse ? Theme.alpha(Theme.surfaceHighest, 0.5) : "transparent"
                Row { anchors { fill: parent; leftMargin: 10; rightMargin: 10 } spacing: 12
                    Image { width: 28; height: 28; anchors.verticalCenter: parent.verticalCenter; asynchronous: true; sourceSize: Qt.size(56, 56)
                            source: modelData.icon ? Quickshell.iconPath(modelData.icon, true) : "" }
                    Column { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 60
                        Label { text: modelData.name; font.bold: true; width: parent.width }
                        Label { text: modelData.comment || modelData.genericName || ""; font.pixelSize: 11; color: Theme.onSurfaceVariant; width: parent.width; visible: text !== "" } } }
                MouseArea { id: ma; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { list.currentIndex = index; root.activate() } }
            }
            Column {
                anchors.centerIn: parent; spacing: 6; visible: root.results.length === 0 && !input.text.startsWith(">")
                Label { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.outline
                        text: root.hiddenMatches > 0 ? "No match in your apps" : Apps.mode === "apps" && input.text.trim() === "" ? "No apps installed yet" : "No matches" }
                Label { anchors.horizontalCenter: parent.horizontalCenter; color: Theme.onSurfaceVariant; font.pixelSize: 11; visible: root.hiddenMatches > 0
                        text: root.hiddenMatches + (root.hiddenMatches === 1 ? " match" : " matches") + " under All  —  press Tab" }
            }
        }
    }
}
