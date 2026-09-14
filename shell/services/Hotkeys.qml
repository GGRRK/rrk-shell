pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Data for the keyboard cheat sheet (SUPER+K, panels/HotkeysPanel.qml). It is parsed from hypr/config/keybinds.lua —
// the file Hyprland itself loads — so the sheet cannot drift from the real binds. Rules (also in the file's header):
//   · a comment line holding only a short title ("-- Shell panels") starts a section; comment lines that look like code
//     or prose (contain "(", "hl.", start with another "-", or are longer than 40 characters) are ignored, and so are
//     `--[[ block ]]` comments
//   · the trailing `-- comment` of an hl.bind(...) line is the description (a `description = "…"` field in the options
//     table wins over it); consecutive binds with the same description share one row (arrows: "Super + ← → ↑ ↓";
//     alternatives with different prefixes: "Super + C or Alt + F4"); a bind without either shows its dispatcher
//     instead (never merged); binds before the first section title land in a section called "Other"
//   · the key expression is evaluated: string pieces joined with `..`, `mainMod` (and any other `name = "value"` or
//     `name = a .. "b"` line in variables.lua or keybinds.lua) substituted, the variable of `for i = a, b do … end` shown as "a–b" (if/while/function
//     blocks inside the loop are fine). A bind whose key uses an unknown variable is left out (with a warning in the log)
//     rather than shown wrong
//   · a call may span several lines (joined until the parentheses balance); several hl.bind on one line all count
//   · `locked = true` in the options table marks the row as working on the lock screen
// Not understood: Lua long-bracket strings ([[…]]), keys built by function calls, submaps (listed as global binds). Both files are watched, so saving
// keybinds.lua updates the sheet (Hyprland reloads its binds itself). `staticSections` (keys that only work inside a
// shell panel and are not Hyprland binds) are appended at the end.
Singleton {
    id: root
    readonly property string repo: Quickshell.env("HOME") + "/claude/rrk-shell"
    property var sections: []       // [{ title, rows: [{ desc, combos: [[cap, …], …], tokens: [{t: "cap", v} | {t: "plus"} | {t: "alt"} | {t: "or"}], locked, search }] }]
    readonly property int rowCount: sections.reduce((n, s) => n + s.rows.length, 0)
    readonly property bool anyLocked: sections.some(s => s.rows.some(r => r.locked))
    property var vars: ({ mainMod: "SUPER" })

    // keys that work inside the shell's own panels (not Hyprland binds, so not in keybinds.lua)
    readonly property var staticSections: [{ title: "Inside a panel", rows: [
        { desc: "Launch / copy the highlighted entry", combos: [["Enter"]] },
        { desc: "Move the highlight",                  combos: [["↑"], ["↓"]] },
        { desc: "Launcher: Apps ↔ All",                combos: [["Tab"]] },
        { desc: "Launcher: run a shell command",       combos: [[">"]] },
        { desc: "Clipboard: delete the highlighted",   combos: [["Shift", "Del"]] },
        { desc: "Close the panel",                     combos: [["Esc"]] },
    ] }]

    FileView {
        id: varsFile
        path: root.repo + "/hypr/config/variables.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.vars = root.parseVars(text()); if (binds.loaded) root.sections = root.parse(binds.text()) }
    }
    FileView {
        id: binds
        path: root.repo + "/hypr/config/keybinds.lua"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.sections = root.parse(text())
    }

    // display names for Hyprland / xkb key names (looked up case-insensitively)
    readonly property var names: ({
        super: "Super", win: "Super", logo: "Super", mod4: "Super", super_l: "Super", super_r: "Super",
        shift: "Shift", alt: "Alt", mod1: "Alt", ctrl: "Ctrl", control: "Ctrl",
        space: "Space", return: "Enter", enter: "Enter", tab: "Tab", print: "PrtSc", escape: "Esc", backspace: "Backspace",
        delete: "Del", insert: "Ins", home: "Home", end: "End", prior: "PgUp", next: "PgDn", page_up: "PgUp", page_down: "PgDn",
        left: "←", right: "→", up: "↑", down: "↓",
        minus: "-", plus: "+", equal: "=", comma: ",", period: ".", slash: "/", backslash: "\\", semicolon: ";", apostrophe: "'",
        grave: "`", bracketleft: "[", bracketright: "]",
        kp_add: "Num +", kp_subtract: "Num -", kp_multiply: "Num *", kp_divide: "Num /", kp_enter: "Num Enter",
        mouse_down: "Scroll ↓", mouse_up: "Scroll ↑", "mouse:272": "Left drag", "mouse:273": "Right drag", "mouse:274": "Middle drag",
        xf86audioraisevolume: "Vol +", xf86audiolowervolume: "Vol −", xf86audiomute: "Mute", xf86audiomicmute: "Mic mute",
        xf86monbrightnessup: "Bright +", xf86monbrightnessdown: "Bright −",
        xf86audioplay: "Play", xf86audiopause: "Pause", xf86audionext: "Next", xf86audioprev: "Prev"
    })
    function capName(k) {
        const known = names[k.toLowerCase()]
        if (known) return known
        if (/^xf86/i.test(k)) return k.replace(/^xf86/i, "").replace(/([a-z])([A-Z])/g, "$1 $2")   // XF86Calculator → "Calculator"
        if (/^code:\d+$/i.test(k)) return "key " + k.slice(5)
        if (k.length === 1) return k.toUpperCase()
        return k
    }

    // `name = "value"` / `name = other .. " + SHIFT"` lines; anything else on the right-hand side (function calls…) is skipped
    function parseVars(txt) {
        const v = { mainMod: "SUPER" }
        for (const line of txt.split("\n")) { const a = assignment(line, v); if (a) v[a.name] = a.value }
        return v
    }
    function assignment(line, known) {
        const m = line.match(/^\s*(?:local\s+)?([A-Za-z_]\w*)\s*=\s*([^=].*?)\s*(--.*)?$/)
        if (!m || /[()\[\]{}]/.test(m[2])) return null
        const r = evalConcat(m[2], known || {})
        return r.unknown.length ? null : { name: m[1], value: r.text }
    }

    function parse(txt) {
        txt = txt.replace(/--\[(=*)\[[\s\S]*?\]\1\]/g, "").replace(/\r/g, "")   // block comments (--[[ … ]], --[==[ … ]==]), CRLF
        const sections = []
        const fileVars = {}
        let cur = null
        let blocks = []                  // open Lua blocks; each may carry loop variables { i: "1–8" }
        const section = title => { cur = { title: title, rows: [] }; sections.push(cur) }
        const scope = () => { const v = Object.assign({}, vars, fileVars); for (const b of blocks) Object.assign(v, b); return v }
        let pending = "", pendingComment = ""   // a call split over several lines is joined (code only) until its parentheses balance
        for (const raw of txt.split("\n")) {
            const line = raw.trim()
            if (line === "" && pending === "") continue
            const ci = commentStart(line)
            let code = (ci < 0 ? line : line.slice(0, ci)).trim()
            let comment = ci < 0 ? "" : line.slice(ci + 2).trim()
            if (pending !== "") { code = pending + " " + code; if (comment === "") comment = pendingComment; pending = "" }
            else if (code === "") {      // comment-only line: a short plain title opens a section, anything else is ignored
                if (comment !== "" && comment.length <= 40 && !/^[-=#*]/.test(comment) && !/[()\[\]{}]|hl\./.test(comment)) section(comment)
                continue
            }
            if (parenDepth(code) > 0) { pending = code; pendingComment = comment; continue }
            const a = assignment(code, scope()); if (a) { fileVars[a.name] = a.value; continue }
            // block structure: for-loops carry their variable; if / while / function / do only nest
            let rest = code
            const f = rest.match(/^for\s+([A-Za-z_]\w*)\s*=\s*(-?\d+)\s*,\s*(-?\d+)(?:\s*,\s*-?\d+)?\s+do\b(.*)$/)
            if (f) { const b = {}; b[f[1]] = f[2] + "–" + f[3]; blocks.push(b); rest = f[4].trim() }
            else if (/^for\b/.test(rest)) { blocks.push({}); const m = rest.match(/\bdo\b(.*)$/); rest = m ? m[1].trim() : "" }   // generic for: no key info
            else if (/^(if|while)\b/.test(rest)) { blocks.push({}); const m = rest.match(/\b(then|do)\b(.*)$/); rest = m ? m[2].trim() : "" }
            else if (/^(local\s+)?function\b|^do\b/.test(rest)) { blocks.push({}); rest = rest.replace(/^(local\s+)?function\b[^)]*\)|^do\b/, "").trim() }
            let closes = 0
            const e = rest.match(/^(.*?)\s*\bend\s*$/); if (e) { rest = e[1]; closes = 1 } else if (/^end\b/.test(rest)) { rest = ""; closes = 1 }
            // every hl.bind(...) on the line
            let pos = 0
            while ((pos = rest.indexOf("hl.bind", pos)) >= 0) {
                const open = rest.indexOf("(", pos + 7)
                if (open < 0 || rest.slice(pos + 7, open).trim() !== "") { pos += 7; continue }
                const args = splitArgs(rest.slice(open + 1))
                pos = open + 1 + args.consumed
                if (args.length < 2) { console.warn("Hotkeys: cannot parse", line); continue }
                const r = evalConcat(args[0], scope())
                if (r.unknown.length) { console.warn("Hotkeys: skipping bind with unknown variable(s)", r.unknown.join(", "), "-", line); continue }
                const combo = r.text.split("+").map(k => k.trim()).filter(k => k !== "").map(capName)
                if (combo.length === 0) continue
                const opts = args.slice(2).join(",")
                const locked = /(^|[^\w])locked\s*=\s*true\b/.test(opts)
                const dm = opts.match(/(^|[^\w])description\s*=\s*(["'])(.*?)\2/)
                const explicit = dm ? dm[3] : comment
                const desc = explicit !== "" ? explicit : args[1].trim().replace(/^hl\.dsp\./, "")
                if (!cur) section("Other")
                const last = cur.rows[cur.rows.length - 1]
                if (explicit !== "" && last && last.desc === desc) { last.combos.push(combo); last.locked = last.locked || locked }
                else cur.rows.push({ desc: desc, combos: [combo], locked: locked })
            }
            while (closes-- > 0 && blocks.length) blocks.pop()
        }
        if (pending !== "") console.warn("Hotkeys: unbalanced parentheses at the end of keybinds.lua")
        const out = sections.filter(s => s.rows.length > 0).concat(staticSections.map(s => ({ title: s.title, rows: s.rows.map(r => ({ desc: r.desc, combos: r.combos, locked: false })) })))
        for (const s of out) for (const r of s.rows) {
            r.tokens = tokensFor(r.combos)
            const keys = r.combos.map(c => c.join(" ")).join(" ")
            const range = keys.match(/(\d+)–(\d+)/)          // "1–8" is also found by "3"
            const nums = range ? Array.from({ length: Math.max(0, range[2] - range[1] + 1) }, (_, i) => String(+range[1] + i)).join(" ") : ""
            r.search = (s.title + " " + r.desc + " " + keys + " " + nums).toLowerCase()
        }
        return out
    }

    // index of the first `--` outside a string literal, -1 if none
    function commentStart(line) {
        let q = null
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (q) { if (ch === "\\") i++; else if (ch === q) q = null }
            else if (ch === '"' || ch === "'") q = ch
            else if (ch === "-" && line[i + 1] === "-") return i
        }
        return -1
    }
    // net count of ( [ { opened minus closed, outside string literals
    function parenDepth(code) {
        let d = 0, q = null
        for (let i = 0; i < code.length; i++) {
            const ch = code[i]
            if (q) { if (ch === "\\") i++; else if (ch === q) q = null }
            else if (ch === '"' || ch === "'") q = ch
            else if (ch === "(" || ch === "{" || ch === "[") d++
            else if (ch === ")" || ch === "}" || ch === "]") d--
        }
        return d
    }
    // arguments of a call, split at top-level commas (strings and nested (), {}, [] respected); stops at the closing paren.
    // `consumed` = number of characters used, including that paren
    function splitArgs(s) {
        const out = []
        let depth = 0, q = null, start = 0
        for (let i = 0; i < s.length; i++) {
            const ch = s[i]
            if (q) { if (ch === "\\") i++; else if (ch === q) q = null; continue }
            if (ch === '"' || ch === "'") q = ch
            else if (ch === "(" || ch === "{" || ch === "[") depth++
            else if (ch === ")" || ch === "}" || ch === "]") { if (depth === 0) { out.push(s.slice(start, i)); out.consumed = i + 1; return out } depth-- }
            else if (ch === "," && depth === 0) { out.push(s.slice(start, i)); start = i + 1 }
        }
        out.push(s.slice(start)); out.consumed = s.length
        return out
    }
    // `mainMod .. " + SHIFT + " .. i` → { text: "SUPER + SHIFT + 1–8", unknown: [] }: literals unquoted, identifiers looked up
    function evalConcat(expr, vars) {
        let out = "", tok = "", q = null
        const unknown = []
        const flush = () => {
            const t = tok.trim(); tok = ""
            if (t === "") return
            if (t[0] === '"' || t[0] === "'") out += t.slice(1, -1).replace(/\\(.)/g, "$1")
            else if (/^-?\d+$/.test(t)) out += t
            else if (vars[t] !== undefined) out += vars[t]
            else { unknown.push(t); out += t }
        }
        for (let i = 0; i < expr.length; i++) {
            const ch = expr[i]
            if (q) { tok += ch; if (ch === "\\") { tok += expr[i + 1] || ""; i++ } else if (ch === q) q = null; continue }
            if (ch === '"' || ch === "'") { q = ch; tok += ch }
            else if (ch === "." && expr[i + 1] === ".") { flush(); i++ }
            else tok += ch
        }
        flush()
        return { text: out, unknown: unknown }
    }
    // how a row's key combinations are drawn: caps joined by "+"; alternatives that only differ in the last key share
    // the prefix once — single glyphs sit side by side (Super + ← → ↑ ↓), words get a "/" (Super + Space / R);
    // alternatives with different prefixes are separated by "or". (No Array.flatMap: Qt's JS engine lacks it.)
    function tokensFor(combos) {
        const caps = (out, c) => { c.forEach((k, i) => { if (i > 0) out.push({ t: "plus" }); out.push({ t: "cap", v: k }) }); return out }
        const toks = []
        if (combos.length === 1) return caps(toks, combos[0])
        const n = combos[0].length
        const prefix = JSON.stringify(combos[0].slice(0, -1))
        if (combos.every(c => c.length === n && JSON.stringify(c.slice(0, -1)) === prefix)) {
            caps(toks, combos[0].slice(0, -1))
            if (n > 1) toks.push({ t: "plus" })
            const glyphs = combos.every(c => c[n - 1].length === 1)
            combos.forEach((c, i) => { if (i > 0 && !glyphs) toks.push({ t: "alt" }); toks.push({ t: "cap", v: c[n - 1] }) })
            return toks
        }
        combos.forEach((c, i) => { if (i > 0) toks.push({ t: "or" }); caps(toks, c) })
        return toks
    }
}
