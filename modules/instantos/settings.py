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

conky = True
logo = True
theming = True
wifi = False

class Handler:
    def mainwindow_destroy_cb(self, *args):
        Gtk.main_quit()
    def cancelbutton_clicked_cb(self, button):
        Gtk.main_quit()
    def okbutton_clicked_cb(self, button):
        applysettings()
        Gtk.main_quit()
    
    def applybutton_clicked_cb(self, button):
        applysettings()

    def editbutton_clicked_cb(self, button):
        os.system('urxvt -e "nvim" -c ":e ~/.instantautostart" &')

    def themeswitch_state_set_cb(self, button, state):
        global theming
        theming = state
    def wifiswitch_state_set_cb(self, button, state):
        global wifi
        wifi = state
    def logoswitch_state_set_cb(self, button, state):
        global logo
        logo = state
    def conkyswitch_state_set_cb(self, button, state):
        global conky
        conky = state

def applysettings():
    print(wifi)
    if not conky:
        os.system("iconf -i noconky 1")
    else:
        os.system("iconf -i noconky 0")

    if not theming:
        os.system("iconf -i notheming 1")
    else:
        os.system("iconf -i notheming 0")
    if not logo:
        os.system("iconf -i nologo 1")
    else:
        os.system("iconf -i nologo 0")

    if wifi:
        os.system("iconf -i wifiapplet 1")
        os.system("nm-applet &")
    else:
        os.system("pkill nm-applet &")
        os.system("iconf -i wifiapplet 0")

builder = Gtk.Builder()

builder.add_from_file(os.path.dirname(
    os.path.realpath(__file__)) + "/instantos.glade")

builder.connect_signals(Handler())

window = builder.get_object('window')
window.show_all()

Gtk.main()
