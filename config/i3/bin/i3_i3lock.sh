#!/bin/bash

if ( file $HOME/.config/i3/share/default_wallpaper | grep -q PNG ); then
    i3lock -t -f -i $HOME/.config/i3/share/default_wallpaper
else
    i3lock -t -f -i $HOME/.config/i3/share/default_thinkpad_wallpaper.png
fi
