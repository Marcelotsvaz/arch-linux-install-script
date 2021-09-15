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
	f'home/{user}': [
		'.passwords.kdbx',							# KeePassXC database.
	],
	
	f'home/{user}/.config': [
		# Applications.
		'dolphinrc',
		'konsolerc',
		'gwenviewrc',
		'krunnerrc',
		'keepassxc/keepassxc.ini',
		
		# Fish.
		'fish/fish_variables',
		'fish/functions/fish_prompt.fish',
		'fish/functions/l.fish',
		'fish/functions/ll.fish',
		'fish/functions/la.fish',
		
		# VSCode.
		'Code - OSS/User/settings.json',
		
		# Custom files.
		'Wallpaper.png',							# Desktop, lockscreen and SDDM wallpaper.
		
		# KDE.
		'plasmashellrc',							# Screen connectors. Applets size.
		'systemsettingsrc',							# Desktop layouts.
		'plasma-org.kde.plasma.desktop-appletsrc',	# Desktop applets.
		'kdeglobals',								# Theme colors. Fonts. File dialog.
		'plasmarc',									# Plasma style. Wallpapers.
		'kwinrc',									# KWin.
		'kwinrulesrc',								# KWin rules.
		'kcminputrc',								# Mouse and keyboard settings.
		'ksplashrc',								# Splash screen.
		'kscreenlockerrc',							# Screen locker.
		'kxkbrc',									# Keyboard layout.
		'kiorc',									# Trash confirmations.
		'kactivitymanagerdrc',						# Activities.
		'kactivitymanagerd-statsrc',				# Launcher favorites.
		'kconf_updaterc',							# Config files version.
		'kglobalshortcutsrc',						# Shortcuts.
		'ksmserverrc',								# Session manager.
		'menus/applications-kmenuedit.menu',		# Applications menu.
		'kdedefaults/kdeglobals',					# Themes.
		'kdedefaults/plasmarc',						# Plasma style?
		'kdedefaults/kwinrc',						# Window decoration theme?
		'kdedefaults/kcminputrc',					# Cursor theme.
		'kdedefaults/kscreenlockerrc',				# Screenlocker theme.
		'autostart/',								# Autostart entries.
		
		# Other.
		# 'kded5rc',
		# 'khotkeysrc',
		# 'ktimezonedrc',
		# 'plasma-localerc',
		
		# Themes.
		'gtk-3.0/',									# Theme colors.
		'gtk-4.0/settings.ini',						# Theme colors.
		'xsettingsd/xsettingsd.conf',				# Theme colors.
		'Trolltech.conf',							# Theme colors.
	],
	
	f'home/{user}/.local/share': [
		# KDE.
		'plasma-systemmonitor/overview.page',
		'kscreen/8a3e3f1c7b5fb6c6adcfb26805261ad2',	# Screen layout.
	],
	
	'': [
		'etc/sddm.conf.d/kde_settings.conf',		# SDDM.
		'var/lib/AccountsService/',					# User avatar and email.
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