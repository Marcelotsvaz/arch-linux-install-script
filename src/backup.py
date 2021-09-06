#!/usr/bin/env python3
# 
# 
# 
# 
# Author: Marcelo Tellier Sartori Vaz



import sys
from subprocess import run



user = 'marcelotsvaz'

folders = {
	f'home/{user}/.config': [
		# Fish.
		'fish/functions/fish_prompt.fish',
		'fish/functions/l.fish',
		'fish/functions/ll.fish',
		'fish/functions/la.fish',
		'fish/fish_variables',
		
		# KDE.
		'plasmashellrc',							# Screen connectors. Applets size.
		'systemsettingsrc',							# Desktop layouts.
		'plasma-org.kde.plasma.desktop-appletsrc',	# Desktop applets.
		'kdeglobals',								# Theme colors. Fonts. File dialog.
		'plasmarc',									# Plasma style. Wallpapers.
		'kwinrc',									# Compositor.
		'kcminputrc',								# Mouse and keyboard settings.
		'ksplashrc',								# Splash screen.
		'kscreenlockerrc',							# Screen locker.
		'kdedefaults/kdeglobals',					# Themes.
		'kdedefaults/plasmarc',						# Plasma style?
		'kdedefaults/kwinrc',						# Window decoration theme?
		'kdedefaults/kcminputrc',					# Cursor theme.
		'kdedefaults/kscreenlockerrc',				# Screenlocker theme.
		'kxkbrc',									# Keyboard layout.
		'kiorc',									# Trash confirmations.
		'menus/applications-kmenuedit.menu',		# Applications menu.
		'kactivitymanagerd-statsrc',				# Launcher favorites.
		# 'kmixrc',
		# 'kglobalshortcutsrc',
		# 'klaunchrc',
		# 'ksmserverrc',
		# 'kwinrulesrc',
		# 'kservicemenurc',
		
		# Applications.
		'dolphinrc',
		'konsolerc',
		# 'krunnerrc',
		
		# Themes.
		'gtk-3.0/',						# Theme colors.
		'gtk-4.0/settings.ini',			# Theme colors.
		'xsettingsd/xsettingsd.conf',	# Theme colors.
		'Trolltech.conf',				# Theme colors.
		
		# VSCode.
		'Code - OSS/User/settings.json',
		
		# Custom files.
		'Wallpaper.png',
	],
	
	f'home/{user}/.local/share': [
		# KDE.
		'plasma-systemmonitor/overview.page',
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
		fullFiles.append( f'{src}/./{folder}/{file}' )

args = [
	'rsync',
	'--ignore-missing-args',
	'-aRv',
	'--no-o',
	'--no-g',
] + fullFiles + [ dest ]

run( args )



# Not on Reddit.
# plasmanotifyrc
# kded5rc
# kmixctrlrc

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