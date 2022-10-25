#! /bin/bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for setting up the configuration file for installing arch linux file: base.sh
# Sourcing commonrc
clear
source $SCRIPTS_DIR/utils/commonrc
source $CONFIGS_DIR/setup.conf
logo

# loading keympap
loadkeys $KEYMAP
info_msg "$KEYMAP keymap loaded"

# Setting time
timedatectl set-ntp true
timedatectl status
info_msg "Time is set"

# Partitoningn drives
auto_partition() {

    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[ $TOTAL_MEM -lt 8000000 ]]; then
        swap=TRUE
    fi

    partition_now() {
        local command="g\nn\n\n\n+550M\nn\n\n\n\nt\n1\n1\nw"
        echo -e $command | fdisk ${DISK}
    }

    # NOTE making /mnt direcotry if it does not exist
    mkdir /mnt &> /dev/null

    local pkgs=(gptfdisk glibc)
    do_install "${pkgs[@]}"

    info_msg "Formatting disk"
    umount -A --recursive /mnt # make sure everything is unmounted before we start

    partition_now # Create partitions

    if  [[ "${SSD}" == "TRUE" ]]; then
        export partition1=${DISK}p1
        export partition2=${DISK}p2
    else
        export partition1=${DISK}1
        export partition2=${DISK}2
    fi

    partprobe ${DISK}
    info_msg "partitions successfully made"

}

auto_partition # Automatically creates partition

# NOTE Making file systems

fs () {
    createsubvolumes () {
        btrfs subvolume create /mnt/@
        btrfs subvolume create /mnt/@home
        btrfs subvolume create /mnt/@var
        btrfs subvolume create /mnt/@tmp
        btrfs subvolume create /mnt/@.snapshots
    }

    # @description Mount all btrfs subvolumes after root has been mounted.
    mountallsubvol () {
        mount -o ${MOUNT_OPTIONS},subvol=@home ${partition3} /mnt/home
        mount -o ${MOUNT_OPTIONS},subvol=@tmp ${partition3} /mnt/tmp
        mount -o ${MOUNT_OPTIONS},subvol=@var ${partition3} /mnt/var
        mount -o ${MOUNT_OPTIONS},subvol=@.snapshots ${partition3} /mnt/.snapshots
    }

    # @description BTRFS subvolulme creation and mounting.
    subvolumesetup () {
        # create nonroot subvolumes
        createsubvolumes
        # unmount root to remount with subvolume
        umount /mnt
        # mount @ subvolume
        mount -o ${MOUNT_OPTIONS},subvol=@ ${partition3} /mnt
        # make directories home, .snapshots, var, tmp
        mkdir -p /mnt/{home,var,tmp,.snapshots}
        # mount subvolumes
        mountallsubvol
    }

    if [[ "${FS}" == "btrfs" ]]; then
        mkfs.fat -F32 ${partition1}
        mkfs.btrfs -L ROOT ${partition2} -f
        mount -t btrfs ${partition2} /mnt
        subvolumesetup
    elif [[ "${FS}" == "ext4" ]]; then
        mkfs.fat -F32 ${partition1}
        mkfs.ext4 -L ROOT ${partition2}
        mount -t ext4 ${partition2} /mnt
    fi

    info_msg "Successfully created filesystems"
}

fs # Making filesystems

mkdir -p /mnt/boot/EFI
mount ${parition1} /mnt/boot

# Installing base packages
pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
cp -R ${SCRIPT_DIR} /mnt/root/archins
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist

genfstab -L /mnt >> /mnt/etc/fstab
info_msg "Generated fstab"
cat /mnt/etc/fstab


# Chroot
arch-chroot /mnt


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

echo $ROOT_PASSWORD | passwd
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
