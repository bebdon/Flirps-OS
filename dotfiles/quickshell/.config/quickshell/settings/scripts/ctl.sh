#!/usr/bin/env bash
# Backend for the Quickshell settings app.
#   ctl.sh state                   -> prints all current values as JSON
#   ctl.sh set <section> <key> <v> -> edits the real config file and reloads
set -u

HYPR=~/.config/hypr/config/settings.lua
MON=~/.config/hypr/config/monitors.lua
AUTO=~/.config/hypr/config/autostart.lua
BAR=~/.config/quickshell/panels/bar.json
NOTIF=~/.config/quickshell/panels/notifications.json
IDLE=~/.config/hypr/hypridle.conf
NIGHT=~/.local/bin/nightlight
WALLCONF=~/.config/wallpaper.conf
DOCK=~/.config/quickshell/panels/dock.json

# ---- helpers -------------------------------------------------------------

# Read "key = value," inside a named Lua table block (innermost), e.g. blur.size
lua_get() { # block key file
    B="$1" K="$2" perl -ne '
        if (/^\s*(\w+)\s*=\s*\{\s*$/) { push @s, $1; next }
        if (/^\s*\}/) { pop @s; next }
        if (($s[-1] // "") eq $ENV{B} && /^\s*\Q$ENV{K}\E\s*=\s*([^,]+),/) { $v = $1; $v =~ s/"//g; print $v; exit }
    ' "$3"
}

lua_set() { # block key value file   (value is written verbatim)
    B="$1" K="$2" V="$3" perl -pi -e '
        if (/^\s*(\w+)\s*=\s*\{\s*$/) { push @s, $1 }
        elsif (/^\s*\}/) { pop @s }
        elsif (($s[-1] // "") eq $ENV{B}) { s/^(\s*\Q$ENV{K}\E\s*=\s*)[^,]+,/$1$ENV{V},/ }
    ' "$4"
}

json_set() { # file jq-filter [args...]
    local f="$1"; shift
    local tmp; tmp=$(mktemp)
    jq "$@" "$f" > "$tmp" && cat "$tmp" > "$f"
    rm -f "$tmp"
}


idle_get() { # dim|lock|dpms|suspend
    awk -v want="$1" '
        /^# Dim/ {s="dim"} /^# Lock/ {s="lock"} /^# Screen off/ {s="dpms"} /^# Suspend/ {s="suspend"}
        /timeout *=/ && s == want { gsub(/[^0-9]/, "", $0); print; exit }
    ' "$IDLE"
}

restart() { # process-name command...
    pkill -x "$1"
    shift
    sleep 0.3
    setsid -f "$@" >/dev/null 2>&1 </dev/null
}

# Animation preset: off | fast | normal | relaxed (ANIM_ON / ANIM_SPEED in settings.lua)
anim_get() {
    grep -q "^local ANIM_ON = false" "$HYPR" && { echo off; return; }
    case "$(grep -m1 -oP "^local ANIM_SPEED = \K[0-9.]+" "$HYPR")" in
        0.6) echo fast ;; 1.4) echo relaxed ;; *) echo normal ;;
    esac
}
anim_set() {
    local on=true speed=1.0
    case "$1" in off) on=false ;; fast) speed=0.6 ;; relaxed) speed=1.4 ;; esac
    sed -i -E "s/^local ANIM_ON = (true|false)/local ANIM_ON = $on/; s/^local ANIM_SPEED = [0-9.]+/local ANIM_SPEED = $speed/" "$HYPR"
}

# Set one KEY=value in ~/.config/wallpaper.conf, keeping the other keys.
conf_set() {
    touch "$WALLCONF"
    if grep -q "^$1=" "$WALLCONF"; then sed -i "s|^$1=.*|$1=$2|" "$WALLCONF"; else echo "$1=$2" >> "$WALLCONF"; fi
}
conf_get() { local v; v=$(grep -m1 "^$1=" "$WALLCONF" 2>/dev/null | cut -d= -f2-); echo "${v:-$2}"; }

# ---- state ---------------------------------------------------------------

