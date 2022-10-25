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
}

time_and_locale


# Setting up hostname and network stuff
set_hostname() {
    hostname=$NAME_OF_MACHINE
    echo ${hostname} >> /etc/hostname
    echo -e "\n127.0.0.1   localhost\n::1     localhost\n127.0.1.1   ${hostname}.localdomain  ${hostname}\n" >> /etc/hosts
}

set_hostname

useradd -m $USERNAME
echo "root:$ROOT_PASSWORD" | chpasswd
echo "$USERNAME:$PASSWORD" | chpasswd
usermod -aG wheel,audio,video,optical,storage $USERNAME

sudo_config() {

    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

}

sudo_config

grub_config() {

    # Installing grub and other essentials
    do_install grub efibootmgr dosfstools os-prober mtools

    grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg
}

grub_config

network_config() {

    do_install "networkmanager"
    systemctl enable NetworkManager
}

network_config
