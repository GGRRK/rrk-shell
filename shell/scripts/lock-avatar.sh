#!/usr/bin/env bash
# lock-avatar.sh — builds ~/.config/rrk-shell/avatar.png (512x512 square) for the hyprlock lock screen.
#   ~/.face (or ~/.face.icon) exists -> centre-cropped, resized copy of that photo
#   otherwise                        -> monogram: first letter of the user name on the palette's primaryContainer
#   anything fails / no imagemagick  -> assets/avatar-default.png, so the file always exists (hyprlock re-renders
#                                       every frame while an image widget's file is missing)
# Run by `rrkshell wallpaper …` (palette changed), `rrkshell avatar [photo]` and install.sh. Safe to re-run:
# a photo that has not changed since the last build (avatar.src remembers path+mtime+size) is skipped.
set -u
CONF="${XDG_CONFIG_HOME:-$HOME/.config}/rrk-shell"
OUT="$CONF/avatar.png"
STAMP="$CONF/avatar.src"                                     # what avatar.png was built from
FONT=/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Bold.ttf     # ttf-jetbrains-mono-nerd
DEFAULT="$(cd "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/../.." && pwd)/assets/avatar-default.png"
mkdir -p "$CONF"

fallback() { [ -s "$OUT" ] || { cp -- "$DEFAULT" "$OUT" && printf 'default\n' > "$STAMP"; }; }

if ! command -v magick >/dev/null 2>&1; then
    echo "lock-avatar: imagemagick not installed, using the default avatar" >&2
    fallback; exit 0
fi

for src in "$HOME/.face" "$HOME/.face.icon"; do
    [ -f "$src" ] || continue
    sig="$src $(stat -c '%Y %s' "$src")"
    [ -s "$OUT" ] && [ "$(cat "$STAMP" 2>/dev/null)" = "$sig" ] && exit 0      # same photo as last time
    # "[0]" = first frame only (an animated GIF would otherwise produce one file per frame)
    if magick "$src[0]" -auto-orient -gravity center -extent '%[fx:min(w,h)]x%[fx:min(w,h)]' -resize 512x512 -depth 8 "$OUT.tmp.png" 2>/dev/null; then
        mv "$OUT.tmp.png" "$OUT" && printf '%s\n' "$sig" > "$STAMP"; exit 0
    fi
    rm -f "$OUT.tmp.png"
    echo "lock-avatar: cannot read $src, using a monogram instead" >&2
done

bg=$(jq -r '.primaryContainer // empty' "$CONF/colors.json" 2>/dev/null); bg="${bg:-#2d4a75}"
fg=$(jq -r '.onPrimaryContainer // empty' "$CONF/colors.json" 2>/dev/null); fg="${fg:-#d6e3ff}"
initial=$(printf '%s' "${USER:-$(id -un)}" | cut -c1 | tr '[:lower:]' '[:upper:]')
if magick -size 512x512 "xc:$bg" -fill "$fg" -font "$FONT" -pointsize 280 -gravity center -annotate +0+0 "${initial:-?}" -depth 8 "$OUT.tmp.png" 2>/dev/null; then
    mv "$OUT.tmp.png" "$OUT" && printf 'monogram\n' > "$STAMP"
else
    rm -f "$OUT.tmp.png"
    echo "lock-avatar: monogram failed, using the default avatar" >&2
fi
fallback
