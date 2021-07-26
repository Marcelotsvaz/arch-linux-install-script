#!/bin/bash
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



home=${1}
src=${2}
dest=${3}


config=(
	menus/*
	plasmashellrc
	plasma-org.kde.plasma.desktop-appletsrc
	kdeglobals
	plasmarc
	kwinrc
	kiorc
	kscreenlockerrc
	kglobalshortcutsrc
	kmixrc
	konsolerc
	klaunchrc
	kcminputrc
	kxkbrc
	ksmserverrc
	ksplashrc
	kwinrulesrc
	krunnerrc
	kservicemenurc
)

local=(
	share/plasma-systemmonitor/overview.page
)

system=(
	/etc/sddm.conf.d/kde_settings.conf
)


for file in "${config[@]}"; do
	files+="${src}/./${home}/.config/${file} "
done

for file in "${local[@]}"; do
	files+="${src}/./${home}/.local/${file} "
done

for file in "${system[@]}"; do
	files+="${src}/./${file} "
done

sudo rsync -aRvn ${files} "${dest}"



# Not on Reddit.
# plasmanotifyrc
# kded5rc
# gtk-3.0/*
# gtk-4.0/*
# kdedefaults/*
# xsettingsd/xsettingsd.conf
# kmixctrlrc
# dolphinrc


# From Reddit.
# breezerc
# kaccessrc
# kcmdisplayrc
# kconf_updaterc
# kdebugrc
# kded_device_automounterrc
# kgammarc
# khotkeysrc
# kmenueditrc
# knotifyrc
# ktimezonedrc
# plasma-localerc
# plasma-locale-settings.sh
# startupconfig
# startupconfigfiles
# startupconfigkeys
# systemsettingsrc