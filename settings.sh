#!/bin/bash

sidebar() {
	instantmenu -l 2000 -w 400 -i -h 54 -x 100000 -y 0 -bw 4 -H -q "${1:-search...}"
}

asksetting() {
	echo '>>h Settings
:b 墳Sound
:b instantOS
:b Display
:g Network
:b Install Software
:y Appearance
:b Bluetooth
:g Power
:b Keyboard
:b Mouse
:b Default applications
:b Language
:b 朗Printing
:y Wallpaper
:r Storage
:y Advanced
:y Dotfiles
:r Close Settings' |
		instantmenu -l 2000 -w 400 -i -h 54 -x 100000 -y 0 -bw 4 -H -q "search"
}

defaultapplicationsettings() {
	CHOICE="$(echo '>>h Default applications
>>r this is not fully working yet
:b Browser
:b Terminal emulator
:b File manager
:b Back' | sidebar)"
	case "$CHOICE" in
	*manager)
		selectfilemanager
		;;
	*Browser)
		selectbrowser
		;;
	*)
		LOOPSETTING="True"
		;;
	esac

}

selectfilemanager() {
	CHOICE="$(echo '>>h Default File Manager
:b Nautilus
:b Thunar
:b PCManFM
:b Nemo
:b Caja
:b Back' | sidebar)"
	case "$CHOICE" in
	*)
		defaultapplicationsettings
		;;
	esac

}

selectbrowser() {
	CHOICE="$(echo '>>h Default Browser
:y Firefox
:b Chromium
:y Brave
:y Chrome
:b Back' | sidebar)"
	case "$CHOICE" in
	*)
		defaultapplicationsettings
		;;
	esac

}

displaysettings() {
	CHOICE="$(echo '>>h Display Settings
:b Change display settings
:g Make current settings permanent
:b Back' | sidebar)"

	case $CHOICE in
	*Change*)
		arandr &
		;;
	*Make*)
		autorandr --force --save instantos
		;;
	*)
		LOOPSETTING="True"
		;;
	esac

}

advancedsettings() {
	CHOICE="$(echo '>>h Advanced settings
:b Firewall
:y TLP
:g Bootloader
:b Back' | sidebar)"
	case $CHOICE in
	*Firewall)
		gufw &
		;;
	*TLP)
		tlpui &
		;;
	*Bootloader)
		instantinstall grub-customizer
		grub-customizer &
		;;
	*)
		LOOPSETTING="True"
		;;
	esac
}

wallpapersettings() {
	CHOICE="$(echo '>>h Wallpaper settings
:b Generate new wallpaper
:b Set own wallpaper
:b Browse wallpapers
:b Back' | sidebar)"
	case $CHOICE in
	*Generate*)
		instantwallpaper clear && instantwallpaper w
		;;
	*Browse*)
		instantwallpaper select &
		;;
	*Set*)
		instantwallpaper gui &
		;;
	*)
		LOOPSETTING="True"
		;;

	esac
}

networksettings() {

	CHOICE="$(echo '>>h Network settings
:b Start network applet
:g Autostart network applet
:b Back' | sidebar)"

	case "$CHOICE" in
	*Autostart*)
		toggleiconf wifiapplet "Show network applet on startup?"
		networksettings
		;;
	*Start*)
		pgrep nm-applet || nm-applet &
		;;
	*)
		LOOPSETTING="True"
		;;

	esac

}

# the language settings reuse instantARCH components
fetchlanguage() {
	if ! [ -e ~/.cache/instantARCH ]; then
		if ! checkinternet; then
			imenu -e "internet not found, couldn't fetch language list"
			exit 1
		fi
		imenu -w "Preparing language settings"
		cd ~/.cache
		git clone --depth=1 https://github.com/instantOS/instantARCH
		pkill imenu
		pkill instantmenu
	else
		cd ~/.cache/instantARCH
		if ! [ -e askutils.sh ]; then
			cd ..
			rm -rf instantARCH
			if imenu -c "language cache invalid, reload?"; then
				fetchlanguage
			else
				exit 1
			fi
		fi
		git reset --hard
		git pull &
	fi
	cd ~/.cache/instantARCH
	mkdir bin
	cat iroot.sh >bin/iroot
	chmod +x ./bin/iroot
	export PATH="$PATH:~/.cache/instantARCH/bin"
	mkdir -p ~/.config/instantos/iroot
	IROOT="$(realpath ~/.config/instantos/iroot)"
	export IROOT
	INSTANTARCH="$(realpath ~/.cache/instantARCH)"
	export INSTANTARCH
	source askutils.sh
}

languagesettings() {
	fetchlanguage
	CHOICE="$(echo '>>h Language settings
:b Application Language
:g Timezone
:b Back' | sidebar)"

	case "$CHOICE" in
	*Language)
		echo "changing language"
		asklocale
		instantsudo INSTANTARCH="$INSTANTARCH" IROOT="$IROOT" PATH="$PATH" "$INSTANTARCH/lang/locale.sh"
		if echo "some settings are only applied after a reboot
