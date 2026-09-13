pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property var all: DesktopEntries.applications.values.filter(a => !a.noDisplay).sort((a, b) => a.name.localeCompare(b.name))
    function search(q) {
        q = q.trim().toLowerCase()
        if (!q) return all
        const starts = [], contains = []
        for (const a of all) {
            const n = a.name.toLowerCase()
            if (n.startsWith(q)) starts.push(a)
            else if (n.includes(q) || (a.comment || "").toLowerCase().includes(q) || (a.genericName || "").toLowerCase().includes(q)) contains.push(a)
        }
        return starts.concat(contains)
    }
    function launch(a) { a.execute() }
}
