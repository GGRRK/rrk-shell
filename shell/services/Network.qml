pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Thin wrapper around nmcli, polled every 10 s (and on demand).
Singleton {
    id: root
    property bool wifiEnabled: true
    property bool connected: false
    property string kind: ""          // "wifi" | "ethernet" | ""
    property string ssid: ""
    property int signal: 0
    property var networks: []         // [{ssid, signal, security, inUse}]
    readonly property string icon: !connected ? "signal_wifi_off" : kind === "ethernet" ? "lan"
        : signal > 75 ? "signal_wifi_4_bar" : signal > 50 ? "network_wifi_3_bar" : signal > 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
    readonly property string label: !connected ? "Offline" : (ssid || "Wired")

    Process {
        id: poll
        command: ["sh", "-c",
            "nmcli -t -f TYPE,STATE,CONNECTION dev; echo '---'; nmcli -t radio wifi; echo '---'; nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list"]
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { interval: 10000; running: true; repeat: true; triggeredOnStart: true; onTriggered: poll.running = true }

    function refresh() { poll.running = true }
    function parse(out) {
        const parts = out.split("---\n")
        let conn = false, kind = "", name = ""
        for (const line of (parts[0] || "").trim().split("\n")) {
            const f = line.split(":")
            if (f[1] === "connected" && (f[0] === "wifi" || f[0] === "ethernet")) {
                if (!conn || (f[0] === "ethernet" && kind !== "ethernet")) { conn = true; kind = f[0]; name = f.slice(2).join(":") }
            }
        }
        root.wifiEnabled = (parts[1] || "").trim() === "enabled"
        const nets = []; let sig = 0
        for (const line of (parts[2] || "").trim().split("\n")) {
            // nmcli escapes ':' inside fields as '\:' — swap for a placeholder before splitting
            const f = line.replace(/\\:/g, "§").split(":").map(s => s.replace(/§/g, ":"))
            if (f.length < 4 || !f[1]) continue
            const n = { inUse: f[0] === "*", ssid: f[1], signal: parseInt(f[2]) || 0, security: f[3] }
            if (n.inUse) { sig = n.signal; if (kind === "wifi") name = n.ssid }
            if (!nets.find(x => x.ssid === n.ssid)) nets.push(n)
        }
        nets.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
        root.connected = conn; root.kind = kind; root.ssid = name; root.signal = sig; root.networks = nets
    }

    Process { id: act; onExited: root.refresh() }
    function toggleWifi() { act.command = ["nmcli", "radio", "wifi", wifiEnabled ? "off" : "on"]; act.running = true }
    function connect(ssid) { act.command = ["nmcli", "dev", "wifi", "connect", ssid]; act.running = true }
    function rescan() { act.command = ["nmcli", "dev", "wifi", "rescan"]; act.running = true }
}
