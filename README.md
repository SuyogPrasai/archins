## This script is still in development and is not complete so please wait until further notice
# ARCHINS

## This script installs my basic arch linux

This repository contains my arch linux installation script that fully installs my arch environment and setup with my configs and packages. This makes my arch environment portable and it is very userful for future installs. This script may be useful for you guys as well.

* Installs base Arch linux
* Fast and optimized script 
* Install multiple packages 
* Very customizable 
* With my configurations

## Create Arch ISO or Use Image

Download ArchISO from <https://archlinux.org/download/> and put on a USB drive with [Etcher](https://www.balena.io/etcher/), [Ventoy](https://www.ventoy.net/en/index.html), or [Rufus](https://rufus.ie/en/)

## Boot Arch ISO

From initial Prompt type the following commands:

```
sudo pacman -Syy git
git clone https://github.com/suyogprasai/archins
cd archins
chmod +x install.sh
./install.sh
```

#### You will be given a prompt to select the section of the script. If so please select the first part (livecd part).


## After the first part (livecd part) in the script you will be asked to execute the script again

Please follow these steps after the first part.

```
cd ~
cd archins 
./install.sh
```

#### Select the second option (chrooted part) after this and you are good to go .

## System Description
This script completely installs arch linux in your system. It includes prompts to select your desired desktop environment, window manager, AUR helper, and whether to do a full or minimal install. 

## Found a bug?
If you found an issue or would like to submit an improvement to this project, please submit the issue in the issues tab above. If you would like to submit a PR with a fix please reference the issue you found.   

## Authors

- [@suyogprasai](https://www.github.com/suyogprasai)
