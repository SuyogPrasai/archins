#! /usr/bin/env bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for setting up the configuration file for installing arch linux
# file: setup.sh

## Source other function files
source $COMMONRC

## Setup and generate the configuration file
CONFIG_FILE=$CONFIGS_DIR/setup.conf
if [ ! -f $CONFIG_FILE ]; then # check if file exists or not
    touch -a $CONFIG_FILE      # create file if it does not exist
fi

## Function of setting option
## $1 ==> option name
## $2 ==> value name
set_option() {
    if grep -Eq "^${1}.*" $CONFIG_FILE; then # check if option exists
        sed -i -e "/^${1}.*/d" $CONFIG_FILE  # delete option if exists
    fi
    echo "${1}=${2}" >>$CONFIG_FILE # add option
}

## Function of setting password for a given user
## $1 ==> option to be printed in the user 
## $2 ==> option to be echoed to the config file
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

## Some bakground checks to see if the script is compatible with the system or not
UEFI_check() {
    # Verify the boot mode
    if [[ -d /sys/firmware/efi/efivars ]]; then
        cecho "UEFI check: OK!" $cyan
    else
        put_error "Sorry, this script only support UEFI mode for now"
        exit 0
    fi
}

## Checking root check if the script is not run as root
root_check() {
    if [[ "$(id -u)" != "0" ]]; then
        put_error "This script must be run under the 'root' user!\n"
        exit 0
    else
        cecho "Root Check: OK!" $cyan
    fi

}
## Checking if the distro is arch linux or not
arch_check() {
    if [[ ! -e /etc/arch-release ]]; then
        put_error "This script must be run in Arch Linux!\n"
        exit 0
    else
        cecho "Arch Check: OK!" $cyan
    fi
}
## Checks Pacman ( package manager ) is working properly
pacman_check() {
    if [[ -f /var/lib/pacman/db.lck ]]; then
        put_error "Pacman is blocked."
        put_error "If not running remove /var/lib/pacman/db.lck.\n"
        exit 0
    else
        cecho "Pacman Check: OK!" $cyan
    fi
}
## Checks the internet
internet_check() {
    ping -c 5 archlinux.org 2>&1 >/dev/null
    if [[ $? == 1 ]]; then
        put_error "No internet connection"
        put_error "Check your internet"
        exit 0
    else
        cecho "Internet Check: OK!" $cyan
    fi
}

## Does some background checks
background_checks() {
    UEFI_check
    root_check
    arch_check
    pacman_check
    internet_check
}

## NOTE Gather username and password to be used for installation
userinfo() {
    echo # formatting
    put_cutoff # formatting
    read -p "Please enter your username: " username
    set_option USERNAME ${username,,}
    set_password "PASSWORD" ${username,,}
    set_password "ROOT_PASSWORD" "ROOT"
    read -rep "Please enter your hostname: " nameofmachine
    set_option NAME_OF_MACHINE "${nameofmachine}"

}

## Selects the filesystem for the user
filesystem() {
    options=( "btrfs" "ext4" ) # File systems supported
    select_option "Select a filesystem from the following" "${options[@]}" 
    case $ans in # Case statement for setting right filesystem
    0) set_option FS ext4 ;; 
    1) set_option FS btrfs ;;
    esac
    local FS=${options[$ans]}
    info_msg "$FS selected as Filesystem"
}

## Sets timezone for the user
timezone() {
    time_zone="$(curl --fail -s https://ipapi.co/timezone)"
    options=( "Yes" "No" )
    select_option "System detected your timezone to be $time_zone. \nIs this correct?" "${options[@]}"
    case ${options[$ans]} in
    Yes)
        info_msg "$time_zone set as timezone."
        set_option TIMEZONE $time_zone
        ;;
    No)
        read -p "Please enter your desired timezone e.g. Europe/London: " new_timezone
        info_msg "${new_timezone} set as timezone"
        set_option TIMEZONE $new_timezone
        ;;
    esac
}

## Sets keymap for the user
keymap() {
    options=(us by ca cf cz de dk es et fa fi fr gr hu il it lt lv mk nl no pl ro ru sg ua uk)
    select_option "Please select a key board layout from this list" "${options[@]}"
    keymap=${options[${ans}]}
    info_msg "Your key board layout is set as: $keymap"
    set_option KEYMAP $keymap
}

## Selects the disk to install the system in
drivessd() {
    options=("Yes" "No")
    select_option "Is this an ssd?" "${options[@]}" # Asks if the device is an ssd or not
    option=${options[$ans]}
    case $option in
    Yes)
        set_option MOUNT_OPTIONS "noatime,compress=zstd,ssd,commit=120"
        set_option SSD "TRUE"
        info_msg "This drive is selected as an SSD"
        ;;
    No)
        set_option MOUNT_OPTIONS "noatime,compress=zstd,commit=120"
        set_option SSD "FALSE"
        info_msg "This drive is not selected as an SSD"
        ;;
    esac
}

