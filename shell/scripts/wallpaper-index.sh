#!/usr/bin/env bash
# Prints a JSON array of wallpapers in $1 with a cached dominant colour for each:
#   [{"path":"...","name":"...","color":"#rrggbb","hue":210,"poster":"..."}]
# Videos (live wallpapers) are listed too; their "poster" is a cached frame (wallpaper-poster.sh) used for the
# thumbnail and the colour. Colours are computed once with ImageMagick and cached in ~/.cache/rrk-shell/wallcolors.
set -u
DIR="${1:-$HOME/Pictures/Wallpapers}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rrk-shell/wallcolors"
mkdir -p "$CACHE"
first=1
echo "["
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
while IFS= read -r -d '' f; do
    key=$(printf '%s' "$f" | md5sum | cut -c1-32)
    poster=""
    case "${f,,}" in *.mp4|*.webm|*.mkv|*.mov) poster="$("$HERE/wallpaper-poster.sh" "$f" 2>/dev/null)" || continue ;; esac
    src="${poster:-$f}"
    if [ -f "$CACHE/$key" ]; then
        read -r color hue < "$CACHE/$key"
    else
        # average colour of a heavily downscaled copy, then boost saturation so the hue is meaningful
        color=$(magick "$src" -resize 64x64! -modulate 100,180 -scale 1x1! -format '%[hex:u.p{0,0}]' info: 2>/dev/null | cut -c1-6)
        hue=$(magick "$src" -resize 32x32! -colorspace HSL -scale 1x1! -format '%[fx:int(u.r*360)]' info: 2>/dev/null)
        if [ -n "$color" ] && [ -n "$hue" ]; then
            color="#$color"
            echo "$color $hue" > "$CACHE/$key"   # only cache real results (magick may be missing)
        else
            color="#808080"; hue=0
        fi
    fi
    name=$(basename "$f"); name="${name%.*}"
    [ $first -eq 1 ] || echo ","
    first=0
    printf '{"path":"%s","name":"%s","color":"%s","hue":%s,"poster":"%s"}' "$f" "${name//\"/}" "$color" "$hue" "$poster"
done < <(find "$DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \) -print0 | sort -z)
echo
echo "]"
