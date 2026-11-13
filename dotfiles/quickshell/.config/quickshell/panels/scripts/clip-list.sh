#!/usr/bin/env bash
# Print cliphist entries as JSON lines; decode images to a cache dir for previews.
CACHE="$HOME/.cache/quickshell/clip"
mkdir -p "$CACHE"
cliphist list | head -200 | while IFS=$'\t' read -r id preview; do
    img=""
    if [[ "$preview" =~ ^\[\[\ binary\ data.*(png|jpe?g|webp|bmp|gif) ]]; then
        img="$CACHE/$id.${BASH_REMATCH[1]}"
        [ -s "$img" ] || cliphist decode "$id" > "$img" 2>/dev/null
    fi
    jq -cn --arg id "$id" --arg text "$preview" --arg img "$img" '{id: $id, text: $text, img: $img}'
done
# drop cached previews for entries that no longer exist
ls "$CACHE" 2>/dev/null | while read -r f; do cliphist list | grep -q "^${f%%.*}	" || rm -f "$CACHE/$f"; done &
