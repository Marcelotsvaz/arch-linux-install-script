#!/usr/bin/bash
# 
# Arch Linux Install Script
# 
# 
# Author: Marcelo Tellier Sartori Vaz <marcelotsvaz@gmail.com>



# Abort on error.
set -e



# Install software.
#---------------------------------------------------------------------------------------------------
# Desktop enviroment.
desktopEnvironment='plasma-desktop plasma-wayland-session libva-mesa-driver phonon-qt5-vlc sddm'
fonts='noto-fonts-cjk noto-fonts-emoji ttf-cascadia-code ttf-liberation'
audio='pipewire pipewire-alsa pipewire-jack pipewire-pulse'
applets='kscreen plasma-pa kinfocenter plasma-disks print-manager plasma-systemmonitor sddm-kcm plasma-browser-integration drkonqi kde-gtk-config breeze-gtk'
applications='dolphin gwenview ark spectacle qjackctl'

# Main applications.
everydaySoftware='firefox thunderbird keepassxc rhythmbox vlc okular libreoffice-fresh discord cups obs-studio v4l2loopback-dkms obs-ndi torbrowser-launcher'
developmentSoftware='konsole code docker docker-compose terraform npm'
misc='neofetch flatpak'

pacman --noconfirm -S													\
	${desktopEnvironment} ${fonts} ${audio} ${applets} ${applications}	\
	${everydaySoftware} ${developmentSoftware} ${misc}
	
sudo -u marcelotsvaz yay -S code-marketplace code-features docker-credential-secretservice

npm install -g less

systemctl --global enable pipewire-pulse
systemctl enable sddm cups docker



# Games.
#---------------------------------------------------------------------------------------------------
# Install Steam.
gamesFolder='/usr/local/games'
setfacl -m u:marcelotsvaz:rwx ${gamesFolder}

# Bind-mount games folder outside /usr so flatpak apps can access it.
#-------------------------------------------------------------------------------
cat > /etc/systemd/system/opt-games.mount << EOF
[Unit]
Description = Mount games folder for flatpak access

[Mount]
What = ${gamesFolder}
Where = /opt/games
Type = none
Options = bind

[Install]
WantedBy = multi-user.target
EOF
#-------------------------------------------------------------------------------
systemctl enable opt-games.mount

flatpak install --assumeyes com.valvesoftware.Steam
flatpak override --filesystem=/opt/games/steam:create com.valvesoftware.Steam


# Path of Exile stuff.
sudo -u marcelotsvaz yay -S path-of-building-community-git awakened-poe-trade-git



# Configure software.
#---------------------------------------------------------------------------------------------------
# Temporary fix for SDDM not sourcing /etc/profile when fish is set as the default shell.
sed -Ei 's/--login.*sh/\0 --login/' /usr/share/sddm/scripts/wayland-session
sed -Ei 's/--login.*sh/\0 --login/' /usr/share/sddm/scripts/Xsession