#!/bin/bash
# Runs inside the Arch live ISO, driven by tools/vmware-test.ps1 from the Windows host.
# Wipes the VM's disk, installs a minimal Arch (like archinstall's "Minimal" profile),
# then runs Flirps OS's install.sh as the user, exactly as a person would after first login.
#
# Expects in /root: flirps-test.env (settings), flirps-pw ("user:password"), flirps.bundle (the repo).
set -euo pipefail
source /root/flirps-test.env   # USERNAME TIMEZONE KEYMAP LOCALE HOSTNAME REMOTE
exec > /root/flirps-test.log 2>&1

cleanup() {
    rc=$?
    rm -f /root/flirps-pw /mnt/etc/sudoers.d/99-flirps-test
    sync
    if [ "$rc" -eq 0 ]; then
        umount -R /mnt
        echo "FLIRPS_RESULT=ok"
    else
        echo "FLIRPS_RESULT=fail (exit $rc)"
    fi
}
trap cleanup EXIT
trap 'echo "!! failed at line $LINENO: $BASH_COMMAND"' ERR
step() { printf '\n### %s\n' "$*"; }

DISK=$(lsblk -dpno NAME,TYPE | awk '$2 == "disk" { print $1; exit }')
[ -n "$DISK" ] || { echo "no disk found"; exit 1; }

step "Partitioning $DISK (1 GB EFI + ext4 root)"
umount -R /mnt 2>/dev/null || true
wipefs -af "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1G -t1:ef00 -n2:0:0 -t2:8300 "$DISK"
partprobe "$DISK"
udevadm settle
EFI=$(lsblk -lpno NAME "$DISK" | sed -n 2p)
ROOT=$(lsblk -lpno NAME "$DISK" | sed -n 3p)
mkfs.fat -F32 "$EFI"
mkfs.ext4 -F -q "$ROOT"
mount "$ROOT" /mnt
mount --mkdir "$EFI" /mnt/boot

step "Installing a minimal Arch"
pacstrap -K /mnt base linux linux-firmware sudo nano networkmanager \
    pipewire pipewire-alsa pipewire-pulse wireplumber git
genfstab -U /mnt >> /mnt/etc/fstab

step "Configuring it"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /mnt/etc/localtime
sed -i "s/^#$LOCALE /$LOCALE /" /mnt/etc/locale.gen
echo "LANG=$LOCALE"    > /mnt/etc/locale.conf
echo "KEYMAP=$KEYMAP"  > /mnt/etc/vconsole.conf
echo "$HOSTNAME"       > /mnt/etc/hostname
arch-chroot /mnt locale-gen
arch-chroot /mnt hwclock --systohc
arch-chroot /mnt bootctl install
printf 'default arch.conf\ntimeout 3\n' > /mnt/boot/loader/loader.conf
cat > /mnt/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=UUID=$(blkid -s UUID -o value "$ROOT") rw
EOF
arch-chroot /mnt useradd -m -G wheel "$USERNAME"
arch-chroot /mnt chpasswd < /root/flirps-pw
rm -f /root/flirps-pw
echo '%wheel ALL=(ALL:ALL) ALL' > /mnt/etc/sudoers.d/10-wheel
chmod 440 /mnt/etc/sudoers.d/10-wheel
arch-chroot /mnt systemctl enable NetworkManager.service systemd-timesyncd.service

step "Copying in the Flirps OS repo"
cp /root/flirps.bundle /mnt/root/flirps.bundle
arch-chroot /mnt /bin/bash -euc "
    git clone -q -b flirps-vm-test /root/flirps.bundle /home/$USERNAME/flirps-os
    cd /home/$USERNAME/flirps-os
    git checkout -q -B main
    git branch -q -D flirps-vm-test
    git remote set-url origin '$REMOTE'
    git log --oneline -1
    chown -R $USERNAME:$USERNAME /home/$USERNAME/flirps-os
    rm /root/flirps.bundle
"

step "Adding the screenshot helper (test VMs only)"
# Lets vmware-test.ps1 switch on auto-login for the screenshot tour and off again,
# since nobody types the password at the login screen.
cat > /mnt/usr/local/bin/flirps-showcase <<'EOF'
#!/bin/bash
# Test-VM helper: "login" turns on SDDM auto-login and restarts SDDM, "logout" undoes it.
conf=/etc/sddm.conf.d/zz-flirps-showcase.conf
case "$1" in
    login)  printf '[Autologin]\nUser=%s\nSession=hyprland.desktop\n' "$SUDO_USER" > "$conf" ;;
    logout) rm -f "$conf" ;;
    *) echo "usage: flirps-showcase login|logout"; exit 1 ;;
esac
systemctl restart sddm.service
EOF
chmod 755 /mnt/usr/local/bin/flirps-showcase
echo "$USERNAME ALL=(root) NOPASSWD: /usr/local/bin/flirps-showcase" > /mnt/etc/sudoers.d/98-flirps-showcase
chmod 440 /mnt/etc/sudoers.d/98-flirps-showcase

step "Running install.sh as $USERNAME"
# Passwordless sudo only while the installer runs, so it needs no one at the keyboard.
echo "$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL" > /mnt/etc/sudoers.d/99-flirps-test
chmod 440 /mnt/etc/sudoers.d/99-flirps-test
arch-chroot /mnt su - "$USERNAME" -c 'cd ~/flirps-os && ./install.sh --no-reboot </dev/null'
