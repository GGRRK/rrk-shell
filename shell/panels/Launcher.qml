import QtQuick
import QtQuick.Controls
import qs.services
import qs.components

// App launcher: type to filter, Enter launches, arrows move. Also a ">" prefix runs a shell command.
Popup {
    id: root
    name: "launcher"
    implicitWidth: 620; implicitHeight: 500
    property var results: Apps.search(input.text)
    onShownChanged: if (shown) { input.text = ""; input.forceActiveFocus(); list.currentIndex = 0 }

    function activate() {
        const q = input.text.trim()
        if (q.startsWith(">")) { Runner.run(q.slice(1).trim()); Panels.close(); return }
        const a = results[list.currentIndex]; if (a) { Apps.launch(a); Panels.close() }
    }

    Column {
        anchors { fill: parent; margins: 16 }
        spacing: 12
        Card {
            width: parent.width; height: 46
            Row { anchors { fill: parent; leftMargin: 14; rightMargin: 14 } spacing: 10
                Icon { name: "search"; anchors.verticalCenter: parent.verticalCenter; color: Theme.primary }
                TextField {
                    id: input; width: parent.width - 30; anchors.verticalCenter: parent.verticalCenter
                    placeholderText: "Search apps…  ( > to run a command )"; placeholderTextColor: Theme.outline
                    font.family: Theme.font; font.pixelSize: 14; color: Theme.onSurface
                    background: null
                    onTextChanged: list.currentIndex = 0
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onReturnPressed: root.activate()
                    Keys.onEscapePressed: Panels.close()
                } }
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
            Label { anchors.centerIn: parent; visible: root.results.length === 0 && !input.text.startsWith(">"); text: "No matches"; color: Theme.outline }
        }
    }
}
