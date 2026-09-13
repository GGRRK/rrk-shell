pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property date now: clock.date
    readonly property string time:    Qt.formatDateTime(clock.date, "hh:mm")
    readonly property string seconds: Qt.formatDateTime(clock.date, "ss")
    readonly property string time12:  Qt.formatDateTime(clock.date, "hh:mm:ss AP")
    readonly property string dateLong: Qt.formatDateTime(clock.date, "dddd, MMMM d")
    readonly property string weekday:  Qt.formatDateTime(clock.date, "dddd")
    SystemClock { id: clock; precision: SystemClock.Seconds }
}
