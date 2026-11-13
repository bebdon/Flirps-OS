#!/usr/bin/env bash
# Flirps OS installer: turns a fresh Arch install into the Flirps OS desktop.
# Usage: ./install.sh [--no-aur] [--no-sddm] [--scale N]
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AUR=1 SDDM=1 SCALE=""
while [ $# -gt 0 ]; do
    case "$1" in
        --no-aur)  AUR=0 ;;
        --no-sddm) SDDM=0 ;;
        --scale)   SCALE="$2"; shift ;;
        -h|--help) sed -n '2,3p' "$0"; exit 0 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
    esac
    shift
done

say()  { printf '\n\033[1;35m==>\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31merror:\033[0m %s\n' "$*" >&2; exit 1; }
pkgs() { grep -vE '^\s*(#|$)' "$1"; }

[ -f /etc/arch-release ] || die "Flirps OS needs Arch Linux."
[ "$EUID" -ne 0 ]        || die "Run as your normal user, not root (sudo is used when needed)."
command -v sudo >/dev/null || die "sudo is required."

say "Installing packages"
sudo pacman -Syu --needed --noconfirm $(pkgs "$REPO/packages/pacman.txt")

if [ "$AUR" = 1 ]; then
    if ! command -v paru >/dev/null; then
        say "Installing paru (AUR helper)"
        tmp=$(mktemp -d)
        git clone --depth 1 https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin"
        (cd "$tmp/paru-bin" && makepkg -si --noconfirm)
        rm -rf "$tmp"
    fi
    say "Installing AUR packages"
    paru -S --needed --noconfirm $(pkgs "$REPO/packages/aur.txt")
fi

say "Linking configs into $HOME"
cd "$REPO/dotfiles"
backup="$HOME/.flirps-backup/$(date +%Y%m%d-%H%M%S)"
# Stow links whole folders (~/.config/hypr -> repo), so config edits made by the
# settings app land in the repo. Shared folders like ~/.config are entered instead.
is_shared() { case "$1" in .config|.local|.local/bin|.local/share) return 0 ;; esac; return 1; }

# Move aside anything that would block stow: real files/folders, or links to somewhere else.
clear_target() { # path relative to the package root
    local rel="$1" target="$HOME/$1"
    if is_shared "$rel"; then
        local child
        for child in "$pkgdir/$rel"/* "$pkgdir/$rel"/.[!.]*; do
            if [ -e "$child" ]; then clear_target "$rel/${child##*/}"; fi
        done
        return 0
    fi
    if [ -L "$target" ]; then
        if [[ "$(readlink -f "$target")" == "$REPO/"* ]]; then return 0; fi
    elif [ ! -e "$target" ]; then
        return 0
    fi
    mkdir -p "$backup/$(dirname "$rel")"
    mv "$target" "$backup/$rel"
}
for pkg in */; do
    pkgdir="$REPO/dotfiles/${pkg%/}"
    for entry in "$pkgdir"/* "$pkgdir"/.[!.]*; do
        if [ -e "$entry" ]; then clear_target "${entry##*/}"; fi
    done
done
if [ -d "$backup" ]; then echo "Existing configs backed up to $backup"; fi
# Remove links left behind by config folders a newer Flirps OS no longer ships.
find "$HOME/.config" "$HOME/.local/bin" -maxdepth 1 -xtype l 2>/dev/null | while IFS= read -r l; do
    case "$(readlink -m "$l")" in "$REPO"/*) rm -f "$l" ;; esac
done
# Shared folders must exist as real folders, or stow would link them wholesale into the repo.
mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.local/share"
stow --restow -t "$HOME" */

say "Writing machine-specific files"
# These land inside the linked repo folders and are gitignored (they differ per machine).
# An existing monitors.lua is kept unless --scale is passed, so re-running the
# installer doesn't undo changes made in the settings app.
MON="$HOME/.config/hypr/config/monitors.lua"
if [ -n "$SCALE" ] || [ ! -f "$MON" ]; then
    if [ -z "$SCALE" ]; then
        read -rp "Display scale (1 for most screens, 1.5-2 for HiDPI laptops) [1]: " SCALE || true
    fi
    SCALE="${SCALE:-1}"
    [[ "$SCALE" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "scale must be a number, got '$SCALE'"
    sed "s|@SCALE@|$SCALE|" "$REPO/templates/monitors.lua" > "$MON"
fi
sed "s|@HOME@|$HOME|"   "$REPO/templates/qt6ct.conf"   > "$HOME/.config/qt6ct/qt6ct.conf"

xdg-user-dirs-update
mkdir -p "$HOME/Pictures/Wallpapers"

if [ "$SDDM" = 1 ]; then
    say "Setting up the login screen"
    sudo cp -r "$REPO/system/sddm/themes/hyprlock-match" /usr/share/sddm/themes/
    sudo chown -R "$USER:" /usr/share/sddm/themes/hyprlock-match   # sddm-sync updates it on wallpaper change
    sudo install -Dm644 "$REPO/system/sddm.conf.d/10-theme.conf" /etc/sddm.conf.d/10-theme.conf
    sudo systemctl enable sddm.service
fi

say "Enabling services"
sudo systemctl enable NetworkManager.service bluetooth.service power-profiles-daemon.service

say "Done!"
cat <<MSG
Next steps:
  1. Put some wallpapers in ~/Pictures/Wallpapers
  2. Reboot (or log out and pick Hyprland)
  3. Pick a wallpaper and the whole theme recolors to match it
MSG
