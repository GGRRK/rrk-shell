#!/usr/bin/env bash
# Prints a JSON array of wallpapers in $1 with a cached dominant colour for each:
#   [{"path":"...","name":"...","color":"#rrggbb","hue":210}]
# Colours are computed once with ImageMagick and cached in ~/.cache/rrk-shell/wallcolors.
set -u
DIR="${1:-$HOME/Pictures/Wallpapers}"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rrk-shell/wallcolors"
mkdir -p "$CACHE"
first=1
echo "["
while IFS= read -r -d '' f; do
    key=$(printf '%s' "$f" | md5sum | cut -c1-32)
    if [ -f "$CACHE/$key" ]; then
        read -r color hue < "$CACHE/$key"
    else
        # average colour of a heavily downscaled copy, then boost saturation so the hue is meaningful
        color=$(magick "$f" -resize 64x64! -modulate 100,180 -scale 1x1! -format '%[hex:u.p{0,0}]' info: 2>/dev/null | cut -c1-6)
        [ -n "$color" ] || color="808080"
        hue=$(magick "$f" -resize 32x32! -colorspace HSL -scale 1x1! -format '%[fx:int(u.r*360)]' info: 2>/dev/null)
        [ -n "$hue" ] || hue=0
        color="#$color"
        echo "$color $hue" > "$CACHE/$key"
    fi
    name=$(basename "$f"); name="${name%.*}"
    [ $first -eq 1 ] || echo ","
    first=0
    printf '{"path":"%s","name":"%s","color":"%s","hue":%s}' "$f" "${name//\"/}" "$color" "$hue"
done < <(find "$DIR" -maxdepth 2 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) -print0 | sort -z)
echo
echo "]"
