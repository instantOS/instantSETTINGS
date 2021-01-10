#!/usr/bin/env bash

# graphical settings menu for instantOS

source /usr/share/instantsettings/utils/functions.sh
[ -r ./utils/functions.sh ] && source ./utils/functions.sh

# access specific settings page from external script
if [ "$1" = "-s" ] && [ -z "$SCRIPTSETTINGS" ]; then
    if [ -z "$2" ]; then
        echo "usage: instantsettings -s settingspage"
    fi
    export SCRIPTSETTINGS="true"
    source /usr/bin/instantsettings
    eval "$2"
    exit
fi

asksetting() {
    menu '>>h Settings'
    menu ':y SEARCH ALL' #  
    menu ':b 墳Sound'
    menu ':b instantOS'
    menu ':b Display'
    menu ':g Network'
    menu ':b Install Software'
    menu ':y Appearance'
    menu ':b Bluetooth'
    menu ':g Power'
    menu ':b Keyboard'
    menu ':b Mouse'
    menu ':b Default applications'
    menu ':b Language'
    menu ':g Time and date'
    menu ':b 朗Printing'
    menu ':r Storage'
    menu ':y Advanced'
    menu ':y Dotfiles'
    menu ':r Close Settings'
    meta asksetting menu |
        instantmenu -ps 1 -l 2000 -w -$SIDEBAR_WIDTH -i -h -1 -x $SIDEBAR_POS -y -1 -bw 4 -H -q "search"
}

# Variables for global settings search
declare -A allsettings
export SIDEBARSEARCH=
export CFG_CACHE="${XDG_CACHE_HOME:-~/.cache}/instantos/allsettings.bash"
[ -r "$CFG_CACHE" ] && source -- "$CFG_CACHE"

filter_entries() {
    typeset funcname="$1"
    # Filter out a few things
    meta "$funcname" menu |
        grep -vE "^(>>h|>h)" |
        grep -vE "(Apply|Back|Custom|Yes|No|Close|Close Settings|permanent|Edit|Reset|ALL)$"
}

searchall() {
    if [ ${#allsettings[*]} -eq 0 ]; then
        for funcname in $(list_func_names); do
            OLDIFS="$IFS"
            IFS=$'\n'
            for entry in $(filter_entries "$funcname"); do
                allsettings["$entry"]="$funcname"
            done
            IFS="$OLDIFS"
        done
        declare -p allsettings >"$CFG_CACHE" 2>/dev/null
    fi
    CHOICE=$(for k in "${!allsettings[@]}"; do echo "$k"; done | sidebar)
    [ -z "$CHOICE" ] && return
    SIDEBARSEARCH="${CHOICE:4}"
    "${allsettings["$CHOICE"]}" -ps 1
    SIDEBARSEARCH=
}

soundsettings() {
    menu '>>h Sound settings'
    menu ':b ﰝSystem audio'
    menu ':y Notification sound'
    menu ':b Back'

    CHOICE="$(meta soundsettings menu | sidebar)"
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
    menu '>>h Notification sound settings'
    menu ':b Custom'
    menu ':y 碑Reset'
    menu ':r Mute'

    CHOICE="$(meta notificationsettings menu | sidebar)"
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
    menu '>>h Default applications'
    menu ':b Browser'
    menu ':b 龍System monitor'
    menu ':b Terminal emulator'
    menu ':b File manager'
    menu ':b Application launcher'
    menu ':y Text editor'
    menu ':r Lock screen'
    menu ':b Back'

    CHOICE="$(meta defaultapplicationsettings menu | sidebar)"
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
    *screen)
        selectlockscreen
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
    selectdefault "appmenu" "Application launcher"
}

selectsystemmonitor() {
    selectdefault "systemmonitor" "System Monitor"
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
        defaultapplicationsettings
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

    if ! grep -q ',' <<<"$INSTALLCOMMAND"; then
        if command -v "$SETCOMMAND"; then
            return
        fi
        instantinstall "$INSTALLCOMMAND"
    else
        echo "multiple dependencies detected"
        INSTALLLIST="$(sed 's/\,/ /g' <<<"$INSTALLCOMMAND")"
        for i in $(echo $INSTALLLIST); do
            echo "multi installing"
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
    selectdefault editor "Text editor"
}

selectlockscreen() {
    selectdefault lockscreen "Lock Screen"
}

displaysettings() {
    menu '>>h Display Settings'
    menu ':b Change display settings'
    menu ':g Make current settings permanent'
    menu ':y Change screen brightness'
    menu ':b Autodetect monitor docking'
    menu ':b External screen'
    menu ':b HiDPI'
    menu ':b Keep screen on when locked'
    menu ':b Settings window positioning'

    CHOICE="$({
        meta displaysettings menu
        [ -e /usr/bin/nvidia-smi ] &&
            echo ':g 來Nvidia'
        echo ':b Back'
    } | sidebar)"
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
    *locked)
        toggleiconf nolocktimeout "keep monitor on when the screen is locked?"
        displaysettings
        ;;
    *Nvidia)
        instantinstall nvidia-settings || exit 1
        nvidia-settings
        exit
        ;;
    *positioning)
        settingspositioning
        displaysettings
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac
}

