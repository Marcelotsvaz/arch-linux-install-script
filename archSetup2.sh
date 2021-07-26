#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Development Tools
####################################################################################################
dependencies='base-devel'
developmentTools='mercurial git aws-cli'
pacman --noconfirm -S ${dependencies} ${developmentTools}



# Desktop Enviroment
####################################################################################################
desktopEnvironment='plasma-desktop phonon-qt5-vlc ttf-liberation plasma-wayland-session sddm'
applets='kscreen kmix kinfocenter plasma-disks plasma-systemmonitor sddm-kcm drkonqi kde-gtk-config breeze-gtk'
applications='dolphin ark spectacle'
# khotkeys browser integration
pacman --noconfirm -S ${desktopEnvironment} ${applets} ${applications}

systemctl enable sddm



# Main Applications
####################################################################################################
everydaySoftware='firefox thunderbird vlc discord keepassxc'
developmentSoftware='konsole code'
misc='neofetch'
pacman --noconfirm -S ${everydaySoftware} ${developmentSoftware} ${misc}



# Games
####################################################################################################
gpuDrivers='mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon'
# games='steam'

# Enable multilib repository.
perl -0777 -pi -e 's/#(\[multilib\]\n)#(Include = \/etc\/pacman.d\/mirrorlist)/\1\2/' /etc/pacman.conf

pacman --noconfirm -Sy ${gpuDrivers} ${games}



# Configure software
####################################################################################################
# Enable Microsoft VSCode marketplace.
sed -Ei 's/("serviceUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/_apis\/public\/gallery",/' /usr/lib/code/product.json
sed -Ei 's/("itemUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/items",\n\t\t"cacheUrl": "https:\/\/vscode.blob.core.windows.net\/gallery\/index"/' /usr/lib/code/product.json