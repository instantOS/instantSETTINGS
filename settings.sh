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
>>h Advanced settings
:b Firewall
:y TLP
:r Close Settings' | instantmenu -l 2000 -w 400 -i -h 60 -x 100000 -y 0 -bw 4
}

LOOPSETTING="true"
while [ -n "$LOOPSETTING" ]
do
	SETTING="$(asksetting)"
	unset LOOPSETTING
	case "$SETTING" in
		*Sound)
			pavucontrol &
		;;
		*Appearance)
			lxappearance &
		;;
	esac
done
