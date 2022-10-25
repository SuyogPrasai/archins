#! /usr/bin/env bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins

# Sourcing stuff
source $CONFIGS_DIR/setup.conf
source $COMMONRC

# setting up time and locale
time_and_locale(){

    ln -sf /usr/share/zoneinfo/$TIMEZONE  /etc/localtime # Sets local time
    hwclock --systohc

    sed -i '/^#\(en_US.UTF-8\)/s/#//' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    info_msg "generated locales"
}

time_and_locale

do_install sudo wget libnewt
# Setting up hostname and network stuff
set_hostname() {
    hostname=$NAME_OF_MACHINE
    echo ${hostname} >> /etc/hostname
    echo -e "\n127.0.0.1   localhost\n::1     localhost\n127.0.1.1   ${hostname}.localdomain  ${hostname}\n" >> /etc/hosts
    info_msg "Finished setting up hostname and hosts"
}

set_hostname

useradd -m $USERNAME
echo "root:$ROOT_PASSWORD" | chpasswd
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG wheel,audio,video,optical,storage $USERNAME

sudo_config() {

    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

    info_msg "writeen in sudoers file"
}

sudo_config

# Creating EFI Directory and mounting it

 mkdir -p /boot/EFI
 info_msg "Created /mnt/boot/EFI"
 mount ${partition1} /boot/EFI
 info_msg "mounted $partition1 to /mnt/boot"


grub_config() {

    # Installing grub and other essentials
    do_install grub efibootmgr dosfstools os-prober mtools

    grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --efi-directory=/boot/EFI --recheck
    grub-mkconfig -o /boot/grub/grub.cfg
}

grub_config

network_config() {

    do_install "networkmanager"
    systemctl enable NetworkManager
}

network_config
