pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

Singleton {
    id: root
    property bool dnd: false
    property var popups: []          // notifications still showing as toasts
    readonly property var list: server.trackedNotifications.values
    readonly property int count: list.length

    NotificationServer {
        id: server
        keepOnReload: true
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        persistenceSupported: true
        onNotification: n => {
            n.tracked = true
            if (!root.dnd) root.popups = [n, ...root.popups].slice(0, 5)
            n.closed.connect(() => root.popups = root.popups.filter(p => p !== n))
        }
    }

    function hidePopup(n) { popups = popups.filter(p => p !== n) }
    function dismiss(n)   { n.dismiss() }
    function clearAll()   { for (const n of [...list]) n.dismiss() }
    function timeText(n)  { return Qt.formatDateTime(new Date(), "hh:mm") }
}
