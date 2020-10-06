#!/bin/bash

# graphical settings menu for instantOS

source /usr/share/instantsettings/utils/functions.sh

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
:g Time and date
:b 朗Printing
:r Storage
:y Advanced
:y Dotfiles
:r Close Settings' |
        instantmenu -l 2000 -w -400 -i -h -1 -x 100000 -y -1 -bw 4 -H -q "search"
}

soundsettings() {

    CHOICE="$(echo '>>h Sound settings
:b ﰝSystem audio
:y Notification sound
:b Back' | sidebar)"
    case "$CHOICE" in
    *audio)
        pavucontrol &
        exit
        ;;
    *sound)
        notificationsettings
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac
}

notificationsettings() {
    CHOICE="$(echo '>>h Notification sound settings
:b Custom
:y 碑Reset
:r Mute
:b Back' | sidebar)"
    case $CHOICE in
    *Custom)
        SOUNDPATH="$(zenity --file-selection)"
        if [ -z "$SOUNDPATH" ]; then
            notificationsettings
            return
        fi
        if ! mpv "$SOUNDPATH"; then
            if ! echo "file $SOUNDPATH does not appear to be an audio file, use regardless ?" | imenu -C; then
                exit
            fi
        fi
        iconf -i nonotify 0
        cp "$SOUNDPATH" ~/instantos/notifications/customsound
        ;;
    *Reset)
        iconf -i nonotify 0
        rm ~/instantos/notifications/customsound
        ;;
    *Mute)
        toggleiconf nonotify "mute notification alert sounds"
        ;;
    esac

}

defaultapplicationsettings() {
    CHOICE="$(echo '>>h Default applications
:b Browser
:b 龍System monitor
:b Terminal emulator
:b File manager
:b Application launcher
:y Text editor
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
    *editor)
        selecteditor
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac
    if [ -z "$LOOPSETTING" ]; then
        instantutils default
    fi
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
    none)
        iconf -d "$2"
        ;;
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
    instantinstall "$(iconf systemmonitor | grep -o '[^ ]*$')"

}

selectfilemanager() {
    selectdefault filemanager "File Manager"
}

selectdefault() {
    LIST=">>h Default ${2:-$1}
$(grep -o '^[^:][^:]*' /usr/share/instantsettings/data/default/"$1" | sed 's/^/:/g')
:b Custom
:b Back"

    APPCHOICE="$(echo "$LIST" | sidebar | sed 's/^://g')"

    case "$APPCHOICE" in
    *Custom)
        CUSTOMAPP="$(imenu -i "default $1")"
        [ -z "$CUSTOMAPP" ] && return 1
        iconf "$1" "$CUSTOMAPP"
        ;;
    *Back)
        return 0
        ;;
    esac

    CHOICE="$(grep "$APPCHOICE" /usr/share/instantsettings/data/default/"$1")"
    if [ -z "$CHOICE" ]; then
        return 1
    fi

    if ! grep -q ':' <<<"$CHOICE"; then
        instantinstall "$(sed 's/^....//g')"
        return
    fi
    echo "choice: $CHOICE"
    SETCOMMAND="$(sed 's/^[^:]*://g' <<<"$CHOICE" | grep -o '^[^:]*')"
    iconf "$1" "$SETCOMMAND"
    echo "echo setting command to $SETCOMMAND"

    if grep -q '.*:.*:' <<<"$CHOICE"; then
        INSTALLCOMMAND="$(grep -o '[^:]*$' <<<"$CHOICE")"
    else
        INSTALLCOMMAND="$SETCOMMAND"
    fi

    if ! grep -q ',' "$INSTALLCOMMAND"; then
        if command -v "$SETCOMMAND"; then
            return
        fi
        instantinstall "$INSTALLCOMMAND"
    else
        echo "multiple dependencies detected"
        INSTALLLIST="$(sed 's/,/ /g' <<< "$INSTALLCOMMAND")"
        for i in $(echo $INSTALLLIST)
        do
            instantinstall "$i"
        done
    fi


}

selectterminal() {
    selectdefault "terminal" "Terminal emulator"
}

selectbrowser() {
    selectdefault browser "Web Browser"
}

