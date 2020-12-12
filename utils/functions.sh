#!/usr/bin/env bash

sidebar() {
    instantmenu -l 2000 -w -400 -i -h -1 -x 100000 -y -1 -bw 4 -H -q "${1:-search...}"
}

die() {
    imenu -m "error: $1"
    exit 1
}

# System to attach data to functions see: https://github.com/erichs/composure

for f in about menu; do eval "$f() { :; }"; done; unset f  # "register" keywords

meta () {
    about prints function metadata associated with keyword

    typeset funcname=$1
    typeset keyword=$2

    if [ -z "$keyword" ]; then
        printf '%s\n' 'missing parameter(s)'
        reference metafor
        return
    fi

    typeset -f "$funcname" |
        sed -n "/$keyword / s/['\";]*$//;s/^[ 	]*$keyword ['\"]*\([^([].*\)*$/\1/p"
}

menuentries () {
    typeset funcname=$1

    meta "$funcname" menu |
        grep -vP "(>>h|>h|Apply|Back|Custom|Yes|No|Edit)$"  # Filter out a few things
}
