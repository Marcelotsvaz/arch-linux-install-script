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
applications='dolphin gwenview ark spectacle qjackctl kimageformats qt5-imageformats'

# Main applications.
everydaySoftware='firefox chromium thunderbird keepassxc rhythmbox vlc okular libreoffice-fresh discord cups obs-studio v4l2loopback-dkms torbrowser-launcher'
developmentSoftware='konsole code docker docker-compose terraform packer ansible'
misc='neofetch flatpak'

pacman --noconfirm -S													\
	${desktopEnvironment} ${fonts} ${audio} ${applets} ${applications}	\
	${everydaySoftware} ${developmentSoftware} ${misc}
	
sudo -u marcelotsvaz yay -S code-marketplace code-features docker-credential-secretservice obs-plugin-ios-camera-source-git obs-ndi

systemctl --global enable pipewire-pulse
systemctl enable sddm docker.socket



# Get AWS credentials from KeePassXC.
#---------------------------------------------------------------------------------------------------
cat > /usr/local/lib/getAwsCredentials << 'EOF'
#!/usr/bin/bash

profile=${1}

usernameRegex='^attribute.UserName = '

# TODO: Remove stderr redirection.
accessKeyId=$(secret-tool search Service aws Profile ${profile} 2>&1 | grep "${usernameRegex}" | sed "s/${usernameRegex}//")
secretAccessKey=$(secret-tool lookup Service aws Profile ${profile})

cat << EOF2
{
	"Version": 1,
	"AccessKeyId": "${accessKeyId}",
	"SecretAccessKey": "${secretAccessKey}"
}
EOF2
EOF



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