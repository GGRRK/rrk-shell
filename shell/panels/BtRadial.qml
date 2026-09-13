import QtQuick
import qs.services
import qs.components

// Radial Bluetooth view (900×700): eccentric backdrop discs, the connected device in a big circle,
// satellite chips on an ellipse around it, thin zig-zag links centre → chip on the info page.
//   page "info"    — chips about the connected device: Scan / Battery / Audio profile / Disconnect / MAC
//   page "devices" — Scan chip, "Current device" chip (when one is connected), nearby / paired devices
Item {
    id: radial
    property string page: "devices"
    signal openList()

    readonly property real cx: 450
    readonly property real cy: 308
    readonly property int  rCentre: 100        // centre circle radius (Ø200)
    readonly property int  rHalo: 130          // halo ring outer radius (Ø260)
    readonly property real rx: 300             // chip orbit — ellipse through the chip centres
    readonly property real ry: 220
    readonly property int  chipW: 168
    readonly property int  chipH: 60
    readonly property int  maxSlots: 6
    readonly property var  dev: Bluetooth.primary
    readonly property bool lit: Bluetooth.enabled && dev !== null
    readonly property bool hasBattery: lit && dev.batteryAvailable

    // ---- slot model ----------------------------------------------------------------------------
    // The chips are a fixed pool of `maxSlots` BtChip items (never re-created); chip i shows slots[i].
    // Rebuilds are debounced: 200 ms for open / page / adapter / primary changes (chips fly in again,
    // `epoch` tells them), 600 ms for device-list churn while scanning (existing chips just slide).
    property var  slots: []
    property var  order: []            // device addresses in first-seen order, so slots never shuffle mid-scan
    property int  epoch: 0
    property bool flyNext: false
    property bool linksOn: false

    function computeSlots() {
        if (!Bluetooth.enabled) return []
        let s = []
        if (page === "info" && dev) {
            s.push({ kind: "scan" })
            if (dev.batteryAvailable) s.push({ kind: "battery" })
            s.push({ kind: "profile" }, { kind: "disconnect" }, { kind: "mac" })
        } else {
            s.push({ kind: "scan" })
            if (dev) s.push({ kind: "back" })
            const others = BtInfo.others
            others.forEach(d => { if (order.indexOf(d.address) < 0) order.push(d.address) })
            const list = others.slice().sort((a, b) => order.indexOf(a.address) - order.indexOf(b.address))
            const room = maxSlots - s.length
            if (list.length <= room) list.forEach(d => s.push({ kind: "dev", dev: d }))
            else {
                list.slice(0, room - 1).forEach(d => s.push({ kind: "dev", dev: d }))
                s.push({ kind: "more", count: list.length - (room - 1) })
            }
        }
        const n = s.length
        for (let i = 0; i < n; i++) {
            const a = (-90 + i * 360 / n) * Math.PI / 180       // first slot straight up, then clockwise
            s[i].tx = cx + rx * Math.cos(a)
            s[i].ty = cy + ry * Math.sin(a)
        }
        return s
    }
    // called by the panel when it opens: drop last time's chips at once, rebuild (and fly in) after the debounce
    function reset() { slots = []; order = []; linksOn = false; flyNext = true; page = dev ? "info" : "devices"; relayout.restart() }
    function apply() {
        relayout.stop(); devRelayout.stop()
        if (!radial.visible) return                      // hidden (popup closed / list mode): reset()/visible handle it later
        if (flyNext) { flyNext = false; epoch++ }        // before `slots`, so chips take the new targets as fly-in starts
        slots = computeSlots()
        linksOn = false; linkShow.restart()
    }
    Timer { id: relayout;    interval: 200; onTriggered: radial.apply() }
    Timer { id: devRelayout; interval: 600; onTriggered: radial.apply() }
    Timer { id: linkShow;    interval: 380; onTriggered: radial.linksOn = true }
    onPageChanged: { flyNext = true; relayout.restart() }
    onVisibleChanged: if (visible) { flyNext = true; relayout.restart() }
    onSlotsChanged: links.requestPaint()
    // identity of the device set (names arrive after the device object, so devicesChanged alone is not enough)
    readonly property string slotKey: BtInfo.others.map(d => d.address).join(",")
    onSlotKeyChanged: devRelayout.restart()
    Connections {
        target: Bluetooth
        enabled: radial.visible
        function onEnabledChanged() { radial.flyNext = true; relayout.restart() }
        function onPrimaryChanged() { radial.flyNext = true; radial.page = Bluetooth.primary ? "info" : "devices"; relayout.restart() }
    }
    Connections { target: radial.dev; enabled: radial.visible; function onBatteryAvailableChanged() { devRelayout.restart() } }

    // ---- backdrop: two eccentric filled discs + two thin concentric rings (plain Rectangles, zero per-frame cost) ----
    Rectangle { x: 437 - 385; y: 328 - 385; width: 770; height: 770; radius: 385; color: Theme.alpha(Theme.surfaceContainer, 0.55) }
    Rectangle { x: 576 - 328; y: 291 - 328; width: 656; height: 656; radius: 328; color: Theme.alpha(Theme.surfaceHigh, 0.75) }
    Rectangle { x: radial.cx - 168; y: radial.cy - 168; width: 336; height: 336; radius: 168; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.outline, 0.16) }
    Rectangle { x: radial.cx - 245; y: radial.cy - 245; width: 490; height: 490; radius: 245; color: "transparent"; border.width: 1; border.color: Theme.alpha(Theme.outline, 0.12) }

    // ---- links: one canvas, painted only when the slot layout changes; fades in after the chips settle.
    //      Only the info page has links (the reference shows none around device chips). ----
    Canvas {
        id: links
        x: 0; y: 0; width: 900; height: 600
        opacity: radial.linksOn && radial.page === "info" ? 0.9 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 260 } }
        onVisibleChanged: if (visible) requestPaint()
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            if (radial.page !== "info") return
            ctx.strokeStyle = Theme.alpha(Theme.onSurfaceVariant, 0.55); ctx.fillStyle = Theme.alpha(Theme.onSurfaceVariant, 0.55)
            ctx.lineWidth = 1.5; ctx.lineJoin = "round"; ctx.lineCap = "round"
            const cx = radial.cx, cy = radial.cy, wob = [5, -5, 3]
            radial.slots.forEach((s, i) => {
                if (s.kind === "dev" || s.kind === "more" || s.kind === "back") return
                const dx = s.tx - cx, dy = s.ty - cy, len = Math.hypot(dx, dy)
                if (len < 1) return
                const ux = dx / len, uy = dy / len
                // where the centre→chip ray meets the chip's edge
                const t = Math.min(Math.abs(ux) > 1e-3 ? (radial.chipW / 2) / Math.abs(ux) : 1e9,
                                   Math.abs(uy) > 1e-3 ? (radial.chipH / 2) / Math.abs(uy) : 1e9)
                const x0 = cx + ux * (radial.rHalo + 2), y0 = cy + uy * (radial.rHalo + 2)
                const x1 = s.tx - ux * (t + 1),           y1 = s.ty - uy * (t + 1)
                const px = -uy, py = ux
                ctx.beginPath(); ctx.moveTo(x0, y0)
                for (let k = 1; k <= 3; k++) {
                    const f = k / 4, o = wob[(k + i) % 3]
                    ctx.lineTo(x0 + (x1 - x0) * f + px * o, y0 + (y1 - y0) * f + py * o)
                }
                ctx.lineTo(x1, y1); ctx.stroke()
                ctx.beginPath(); ctx.arc(x0, y0, 2.5, 0, Math.PI * 2); ctx.fill()
            })
        }
        Connections { target: Theme; function onCChanged() { links.requestPaint() } }
    }

    // ---- halo ring around the centre (video: primary at ~25 % over the disc) ----
    Rectangle {
        x: radial.cx - radial.rHalo; y: radial.cy - radial.rHalo; width: 2 * radial.rHalo; height: 2 * radial.rHalo; radius: radial.rHalo
        color: Bluetooth.enabled ? Theme.alpha(Theme.primary, 0.22) : Theme.alpha(Theme.onSurfaceVariant, 0.08)
        border.width: 1; border.color: Theme.alpha(Theme.primary, Bluetooth.enabled ? 0.12 : 0)
        Behavior on color { ColorAnimation { duration: 200 } }
    }
    // ---- scanning: three short arcs just outside the halo, painted once, stepped round by a slow timer
    //      (12.5 fps, 3 s per turn — nouveau) and switched off after 15 s of scanning ----
    Canvas {
        id: scanArc
        property bool active: false
        x: radial.cx - 140; y: radial.cy - 140; width: 280; height: 280
        opacity: Bluetooth.discovering && active ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 300 } }
        onVisibleChanged: if (visible) requestPaint()
        Timer { interval: 80; repeat: true; running: Bluetooth.discovering && scanArc.active && radial.visible
                onTriggered: scanArc.rotation = (scanArc.rotation + 9.6) % 360 }
        Timer { id: arcStop; interval: 15000; onTriggered: scanArc.active = false }
        Connections {
            target: Bluetooth
            function onDiscoveringChanged() { scanArc.active = Bluetooth.discovering; if (Bluetooth.discovering) arcStop.restart(); else arcStop.stop() }
        }
        onPaint: {
            const ctx = getContext("2d"); ctx.reset()
            ctx.lineWidth = 2.5; ctx.lineCap = "round"; ctx.strokeStyle = Theme.alpha(Theme.primary, 0.85)
            for (let k = 0; k < 3; k++) { ctx.beginPath(); ctx.arc(140, 140, 136, k * 2 * Math.PI / 3, k * 2 * Math.PI / 3 + 0.9); ctx.stroke() }
        }
        Connections { target: Theme; function onCChanged() { scanArc.requestPaint() } }
    }
    // ---- battery ring in the middle of the halo (only when the device reports a battery) ----
    Ring {
        x: radial.cx - 115; y: radial.cy - 115; size: 230; thickness: 3
        visible: radial.hasBattery
        value: radial.hasBattery ? radial.dev.battery : 0
        color: Theme.primary; track: Theme.alpha(Theme.primary, 0.12)
    }

    // ---- centre circle ----
    Rectangle {
        id: centre
        x: radial.cx - radial.rCentre; y: radial.cy - radial.rCentre; width: 2 * radial.rCentre; height: 2 * radial.rCentre; radius: radial.rCentre
        color: radial.lit ? Theme.primary : Bluetooth.enabled ? Theme.alpha(Theme.surfaceHighest, 0.95) : Theme.alpha(Theme.surfaceHigh, 0.9)
        gradient: radial.lit ? litGrad : null
        Gradient { id: litGrad
            GradientStop { position: 0; color: Qt.lighter(Theme.primary, 1.12) }
            GradientStop { position: 1; color: Theme.primary } }
        border.width: radial.lit ? 0 : 1
        border.color: Theme.alpha(Theme.primary, Bluetooth.enabled ? 0.4 : 0.15)
        scale: cmouse.containsMouse && cmouse.enabled ? 1.03 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
        Column {
            anchors.centerIn: parent; spacing: 4; width: 170
            Icon { anchors.horizontalCenter: parent.horizontalCenter; font.pixelSize: 40; fill: true
                   name: !Bluetooth.enabled ? "bluetooth_disabled" : radial.dev ? BtInfo.icon(radial.dev) : Bluetooth.discovering ? "bluetooth_searching" : "bluetooth"
                   color: radial.lit ? Theme.onPrimary : Bluetooth.enabled ? Theme.primary : Theme.onSurfaceVariant }
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 16; font.bold: true
                    text: !Bluetooth.available ? "No adapter" : !Bluetooth.enabled ? "Bluetooth off" : radial.dev ? radial.dev.name : "Not connected"
                    color: radial.lit ? Theme.onPrimary : Theme.onSurface }
            Label { width: parent.width; horizontalAlignment: Text.AlignHCenter; font.pixelSize: 12
                    text: !Bluetooth.available ? "" : !Bluetooth.enabled ? "Tap to turn on" : radial.dev ? BtInfo.stateText(radial.dev)
                        : Bluetooth.discovering ? "Scanning…" : BtInfo.others.length ? "Pick a device" : "Tap to scan"
                    color: radial.lit ? Theme.alpha(Theme.onPrimary, 0.75) : Theme.onSurfaceVariant }
        }
        MouseArea {
            id: cmouse; anchors.fill: parent; hoverEnabled: true; enabled: Bluetooth.available; cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!Bluetooth.enabled) Bluetooth.toggle()
                else if (!radial.dev) Bluetooth.setDiscovering(!Bluetooth.discovering)
                else radial.page = "info"
            }
        }
    }

    // ---- satellite chips: a fixed pool, chip i shows slots[i] ----
    Repeater {
        model: radial.maxSlots
        BtChip {
            id: c
            required property int index
            readonly property var slot: index < radial.slots.length ? radial.slots[index] : null
            readonly property string kind: slot ? slot.kind : ""
            readonly property var d: kind === "dev" ? slot.dev : radial.dev
            readonly property bool audio: kind === "profile" && BtInfo.isAudio(d)
            property bool hadSlot: false
            property bool fly: false
            property int epoch: radial.epoch
            onEpochChanged: fly = true
            onSlotChanged: {
                if (!slot) { hadSlot = false; return }
                if (fly || !hadSlot) c.flyIn(slot.tx, slot.ty)
                else c.moveTo(slot.tx, slot.ty)
                fly = false; hadSlot = true
            }
            visible: slot !== null
            ox: radial.cx; oy: radial.cy; delay: index * 45
            titleSize: kind === "mac" ? 11 : 13
            icon:     kind === "scan" ? (radial.page === "devices" && Bluetooth.discovering ? "stop_circle" : "search")
                    : kind === "back" ? "info" : kind === "more" ? "more_horiz" : kind === "mac" ? "dns"
                    : kind === "disconnect" ? "link_off"
                    : kind === "battery" ? BtInfo.batteryIcon(d ? d.battery : 0)
                    : kind === "profile" ? (audio ? "graphic_eq" : "category") : BtInfo.icon(d)
            title:    kind === "scan" ? (radial.page === "devices" && Bluetooth.discovering ? "Scanning…" : "Scan devices")
                    : kind === "back" ? "Current device" : kind === "more" ? slot.count + " more"
                    : kind === "disconnect" ? "Disconnect"
                    : kind === "mac" ? (d ? d.address : "")
                    : kind === "battery" ? (d ? Math.round(d.battery * 100) + "%" : "")
                    : kind === "profile" ? (audio ? BtInfo.audioLabel : BtInfo.typeLabel(d)) : (d ? d.name : "")
            subtitle: kind === "scan" ? (radial.page === "info" ? "Switch view" : Bluetooth.discovering ? "Tap to stop" : "Find nearby")
                    : kind === "back" ? "View info" : kind === "more" ? "Open list" : kind === "mac" ? "MAC address"
                    : kind === "disconnect" ? (d ? d.name : "")
                    : kind === "battery" ? "Battery" : kind === "profile" ? (audio ? "Audio profile" : "Device type") : BtInfo.stateText(d)
            accent:   kind === "scan" ? (radial.page === "devices" && Bluetooth.discovering) : (kind === "back" || kind === "more") ? true
                    : kind === "dev" ? !!(d && (d.connected || d.paired)) : false
            dim:      (kind === "dev" || kind === "disconnect") && BtInfo.busy(d)
            onClicked: {
                if (kind === "scan") {
                    // from the info page: always go to the devices page and make sure a scan is running;
                    // on the devices page: plain start/stop toggle
                    if (radial.page === "info") { if (!Bluetooth.discovering) Bluetooth.setDiscovering(true); radial.page = "devices" }
                    else Bluetooth.setDiscovering(!Bluetooth.discovering)
                }
                else if (kind === "back") radial.page = "info"
                else if (kind === "more") radial.openList()
                else if (kind === "dev" || kind === "disconnect") BtInfo.act(d)
            }
        }
    }
}
