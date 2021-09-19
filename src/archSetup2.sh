#!/usr/bin/bash
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
desktopEnvironment='plasma-desktop plasma-wayland-session libva-mesa-driver phonon-qt5-vlc sddm'
fonts='noto-fonts-cjk ttf-cascadia-code ttf-liberation'
audio='pipewire pipewire-alsa pipewire-jack pipewire-pulse'
applets='kscreen plasma-pa kinfocenter plasma-disks plasma-systemmonitor sddm-kcm plasma-browser-integration drkonqi kde-gtk-config breeze-gtk'
applications='dolphin gwenview ark spectacle qjackctl'

# Main applications.
everydaySoftware='firefox thunderbird keepassxc rhythmbox vlc okular libreoffice-fresh discord'
developmentSoftware='konsole code'
misc='neofetch flatpak'

pacman --noconfirm -S													\
	${desktopEnvironment} ${fonts} ${audio} ${applets} ${applications}	\
	${everydaySoftware} ${developmentSoftware} ${misc}
	
sudo -u marcelotsvaz yay -S pipewire-jack-dropin

systemctl --global enable pipewire-pulse
systemctl enable sddm



# Games.
#---------------------------------------------------------------------------------------------------
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

# Install Steam.
flatpak install --assumeyes com.valvesoftware.Steam
flatpak override --filesystem=/opt/games/steam:create com.valvesoftware.Steam



# Configure software.
#---------------------------------------------------------------------------------------------------
# Temporally fix for SDDM not sourcing /etc/profile when fish is set as the login shell.
sed -Ei 's/--login.*sh/\0 --login/' /usr/share/sddm/scripts/wayland-session
sed -Ei 's/--login.*sh/\0 --login/' /usr/share/sddm/scripts/Xsession

# Enable Microsoft VSCode marketplace.
sed -Ei 's/("serviceUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/_apis\/public\/gallery",/' /usr/lib/code/product.json
sed -Ei 's/("itemUrl": ).*/\1"https:\/\/marketplace.visualstudio.com\/items",\n\t\t"cacheUrl": "https:\/\/vscode.blob.core.windows.net\/gallery\/index"/' /usr/lib/code/product.json

# Move file outside home.
#-------------------------------------------------------------------------------
cat > /etc/profile.d/cleanHome.sh << 'EOF'
config="${XDG_CONFIG_HOME:-${HOME}/.config}"
data="${XDG_DATA_HOME:-${HOME}/.local/share}"
cache="${XDG_CACHE_HOME:-${HOME}/.cache}"

export KDEHOME="${config}/kde4"

export VSCODE_EXTENSIONS="${data}/code-oss"

export LESSHISTFILE="${cache}/lesshst"
export HISTFILE="${cache}/bash_history"
EOF
#-------------------------------------------------------------------------------