state() {
    local scheme=scheme-tonal-spot mode=dark
    [ -f "$WALLCONF" ] && . "$WALLCONF" && scheme=${SCHEME:-$scheme} && mode=${MODE:-$mode}
    local nl=false; pgrep -x hyprsunset >/dev/null && nl=true
    local dnd; dnd=$(qs -c panels ipc call notifications getDnd 2>/dev/null); [ "$dnd" = true ] || dnd=false

    jq -n \
      --arg wall "$(cat ~/.cache/wallpaper/current 2>/dev/null)" \
      --arg scheme "$scheme" --arg mode "$mode" \
      --arg rotate "$(conf_get ROTATE off)" --argjson rotate_min "$(conf_get ROTATE_MIN 30)" \
      --arg rotate_order "$(conf_get ROTATE_ORDER random)" --arg rotate_pool "$(conf_get ROTATE_POOL all)" \
      --argjson gaps_in "$(lua_get general gaps_in "$HYPR")" \
      --argjson gaps_out "$(lua_get general gaps_out "$HYPR")" \
      --argjson border_size "$(lua_get general border_size "$HYPR")" \
      --argjson rounding "$(lua_get decoration rounding "$HYPR")" \
      --argjson active_opacity "$(lua_get decoration active_opacity "$HYPR")" \
      --argjson inactive_opacity "$(lua_get decoration inactive_opacity "$HYPR")" \
      --argjson blur "$(lua_get blur enabled "$HYPR")" \
      --argjson blur_size "$(lua_get blur size "$HYPR")" \
      --argjson blur_passes "$(lua_get blur passes "$HYPR")" \
      --argjson shadow "$(lua_get shadow enabled "$HYPR")" \
      --argjson natural_scroll "$(lua_get touchpad natural_scroll "$HYPR")" \
      --arg accel "$(lua_get input accel_profile "$HYPR")" \
      --arg anim "$(anim_get)" \
      --argjson scale "$(grep -m1 -oP 'scale = \K[0-9.]+' "$MON")" \
      --argjson nl "$nl" \
      --argjson nl_temp "$(grep -m1 -oP '^TEMP=\K[0-9]+' "$NIGHT")" \
      --arg power "$(powerprofilesctl get 2>/dev/null)" \
      --slurpfile notif "$NOTIF" \
      --argjson dnd "$dnd" \
      --slurpfile bar "$BAR" \
      --slurpfile dock "$DOCK" \
      --argjson idle_dim "$(idle_get dim)" --argjson idle_lock "$(idle_get lock)" \
      --argjson idle_dpms "$(idle_get dpms)" --argjson idle_suspend "$(idle_get suspend)" \
      --argjson idle_running "$(pgrep -x hypridle >/dev/null && echo true || echo false)" \
      '{
        wallpaper: { current: $wall, scheme: $scheme, mode: $mode,
                     rotate: ($rotate == "on"), rotate_min: $rotate_min, rotate_order: $rotate_order, rotate_pool: $rotate_pool },
        hypr: { gaps_in: $gaps_in, gaps_out: $gaps_out, border_size: $border_size, rounding: $rounding,
                active_opacity: $active_opacity, inactive_opacity: $inactive_opacity,
                blur: $blur, blur_size: $blur_size, blur_passes: $blur_passes, shadow: $shadow,
                natural_scroll: $natural_scroll, accel: $accel, anim: $anim },
        display: { scale: $scale, nightlight: $nl, nightlight_temp: $nl_temp, power: $power },
        bar: { position: $bar[0].position, height: $bar[0].height, margin: $bar[0].margin },
        dock: { mode: $dock[0].mode, size: $dock[0].size, position: $dock[0].position },
        notif: { x: $notif[0].x, y: $notif[0].y, timeout: $notif[0].timeout,
                 width: $notif[0].width, sound: $notif[0].sound, dnd: $dnd },
        idle: { enabled: $idle_running, dim: $idle_dim, lock: $idle_lock, dpms: $idle_dpms, suspend: $idle_suspend }
      }'
}

# ---- setters -------------------------------------------------------------

set_hypr() {
    local k="$1" v="$2"
    case "$k" in
        gaps_in|gaps_out|border_size) lua_set general "$k" "$v" "$HYPR" ;;
        rounding|active_opacity|inactive_opacity) lua_set decoration "$k" "$v" "$HYPR" ;;
        blur) lua_set blur enabled "$v" "$HYPR" ;;
        blur_size) lua_set blur size "$v" "$HYPR" ;;
        blur_passes) lua_set blur passes "$v" "$HYPR" ;;
        shadow) lua_set shadow enabled "$v" "$HYPR" ;;
        natural_scroll) lua_set touchpad natural_scroll "$v" "$HYPR" ;;
        accel) lua_set input accel_profile "\"$v\"" "$HYPR" ;;
        anim) anim_set "$v" ;;
        *) echo "unknown hypr key $k" >&2; return 1 ;;
    esac
    hyprctl reload >/dev/null
}

