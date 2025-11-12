#!/usr/bin/env bash
set -e

echo "Where do you want to install Pookie/Linux?"
fdisk -l
read -p "Enter target disk (e.g., /dev/sda): " DISK

if [ ! -b "$DISK" ]; then
  echo "Error: $DISK is not a valid block device."
  exit 1
fi

echo "Creating useful partitions on $DISK..."

sudo parted --script "$DISK" \
    mklabel gpt \
    mkpart primary fat32 1MiB 201MiB \
    set 1 boot on \
    name 1 boot \
    mkpart primary fat32 201MiB 501MiB \
    name 2 efi \
    mkpart primary linux-swap 501MiB 2501MiB \
    name 3 swap \
    mkpart primary ext4 2501MiB 32501MiB \
    name 4 root \
    mkpart primary ext4 32501MiB 100%

# Format partitions
sudo mkfs.fat -F32 "${DISK}1"   # /boot
sudo mkfs.fat -F32 "${DISK}2"   # /boot/efi
sudo mkswap "${DISK}3"          # swap
sudo mkfs.ext4 "${DISK}4"       # root

echo "Partitions created and formatted successfully."

# mount partitions
sudo mount "${DISK}4" /mnt
sudo mkdir -p /mnt/boot
sudo mount "${DISK}1" /mnt/boot
sudo mkdir -p /mnt/boot/efi
sudo mount "${DISK}2" /mnt/boot/efi
sudo swapon "${DISK}3"
echo "Partitions mounted successfully."

# set up archlinux mirrorlist
cat << EOF
## Worldwide
#Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
#Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
EOF > /etc/pacman.d/mirrorlist

# install base system

pacstrap -K /mnt base linux-zen linux-firmware

# generate fstab
genfstab -U /mnt >> /mnt/etc/fstab

echo "Base system installed and fstab generated."

cp ./scripts/chroot.sh /mnt/root

arch-chroot /mnt /bin/bash /root/chroot.sh
