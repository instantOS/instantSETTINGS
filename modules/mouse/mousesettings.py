#!/usr/bin/env python3
from gi.repository import Gtk
import subprocess
import pathlib
import gi
gi.require_version('Gtk', '3.0')

# won't show icons otherwise
settings = Gtk.Settings.get_default()
settings.props.gtk_button_images = True


class Handler:

    mousescale = builder.get_object('mousescale')

    def window_destroy_cb(self, *args):
        Gtk.main_quit()

    def cancelbutton_clicked_cb(self, button):
        builder.get_object('window').destroy()

    def okbutton_clicked_cb(self, button):
        builder.get_object('window').destroy()

    def applybutton_clicked_cb(self, button):
        print("frank")

builder = Gtk.Builder()

builder.add_from_file("./mouse.glade")

builder.connect_signals(Handler())

window = builder.get_object('window')
window.show_all()

Gtk.main()
