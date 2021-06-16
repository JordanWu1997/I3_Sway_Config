#!/bin/bash

killall xss-lock

if ( file $HOME/.config/i3/share/default_wallpaper | grep -q PNG ); then
    xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $HOME/.config/i3/share/default_wallpaper
else
    xss-lock -v --transfer-sleep-lock -- i3lock -t -f -i $HOME/.config/i3/share/default_thinkpad_wallpaper.png
fi
