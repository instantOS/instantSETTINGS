#!/bin/bash

sidebar() {
    instantmenu -l 2000 -w -400 -i -h -1 -x 100000 -y -1 -bw 4 -H -q "${1:-search...}"
}

die() {
    imenu -m "error: $1"
    exit 1
}
