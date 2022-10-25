
time_and_locale(){

    ln -sf /usr/share/zoneinfo/$TIMEZONE  /etc/localtime # Sets local time
    hwclock --systohc

    sed -i '/^#\(en_US.UTF-8\|zh_CN.UTF-8\|zh_HK.UTF-8\|zh_TW.UTF-8\)/s/#//' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
}

time_and_locale

set_hostname() {
    hostname=$NAME_OF_MACHINE
    echo ${hostname} >> /etc/hostname
    echo -e "\n127.0.0.1   localhost\n::1     localhost\n127.0.1.1   ${hostname}.localdomain  ${hostname}\n" >> /etc/hosts
}

set_hostname

echo -e "$ROOT_PASSWORD\n$ROOT_PASSWORD" | passwd
useradd -m $USERNAME
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

network_config() {

    do_install "networkmanager"
    systemctl enable NetworkManager
}

exit