#!/bin/bash

if [ ! -f $HOME/.config/i3/share/default_wallpaper ]; then
    /bin/cp $HOME/.config/i3/share/default_i3_wallpaper.png $HOME/.config/i3/share/default_wallpaper
else
    rm -f $home/.config/i3/share/default_wallpaper
    /bin/cp $(cat $HOME/.config/variety/wallpaper/wallpaper.jpg.txt) $HOME/.config/i3/share/default_wallpaper
fi
