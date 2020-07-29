#!/bin/bash

sidebar() {
	instantmenu -l 2000 -w -400 -i -h -1 -x 100000 -y -1 -bw 4 -H -q "${1:-search...}"
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
		instantmenu -l 2000 -w -400 -i -h -1 -x 100000 -y -1 -bw 4 -H -q "search"
}

defaultapplicationsettings() {
	CHOICE="$(echo '>>h Default applications
>>r this is not fully working yet
:b Browser
:b 龍System monitor
:b Terminal emulator
:b File manager
:b Application launcher
:b Back' | sidebar)"
	case "$CHOICE" in
	*manager)
		selectfilemanager
		;;
	*Browser)
		selectbrowser
		;;
	*emulator)
		selectterminal
		;;
	*monitor)

		selectsystemmonitor
		;;
	*launcher)
		selectappmenu
		;;
	*)
		LOOPSETTING="True"
		;;
	esac

}

# generic default app selector
selectapp() {

	# usage: echo list | selectapp heading iconf-name
	LIST=">>h Default $1
$(cat /dev/stdin)
:b Custom
:b Back"
	CHOICE="$(echo "$LIST" | sidebar | sed 's/^....//g')"
	echo "choice"
	case "$CHOICE" in
	Custom)
		echo "setting custom application"
		CUSTOMCHOICE="$(imenu -i "enter default $1")"
		if ! command -v "$CUSTOMCHOICE"; then
			if ! imenu -c "$CUSTOMCHOICE not found, still set as default $1?"; then
				defaultapplicationsettings
				return
			fi
		fi
		iconf "$2" "$CUSTOMCHOICE"
		;;
	Back)
		defaultapplicationsettings
		;;
	*)
		LOWERCHOICE="$(echo "$CHOICE" | tr '[:upper:]' '[:lower:]')"
		iconf "$2" "$LOWERCHOICE"
		;;
	esac

}

selectappmenu() {
	echo ':b appmenu
:b instantmenu_smartrun
:b instantmenu_run
:b rofi -show run
:r none' | selectapp "application launcher" "appmenu"
}

selectsystemmonitor() {
	echo ':b 龍mate-system-monitor
:b 龍st -e htop
:b 龍st -e ytop' | selectapp "system monitor" "systemmonitor"
}

selectfilemanager() {

	echo ':b Nautilus
:b Thunar
:b PCManFM
:b Nemo
:b Caja' | selectapp "file manager" "filemanager"

}

selectterminal() {
	echo ':b st
:b xterm
:b urxvt' | selectapp "terminal emulator" "terminal"
}

selectbrowser() {

	echo ':y Firefox
:b Chromium
:y Brave
:y Chrome' | selectapp "web browser" "browser"

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
:b Custom wallpaper with logo
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
	*logo)
		instantwallpaper logo
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
		if iconf -i wifiapplet; then
			pgrep nm-applet || nm-applet
		else
			pgrep nm-applet && pkill nm-applet
		fi

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
:b Status bar
:b Dad joke on lock screen
:b Back' | sidebar)"
	case $CHOICE in
	*script)
		st -e "nvim" -c ":e ~/.instantautostart" &
		;;
	*Theming)
		toggleiconf notheming "enable instantOS theming?" i
		instantossettings
		;;
	*bar)
		toggleiconf nostatus "enable default status text?" i
		if iconf -i nostatus; then
			[ -e ~/.instantsilent ] || touch ~/.instantsilent
		else
			[ -e ~/.instantsilent ] && rm ~/.instantsilent
		fi &
		instantossettings
		;;
	*wallpaper)
		toggleiconf nologo "show logo on wallpaper?" i
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
	*screen)
		toggleiconf dadjoke "show dad joke on lock screen?"
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

bluetoothsettings() {

	# check for bluetooth hardware
	if ! {
		iconf -i hasbluetooth || lsusb | grep -iq 'bluetooth'
	}; then
		if echo 'System does not appear to have bluetooth support
Try regardless?' | imenu -C; then
			iconf -i hasbluetooth 1
		else
			return
		fi
	fi

	if ! systemctl is-active --quiet bluetooth; then
		if imenu -c "enable bluetooth?"; then
			instantsudo "systemctl enable bluetooth"
			instantsudo "systemctl start bluetooth"
		else
			return
		fi
	fi

	CHOICE="$(echo '>>h Bluetooth settings
:b Set up new device
:b Bluetooth applet
:b Back' | sidebar)"

	case "$CHOICE" in
	applet*)
		toggleiconf bluetoothapplet "enable bluetooth applet?"

		if iconf -i bluetoothapplet; then
			blueman-applet &
		else
			pgrep blueman-applet && pkill blueman-applet &
		fi

		bluetoothsettings
		;;
	device*)
		blueman-assistant &
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
	instantmouse gen &
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
		/usr/share/instantassist/assists/t/k.sh 123
		;;
	*Printing)
		system-config-printer &
		;;
	*Bluetooth)
		bluetoothsettings
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