set_display() {
    local k="$1" v="$2"
    case "$k" in
        scale) perl -pi -e "s/(scale = )[0-9.]+/\${1}$v/" "$MON"; hyprctl reload >/dev/null ;;
        nightlight)
            if [ "$v" = true ] && ! pgrep -x hyprsunset >/dev/null; then "$NIGHT" toggle
            elif [ "$v" = false ] && pgrep -x hyprsunset >/dev/null; then "$NIGHT" toggle; fi ;;
        nightlight_temp)
            sed -i "s/^TEMP=[0-9]*/TEMP=$v/" "$NIGHT"
            pgrep -x hyprsunset >/dev/null && restart hyprsunset hyprsunset -t "$v" ;;
        power) powerprofilesctl set "$v" ;;
    esac
}

set_bar() {
    local k="$1" v="$2"
    case "$k" in
        position) json_set "$BAR" --arg v "$v" '.position = $v' ;;
        height)   json_set "$BAR" --argjson v "$v" '.height = $v' ;;
        margin)   json_set "$BAR" --argjson v "$v" '.margin = $v' ;;
    esac
    # quickshell watches bar.json, nothing to reload
}

set_dock() {
    local k="$1" v="$2"
    case "$k" in
        mode)     json_set "$DOCK" --arg v "$v" '.mode = $v' ;;
        size)     json_set "$DOCK" --argjson v "$v" '.size = $v' ;;
        position) json_set "$DOCK" --arg v "$v" '.position = $v' ;;
    esac
    # quickshell watches dock.json, nothing to reload
}

set_notif() {
    local k="$1" v="$2"
    case "$k" in
        x) json_set "$NOTIF" --arg v "$v" '.x = $v' ;;
        y) json_set "$NOTIF" --arg v "$v" '.y = $v' ;;
        timeout) json_set "$NOTIF" --argjson v "$v" '.timeout = $v' ;;
        width) json_set "$NOTIF" --argjson v "$v" '.width = $v' ;;
        sound) json_set "$NOTIF" --argjson v "$v" '.sound = $v' ;;
        dnd) qs -c panels ipc call notifications setDnd "$v" >/dev/null 2>&1 ;;
    esac
    # quickshell watches notifications.json, nothing to reload
}

set_idle() {
    local k="$1" v="$2"
    case "$k" in
        enabled) if [ "$v" = true ]; then pgrep -x hypridle >/dev/null || setsid -f hypridle >/dev/null 2>&1; else pkill -x hypridle; fi; return ;;
        dim|lock|dpms|suspend)
            local tmp; tmp=$(mktemp)
            awk -v want="$k" -v val="$v" '
                /^# Dim/ {s="dim"} /^# Lock/ {s="lock"} /^# Screen off/ {s="dpms"} /^# Suspend/ {s="suspend"}
                /timeout *=/ && s == want { sub(/[0-9]+/, val); s="" }
                { print }' "$IDLE" > "$tmp" && cat "$tmp" > "$IDLE"
            rm -f "$tmp" ;;
    esac
    pgrep -x hypridle >/dev/null && restart hypridle hypridle
}

set_wallpaper() {
    local k="$1" v="$2"
    case "$k" in
        file) ~/.local/bin/wallpaper set "$v" ;;
        random) ~/.local/bin/wallpaper random ;;
        scheme) conf_set SCHEME "$v"; ~/.local/bin/wallpaper set "$(cat ~/.cache/wallpaper/current)" ;;
        mode)   conf_set MODE "$v";   ~/.local/bin/wallpaper set "$(cat ~/.cache/wallpaper/current)" ;;
        rotate) [ "$v" = true ] && conf_set ROTATE on || conf_set ROTATE off ;;
        rotate_min)   conf_set ROTATE_MIN "$v" ;;
        rotate_order) conf_set ROTATE_ORDER "$v" ;;
        rotate_pool)  conf_set ROTATE_POOL "$v" ;;
        rotate_now)   ~/.local/bin/wallpaper rotate ;;
    esac
}

case "${1:-}" in
    state) state ;;
    set)   "set_$2" "$3" "$4" ;;
    *)     echo "usage: ctl.sh state | set <section> <key> <value>" >&2; exit 1 ;;
esac