Reboot now?" | imenu -C; then
			reboot
		fi
		;;
	*Timezone)
		askregion
		echo "changing timezone"
		instantsudo INSTANTARCH="$INSTANTARCH" IROOT="$IROOT" PATH="$PATH" "$INSTANTARCH/lang/timezone.sh"
		;;
	*)
		LOOPSETTING="True"
		;;
	esac

}

toggleiconf() {
	if [ -z "$3" ]; then
		if iconf -i "$1"; then
			CONFSTATUS="enabled"
		else
			CONFSTATUS="disabled"
		fi
	else
		if iconf -i "$1"; then
			CONFSTATUS="disabled"
		else
			CONFSTATUS="enabled"
		fi
	fi
	CONFPROMPT=">>h $2
> Currently $CONFSTATUS
:g Yes
:r No
:b Back"
	CHOICE=$(echo "$CONFPROMPT" | sidebar "choose answer" | grep -o '[^ ]*$')
	case $CHOICE in
	*Yes)
		if [ -z "$3" ]; then
			iconf -i "$1" 1
		else
			iconf -i "$1" 0
		fi
		;;
	*No)
		if [ -z "$3" ]; then
			iconf -i "$1" 0
		else
			iconf -i "$1" 1
		fi
		;;
	esac
}

instantossettings() {
	CHOICE="$(echo '>>h instantOS settings
:b Edit Autostart script
:b Theming
:b Logo on wallpaper
:b 𧻓Animations
:b ﰪConky Widgets
:b Desktop icons
:b Back' | sidebar)"
	case $CHOICE in
	*script)
		st -e "nvim" -c ":e ~/.instantautostart" &
		;;
	*Theming)
		toggleiconf notheming "enable instantOS theming?" i
		instantossettings
		;;
	*wallpaper)
		toggleiconf noanimations "show logo on wallpaper?" i
		instantossettings
		;;
	*Animations)
		if ! iconf -i noanimations; then
			ANIMATED="true"
		fi
		toggleiconf noanimations "enable animations?" i
		if [ -n "$ANIMATED" ]; then
			if iconf -i noanimations; then
				xdotool key super+alt+shift+s
			fi
		else
			if ! iconf -i noanimations; then
				xdotool key super+alt+shift+s
			fi
		fi
		;;
	*Widgets)
		toggleiconf noconky "show desktop widgets?" i
		instantossettings
		;;
	*icons)
		toggleiconf desktopicons "show desktop icons?"
		if iconf -i desktopicons; then
			iconf -i desktop 1
			rox --pinboard Default &
		else
			iconf -i desktop 0
			pgrep ROX && pkill ROX
		fi
		instantossettings
		;;
	*)
		LOOPSETTING="True"
		;;
	esac

}

storagesettings() {
	CHOICE="$(echo '>>h Storage settings
:b Open disk management
:b 﫭Auto mount disks
:b Back' | sidebar)"
	case $CHOICE in
	*management)
		gnome-disks &
		;;
	*disks)
		toggleiconf udiskie "auto mount disks (udiskie)?"
		if iconf -i udiskie; then
			pgrep udiskie || udiskie -t &
		else
			pgrep udiskie && pkill udiskie
		fi
		storagesettings
		;;
	*)
		LOOPSETTING="True"
		;;
	esac
}

mousesettings() {
	CHOICE="$(echo '>>h Mouse settings
:b Sensitivity
:b Reverse scrolling
:b Back' | sidebar)"
	case $CHOICE in
	*Sensitivity)
		CURRENTSPEED="$(iconf mousespeed)"
		PRESPEED=$(echo "($CURRENTSPEED + 1) * 50" | bc -l | grep -o '^[^.]*')
		islide -s "$PRESPEED" -c "instantmouse m " -p "mouse sensitivity"
		iconf mousespeed "$(instantmouse l)"
		;;
	*scrolling)
		toggleiconf reversemouse "Reverse mouse scrolling?"
		if iconf -i reversemouse; then
			instantmouse r 1
		else
			instantmouse r 0
		fi
		mousesettings
		;;
	*)
		LOOPSETTING="True"
		;;

	esac
}

LOOPSETTING="true"
while [ -n "$LOOPSETTING" ]; do
	SETTING="$(asksetting)"
	unset LOOPSETTING
	case "$SETTING" in
	*Sound)
		pavucontrol &
		;;
	*Appearance)
		lxappearance &
		;;
	*instantOS)
		instantossettings
		;;
	*Software)
		pamac-manager &
		;;
	*Display)
		displaysettings
		;;
	*Keyboard)
		/opt/instantos/menus/dm/tk.sh 123
		;;
	*Printing)
		system-config-printer &
		;;
	*Bluetooth)
		blueman-assistant &
		;;
	*Dotfiles)
		[ -e ~/.instantrc ] || instantdotfiles
		st -e "nvim" -c ":e ~/.instantrc" &
		;;
	*Power)
		xfce4-power-manager-settings &
		;;
	*Wallpaper)
		wallpapersettings
		;;
	*Language)
		languagesettings
		;;
	*Network)
		networksettings
		;;
	*Storage)
		storagesettings
		;;
	*Advanced)
		advancedsettings
		;;
	*Mouse)
		mousesettings
		;;
	*applications)
		defaultapplicationsettings
		;;
	esac
done
