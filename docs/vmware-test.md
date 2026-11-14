# Testing Flirps OS in VMware

A practice run on a clean machine, so you find out what breaks before it matters. There are two ways: one command that does everything, or by hand.

## The quick way: one command (Windows + VMware Workstation)

From the repo folder in PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File tools\vmware-test.ps1 -Timezone Europe/London -Keymap uk -Locale en_GB.UTF-8
```

It asks once for a password for the VM's user (`flirps`; use a test-only password), then takes 15–20 minutes:

1. **Creates the VM** `Flirps-Test` in *Documents\Virtual Machines* with UEFI, 3D acceleration, 8 GB RAM, 4 cores and a 40 GB disk (skipped if it already exists).
2. **Downloads the latest Arch ISO** and checks its SHA-256 (or pass `-Iso path\to\arch.iso`).
3. **Installs Arch** through VMware's guest tools, so there's no typing in the VM. It wipes the VM's disk and installs a minimal system like archinstall's *Minimal* profile.
4. **Copies in this checkout**, uncommitted changes included, and runs `./install.sh` as the user.
5. **Takes a snapshot** named after the commit (e.g. *Flirps installed (f0cd30b+changes)*) and boots it.
6. **Takes screenshots** into `docs/screenshots/`: the login screen, a tour of the desktop (terminal, launcher, dashboard, Quick Settings, wallpaper picker, power menu), and one "look" per wallpaper in `-Wallpapers` to show the recolor. The tour logs in automatically, then switches that off again. It also shows a neutral weather city, not wherever the VM's internet connection is.

The VM is left at the login screen; log in as `flirps` to look around.

| Option | What it does |
|---|---|
| `-Iso <file>` | Use this Arch ISO instead of downloading one |
| `-VmDir <folder>` | Where the VM lives (default *Documents\Virtual Machines\Flirps-Test*) |
| `-User <name>` | The VM user (default `flirps`) |
| `-Timezone`, `-Keymap`, `-Locale` | e.g. `Europe/London`, `uk`, `en_GB.UTF-8` (defaults: UTC, us, en_US) |
| `-MemoryMB`, `-Cpus`, `-DiskGB` | VM size for a new VM (8192, 4, 40) |
| `-Wallpapers a.jpg,b.jpg,...` | Wallpapers for the tour, one "look" screenshot each (file names in `wallpapers/`) |
| `-Resolution 1920x1080` | Screen size for the screenshots, so they don't depend on the VMware window (default 1920x1080) |
| `-NoScreenshots` | Install only |
| `-ScreenshotsOnly` | Only redo the screenshots on the existing VM. It first copies your changed files under `dotfiles/` into the VM and refreshes the VM tweaks from `install.sh`, so config edits show up without a reinstall |

Run it again any time: it reinstalls from scratch on the same VM, so every run tests a clean install.

**If something fails:** an install error saves the full log to `install-failed.log` in the VM folder. If the desktop doesn't come up, the session's logs (Hyprland, Quickshell, journal) are saved to `diagnostics.txt` there.

How it works: [`tools/vmware-test.ps1`](../tools/vmware-test.ps1) drives VMware's `vmrun`; [`tools/vm-guest-install.sh`](../tools/vm-guest-install.sh) runs inside the Arch live ISO; [`tools/vm-session.sh`](../tools/vm-session.sh) and [`tools/vm-diagnose.sh`](../tools/vm-diagnose.sh) run inside the desktop session. The live ISO's root account has no password, which is what lets the script in before Arch is installed.

## By hand

### 1. Make the virtual machine

Download the Arch ISO from <https://archlinux.org/download/>, then in VMware Workstation choose
**Create a New Virtual Machine → Typical → Installer disc image file (iso)**:

| Setting | Value |
|---|---|
| Guest OS | Linux → *Other Linux 6.x kernel 64-bit* |
| Disk | 40 GB (the wallpapers alone are ~250 MB) |
| Memory | 8 GB (4 GB minimum) |
| Processors | 4 cores |

Before starting it, open **Edit virtual machine settings**:

- **Display → Accelerate 3D graphics: ON** and graphics memory as high as it allows. *Hyprland won't start without this.*
- **Options → Advanced → Firmware type: UEFI**

### 2. Install Arch

Boot the VM. At the `root@archiso` prompt type `archinstall` and choose:

- **Disk configuration**: use the whole disk, ext4 or btrfs
- **Bootloader**: systemd-boot (or GRUB)
- **User account**: make a user and say **yes** to *superuser (sudo)*
- **Profile**: *Minimal* (Flirps OS brings its own desktop)
- **Audio**: Pipewire
- **Network configuration**: *Use NetworkManager*

Install, choose **reboot**, and log in as your user. Now is a good time for a snapshot (**VM → Snapshot → Take Snapshot**), so you can jump back to a fresh Arch and run the installer as often as you like.

### 3. Install Flirps OS

The repo is private, so log in to GitHub first:

```sh
sudo pacman -S --needed git github-cli
gh auth login                       # GitHub.com → HTTPS → login with a web browser (enter the code on your PC)
gh repo clone bebdon/Flirps-OS ~/flirps-os
cd ~/flirps-os
./install.sh
```

The installer notices it's inside a VM and handles that for you:

- sets scale to 1
- installs VMware's guest tools, so the screen resizes with the window
- makes apps draw in software: Hyprland can't use the GPU buffers VMware's virtual graphics give apps, so without this the bar, kitty and hyprlock never appear
- uses a software cursor, since the hardware one is invisible in VMs
- has the lock screen grab its blurred-screenshot background into normal memory, since Hyprland rejects the GPU buffer it would otherwise use (and hyprlock crashes)
- turns blur down and shadows off, so it stays smooth

It reboots on its own when it finishes (press any key during the countdown to stay put).

### 4. What to check

- [ ] The login screen shows the Flirps theme
- [ ] Hyprland starts, and the bar and desktop widgets appear
- [ ] SUPER+W: pick a wallpaper, and everything recolors (bar, kitty, lock screen)
- [ ] Notifications: `notify-send hello`
- [ ] Volume popup, Quick Settings (Wi-Fi shows the VM's wired network)
- [ ] Launcher, settings app, power menu, lock screen (hyprlock)
- [ ] Waterfox opens (SUPER+F)

Write down anything that's broken, missing or ugly. Those are the installer bugs.

**Expected in a VM and not bugs:** no Bluetooth, no brightness control, less blur than on real hardware, and slower animations (apps draw in software).

### If Hyprland shows a black screen or won't start

Press Ctrl+Alt+F3 to get a text login and check:

- Is *Accelerate 3D graphics* on? (shut the VM down to change it)
- Log in there and type `Hyprland`. The error it prints says why it won't start.
