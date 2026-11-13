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
# Move aside real files, and symlinks pointing somewhere other than this repo, that would block stow.
for pkg in */; do
    while IFS= read -r -d '' f; do
        rel="${f#./}"; target="$HOME/$rel"
        if { [ -e "$target" ] && [ ! -L "$target" ]; } ||
           { [ -L "$target" ] && [[ "$(readlink -f "$target")" != "$REPO/"* ]]; }; then
            mkdir -p "$backup/$(dirname "$rel")"
            mv "$target" "$backup/$rel"
        fi
    done < <(cd "$pkg" && find . -type f -print0)
done
[ -d "$backup" ] && echo "Existing configs backed up to $backup"
stow --no-folding --restow -t "$HOME" */

say "Writing machine-specific files"
if [ -z "$SCALE" ]; then
    read -rp "Display scale (1 for most screens, 1.5-2 for HiDPI laptops) [1]: " SCALE || true
fi
SCALE="${SCALE:-1}"
[[ "$SCALE" =~ ^[0-9]+(\.[0-9]+)?$ ]] || die "scale must be a number, got '$SCALE'"
mkdir -p "$HOME/.config/hypr/config" "$HOME/.config/qt6ct"
rm -f "$HOME/.config/hypr/config/monitors.lua" "$HOME/.config/qt6ct/qt6ct.conf"   # never write through an old symlink
sed "s|@SCALE@|$SCALE|" "$REPO/templates/monitors.lua" > "$HOME/.config/hypr/config/monitors.lua"
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