advancedsettings() {
    menu '>>h Advanced settings'
    menu ':b Firewall'
    menu ':y TLP'
    menu ':g Bootloader'
    menu ':b Pacman cache autoclean'
    menu ':b 力Systemd'
    menu ':b Lightdm'
    menu ':b Back'

    CHOICE="$(meta advancedsettings menu | sidebar)"
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
    *Pacman*cache*autoclean)
        instantinstall pacman-contrib
        if imenu -c 'Enable weekly autoclean pacman cache?'; then
            instantsudo bash -c 'sed -e "s;paccache -r;paccache -rk3 -ruk1;g" /usr/lib/systemd/system/paccache.service | tee /usr/lib/systemd/system/instantpaccache.service; cp /usr/lib/systemd/system/paccache.timer /usr/lib/systemd/system/instantpaccache.timer; systemctl daemon-reload; systemctl enable --now instantpaccache.timer'
        else
            instantsudo systemctl disable --now instantpaccache.timer
        fi
        ;;
    *Systemd)
        instantinstall cockpit chromium
        if ! systemctl is-enabled cockpit.socket; then
            instantsudo systemctl enable --now cockpit.socket || exit 1
            sleep 4
            imenu -m "sign in with $(whoami) in the next window"
        fi
        chromium --app="http://localhost:9090" &
        exit
        ;;
    *Lightdm)
        instantintall lightdm-gtk-greeter-settings || exit 1
        pkexec lightdm-gtk-greeter-settings
        exit
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac
}

wallpapersettings() {
    menu '>>h Wallpaper settings'
    menu ':b Generate new wallpaper'
    menu ':b Set own wallpaper'
    menu ':b Browse wallpapers'
    menu ':b Custom wallpaper with logo'
    menu ':b Logo'
    menu ':b Repair wallpaper'
    menu ':b Colored wallpaper'
    menu ':b Export current wallpaper'
    menu ':b Back'

    CHOICE="$(meta wallpapersettings menu | sidebar)"
    case $CHOICE in
    *Generate*)
        instantwallpaper clear && instantwallpaper w
        ;;
    *Export*)
        if [ -e ~/instantos/wallpapers/instantwallpaper.png ]; then
            SAVEPATH="$(zenity --file-selection --save --confirm-overwrite)"
            if [ -n "$SAVEPATH" ]; then
                cp ~/instantos/wallpapers/instantwallpaper.png "$SAVEPATH"
                exit
            else
                wallpapersettings
                return
            fi
        else
            imenu -m "no instantwallpaper set"
            wallpapersettings
            return
        fi
        ;;
    *Browse*)
        instantwallpaper select &
        ;;
    *Colored*)
        coloredwallsettings
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

coloredwallsettings() {

    menu '>>h Colored wallpaper'
    menu ':b Use colored wallpaper'
    menu ':b Foreground color'
    menu ':b Background color'
    menu ':b Back'
    CHOICE="$(meta coloredwallsettings menu | sidebar)"

    askcolor() {
        RETCOLOR="$(zenity --color-selection)"
        [ -z "$RETCOLOR" ] && return 1
        printf "#%02x%02x%02x\n" $(grep -o '[0-9,]*' <<<"$RETCOLOR" | sed 's/,/ /g')
    }

    refreshwall() {
        if iconf -i coloredwallpaper; then
            echo "refreshing colored wallpaper"
            notify-send 'generating colored wallpaper'
            {
                instantwallpaper color "$(iconf bgcolor:\#ffffff)" "$(iconf fgcolor:\#00000)"
                instantwallpaper set ~/instantos/wallpapers/color/customcolor.png
            } &
        else
            imenu -m 'Colored wallpaper is currently disabled. Your settings will not take effect until you enable it'
        fi
    }
    case "$CHOICE" in
    *wallpaper)
        toggleiconf coloredwallpaper "use solid colors as wallpaper?"
        if iconf -i coloredwallpaper; then
            [ -e ~/instantos/wallpapers/color/customcolor.png ] || instantwallpaper color "$(iconf fgcolor:\#ffffff)" "$(iconf fgcolor:\#00000)"
            instantwallpaper set ~/instantos/wallpapers/color/customcolor.png
        else
            instantwallpaper clear
        fi
        coloredwallsettings
        return
        ;;
    *Foreground*)
        FGCOLOR="$(askcolor)"
        [ -n "$FGCOLOR" ] && iconf fgcolor "$FGCOLOR"
        refreshwall
        coloredwallsettings
        return
        ;;
    *Background*)
        BGCOLOR="$(askcolor)"
        [ -n "$BGCOLOR" ] && iconf bgcolor "$BGCOLOR"
        refreshwall
        coloredwallsettings
        return
        ;;
    *)
        echo "going back"
        wallpapersettings
        return
        ;;
    esac
}

