#!/usr/bin/env bash

killall picom

if [ -z $1 ]; then
    echo $0
elif [ $1 == "default" ]; then
    i3-msg exec "picom"
elif [ $1 == "blur" ]; then
    i3-msg exec "picom --config ${HOME}/.config/picom/picom_blur.conf"
elif [ $1 == "transparency" ]; then
    i3-msg exec "picom --config ${HOME}/.config/picom/picom_transparency.conf"
else
    echo $0
fi
