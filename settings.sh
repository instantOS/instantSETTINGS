#!/bin/bash

asksetting() {
	echo '>>h General settings
:b 墳Sound
:b instantOS
:b Display
:g Network
:b Install Software
:y Appearance
:b Bluetooth
:g Power
:b Keyboard
:b 朗Printing
:y Wallpaper
:r Storage
:y Dotfiles
>>h Advanced settings
:b Firewall
:y TLP
:r Close Settings' | instantmenu -l 2000 -w 400 -i -h 55 -x 100000 -y 0 -bw 4 -H
}

sidebar() {
	instantmenu -l 2000 -w 400 -i -h 55 -x 100000 -y 0 -bw 4 -H
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
	if [ -n "$WIFIAPPLET" ] || iconf -i wifiapplet; then
		WIFIAPPLET="true"
	fi
	if [ -n "$WIFIAPPLET" ]; then
		CHOICE="$(echo '>>h Network settings
:b Start network applet
:g Autostart network applet
:b Back' | sidebar)"
	else
		CHOICE="$(echo '>>h Network settings
:b Start network applet
:r Autostart network applet
:b Back' | sidebar)"
	fi

	case "$CHOICE" in
	*Autostart*)
		if [ -n "$WIFIAPPLET" ]; then
			unset WIFIAPPLET
			iconf -i wifiapplet 0
		else
			WIFIAPPLET="true"
			iconf -i wifiapplet 1
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
	*Network)
		networksettings
		;;

	esac
done