networksettings() {
    menu '>>h Network settings'
    menu ':b Start network applet'
    menu ':g Autostart network applet'
    menu ':b IP info'
    menu ':b 龍Test internet speed'
    menu ':b Back'

    CHOICE="$(meta networksettings menu | sidebar)"
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
            TEMPIP="$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')"
            if grep -q '192' <<<"$TEMPIP"; then
                echo "$TEMPIP" | grep '192' | tail -1
            else
                echo "$TEMPIP" | tail -1
            fi
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
    *speed)
        instantspeedtest
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
Auto detect
Year $YEAR
Month $MONTH
Day $DAY
Hour $HOUR
Minute $MINUTE
:g Apply
:b Back" | sidebar)"
        echo "datechoice $DATECHOICE"
        case "$DATECHOICE" in
        *detect)
            if imenu -c 'auto detect time?'; then
                instantsudo systemctl enable --now systemd-timesyncd
            else
                instantsudo systemctl disable --now systemd-timesyncd
            fi
            ;;
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
            if systemctl is-enabled systemd-timesyncd; then
                instantsudo systemctl disable --now systemd-timesyncd
            fi
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
    menu '>>h Language settings'
    menu ':b Application Language'
    menu ':g Timezone'
    menu ':b Back'

    fetchlanguage
    CHOICE="$(meta languagesettings menu | sidebar)"
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
    menu '>>h instantOS settings'
    menu ':b Edit Autostart script'
    menu ':b Edit Session Environment'
    menu ':b Theming'
    menu ':y Potato'
    menu ':b 𧻓Animations'
    menu ':b ﰪConky Widgets'
    menu ':b Desktop icons'
    menu ':b ﰪDefault layout'
    menu ':b Status bar'
    menu ':b Clipboard manager'
    menu ':b Alttab menu'
    menu ':b Dad joke on lock screen'
    menu ':b Autologin'
    menu ':g Neovim preconfig'
    menu ':r instantOS development tools'
    menu ':b Back'

    CHOICE="$(meta instantossettings menu | sidebar)"
    case $CHOICE in
    *Autostart*)
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
        instantutils open editor ~/.config/instantos/autostart.sh &
        ;;
    *Environment)
        if ! [ -e ~/.instantsession ]; then
            echo "# instantOS Session Environment Script
# This script gets sourced when $(whoami) logs in
# Add environment variables that should be available to all processes executed from your desktop session." > \
                ~/.instantsession
        fi
        instantutils open editor ~/.instantsession &
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
    *Autologin)

        if iconf -i noautologin; then
            LOGINCHANGE="true"
        fi

        toggleiconf noautologin "Do you want to automatically log in on boot?" i
        if [ -n "$LOGINCHANGE" ]; then
            if ! iconf -i noautologin; then
                LOGINUSER="$(imenu -i "automatically log in as" "username" "$(whoami)")"
                if [ -z "$LOGINUSER" ]; then
                    exit
                fi

                if ! id "$LOGINUSER"; then
                    imenu -e "user $LOGINUSER does not exist"
                    iconf -i noautologin 1
                    exit 1
                fi

                if grep -q '^autologin-user' /etc/lightdm/lightdm.conf; then
                    instantsudo sed -i "s/^autologin-user=.*/autologin-user=$LOGINUSER/g" /etc/lightdm/lightdm.conf
                else
                    instantsudo sed -i "s/^\[Seat:\*\]/[Seat:*]\nautologin-user=$LOGINUSER/g" /etc/lightdm/lightdm.conf
                fi
            fi
        else
            if iconf -i noautologin; then
                echo "disabling auto login"
            fi
            instantsudo sed -i '/^autologin-user/d' /etc/lightdm/lightdm.conf
            if grep -q '^autologin-user' /etc/lightdm/lightdm.conf; then
                iconf -i noautologin 0
            fi
        fi

        ;;
    *layout)

        CHOICE="$(echo '>>h Default layout
