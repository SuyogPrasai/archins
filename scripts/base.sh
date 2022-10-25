#! /bin/bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for setting up the configuration file for installing arch linux
# file: base.sh

# Sourcing commonrc
clear
source $SCRIPTS_DIR/utils/commonrc
source $CONFIGS_DIR/setup.sh
logo

# loading keympap
loadkeys $KEYMAP
info_msg "$KEYMAP keymap loaded"

# Setting time
timedatectl set-ntp true
timedatectl status

# Partitoningn drives
auto_partiton() {

    TOTAL_MEM=$(cat /proc/meminfo | grep -i 'memtotal' | grep -o '[[:digit:]]*')
    if [[ $TOTAL_MEM -lt 8000000 ]]; then
        swap=TRUE
    fi

    partiton_now() {
           local command="g\nn\n\n\n+550M\nn\n\n\n\nt\n1\n1\nw"
           echo -e $command | fdisk ${DISK}
    }

    # NOTE making /mnt direcotry if it does not exist
    mkdir /mnt &> /dev/null

    local pkgs=(gptfdisk glibc)
    do_install "${pkgs[@]}"

    info_msg "Formatting disk"
    unmount -A --recursive /mnt # make sure everything is unmounted before we start

    partition_now # Create partitions

    if  [ "${DISK}" == "nvme" ]; then
        partition1=${DISK}p1
        partition2=${DISK}p2
    else
        parition1=${DISK}1
        parition2=${DISK}2
    fi

    partprobe ${DISK}

}
