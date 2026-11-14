#!/bin/bash
# vm-session.sh <command> [args...]: run a command inside the user's running Hyprland session.
# Used by tools/vmware-test.ps1, whose guest commands otherwise start outside the session.
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
HYPRLAND_INSTANCE_SIGNATURE="$(ls -t "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1)"
WAYLAND_DISPLAY="$(cd "$XDG_RUNTIME_DIR" 2>/dev/null && ls -d wayland-? 2>/dev/null | head -1)"
export HYPRLAND_INSTANCE_SIGNATURE WAYLAND_DISPLAY
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
export PATH="$HOME/.local/bin:$PATH"
# The env lines Hyprland got from machine.lua (e.g. software rendering in VMs), so apps
# started from here behave like apps started from the desktop.
while IFS='|' read -r k v; do
    [ -n "$k" ] && export "$k=$v"
done < <(sed -n 's/^hl\.env("\([A-Za-z_]*\)", *"\([^"]*\)").*/\1|\2/p' \
    "$HOME/.config/hypr/config/env.lua" "$HOME/.config/hypr/config/machine.lua" 2>/dev/null)
cd "$HOME" || exit 1
"$@"
