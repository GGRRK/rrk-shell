#!/usr/bin/env bash
# Prints the poster frame (jpg) for a video wallpaper, extracting it with ffmpeg on first use.
#   wallpaper-poster.sh <video>   →  ~/.cache/rrk-shell/wallposter/<md5 of path>.jpg
# The poster is what matugen (colours), hyprlock (background), awww (still behind the video) and the picker use.
set -u
video="$1"
cache="${XDG_CACHE_HOME:-$HOME/.cache}/rrk-shell/wallposter"
mkdir -p "$cache"
key=$(printf '%s' "$video" | md5sum | cut -c1-32)
poster="$cache/$key.jpg"
if [ ! -s "$poster" ] || [ "$video" -nt "$poster" ]; then
    ffmpeg -v error -y -ss 2 -i "$video" -frames:v 1 -q:v 2 "$poster" </dev/null || exit 1
fi
printf '%s\n' "$poster"