:b ﱖtile
:b ﱖgrid
:b ﱖfloat
:b ﱖmonocle
:b ﱖtcl
:b ﱖdeck
:b ﱖoverviewlayout
:b ﱖbstack
:b ﱖbstackhoriz
:b Back' | sidebar)"

        if grep -q 'Back' <<<"$CHOICE"; then
            instantossettings
            return
        fi

        # check if layout is valid
        if [ -n "$CHOICE" ] && grep -q ':b ﱖ' <<<"$CHOICE"; then
            LAYOTCHOICE="$(sed 's/^....//g' <<<"$CHOICE")"
            iconf defaultlayout "$LAYOTCHOICE"
        fi
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
This will override any neovim configurations done previously" | imenu -C; then
            echo "installing nvim build"
            exit
        fi
        iconf neovimconfig 1
        iconf -i neovimconfig 1
        instantinstall neovim-git neovim-qt nodejs npm python-pip
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
        toggleiconf noanimations "enable animations?" i

        if iconf -i noanimations; then
            instantwmctrl animated 1
        else
            instantwmctrl animated 3
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

        if iconf -i alttab; then
            instantwmctrl alttab 3
            sleep 0.5
            instantutils alttab
        else
            pkill alttab
            sleep 0.5
            instantwmctrl alttab 1
        fi

        instantinstall alttab
        instantossettings
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac

}

storagesettings() {
    menu '>>h Storage settings'
    menu ':b Open disk management'
    menu ':b 﫭Auto mount disks'
    menu ':b Back'

    CHOICE="$(meta storagesettings menu | sidebar)"
    case $CHOICE in
    *management)
        instantinstall gnome-disk-utility
        gnome-disks &
        ;;
    *disks)
        instantinstall udiskie
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
    menu '>>h Bluetooth settings'
    menu ':b Set up new device'
    menu ':b Bluetooth applet'
    menu ':b Back'

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

    CHOICE="$(meta bluethoothsettings menu | sidebar)"
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
    menu '>>h Mouse settings'
    menu ':b Sensitivity'
    menu ':b Reverse scrolling'
    menu ':b Back'

    CHOICE="$(meta mousesettings menu | sidebar)"
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
    menu '>>h Appearance settings'
    menu ':b Application appearance'
    menu ':y Wallpaper'
    menu ':b Enable compositing'
    menu ':b 並V-Sync'
    menu ':b Blur'
    menu ':b Autotheming'
    menu ':b Back'

    CHOICE="$(meta appearancesettings menu | sidebar)"
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

keyboardsettings() {

    menu '>>h Keyboard settings'
    menu ':b Keyboard layout'
    menu ':b Keyboard variant'
    menu ':b Back'

    CHOICE="$(meta keyboardsettings menu | sidebar)"
    case "$CHOICE" in
    *layout)
        /usr/share/instantassist/assists/t/k.sh 123
        ;;
    *variant)
        CURLAYOUT="$(setxkbmap -query | grep layout | grep -o '..$')"
        VARIANTCHOICE="$(localectl list-x11-keymap-variants "$CURLAYOUT" | imenu -l "select keyboard variant for $CURLAYOUT")"
        iconf keyvariant "$VARIANTCHOICE"
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac

}

settingspositioning() {
    menu 'Settings window positioning'
    menu 'Left'
    menu 'Center'
    menu 'Right'
    menu ':b Back'

    CHOICE="$(meta settingspositioning menu | sidebar)"
    case $CHOICE in
    *Left)
        iconf settingswinpos "left"
        recalculatesidebar
        ;;
    *Center)
        iconf settingswinpos "center"
        recalculatesidebar
        ;;
    *Right)
        iconf settingswinpos "right"
        recalculatesidebar
        ;;
    *)
        LOOPSETTING="True"
        ;;
    esac

}

LOOPSETTING="true"
if [ -n "$SCRIPTSETTINGS" ]; then
    echo "running in scripted mode"
    unset LOOPSETTING
fi
while [ -n "$LOOPSETTING" ]; do
    SETTING="$(asksetting)"
    unset LOOPSETTING
    case "$SETTING" in
    *ALL)
        searchall
        ;;
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
        keyboardsettings
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
        instantutils open editor ~/.instantrc
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
