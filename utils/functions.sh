#!/usr/bin/env bash
getsidebarwidth()
{
    CURRENTSETTING="$(iconf settingswinpos)"
    SIDEBARWIDTH=400
    case $CURRENTSETTING in
        *center)
            SIDEBARWIDTH=800
            ;;
        *)
            ;;
    esac
    echo "$SIDEBARWIDTH"
}

getwinpos()
{
    CURRENTSETTING="$(iconf settingswinpos)"

    HORIZONTALOFFSET=0
    case $CURRENTSETTING in
        *left)
            HORIZONTALOFFSET=0
            ;;
        *center)
            eval "$(xdotool getmouselocation --shell)"

            for i in $(xrandr | pcregrep -o3 '(\d+)x(\d+)\+(\d+)\+(\d+)' | sort); do
                if (( X > i )); then
                     MONITORSTART=$i
                fi
            done

            SCREENWIDTH=$(xrandr | pcregrep -o1 "(\d+)x(\d+)\+$MONITORSTART\+(\d+)")

            HORIZONTALOFFSET=$(( (SCREENWIDTH - $(getsidebarwidth))/2 ))
            ;;
        *)
            HORIZONTALOFFSET=100000
            ;;
    esac

    echo "$HORIZONTALOFFSET"
}

sidebar() {
    querystring="${1:-search...}"
    shift
    sbs="$SIDEBARSEARCH"
    SIDEBARSEARCH=
    instantmenu -it "$sbs" -l 2000 -w -$(getsidebarwidth) -i -h -1 -x $(getwinpos) -y -1 -bw 4 -H -q "$querystring" "$@"
}

die() {
    imenu -m "error: $1"
    exit 1
}

# System to attach data to functions see: https://github.com/erichs/composure

for f in about menu; do eval "$f() { :; }"; done
unset f # "register" keywords

meta() {
    typeset funcname="$1"
    typeset keyword="$2"

    if [ -z "$funcname" ] || [ -z "$keyword" ]; then
        printf '%s\n' 'missing parameter(s)'
        return
    fi

    typeset -f -- "$funcname" |
        sed -n "/$keyword / s/['\";]*$//;s/^[ 	]*$keyword ['\"]*\([^([].*\)*$/\1/p" ||
        echo "name: $funcname; kw: $keyword" 1>&2
}

_shell() {
    typeset this=$(ps -o comm -p $$ | tail -1 | awk '{print $NF}' | sed 's/^-*//')
    echo "${this##*/}"
}

list_func_names() {
    typeset shell="$(_shell)"
    if [ "$shell" = "bash" ] || [ "$shell" = "sh" ] || echo "$SHELL" | grep -q "bash$"; then
        typeset -F | awk '{print $3}'
    else
        typeset +f | sed 's/().*$//'
    fi
}
