#!/bin/bash
# window to drag applications to rox desktop

if ! pgrep ROX; then
    rox --pinboard Default
fi

zenity --info --text="drag icons to the desktop to add them" --title="Desktop icons\!" &
cd /usr/share/applications/
rox .
