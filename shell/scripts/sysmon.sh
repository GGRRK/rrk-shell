#!/bin/sh
# sysmon.sh — prints ONE line of raw counters for shell/services/SysMon.qml (rates/deltas are computed in QML).
# Fields (space separated, all integers):
#   1 cpuBusy    2 cpuTotal    (jiffies since boot, from /proc/stat)
#   3 memTotalKB 4 memAvailKB  (from /proc/meminfo)
#   5 tempMilliC (coretemp "Package id 0", or AMD Tctl/Tdie, else thermal_zone0; 0 if none)
#   6 diskUsedB  7 diskSizeB   (df of /)
#   8 rxBytes    9 txBytes     (sum of all interfaces except lo, from /proc/net/dev)
set -- $(head -n1 /proc/stat)              # cpu user nice system idle iowait irq softirq steal ...
busy=$(( $2 + $3 + $4 + $7 + $8 + $9 ))
total=$(( busy + $5 + $6 ))
mem=$(awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {print t+0, a+0}' /proc/meminfo)
temp=""
for l in /sys/class/hwmon/hwmon*/temp*_label; do
    [ -r "$l" ] || continue
    case "$(cat "$l")" in
        "Package id 0"|Tctl|Tdie) temp=$(cat "${l%_label}_input" 2>/dev/null); break ;;
    esac
done
[ -n "$temp" ] || temp=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
disk=$(df -B1 --output=used,size / 2>/dev/null | tail -n1)
net=$(awk 'NR>2 { sub(/^[ \t]+/, ""); n=split($0, f, /[: ]+/); if (f[1] != "lo" && n >= 10) { rx += f[2]; tx += f[10] } } END { printf "%d %d\n", rx, tx }' /proc/net/dev)
echo "$busy $total $mem $temp $disk $net"