selecteditor() {
    echo ':y Gedit
:g Vim
:y nvim-qt
:y Pluma' | selectapp "text editor" "editor"
    instantinstall "$(iconf editor)"
}

displaysettings() {
    CHOICE="$(echo '>>h Display Settings
:b Change display settings
:g Make current settings permanent
:y Change screen brightness
:b Autodetect monitor docking
:b External screen
:b HiDPI
:b Back' | sidebar)"

    case $CHOICE in
    *settings)
        arandr &
        ;;
    *brightness)
        /usr/share/instantassist/assists/b.sh
        ;;
    *permanent)
        notify-send "saving current monitor settings"
        instantinstall autorandr
        autorandr --force --save instantos
        ;;
    *screen)
        instantdisper
        ;;
    *docking)
        toggleiconf autoswitch "auto detect new monitors being plugged in?"
        displaysettings
        ;;
    *HiDPI)
        if imenu -c "enable HiDPI"; then
            DPI=$(imenu -i 'enter dpi (default is 96)')
            [ -z "$DPI" ] && return
            if ! [ "$DPI" -eq "$DPI" ] || [ "$DPI" -gt 500 ] || [ "$DPI" -lt "20" ]; then
                imenu -m "please enter a number between 20 and 500 (default is 96)"
                return
            fi
            iconf dpi "$DPI"
        else
            iconf -d dpi
        fi

        instantdpi
        xrdb ~/.Xresources

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
        instantinstall gufw
        gufw &
        ;;
    *TLP)
        instantinstall tlpui
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
:b Logo
:b Repair wallpaper
:b Back' | sidebar)"
    case $CHOICE in
    *Generate*)
        instantwallpaper clear && instantwallpaper w
        ;;
    *Browse*)
        instantwallpaper select &
        ;;
    *Repair*)
        rm ~/instantos/wallpapers/*.png
        rm ~/instantos/wallpapers/default
        instantmonitor
        instantwallpaper
        ;;
    *wallpaper)
        instantwallpaper gui &
        ;;
    *Logo)
        toggleiconf nologo "show logo on wallpaper?" i
        wallpapersettings
        ;;
    *logo)
        instantwallpaper logo
        ;;
    *)
        appearancesettings
        return
        ;;
    esac
}

networksettings() {

    CHOICE="$(echo '>>h Network settings
:b Start network applet
:g Autostart network applet
:b IP info
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
    *info)
        getlocalip() {
            INTERFACE=$(ip addr | awk '/state UP/ {print $2}' | sed 's/.$//')
            if [ "$(echo "$INTERFACE" | wc -l)" -gt 1 ]; then
                echoerr "error: more than one network interface found"
                return 1
            fi
            ip addr | grep -A2 "$INTERFACE" | grep -o 'inet .*/' | grep -o '[0-9\.]*'
        }
        if getlocalip; then
            LOCALIP="$(getlocalip)"
        fi

        if checkinternet; then
            PUBLICIP="$(curl ifconfig.me)"
        fi

        if [ -z "${PUBLICIP}${LOCALIP}" ]; then
            imenu -e "error getting network information"
            exit
        fi

        CHOICE="$(echo "public ip: ${PUBLICIP:-not found}
local ip: ${LOCALIP:-not found}
OK" | imenu -l "Network info")"

        if grep -q 'not found' <<<"$CHOICE" || ! grep -q 'ip' <<<"$CHOICE"; then
            exit
        fi

        echo "$CHOICE" | grep -o '[^:]*$' | grep -o '[^ ]*' | head -1 | xclip -selection c
        notify-send "copied ip to clipboard"

        exit

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
        cd ~/.cache || die "no cache"
        git clone --depth=1 https://github.com/instantOS/instantARCH
        pkill imenu
        pkill instantmenu
    else
        cd ~/.cache/instantARCH || die "cache error"
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
    cd ~/.cache/instantARCH || die "cache error"
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

choosenumber() {
    NUMCHOICE="$({
        echo "$1"
        seq 1 "$2" | tac
    } | sidebar "Change $3")"
    [ -n "$NUMCHOICE" ] && [ "$NUMCHOICE" -eq "$NUMCHOICE" ] && echo "$NUMCHOICE"
}

