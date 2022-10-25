#! /usr/bin/env bash
#
# https://github.com/suyogprasai/archins
# GITHUB: https://github.com/suyogprasai
# @suyogprasai
#
# This my custom arch linux installation script.

# NOTE Initializing script path variables

export SCRIPT_DIR=$PWD
export SCRIPTS_DIR=$SCRIPT_DIR/scripts
export CONFIGS_DIR=$SCRIPT_DIR/configs
export PKG_LISTS_DIR=$SCRIPT_DIR/pkglists
export LOGS_DIR=$SCRIPT_DIR/logs
export COMMONRC=$SCRIPTS_DIR/utils/commonrc

echo  "
VARIABLE INFORMATION:

SCRIPTS_DIR=$SCRIPTS_DIR
CONFIGS_DIR=$CONFIGS_DIR
PKG_LISTS_DIR=$PKG_LISTS_DIR
LOGS_DIR=$LOGS_DIR
COMMONRC=$COMMONRC
"

# NOTE sourcing commonrc
source $COMMONRC
mkdir $LOGS_DIR
arch_run() {

    ( bash $SCRIPTS_DIR/setup.sh ) |& tee $LOGS_DIR/setup.sh
    ( bash $SCRIPTS_DIR/base.sh ) |& tee $LOGS_DIR/base.log
    ( arch-chroot $SCRIPTS_DIR/chrooted.sh ) |& tee $LOGS_DIR/chrooted.log
    # ( bash $SCRIPTS_DIR/user.sh ) |& tee $LOGS_DIR/user.sh

}

# NOTE main script running function
arch_run
