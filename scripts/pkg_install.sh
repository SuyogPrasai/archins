#! /usr/bin/env bash

# @suyogprasai
# https://github.com/suyogprasai/
# https://github.ocm/suyogprasai/archins
# Script for installing all the required packages in arch linux 


declare -a pkgs # Array declaration for installing packages

pkg_dir=$PKG_LISTS_DIR
default=${PKG_LISTS_DIR}/default

cli_pkg=${default}/d_cli.txt
gui_pkg=${default}/d_gui.txt
combined_pkg=${pkg_dir}/combined.txt
final_pkg=${pkg_dir}/final.txt

if [ ${INSTALL_TYPE} == "MINIMAL" ]
then 
    cat ${cli_pkg} >> ${combined_pkg}
elif [ ${INSTALL_TYPE} == "FULL" ]
then 
    cat ${cli_pkg} >> ${combined_pkg} 
    cat ${gui_pkg} >> ${combined_pkg}
    case $DESKTOP_ENV in 

        awesome)
            cat ${pkg_dir}/awesome.txt >> ${combined_pkg}
            ;;
        bspwm)
            cat ${pkg_dir}/bspwm.txt >> ${combined_pkg}
            ;;
         qtile)           
            cat ${pkg_dir}/qtile.txt >> ${combined_pkg}
            ;;
        xmonad)
            cat ${pkg_dir}/xmonad.txt >> ${combined_pkg}
            ;;
        *)
            ;;
        esac
fi
sed '/^\#/d;/^[[:space:]]*$/d' ${combined_pkg} > ${final_pkg}
rm ${combined_pkg}


while read -r line; 
do

    pkgs+=("$(echo "$line")")
done < ${final_pkg}

do_install "${pkgs[@]}"







