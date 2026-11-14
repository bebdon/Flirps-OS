#!/bin/bash
# Collects what's needed to debug the desktop session in the test VM.
# Run through vm-session.sh by tools/vmware-test.ps1; output goes to stdout.
section() { printf '\n===== %s =====\n' "$*"; }

section "session environment"
env | grep -E '^(XDG_|WAYLAND|HYPRLAND|DBUS|QT_|QS_)' | sort

section "processes"
pgrep -a -u "$(id -u)" | grep -Ev 'pgrep|vm-diagnose|vm-session' || true

section "runtime dir"
ls -la "$XDG_RUNTIME_DIR" "$XDG_RUNTIME_DIR/hypr" 2>&1

section "hyprland log (errors, warnings and last 60 lines)"
log="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/hyprland.log"
grep -iE 'err|warn|fail|crash' "$log" 2>&1 | tail -60
echo '--- tail ---'
tail -60 "$log" 2>&1

section "hyprctl"
hyprctl version 2>&1 | head -5
hyprctl monitors 2>&1
hyprctl layers 2>&1
hyprctl clients 2>&1 | head -40

section "quickshell"
qs list --all 2>&1
qs log -c panels 2>&1 | tail -80

section "hyprlock (from the lock screen shot)"
hyprctl layers 2>&1 | grep -i lock || echo "no lock surface"
tail -40 /tmp/hyprlock.log 2>&1

section "start a GL client by hand (kitty, 5 s)"
timeout 5 kitty --hold true 2>&1 | tail -20

section "user journal (last 80 lines)"
journalctl --user -b --no-pager 2>&1 | tail -80

section "system journal warnings (last 40 lines)"
journalctl -b -p warning --no-pager 2>&1 | tail -40

section "graphics"
ls -la /dev/dri 2>&1
grep -h . /sys/class/drm/card*/device/uevent 2>/dev/null | grep -i driver

section "hyprlock output (if the tour started it)"
cat /tmp/hyprlock.log 2>&1 | tail -30
