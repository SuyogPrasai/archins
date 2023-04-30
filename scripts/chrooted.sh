#! /usr/bin/env bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins

## Sourcing stuff
source ${CONFIG_FILE}
source ${COMMONRC}

## setting up time and locale
time_and_locale() {

    ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime # Sets local time
    hwclock --systohc

    sed -i '/^#\(en_US.UTF-8\)/s/#//' /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" >/etc/locale.conf
    info_msg "generated locales"
}

time_and_locale

do_install sudo wget libnewt

## Setting up hostname and network stuff
set_hostname() {
    hostname=$NAME_OF_MACHINE
    echo ${hostname} >>/etc/hostname
    echo -e "\n127.0.0.1   localhost\n::1     localhost\n127.0.1.1   ${hostname}.localdomain  ${hostname}\n" >>/etc/hosts
    info_msg "Finished setting up hostname and hosts"
}

set_hostname

## Setting up the sudoers file to give root access to the user
sudo_config() {

    sed -i 's/^# %wheel ALL=(ALL) ALL/%wheel ALL=(ALL) ALL/' /etc/sudoers
    sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers

    info_msg "Sudoers file configured"
}

sudo_config

## Installing and configuring Grub to the system
grub_config() {

    # Installing grub and other essentials
    do_install grub efibootmgr dosfstools os-prober mtools

    grub-install --target=x86_64-efi --bootloader-id=grub_uefi --efi-directory=/boot/EFI --recheck
    grub-mkconfig -o /boot/grub/grub.cfg

    info_msg "Grub installed on the system"
}

## Setting multilib repository in the system to access more software
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
pacman -Sy --noconfirm --needed

grub_config # Setting up grub in the system

## Network configuration in the system
network_config() {

    do_install "networkmanager"     # Installing NetworkManager
    systemctl enable NetworkManager # Enabling NetworkManager in system
}

network_config


## Installing Graphics Drivers
graphics_driver_setup() {

    gpu_type=$(lspci)
    if grep -E "NVIDIA|GeForce" <<<${gpu_type}; then
        pacman -S --noconfirm --needed nvidia
        nvidia-xconfig
    elif lspci | grep 'VGA' | grep -E "Radeon|AMD"; then
        pacman -S --noconfirm --needed xf86-video-amdgpu
    elif grep -E "Integrated Graphics Controller" <<<${gpu_type}; then
        pacman -S --noconfirm --needed libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    elif grep -E "Intel Corporation UHD" <<<${gpu_type}; then
        pacman -S --needed --noconfirm libva-intel-driver libvdpau-va-gl lib32-vulkan-intel vulkan-intel libva-intel-driver libva-utils lib32-mesa
    fi
}

graphics_driver_setup

## Installating microcode

# Determine processor type and install microcode
proc_type=$(lscpu)
if grep -E "GenuineIntel" <<<${proc_type}; then
    echo "Installing Intel microcode"
    pacman -S --noconfirm --needed intel-ucode
    proc_ucode=intel-ucode.img
elif grep -E "AuthenticAMD" <<<${proc_type}; then
    echo "Installing AMD microcode"
    pacman -S --noconfirm --needed amd-ucode
    proc_ucode=amd-ucode.img
fi

if [[ $INSTALL_TYPE == "MINIMAL" ]]; then
    exit
fi

## Setting up users and permissions

if [ $(whoami) = "root"  ]; then
    groupadd libvirt
    useradd -m -G wheel,libvirt -s /bin/bash $USERNAME 
    info_msg "$USERNAME created, home directory created, added to wheel and libvirt group, default shell set to /bin/bash"

# use chpasswd to enter root:$ROOT_PASSWORD
    echo "root:$ROOT_PASSWORD" | chpasswd # Setting up ROOT password
    info_msg "Password for ROOT is set"

# use chpasswd to enter $USERNAME:$password
    echo "$USERNAME:$PASSWORD" | chpasswd # Setting up user password
    info_msg "Password for $USERNAME is set"


	cp -R $HOME/archins /home/$USERNAME/
    chown -R $USERNAME: /home/$USERNAME/archins
    info_msg "archins copied to home directory"
    
else
	echo "You are already a user proceed with aur installs"
fi
