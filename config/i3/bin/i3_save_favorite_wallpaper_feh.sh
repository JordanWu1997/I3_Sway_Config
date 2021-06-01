#!/bin/bash

current=$(awk 'NR==2 {print $4}' $HOME/.fehbg | xargs)
default=$HOME/.config/i3/share/default_wallpaper

if [ "$current" != "$default" ]; then
    /bin/cp $current $wallpaperf
fi
