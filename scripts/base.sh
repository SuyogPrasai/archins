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

# optimizing pacman
pacman_optimize

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

# Creating EFI Directory and mounting it

mkdir -p /mnt/boot/EFI
info_msg "Created /mnt/boot/EFI"
mount ${partition1} /mnt/boot
info_msg "mounted $partition1 to /mnt/boot"

# Installing base packages

pacstrap /mnt base base-devel linux linux-firmware vim nano sudo archlinux-keyring wget libnewt --noconfirm --needed
info_msg "Installed base packages"

# Copying script directory and mirrorlist to main system
cp -R ${SCRIPT_DIR} /mnt/root/archins
info_msg "Copying script directory to main system"
cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/mirrorlist
info_msg "Copying mirrorlist to main system"

# Generating file system table (FSTAB)
genfstab -L /mnt >> /mnt/etc/fstab
cat /mnt/etc/fstab
info_msg "Generated fstab"


# Creating linux swap file for systems that require it
linux_swap() {

    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[  $TOTAL_MEM -lt 8000000 ]]; then
        # Put swap into the actual system, not into RAM disk, otherwise there is no point in it, it'll cache RAM into RAM. So, /mnt/ everything.
        mkdir -p /mnt/opt/swap # make a dir that we can apply NOCOW to to make it btrfs-friendly.

        chattr +C /mnt/opt/swap # apply NOCOW, btrfs needs that.

        dd if=/dev/zero of=/mnt/opt/swap/swapfile bs=1M count=2048 status=progress

        chmod 600 /mnt/opt/swap/swapfile # set permissions.
        chown root /mnt/opt/swap/swapfile

        mkswap /mnt/opt/swap/swapfile
        swapon /mnt/opt/swap/swapfile

        # The line below is written to /mnt/ but doesn't contain /mnt/, since it's just / for the system itself.
        echo "/opt/swap/swapfile	none	swap	sw	0	0" >> /mnt/etc/fstab # Add swap to fstab, so it KEEPS working after installation.
        info_msg "Generated swap"
    fi

}

linux_swap
