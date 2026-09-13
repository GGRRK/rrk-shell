pragma Singleton
import Quickshell
import QtQuick

// Which popup panel is open ("" = none). Only one at a time.
Singleton {
    id: root
    property string open: ""
    function toggle(name) { open = (open === name) ? "" : name }
    function show(name) { open = name }
    function close() { open = "" }
}
