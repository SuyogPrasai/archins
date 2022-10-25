#! /usr/bin/env bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for setting up the configuration file for installing arch linux
# file: setup.sh

# Source other function files
source $COMMONRC

# Setup and generate the configuration file
CONFIG_FILE=$CONFIGS_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists or not
    touch -f $CONFIG_FILE # create file if it does not exist
fi


set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

set_password() {

    put_cutoff
    echo
    cecho "Password for $2: " $yellow
    read -rs -p "Please enter password: " PASSWORD1
    echo -ne "\n"
    read -rs -p "Please re-enter password: " PASSWORD2
    echo -ne "\n"

    if [[ "$PASSWORD1" == "$PASSWORD2" ]]; then
        set_option "$1" "$PASSWORD1"
    else
        put_error "ERROR! Passwords do not match. \n"
        set_password $1 $2
    fi
    put_cutoff

}


# NOTE some bakground checks to see if the script is compatible with the system or not

UEFI_check() {
    # Verify the boot mode

    if [[ -d /sys/firmware/efi/efivars ]]; then
        cecho "UEFI mode is enabled on an UEFI motherboard" $cyan
    else
        put_error "Sorry, this script only support UEFI mode for now"
        exit -1
    fi

}

root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        put_error "This script must be run under the 'root' user!\n"
        exit 0
    fi
}


arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        put_error "This script must be run in Arch Linux!\n"
        exit 0
    fi
}

pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        put_error "Pacman is blocked."
        put_error "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    fi
}

internet_check() {

    ping -c 5 archlinux.org 2>&1 > /dev/null
    if [[ $? == 1 ]]; then
        put_error "No internet connection"
        put_error "Check your internet"
        exit 0
    fi

}

background_checks() {
    # UEFI_check
    root_check
    arch_check
    pacman_check
    internet_check
}



# NOTE Gather username and password to be used for installation
userinfo() {
    echo
    put_cutoff
    read -p "Please enter your username: " username
    set_option USERNAME ${username,,}
    set_password "PASSWORD" ${username,,}
    set_password "ROOT_PASSWORD" "ROOT"
    read -rep "Please enter your hostname: " nameofmachine
    set_option NAME_OF_MACHINE "$nameofmachine"

}

# Select filesystem
filesystem() {

    options=("ext4" "btrfs" "exit")
    select_option "Select a filesystem from the following" "${options[@]}"
    case $ans in
        0) set_option FS ext4;;
        1) set_option FS btrfs;;
        2) exit;;
    esac
    local FS=${options[$ans]}
    info_msg "$FS selected as Filesystem"
}

timezone() {

    time_zone="$(curl --fail -s https://ipapi.co/timezone)"

    options=(Yes No)
    select_option "System detected your timezone to be $time_zone. \nIs this correct?" "${options[@]}"
    case $ans in
        Y|y)
            echo "$time_zone set as timezone."
            set_option TIMEZONE $time_zone;;
        N|n)
            read -p "Please enter your desired timezone e.g. Europe/London: " new_timezone
            info_msg "${new_timezone} set as timezone"
            set_option TIMEZONE $new_timezone;;
    esac
}

keymap() {
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)
    select_option  "Please select a key board layout from this list" "${options[@]}"
    keymap=${options[$ans]}
    info_msg "Your key board layout is set as: $keymap"
    set_option KEYMAP $keymap

}

drivessd() {
    options=(Yes No)
    select_option "Is this an ssd?" "${options[@]}"
    option=${options[$ans]}
    case $option in
        Yes)
            set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120"
            set_option SSD "TRUE"
            info_msg "This drive is selected as an SSD";;
        No)
            set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120"
            set_option SSD "FALSE"
            info_msg "This drive is not selected as an SSD";;
    esac
}

# NOTE Disk selection for drive to be used with installtion
diskpart() {

    warn "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formating your disk there is no way to get data back
------------------------------------------------------------------------
"
    options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))
    select_option "Select the disk to install on" "${options[@]}"
    disk=${options[$ans]%|*}
    info_msg "${disk%|*} is selected"
    set_option DISK ${disk%|*}

    drivessd
}

aurhelper() {
    options=(paru yay picaur aura trizen pacaur none)
    select_option "Please enter your desired Desktop Environment"  "${options[@]}"
    aur_helper=${options[$ans]}
    info_msg "$aur_helper selected as the aur_helper"
    set_option AUR_HELPER $aur_helper
}

# Sets desktop environment
desktopenv() {

    options=( `for f in pkglists/*.txt; do echo "$f" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done` )
    select_option "Please select your desired Desktop Environment" "${options[@]}"
    desktop_env=${options[$ans]}
    info_msg "$desktop_env selected as desktop environment"
    set_option DESKTOP_ENV $desktop_env
}

# Installation type
installType() {
    options=(FULL MINIMAL)
    echo
    warn "Full install: Installs full featured desktop enviroment, with added apps \nand themes needed for everyday use\nMinimal Install: Installs only apps few selected apps to get you started"
    select_option "Please select type of installation" "${options[@]}"
    install_type=${options[$ans]}
    info_msg "Install type set as $install_type"
    set_option INSTALL_TYPE $install_type

}

# Sets font for tui as the default one sucks
fonts_setup() {
    do_install "terminus-font" &> /dev/null
    setfont ter-v22b
}

display_config() {
    options=(Yes No)
    cecho "This is the configuration file!" $bold
    put_cutoff
    cat $CONFIG_FILE
    put_cutoff
    select_option "Are you sure you want to continue?" "${options[@]}"
    case ${options[$ans]} in
        Yes)
            echo
            info_msg "Configuration completed!!!!";;

        No)
            exit;;
    esac
}



# NOTE Program function sequence
background_checks
clear
fonts_setup
logo
userinfo
filesystem
timezone
keymap
diskpart
aurhelper
desktopenv
installType
display_config
