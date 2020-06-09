#!/bin/bash

# This generates a checklist for enabling or disabling dotfile management

[ -e ~/.instantrc ] || imenu -m "initial dotfile config not found"

[ -e /tmp/instantdotfiles ] && rm -rf /tmp/instantdotfiles

imenu -m "check all dotfiles you would like to be managed by instantOS"

CHECKOPTIONS="$(cat ~/.instantrc | grep -o '^[^#].*' |
    sed 's/^\([^ ]*\) \([01]\)/\2 \1/g' |
    sed 's/^1/TRUE/g' |
    sed 's/^0/FALSE/g' |
    tr '\n' ' ')"

mkdir /tmp/instantdotfiles
cd /tmp/instantdotfiles

echo "zenity --width 500 --height 500 --list --column=Check --column='Dotfile' $CHECKOPTIONS --checklist" > \
    checklist.sh
chmod +x checklist.sh

./checklist.sh >choice

if ! grep -q ..... choice; then
    exit
fi

sed -i 's/|/\n/g' choice
sed -i 's/\(.*\)/\1 1/g' choice

cat ~/.instantrc | sed 's/\(^[^#]*\) [01]/\1 0/g' >temprc

while read p; do
    DOTFILE=$(echo "$p" | grep -o '^[^ ]*')
    echo "choice $DOTFILE"
    sed -i "s|^$DOTFILE .*|$DOTFILE 1|g" temprc
done <choice

OLDDOT="$(cat ~/.instantrc | wc -l)"
NEWDOT="$(cat temprc | wc -l)"

if ! [ "$OLDDOT" = "$NEWDOT" ]; then
    imenu -m "there was an error converting ~/.instantrc"
    exit
fi

cat temprc >~/.instantrc
imenu -m "dotfile management updated successfully."

if imenu -c "would you like to apply all changes now?"; then
    instantdotfiles -f
else
    imenu -m "changes will be applied on the next reboot"
fi
