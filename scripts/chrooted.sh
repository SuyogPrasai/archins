#! /bin/bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins

# setting up time and locale
time_and_locale(){

    ln -sf /usr/share/zoneinfo/$TIMEZONE  /etc/localtime # Sets local time
    hwclock --systohc

    sed -i '/^#\(en_US.UTF-8\|zh_CN.UTF-8\|zh_HK.UTF-8\|zh_TW.UTF-8\)/s/#//' /etc/locale.gen
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
echo -e "root:$ROOT_PASSWORD" | chpasswd
echo -e "$USERNAME:$PASSWORD" | chpasswd
echo $PASSWORD | passwd $USERNAME
usermod -aG wheel,audio,video,optical,storage $USERNAME

sudo_config() {

    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    # sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

}

sudo_config

grub_config() {

    do_install "grub efibootmgr dosfstools os-prober mtools"

    grub-install --target=x86_64-efi  --bootloader-id=grub_uefi --recheck
    grub-mkconfig -o /boot/grub/grub.cfg
}

grub_config

network_config() {

    do_install "networkmanager"
    systemctl enable NetworkManager
}

network_config
