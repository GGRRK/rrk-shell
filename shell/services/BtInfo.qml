pragma Singleton
import Quickshell
import Quickshell.Bluetooth as QsBt
import Quickshell.Services.Pipewire
import QtQuick

// Helpers for the Bluetooth panel: sorted device list, per-device text + icons,
// the codec/profile of the connected audio device (read from its PipeWire sink node),
// and the settings-gear launcher. `Bluetooth` here is the rrk-shell service next door;
// the Quickshell module is namespaced as QsBt so the two names never clash.
Singleton {
    id: root

    // ---- devices, sorted connected → paired → the rest (unnamed "XX-XX-…" junk hidden), A→Z inside a group
    readonly property var sorted: Bluetooth.devices
        .filter(d => d.name && (d.paired || d.connected || !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.name)))
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    // everything except the device shown in the centre of the radial
    readonly property var others: sorted.filter(d => d !== Bluetooth.primary)

    function busy(d) {
        return !!d && (d.pairing || d.state === QsBt.BluetoothDeviceState.Connecting || d.state === QsBt.BluetoothDeviceState.Disconnecting)
    }
    function stateText(d) {
        if (!d) return ""
        if (d.pairing) return "Pairing…"
        if (d.state === QsBt.BluetoothDeviceState.Connecting) return "Connecting…"
        if (d.state === QsBt.BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (d.connected) return "Connected"
        return d.paired ? "Connect" : "Pair"
    }
    // click action for a device chip / list row
    function act(d) {
        if (!d || busy(d)) return
        if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else d.pair()
    }

    // BlueZ Device1.Icon → [Material Symbols glyph, human label]
    readonly property var kinds: ({
        "audio-headphones": ["headphones", "Headphones"], "audio-headset": ["headset_mic", "Headset"],
        "audio-card": ["speaker", "Speaker"],             "multimedia-player": ["music_note", "Media player"],
        "phone": ["mobile", "Phone"],                     "computer": ["computer", "Computer"],
        "video-display": ["tv", "Display"],               "input-keyboard": ["keyboard", "Keyboard"],
        "input-mouse": ["mouse", "Mouse"],                "input-gaming": ["sports_esports", "Controller"],
        "input-tablet": ["tablet", "Tablet"],             "input-hid": ["devices", "Input device"],
        "input-hog": ["devices", "Input device"],         "camera-video": ["videocam", "Camera"],
        "camera-photo": ["photo_camera", "Camera"],       "printer": ["print", "Printer"],
        "scanner": ["scanner", "Scanner"],                "modem": ["router", "Modem"]
    })
    function kind(d) {
        const k = d ? kinds[d.icon] : null
        if (k) return k
        if (d && d.icon && d.icon.startsWith("network")) return ["router", "Network"]
        return ["bluetooth", "Device"]
    }
    function icon(d)      { return kind(d)[0] }
    function typeLabel(d) { return kind(d)[1] }
    // true for devices that can carry audio (so the "Audio profile" chip makes sense)
    function isAudio(d) {
        return !!d && ((d === Bluetooth.primary && node !== null) || (!!d.icon && (d.icon.startsWith("audio-") || d.icon.startsWith("multimedia"))))
    }
    function batteryIcon(v) {
        return v >= 0.95 ? "battery_full" : v >= 0.8 ? "battery_6_bar" : v >= 0.65 ? "battery_5_bar" : v >= 0.5 ? "battery_4_bar"
             : v >= 0.35 ? "battery_3_bar" : v >= 0.2 ? "battery_2_bar" : v >= 0.1 ? "battery_1_bar" : "battery_alert"
    }

    // ---- codec / profile of the connected device. WirePlumber names the sink node
    //      "bluez_output.<MAC with ':' → '_'>.<n>"; its properties carry api.bluez5.codec / api.bluez5.profile,
    //      which PipeWire only fills in while the node is bound (PwObjectTracker).
    readonly property string prefix: Bluetooth.primary ? "bluez_output." + Bluetooth.primary.address.replace(/:/g, "_") + "." : ""
    readonly property var node: prefix ? (Pipewire.nodes.values.find(n => n.isSink && !n.isStream && n.name.startsWith(prefix)) || null) : null
    PwObjectTracker { objects: root.node ? [root.node] : [] }
    readonly property var props: (node && node.properties) ? node.properties : ({})
    readonly property string codec: String(props["api.bluez5.codec"] || "")
    readonly property string profile: String(props["api.bluez5.profile"] || "")
    readonly property var codecNames: ({
        sbc: "SBC", sbc_xq: "SBC-XQ", aac: "AAC", aac_eld: "AAC-ELD", ldac: "LDAC",
        aptx: "aptX", aptx_hd: "aptX HD", aptx_ll: "aptX LL", aptx_ll_duplex: "aptX LL",
        faststream: "FastStream", faststream_duplex: "FastStream", lc3: "LC3", lc3_swb: "LC3-SWB",
        msbc: "mSBC", cvsd: "CVSD", opus_05: "Opus", opus_g: "Opus"
    })
    readonly property string codecLabel: codec ? (codecNames[codec.toLowerCase()] || codec.toUpperCase().replace(/_/g, "-")) : ""
    readonly property string profileLabel: profile.startsWith("a2dp") ? "A2DP"
        : (profile.startsWith("headset") || profile.startsWith("hfp") || profile.startsWith("hsp")) ? "HFP"
        : profile.startsWith("bap") ? "LE Audio" : profile
    // title of the "Audio profile" chip: "LDAC · A2DP" when PipeWire knows, else the device type ("Headphones")
    readonly property string audioLabel: codecLabel ? codecLabel + (profileLabel ? " · " + profileLabel : "")
                                       : (profileLabel || typeLabel(Bluetooth.primary))

    // settings gear: blueman-manager if installed, otherwise bluetoothctl in a floating kitty (see hypr/config/rules.lua).
    // Detached on purpose: Runner's single Process would stay busy for as long as the window is open.
    function openManager() {
        Quickshell.execDetached(["sh", "-c", "command -v blueman-manager >/dev/null 2>&1 && exec blueman-manager; exec kitty --class rrk-btctl -T bluetoothctl bluetoothctl"])
    }
}
