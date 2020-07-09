#!/usr/bin/env python3

#############################################
## main menu of the instantOS settings app ##
#############################################

import gi
gi.require_version('Gtk', '3.0')

from gi.repository import Gtk
import pathlib
import subprocess
import webbrowser
import os

# won't show icons otherwise
settings = Gtk.Settings.get_default()
settings.props.gtk_button_images = True


class Handler:
    def mainwindow_destroy_cb(self, *args):
        Gtk.main_quit()

    def displaybutton_clicked_cb(self, button):
        popover = builder.get_object('displaypopover')
        popover.popup()

    def networkbutton_clicked_cb(self, button):
        os.system('pgrep nm-applet || nm-applet &')
        popover = builder.get_object('networkpopover')
        popover.popup()

    def diskbutton_clicked_cb(self, button):
        popover = builder.get_object('diskpopover')
        popover.popup()

    def softwarebutton_clicked_cb(self, button):
        subprocess.Popen(["pamac-manager"])

    def learnbutton_clicked_cb(self, button):
        webbrowser.open_new_tab('https://instantos.github.io/instantos.github.io/documentation')

    def soundbutton_clicked_cb(self, button):
        subprocess.Popen(["pavucontrol"])

    def keyboardbutton_clicked_cb(self, button):
        subprocess.Popen(["/opt/instantos/menus/dm/tk.sh"])

    def appearancebutton_clicked_cb(self, button):
        subprocess.Popen(["lxappearance"])

    def displaychange_clicked_cb(self, button):
        subprocess.Popen(['arandr'])
        
    def displaysave_clicked_cb(self, button):
        print("saving display settings")
        subprocess.Popen(['autorandr', '--force', '--save', 'instantos'])

    def printerbutton_clicked_cb(self, button):
        subprocess.Popen(['system-config-printer'])
    def bluethoothbutton_clicked_cb(self, button):
        subprocess.Popen(['blueman-assistant'])
    def instantosbutton_clicked_cb(self, button):
        subprocess.Popen(['/usr/share/instantsettings/modules/instantos/settings.py'])

    def mousebutton_clicked_cb(self, button):
        subprocess.Popen(['/usr/share/instantsettings/modules/mouse/mousesettings.py'])
    def quitbutton_clicked_cb(self, button):
        window.destroy()
    def powerbutton_clicked_cb(self, button):
        subprocess.Popen(['xfce4-power-manager-settings'])

    def dotfilesbutton_clicked_cb(self, button):
        if not pathlib.Path(os.environ['HOME'] + '/.instantrc').exists():
            os.system('instantdotfiles')
        os.system('st -e "nvim" -c ":e ~/.instantrc" &')

    def wallpaperbutton_clicked_cb(self, button):
        popover = builder.get_object('wallpopover')
        popover.popup()
    def wallgenbutton_clicked_cb(self, button):
        os.system('(instantwallpaper clear && instantwallpaper w) &')
    def wallprebutton_clicked_cb(self, button):
        os.system('instantwallpaper select &')
    def wallsetbutton_clicked_cb(self, button):
        os.system('instantwallpaper gui &')
    def firewallbutton_clicked_cb(self, button):
        os.system('gufw &')
    def tlpbutton_clicked_cb(self, button):
        os.system('tlpui &')
    def grubbutton_clicked_cb(self, button):
        os.system('grub-customizer &')
    def udiskswitch_state_set_cb(self, button, state):
        if state:
            os.system("iconf -i udiskie 1 &")
        else:
            os.system("iconf -i udiskie 0 &")
    def appletswitch_state_set_cb(self, button, state):
        if state:
            os.system("iconf -i wifiapplet 1 &")
        else:
            os.system("iconf -i wifiapplet 0 &")

builder = Gtk.Builder()

if pathlib.Path('./mainsettings.glade').exists():
    builder.add_from_file("./mainsettings.glade")
else:
    builder.add_from_file("/usr/share/instantsettings/mainsettings.glade")

builder.connect_signals(Handler())

window = builder.get_object('mainwindow')
window.show_all()

Gtk.main()
