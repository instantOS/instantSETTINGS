#!/bin/bash
echo "enabling bluetooth support"
systemctl enable bluetooth
pacman -S --noconfirm --needed pulseaudio-module-bluetooth
systemctl start bluetooth
