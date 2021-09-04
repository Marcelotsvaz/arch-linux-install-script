#!/bin/bash
# 
# Install a package from Arch User Repository.
# 
# 
# Author: Marcelo Tellier Sartori Vaz



package=${1}
cd /tmp
git clone https://aur.archlinux.org/${package}.git
chown -R nobody: ${package}
( cd ${package} && sudo -u nobody makepkg )
pacman --noconfirm -U ${package}/${package}-*.pkg.tar.zst
rm -r ${package}