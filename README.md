# Flirps OS

> Arch · Hyprland · Quickshell

A Hyprland desktop for Arch Linux whose colors follow your wallpaper. Pick a wallpaper and the bar, panels, terminal, launcher, lock screen and login screen all recolor to match it (via [matugen](https://github.com/InioX/matugen)).

## Install

Start from a fresh, minimal Arch install with a normal user that has `sudo`, then:

```sh
git clone https://github.com/bebdon/Flirps-OS.git ~/flirps-os
cd ~/flirps-os
./install.sh
```

Reboot and pick a wallpaper (SUPER+W).

| Option | What it does |
|---|---|
| `--scale 1.6` | Display scale (asked interactively if omitted) |
| `--no-aur` | Skip AUR packages (the Waterfox browser) |
| `--no-sddm` | Don't set up the SDDM login screen |

Existing configs that would be overwritten are moved to `~/.flirps-backup/<date>/` first.

To try it in a virtual machine first, see [docs/vmware-test.md](docs/vmware-test.md).

## What's inside

| Part | Used for |
|---|---|
| Hyprland | Window manager (Lua config in `dotfiles/hypr`) |
| Quickshell | The whole desktop shell: bar, dock, notifications, volume/brightness popups, quick settings (Wi-Fi, Bluetooth, sound), launcher, dashboard, media, clipboard, notes, calculator, wallpapers, power menu, admin-password dialog, settings app |
| kitty, Thunar | Terminal, file manager |
| hyprlock, hypridle, SDDM | Lock screen, idle handling, matching login screen |

## Layout

```
install.sh          the installer
packages/           pacman.txt and aur.txt
dotfiles/           GNU Stow packages, linked into $HOME
templates/          per-machine files the installer generates (monitor scale, qt6ct path)
system/             SDDM login theme and config, copied into /usr/share and /etc
```

Configs are symlinked, so editing `~/.config/...` edits this repo. Commit and push to share changes.
