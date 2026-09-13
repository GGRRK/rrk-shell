pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    Process { id: p }
    function run(cmd) { p.command = ["sh", "-c", cmd]; p.running = true }
}
