#!/usr/bin/env python3
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



import sys
from subprocess import run



folders = {
	'home/marcelotsvaz/.config': [
		# KDE.
		'menus/*',
		'plasmashellrc',
		'plasma-org.kde.plasma.desktop-appletsrc',
		'kdeglobals',	# Fonts.
		'plasmarc',
		'kwinrc',
		'kiorc',
		'kscreenlockerrc',
		'kglobalshortcutsrc',
		'kmixrc',
		'konsolerc',
		'klaunchrc',
		'kcminputrc',
		'kxkbrc',
		'ksmserverrc',
		'ksplashrc',
		'kwinrulesrc',
		'krunnerrc',
		'kservicemenurc',
		
		'Wallpaper.png',
		
		# GTK.
		# 'gtk-4.0/settings.ini',
		
		# xsettingsd
		
		# VSCode.
		'Code - OSS/User/settings.json',
	],
	
	'home/marcelotsvaz/.local': [
		# KDE.
		'share/plasma-systemmonitor/overview.page',
	],
	
	'': [
		# SDDM.
		'etc/sddm.conf.d/kde_settings.conf',
	],
}

fullFiles = []

src = sys.argv[1]
dest = sys.argv[2]

for folder, files in folders.items():
	for file in files:
		fullFiles.append( f'{src}/{folder}/{file}' )

args = [
	'rsync',
	'--ignore-missing-args',
	'-aRv',
	# '--fake-super',
	# '--no-o',
	# '--no-g',
] + fullFiles + [ dest ]

run( args )







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