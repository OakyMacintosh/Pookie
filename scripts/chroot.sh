#!/usr/bin/env bash

set -e

# ask for timezone
echo "Enter your timezone (e.g., 'America/New_York'): "
read TIMEZONE
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

locale-gen

# ask for keymap
echo "Enter your keyboard layout (e.g., 'us', 'uk', 'de'): "
read KEYMAP
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# ask for hostname (default: pookie)
echo "Enter your hostname (default: pookie): "
read HOSTNAME
HOSTNAME=${HOSTNAME:-pookie}
echo "$HOSTNAME" > /etc/hostname

mkinitcpio -P

echo "Enter root password: "
passwd

# ask for UEFI or BIOS
echo "Is your system UEFI or BIOS? (Enter 'uefi' or 'bios'): "
read BOOT_MODE

if [ "$BOOT_MODE" == "uefi" ]; then
  echo "Installing GRUB for UEFI..."
  pacman -S --noconfirm grub efibootmgr
  grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=PookieLinux --recheck
elif [ "$BOOT_MODE" == "bios" ]; then
  echo "Installing GRUB for BIOS..."
  pacman -S --noconfirm grub
  grub-install --target=i386-pc /dev/sda
else
  echo "Invalid option. Please enter 'uefi' or 'bios'."
  exit 1
fi

# customization time!!

pacman -S --noconfirm networkmanager sudo vim git base-devel git
systemctl enable NetworkManager

git clone https://github.com/harishnkr/bsol.git /opt/bsol

cp -r ./bsol/bsol /boot/grub/themes/

# Change the GRUB_THEME line in /etc/default/grub
sed -i 's|^#GRUB_THEME=.*|GRUB_THEME="/boot/grub/themes/bsol/theme.txt"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

wget https://github.com/catppuccin/tty/raw/refs/heads/main/themes/macchiato.txt -O /etc/tty-theme.txt

# Edit /etc/default/grub and append the theme kernel options to GRUB_CMDLINE_LINUX (eg. GRUB_CMDLINE_LINUX="vt.default_red...")

sed -i 's|^GRUB_CMDLINE_LINUX="\(.*\)"|GRUB_CMDLINE_LINUX="\1 vt.default_red=175 vt.default_green=155 vt.default_blue=197 vt.theme=/etc/tty-theme.txt"|' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

echo "export PS1='\T(\u)\w\$'" >> /etc/bash.bashrc

git clone https://github.com/emscripten-core/emsdk.git
cd emsdk
./emsdk install latest
./emsdk activate latest
# echo add emsdk environment to bashrc
echo "source $(pwd)/emsdk_env.sh" >> /etc/bash.bashrc
cd ..

# install wasmer
curl https://get.wasmer.io -sSfL | sh
echo "export WASMER_DIR=/usr/local/lib/wasmer" >> /etc/bash.bashrc
echo "export PATH=\$WASMER_DIR/bin:\$PATH" >> /etc/bash

# install rust + wasi2 target
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
rustup target add wasm32-wasi
echo "export PATH=\$HOME/.cargo/bin:\$PATH" >> /etc/bash.bashrc

# change distro name to Pookie
sed -i 's|^ID=.*|ID=pookie|' /etc/os-release
sed -i 's|^NAME=.*|NAME="Pookie/Linux"|' /etc/os-release
sed -i 's|^PRETTY_NAME=.*|PRETTY_NAME="Pookie/Linux"|' /etc/os-release

# install yay
git clone https://aur.archlinux.org/yay-bin.git
cd yay-bin
makepkg -si --noconfirm
cd ..

echo "Pookie Linux version $(echo $POOKIEVERSION) installed successfully!"
echo "You can now reboot into your new Pookie/Linux installation."