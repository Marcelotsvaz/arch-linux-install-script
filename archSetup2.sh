#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Development Tools
####################################################################################################
dependencies='base-devel' # cmake extra-cmake-modules
developmentTools='mercurial git aws-cli'
pacman --noconfirm -S ${dependencies} ${developmentTools}



# Desktop Enviroment
####################################################################################################
desktopEnvironment='plasma-desktop phonon-qt5-vlc ttf-liberation plasma-wayland-session sddm'
applets='kscreen kmix kinfocenter plasma-disks plasma-systemmonitor sddm-kcm kde-gtk-config breeze-gtk'
applications='dolphin ark spectacle'
# ??? drkonqi khotkeys browser integration
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
games='steam'

# Enable multilib repository.
perl -0777 -pi -e 's/#(\[multilib\]\n)#(Include = \/etc\/pacman.d\/mirrorlist)/\1\2/' /etc/pacman.conf

pacman --noconfirm -Sy ${gpuDrivers} ${games}