timesettings() {
    echo "changing time/date"
    YEAR="$(date +%Y)"
    MONTH="$(date +%m)"
    DAY="$(date +%d)"
    HOUR="$(date +%H)"
    MINUTE="$(date +%M)"
    while :; do
        DATECHOICE="$(echo ">>h Change date
Year $YEAR
Month $MONTH
Day $DAY
Hour $HOUR
Minute $MINUTE
:g Apply
:b Back" | sidebar)"
        echo "datechoice $DATECHOICE"
        case "$DATECHOICE" in
        Day*)
            NEWDAY="$(choosenumber "$DAY" 31 "day")"
            DAY="${NEWDAY:-"$DAY"}"
            ;;
        Year*)
            NEWYEAR="$(choosenumber "$YEAR" 2100 "year")"
            YEAR="${NEWYEAR:-"$YEAR"}"
            ;;
        Hour*)
            NEWHOUR="$(choosenumber "$HOUR" 24 "hour")"
            HOUR="${NEWHOUR:-"$HOUR"}"
            ;;
        Minute*)
            NEWMINUTE="$(choosenumber "$MINUTE" 60 "minute")"
            MINUTE="${NEWMINUTE:-"$MINUTE"}"
            ;;
        Month*)
            NEWMONTH="$(choosenumber "$MONTH" 12 "month")"
            MONTH="${NEWMONTH:-"$MONTH"}"
            ;;
        *Apply)
            echo "changing date to $YEAR-$MONTH-$DAY $HOUR:$MINUTE:$(date +%S)"
            instantsudo timedatectl set-time "$YEAR-$MONTH-$DAY $HOUR:$MINUTE:$(date +%S)"
            ;;
        *)
            LOOPSETTING="True"
            return
            ;;
        esac
    done
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
:y Potato
:b 𧻓Animations
:b ﰪConky Widgets
:b Desktop icons
:b Status bar
:b Clipboard manager
:b Alttab menu
:b Dad joke on lock screen
:g Neovim preconfig
:r instantOS development tools
:b Back' | sidebar)"
    case $CHOICE in
    *script)
        if ! [ -e ~/.config/instantos/autostart.sh ]; then
            mkdir -p ~/.config/instantos
            if [ -e ~/.instantautostart ]; then
                cat ~/.instantautostart >~/.config/instantos/autostart.sh
            else
                echo "# instantOS autostart script
# This script gets executed when $(whoami) logs in
# Add & (a literal) ampersand to the end of a line to make it run in the background" > \
                    ~/.config/instantos/autostart.sh
            fi
        fi
        st -e "nvim" -c ":e ~/.config/instantos/autostart.sh" &
        ;;
    *Theming)
        toggleiconf notheming "enable instantOS theming?" i
        instantossettings
        ;;
    *bar)
        toggleiconf nostatus "enable default status text?" i
        if iconf -i nostatus; then
            [ -e ~/.instantsilent ] || touch ~/.instantsilent
            xsetroot -name '^f11^ xsetroot -name "yourtext"'
        else
            [ -e ~/.instantsilent ] && rm ~/.instantsilent
        fi &
        instantossettings
        ;;
    *manager)
        toggleiconf clipmanager "Enable clipboard manager"
        if ! iconf -i clipmanager; then
            pgrep -f clipmenud && pkill -f clipmenud
        else
            instantinstall clipmenu
            pgrep -f clipmenud || clipmenud &
        fi
        instantossettings
        ;;
    *Potato)
        toggleiconf potato "do you consider this pc a potato?
> this disables multiple effects
> in order to improve performance
> on weak machines this won't
> help much on faster machines
>>h --------"
        instantossettings
        ;;
    *tools)
        imenu -c "install instantOS development tools?" || exit
        checkinternet || {
            imenu -e "internet is required"
            exit 1
        }
        st -e bash -c "curl -s https://raw.githubusercontent.com/instantOS/instantTOOLS/master/netinstall.sh | bash"
        ;;
    *preconfig)
        if ! echo "install the instantOS development neovim dots?
