# Testing Flirps OS in VMware

A practice run on a clean machine, so you find out what breaks before it matters.

## 1. Make the virtual machine

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

## 2. Install Arch

Boot the VM. At the `root@archiso` prompt type `archinstall` and choose:

- **Disk configuration**: use the whole disk, ext4 or btrfs
- **Bootloader**: systemd-boot (or GRUB)
- **User account**: make a user and say **yes** to *superuser (sudo)*
- **Profile**: *Minimal* (Flirps OS brings its own desktop)
- **Audio**: Pipewire
- **Network configuration**: *Use NetworkManager*

Install, choose **reboot**, and log in as your user.

## 3. Install Flirps OS

The repo is private, so log in to GitHub first:

```sh
sudo pacman -S --needed git github-cli
gh auth login                       # GitHub.com → HTTPS → login with a web browser (enter the code on your PC)
gh repo clone bebdon/Flirps-OS ~/flirps-os
cd ~/flirps-os
./install.sh
```

The installer notices it's inside VMware and handles the VM side for you:

- sets scale to 1
- installs VMware's guest tools, so the screen resizes with the window
- uses a software cursor, since the hardware one is invisible in VMs
- turns blur down and shadows off, so it stays smooth

Then `reboot`.

## 4. What to check

- [ ] The login screen shows the Flirps theme
- [ ] Hyprland starts, and the bar and dock appear
- [ ] SUPER+W: pick a wallpaper, and everything recolors (bar, kitty, lock screen)
- [ ] Notifications: `notify-send hello`
- [ ] Volume popup, Quick Settings (Wi-Fi shows the VM's wired network)
- [ ] Launcher, settings app, power menu, lock screen (hyprlock)
- [ ] Waterfox opens (SUPER+F)

Write down anything that's broken, missing or ugly. Those are the installer bugs.

**Expected in a VM and not bugs:** no Bluetooth, no brightness control, and less blur than on the laptop.

## If Hyprland shows a black screen or won't start

Press Ctrl+Alt+F3 to get a text login and check:

- Is *Accelerate 3D graphics* on? (shut the VM down to change it)
- Log in there and type `Hyprland`. The error it prints says why it won't start.

## Tip: snapshots

Take a VMware snapshot right after step 2 (**VM → Snapshot → Take Snapshot**). You can then jump back to a fresh Arch and run the installer again as often as you like.
