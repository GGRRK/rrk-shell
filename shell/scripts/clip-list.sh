#!/usr/bin/env bash
# Prints the clipboard history (cliphist) as a JSON array, newest first:
#   [{"id":12,"kind":"image","preview":"[[ binary data 123 KiB png 800x600 ]]","size":"123 KiB","format":"png","w":800,"h":600,"file":"/home/x/.cache/rrk-shell/clip/12.png"},
#    {"id":11,"kind":"text","preview":"#ff8800"}]
# Image entries get a small thumbnail (<=176x120 PNG, made once with ImageMagick) in ~/.cache/rrk-shell/clip/<id>.png;
# thumbnails of entries that no longer exist are removed. Used by shell/services/Clipboard.qml.
# Exit 0 with "[]" when nothing was ever stored; exit 1 with no output when `cliphist list` failed although the
# database exists (e.g. the bolt lock is held by `cliphist store` for a moment) so the shell keeps its current list.
set -u
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/rrk-shell/clip"
DB="${XDG_CACHE_HOME:-$HOME/.cache}/cliphist/db"
mkdir -p "$CACHE" && chmod 700 "$CACHE"   # thumbnails of screenshots can be sensitive — keep the directory private

if ! list="$(cliphist list 2>/dev/null)"; then
    if [ -e "$DB" ]; then exit 1; fi        # transient failure: keep the previous list, keep the thumbnails
    printf '[]\n'; exit 0                   # "please store something first": genuinely empty
fi

# 1. make thumbnails for image entries that do not have one yet
while IFS=$'\t' read -r id preview; do
    [ -n "$id" ] || continue
    # image preview looks like "[[ binary data 123 KiB png 800x600 ]]" (cliphist preview(): size, go image format, WxH)
    if [[ "$preview" =~ ^\[\[\ binary\ data\ [0-9]+\ [A-Za-z]+\ ([a-z]+)\ [0-9]+x[0-9]+\ \]\]$ ]]; then
        f="$CACHE/$id.png"
        # "-[0]" = first frame of stdin (animated GIFs would otherwise produce one file per frame)
        [ -s "$f" ] || cliphist decode "$id" 2>/dev/null | magick '-[0]' -thumbnail 176x120 "png:$f" 2>/dev/null || rm -f -- "$f"
    fi
done <<< "$list"

# 2. drop thumbnails whose entry is gone (deleted / wiped / trimmed by cliphist)
for f in "$CACHE"/*; do
    [ -e "$f" ] || continue
    id="${f##*/}"; id="${id%%.*}"
    grep -q "^${id}"$'\t' <<< "$list" || rm -f -- "$f"
done

# 3. JSON (jq escapes quotes / backslashes / control characters in the previews)
printf '%s' "$list" | jq -R -s --arg cache "$CACHE" '
  split("\n") | map(select(length > 0))
  | map(capture("^(?<id>[0-9]+)\t(?<preview>.*)$") | .id |= tonumber)
  | map(
      if (.preview | test("^\\[\\[ binary data [0-9]+ [A-Za-z]+ [a-z]+ [0-9]+x[0-9]+ \\]\\]$")) then
        (.preview | capture("^\\[\\[ binary data (?<size>[0-9]+ [A-Za-z]+) (?<format>[a-z]+) (?<w>[0-9]+)x(?<h>[0-9]+) \\]\\]$")) as $m
        | { id, kind: "image", preview, size: $m.size, format: $m.format, w: ($m.w | tonumber), h: ($m.h | tonumber),
            file: ($cache + "/" + (.id | tostring) + ".png") }
      else { id, kind: "text", preview } end)'