## NOTE Disk selection for drive to be used with installtion
diskpart() {
    warn "
------------------------------------------------------------------------
    THIS WILL FORMAT AND DELETE ALL DATA ON THE DISK
    Please make sure you know what you are doing because
    after formatting your disk there is no way to get data back
------------------------------------------------------------------------
"
    options=($(lsblk -n --output TYPE,KNAME,SIZE | awk '$1=="disk"{print "/dev/"$2"|"$3}'))
    select_option "Select the disk to install on" "${options[@]}"
    disk=${options[$ans]%|*}
    info_msg "${disk%|*} is selected"
    set_option DISK ${disk%|*}
    
    drivessd
}

## Sets AUR helper
aurhelper() {
    options=(paru yay picaur aura trizen pacaur none) # All of  aur helpers that are supported
    select_option "Please enter your desired AUR helper" "${options[@]}"
    aur_helper=${options[$ans]}
    info_msg "$aur_helper selected as the aur_helper"
    set_option AUR_HELPER $aur_helper
}

## Sets desktop environment
desktopenv() {
    options=($(for f in pkglists/*.txt; do echo "$f" | sed -r "s/.+\/(.+)\..+/\1/;/pkgs/d"; done)) # Gets the names of files in pkglists
    select_option "Please select your desired Desktop Environment" "${options[@]}"
    desktop_env=${options[$ans]}
    info_msg "$desktop_env selected as desktop environment"
    set_option DESKTOP_ENV $desktop_env
}

## Sets installation type
## There are two different types of installation types supporte 
## FULL ==> installs all the components including my dotfiles and cutomizations
## MINIMAL ==> installs only base arch package
installType() {
    options=(FULL MINIMAL) 
    echo # formatting
    warn "Full install: Installs full featured desktop enviroment, with added apps \nand themes needed for everyday use\nMinimal Install: Installs only apps few selected apps to get you started"
    select_option "Please select type of installation" "${options[@]}"
    install_type=${options[$ans]}
    info_msg "Install type set as $install_type"
    set_option INSTALL_TYPE $install_type

}

# This feature brings alot of delay in the script
# ## Sets font for tui as the default one sucks
# fonts_setup() {
#     do_install "terminus-font" &>/dev/null
#     setfont ter-v22b
#     info_msg "Font is set"
# }

## Installs latest archlinux keyring as it prevents errors in installing latest packages
## This is important as without this packages cannot be installed in the system
archlinux_keyring_setup() {
    pacman -S --noconfirm archlinux-keyring &>/dev/null
    info_msg "Keyring updated"
}


## Installs packages required for the scripts
pkg_setup() {
    pacman -Syu
    archlinux_keyring_setup
    # fonts_setup
}

## Displays the configuaration file that was generated 
## Also asks for confirmation if the config is right
display_config() { # Displays the configuration file generated by the system
    options=("Yes" "No")
    cecho "This is the configuration file!" $bold
    put_cutoff # formatting
    cat ${CONFIG_FILE}
    put_cutoff # formatting
    select_option "Are you sure you want to continue?" "${options[@]}"
    case ${options[$ans]} in
    Yes)
        echo
        info_msg "Configuration completed!!!!"
        ;;
    No)
        exit 1
        ;;
    esac
}

## Main Program function sequence 
## Executes the right functions for installing the arch
## Also implements the feature of using a config file for installation

if [ -f ${CONFIG_FILE} ]; then
    warn "There's already a config file in the directory"
    echo
    cat ${CONFIG_FILE}
    echo
    answer=("Yes" "No")
    select_option "Do you want to use this file for the installation? [${CONFIG_FILE}]?" "${answer[@]}"
    case "${answer[$ans]}" in
        Yes)
            background_checks # Does some background checks
            clear
            display_config # Finally displays the config that is generated
            pkg_setup      # Sets up pkgs required for the install
            ;;
        No)
            background_checks # Does some background checks
            clear
            pkg_setup      # Sets up pkgs required for the install
            logo           # Sets up logo of the script
            userinfo       # Asks for user information
            filesystem     # Asks for the fs the user wants
            timezone       # Sets the timezone of the user
            keymap         # Sets the keympa of the user
            diskpart       # Selects the required disk for the partitio
            aurhelper      # Sets the aur helper
            desktopenv     # Sets the desktop environment
            installType    # Sets the install type
            display_config # Finally displays the config that is generated
            ;;
        *)
            echo "Invalid option: ${answer[$ans]}"
            ;;            
    esac
fi