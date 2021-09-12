#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



# Abort on error.
set -e



# Install software.
#---------------------------------------------------------------------------------------------------
# Desktop enviroment.
desktopEnvironment='plasma-desktop phonon-qt5-vlc sddm'
fonts='ttf-liberation ttf-cascadia-code'
audio='pipewire pipewire-alsa pipewire-jack pipewire-pulse'
applets='kscreen plasma-pa kinfocenter plasma-disks plasma-systemmonitor sddm-kcm drkonqi kde-gtk-config breeze-gtk'
applications='dolphin ark spectacle qjackctl'

# Main applications.
everydaySoftware='firefox thunderbird keepassxc discord vlc'
developmentSoftware='konsole code'
misc='neofetch'

pacman --noconfirm -S													\
	${desktopEnvironment} ${fonts} ${audio} ${applets} ${applications}	\
	${everydaySoftware} ${developmentSoftware} ${misc}
	
sudo -u marcelotsvaz yay -S pipewire-jack-dropin

systemctl --global enable pipewire-pulse
systemctl enable sddm



# Games.
#---------------------------------------------------------------------------------------------------
# gpuDrivers='mesa lib32-mesa vulkan-radeon lib32-vulkan-radeon'
# games='steam'

# # Enable multilib repository.
# perl -0777 -pi -e 's/#(\[multilib\]\n)#(Include = \/etc\/pacman.d\/mirrorlist)/\1\2/' /etc/pacman.conf

# pacman --noconfirm -Sy ${gpuDrivers} ${games}



# Configure software.
#---------------------------------------------------------------------------------------------------
# Enable Microsoft VSCode marketplace.
sed -Ei 's/("serviceUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/_apis\/public\/gallery",/' /usr/lib/code/product.json
sed -Ei 's/("itemUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/items",\n\t\t"cacheUrl": "https:\/\/vscode.blob.core.windows.net\/gallery\/index"/' /usr/lib/code/product.json