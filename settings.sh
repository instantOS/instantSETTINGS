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
	*Back)
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
	esac
done