This will override any neovim configurations done previously" | iconf -C; then
            echo "installing nvim build"
            exit
        fi
        iconf neovimconfig 1
        iconf -i neovimconfig 1
        instantinstall nvim-qt nodejs npm
        mkdir -p ~/.cache/instantosneovim
        cd ~/.cache/instantosneovim || exit 1
        checkinternet || {
            imenu -e "internet is required"
            exit 1
        }

        notify-send "downloading config"
        git clone --depth=1 https://github.com/paperbenni/init.vim

        cd init.vim || exit 1
        chmod +x ./*.sh
        st -e bash -c "./install.sh"
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
        instantossettings
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
            sleep 0.5
            instantwallpaper
        fi
        instantossettings
        ;;
    *screen)
        toggleiconf dadjoke "show dad joke on lock screen?"
        instantossettings
        ;;
    *menu)
        toggleiconf alttab "use graphical alttab menu?"
        imenu -m "alttab settings will be applied on next login"
        instantinstall alttab
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

bluetoothsettings() {

    # check for bluetooth hardware
    if ! (
        iconf -i hasbluetooth || lsusb | grep -iq 'bluetooth'
    ); then
        if echo 'System does not appear to have bluetooth support
Try regardless?' | imenu -C; then
            iconf -i hasbluetooth 1
        else
            return
        fi
    fi

    if ! systemctl is-active --quiet bluetooth; then
        if imenu -c "enable bluetooth?"; then
            instantsudo /usr/share/instantsettings/utils/enablebluetooth.sh
        else
            return
        fi
    fi

    CHOICE="$(echo '>>h Bluetooth settings
:b Set up new device
:b Bluetooth applet
:b Back' | sidebar)"

    case "$CHOICE" in
    *applet)
        toggleiconf bluetoothapplet "enable bluetooth applet?"

        if iconf -i bluetoothapplet; then
            blueman-applet &
        else
            pgrep blueman-applet && pkill blueman-applet &
        fi

        bluetoothsettings
        ;;
    *device)
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

appearancesettings() {
    CHOICE="$(echo '>>h Appearance settings
:b Application appearance
:y Wallpaper
:b Enable compositing
:b 並V-Sync
:b Blur
:b Autotheming
:b Back' | sidebar)"

    case $CHOICE in
    *appearance)
        lxappearance
        ;;
    *compositing)
        if ! iconf -i nocompositing; then
            toggleiconf nocompositing "enable compositing?" i
        else
            toggleiconf nocompositing "enable compositing?" i
            if ! iconf -i nocompositing; then
                iconf -i potato 0
            fi
        fi
        if iconf -i nocompositing; then
            pgrep picom && pkill picom
        else
            pgrep picom || ipicom
        fi
        appearancesettings
        ;;
    *Autotheming)
        toggleiconf notheming "enable instantOS theming? (disable for custom gtk themes)?" i
        appearancesettings
        ;;
    *V-Sync)
        toggleiconf vsync "enable compositor V-Sync?"
        if pgrep picom; then
            pkill picom
            sleep 0.3
            ipicom &
        fi
        appearancesettings
        ;;
    *Blur)
        toggleiconf blur "enable blur?"
        if pgrep picom; then
            pkill picom
            sleep 0.3
            ipicom &
        fi
        appearancesettings
        ;;
    *Wallpaper)
        wallpapersettings
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
        soundsettings
        ;;
    *Appearance)
        appearancesettings
        ;;
    *instantOS)
        instantossettings
        ;;
    *Software)
        instantpacman &
        ;;
    *Display)
        displaysettings
        ;;
    *Keyboard)
        /usr/share/instantassist/assists/t/k.sh 123
        ;;
    *Printing)
        instantinstall cups system-config-printer ghostscript || exit
        if ! systemctl is-active --quiet org.cups.cupsd.service; then
            if imenu -c "enable printer support?"; then
                enableservices() {
                    systemctl enable org.cups.cupsd.service
                    systemctl start org.cups.cupsd.service
                }
                instantsudo bash -c "$(declare -f enableservices); enableservices"
            else
                exit
            fi
        fi
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
    *date)
        timesettings
        ;;
    *applications)
        defaultapplicationsettings
        ;;
    esac
done
