#!/usr/bin/env python3

##########################################
## set mouse sensitivity using libinput ##
##########################################

from gi.repository import Gtk
import subprocess
import pathlib
import gi
import os

gi.require_version('Gtk', '3.0')

# won't show icons otherwise
settings = Gtk.Settings.get_default()
settings.props.gtk_button_images = True


def applyscale(value):
    mousefactor = (int(value) - 50) / 50
    print("setting mouse sensitivity to" + str(mousefactor))
    subprocess.Popen(["instantmouse", "s", str(mousefactor)])
    return mousefactor


class Handler:

    def window_destroy_cb(self, *args):
        Gtk.main_quit()

    def cancelbutton_clicked_cb(self, button):
        builder.get_object('window').destroy()

    def okbutton_clicked_cb(self, button):
        mousescale = builder.get_object('mousescale')
        newmousefactor = applyscale(mousescale.get_value())
        subprocess.Popen(["iconf", "mousespeed", str(newmousefactor)])
        builder.get_object('window').destroy()

    def applybutton_clicked_cb(self, button):
        mousescale = builder.get_object('mousescale')
        applyscale(mousescale.get_value())


builder = Gtk.Builder()
builder.add_from_file(os.path.dirname(
    os.path.realpath(__file__)) + "/mouse.glade")

builder.connect_signals(Handler())

window = builder.get_object('window')
window.show_all()

Gtk.main()
