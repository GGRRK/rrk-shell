pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Weather from open-meteo.com (free, no key). Location: settings.json {"weather":{"lat":..,"lon":..,"city":".."}},
// otherwise a rough city-level lookup from your IP (ipwho.is) — no GPS involved.
Singleton {
    id: root
    property real lat: NaN
    property real lon: NaN
    property string city: ""
    property bool ready: false
    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property real wind: 0
    property int rain: 0
    property int code: 0
    property var hourly: []          // next hours: [{time:"14:00", temp, code}]
    property var daily: []           // [{day:"Fri", hi, lo, code}]

    readonly property string description: describe(code)
    readonly property string icon: iconFor(code, true)

    function describe(c) {
        if (c === 0) return "Clear Sky"; if (c <= 2) return "Partly Cloudy"; if (c === 3) return "Overcast Clouds"
        if (c <= 48) return "Fog"; if (c <= 57) return "Drizzle"; if (c <= 67) return "Rain"; if (c <= 77) return "Snow"
        if (c <= 82) return "Showers"; if (c <= 86) return "Snow Showers"; return "Thunderstorm"
    }
    function iconFor(c, day) {
        if (c === 0) return day ? "clear_day" : "clear_night"; if (c <= 2) return day ? "partly_cloudy_day" : "partly_cloudy_night"
        if (c === 3) return "cloud"; if (c <= 48) return "foggy"; if (c <= 67) return "rainy"; if (c <= 77) return "weather_snowy"
        if (c <= 82) return "rainy"; if (c <= 86) return "weather_snowy"; return "thunderstorm"
    }

    FileView {
        id: settings
        path: Quickshell.env("HOME") + "/.config/rrk-shell/settings.json"
        onLoaded: {
            try { const w = JSON.parse(text()).weather || {}; if (w.lat !== undefined) { root.lat = w.lat; root.lon = w.lon; root.city = w.city || "" } } catch (e) {}
            root.locate()
        }
        onLoadFailed: root.locate()
    }

    Process {
        id: geo
        command: ["curl", "-sf", "--max-time", "8", "https://ipwho.is/?fields=latitude,longitude,city"]
        stdout: StdioCollector { onStreamFinished: { try { const j = JSON.parse(text); root.lat = j.latitude; root.lon = j.longitude; root.city = j.city || ""; root.fetch() } catch (e) { retry.start() } } }
    }
    Process {
        id: api
        stdout: StdioCollector { onStreamFinished: root.parse(text) }
    }
    Timer { id: retry; interval: 60000; onTriggered: root.locate() }
    Timer { interval: 20 * 60 * 1000; running: true; repeat: true; onTriggered: root.fetch() }

    function locate() { if (isNaN(lat)) geo.running = true; else fetch() }
    function fetch() {
        if (isNaN(lat)) return
        api.command = ["curl", "-sf", "--max-time", "10",
            "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon +
            "&current=temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code,precipitation_probability" +
            "&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min&forecast_days=5&timezone=auto&wind_speed_unit=ms"]
        api.running = true
    }
    function parse(txt) {
        try {
            const j = JSON.parse(txt); const c = j.current
            temp = c.temperature_2m; feels = c.apparent_temperature; humidity = c.relative_humidity_2m
            wind = c.wind_speed_10m; code = c.weather_code; rain = c.precipitation_probability || 0
            const nowH = new Date().getHours(); const h = []
            for (let i = nowH; i < nowH + 24 && i < j.hourly.time.length; i += 3)
                h.push({ time: j.hourly.time[i].slice(11), temp: j.hourly.temperature_2m[i], code: j.hourly.weather_code[i] })
            hourly = h
            const d = []
            for (let i = 0; i < j.daily.time.length; i++)
                d.push({ day: Qt.formatDate(new Date(j.daily.time[i] + "T12:00"), "ddd"), hi: j.daily.temperature_2m_max[i], lo: j.daily.temperature_2m_min[i], code: j.daily.weather_code[i] })
            daily = d; ready = true
        } catch (e) { console.warn("weather parse failed", e); retry.start() }
    }
}
