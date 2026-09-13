#!/usr/bin/env bash
# lock-status.sh — text for the hyprlock status pills (pango markup on stdout). Called from the label
# `cmd[...]` entries in matugen/templates/hyprlock.conf. Must return at once: hyprlock renders all label
# commands on one worker thread, so a command that blocks freezes the clock and the other pills.
#   lock-status.sh layout "<xkb layout name>"   ->  <keyboard icon>  EN      ("English (US)" -> EN, like Keyboard.qml)
#   lock-status.sh battery                      ->  <battery icon>  87%     (from /sys/class/power_supply/BAT*)
#   lock-status.sh weather                      ->  <weather icon>  7.7°C   (from a cache; refreshes it in the background)
#   lock-status.sh weather-refresh              ->  internal: fetch open-meteo, write the cache, poke hyprlock (SIGUSR2)
set -u
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rrk-shell/lock-weather"      # one line: "<weather_code> <temperature> <is_day>"
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/rrk-shell/settings.json"
MAXAGE=600                                                          # seconds before the weather cache is refreshed

icon() { printf '<span font_desc="Material Symbols Rounded 24 @FILL=1">%s</span>' "$1"; }

# WMO weather code (+ is_day) -> Material Symbols name; same table as shell/services/Weather.qml iconFor()
wicon() {
    local c="${1:-0}" day="${2:-1}"
    if   [ "$c" -eq 0 ];  then [ "$day" = 1 ] && echo clear_day || echo clear_night
    elif [ "$c" -le 2 ];  then [ "$day" = 1 ] && echo partly_cloudy_day || echo partly_cloudy_night
    elif [ "$c" -eq 3 ];  then echo cloud
    elif [ "$c" -le 48 ]; then echo foggy
    elif [ "$c" -le 67 ]; then echo rainy
    elif [ "$c" -le 77 ]; then echo weather_snowy
    elif [ "$c" -le 82 ]; then echo rainy
    elif [ "$c" -le 86 ]; then echo weather_snowy
    else echo thunderstorm; fi
}

case "${1:-}" in
    layout)
        w="${2:-}"; w="${w%% *}"                                     # first word of "English (US)"
        case "$w" in
            English) a=EN ;; Russian) a=RU ;; German) a=DE ;; French) a=FR ;;
            Spanish) a=ES ;; Ukrainian) a=UA ;; Arabic) a=AR ;;
            *) a=$(printf '%s' "$w" | cut -c1-2 | tr '[:lower:]' '[:upper:]') ;;
        esac
        printf '%s  %s' "$(icon keyboard)" "${a:-??}" ;;
    battery)
        b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -n1)
        if [ -z "$b" ] || [ ! -r "$b/capacity" ]; then printf '%s  AC' "$(icon power)"; exit 0; fi
        cap=$(cat "$b/capacity"); st=$(cat "$b/status" 2>/dev/null || echo Unknown)
        if   [ "$st" = Charging ]; then i=battery_charging_full
        elif [ "$cap" -gt 90 ]; then i=battery_full
        elif [ "$cap" -gt 60 ]; then i=battery_5_bar
        elif [ "$cap" -gt 40 ]; then i=battery_4_bar
        elif [ "$cap" -gt 20 ]; then i=battery_2_bar
        else i=battery_alert; fi
        printf '%s  %s%%' "$(icon "$i")" "$cap" ;;
    weather)
        mkdir -p "$(dirname "$CACHE")"
        if [ -s "$CACHE" ]; then
            read -r code temp day < "$CACHE"
            printf '%s  %s°C' "$(icon "$(wicon "$code" "${day:-1}")")" "$temp"
        else
            printf '%s  --' "$(icon cloud)"
        fi
        age=$(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || echo 0) ))
        # refresh in a detached process with stdio on /dev/null (the child also drops every other inherited
        # fd, see below) so hyprlock sees our stdout close right away instead of after the network round trip
        [ "$age" -gt "$MAXAGE" ] && setsid -f "$0" weather-refresh >/dev/null 2>&1 </dev/null
        exit 0 ;;
    weather-refresh)
        # hyprlock's runSync leaks the write ends of its stdout/stderr pipes into every child (no CLOEXEC); as
        # long as we hold them the `weather` label command above looks unfinished. Close all fds > 2 (255 is
        # bash's own handle on this script) before doing anything slow.
        for f in /proc/$$/fd/*; do n=${f##*/}; [ "$n" -gt 2 ] && [ "$n" -ne 255 ] && eval "exec $n>&-"; done 2>/dev/null
        lat=$(jq -r '.weather.lat // empty' "$SETTINGS" 2>/dev/null); lon=$(jq -r '.weather.lon // empty' "$SETTINGS" 2>/dev/null)
        if [ -z "$lat" ] || [ -z "$lon" ]; then                      # same IP-based fallback as Weather.qml
            geo=$(curl -sf --max-time 8 'https://ipwho.is/?fields=latitude,longitude') || exit 1
            lat=$(jq -r '.latitude // empty' <<<"$geo"); lon=$(jq -r '.longitude // empty' <<<"$geo")
            [ -n "$lat" ] && [ -n "$lon" ] || exit 1
        fi
        j=$(curl -sf --max-time 10 "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code,is_day") || exit 1
        code=$(jq -r '.current.weather_code // empty' <<<"$j"); temp=$(jq -r '.current.temperature_2m // empty' <<<"$j"); day=$(jq -r '.current.is_day // 1' <<<"$j")
        [ -n "$code" ] && [ -n "$temp" ] || exit 1
        mkdir -p "$(dirname "$CACHE")"
        printf '%s %s %s\n' "$code" "$temp" "$day" > "$CACHE.tmp" && mv "$CACHE.tmp" "$CACHE"
        # SIGUSR2 = "re-run the labels". hyprlock installs that handler ~2 s after starting (before that the
        # signal would kill it), so only poke instances that have been running for more than 3 s.
        pkill -O 3 -USR2 -x hyprlock 2>/dev/null || true ;;
    *) sed -n '2,8p' "$0" >&2; exit 1 ;;
esac
