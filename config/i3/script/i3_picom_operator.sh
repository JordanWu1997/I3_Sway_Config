#!/usr/bin/env bash

killall picom

if [ -z $1 ]; then
    echo $0
elif [ $1 == "default" ]; then
    picom
elif [ $1 == "blur" ]; then
    picom --config ${HOME}/.config/picom/picom_blur.conf
elif [ $1 == "transparency" ]; then
    picom --config ${HOME}/.config/picom/picom_transparency.conf
else
    echo $0
fi
