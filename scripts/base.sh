#! /bin/bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for setting up the configuration file for installing arch linux
# file: base.sh

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

    echo $partition1
    echo $partition2
    partprobe ${DISK}

}

auto_partition # Automatically creates partition
