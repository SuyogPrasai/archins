#! /usr/bin/env bash

# https://github.com/suyogprasai/archins
# GITHUB: https://github.com/suyogprasai
# @suyogprasai
# This is my custom Arch Linux installation script.

## NOTE Initializing script path variables

export SCRIPT_DIR=$PWD
export SCRIPTS_DIR=${SCRIPT_DIR}/scripts
export CONFIGS_DIR=${SCRIPT_DIR}/configs
export PKG_LISTS_DIR=${SCRIPT_DIR}/pkglists
export LOGS_DIR=${SCRIPT_DIR}/logs
export COMMONRC=${SCRIPTS_DIR}/utils/commonrc
export CONFIG_FILE=${CONFIGS_DIR}/setup.conf

echo "
VARIABLE INFORMATION:

SCRIPTS_DIR=${SCRIPTS_DIR}
CONFIGS_DIR=${CONFIGS_DIR}
PKG_LISTS_DIR=${PKG_LISTS_DIR}
LOGS_DIR=${LOGS_DIR}
COMMONRC=${COMMONRC}
CONFIG=${CONFIG_FILE}

"

## NOTE sourcing commonrc [Our config file]
source "$COMMONRC"
if [ ! -d "${LOGS_DIR}" ]; then
    mkdir "${LOGS_DIR}"
fi

chmod +x "${SCRIPTS_DIR}"/*.sh # So that we can directly execute a script later

arch_run() {

    (bash "${SCRIPTS_DIR}/setup.sh") |& tee "setup.sh"
    (bash "${SCRIPTS_DIR}/base.sh") |& tee "base.log"
    (arch-chroot /mnt "${HOME}"/archins/scripts/chrooted.sh) |& tee "chrooted.log"

    if [[ ${INSTALL_TYPE} == "MINIMAL" ]]; then
        shutdown now
    elif [[ ${INSTALL_TYPE} == "FULL" ]]; then
        # (su "${USERNAME}" -c "(bash ${SCRIPTS_DIR}/pkg_install.sh |& tee pkg_install.sh)")
        ( arch-chroot /mnt /usr/bin/runuser -u "$USERNAME" -- /home/"$USERNAME"/archins/scripts/pkg_install.sh ) |& tee "pkg_install.log"
        # (su "${USERNAME} -c (bash ${SCRIPTS_DIR}/configuration.sh |& tee configuration.sh)")
        # ( bash ${SCRIPTS_DIR}/user.sh ) |& tee user.sh
    fi
    co -v  *.log /mnt/home/"${USERNAME}"/archins/logs
}

## NOTE main script running function
arch_run
