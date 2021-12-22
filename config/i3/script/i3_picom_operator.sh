#!/usr/bin/env bash

killall picom

case $1 in
    "default")
        i3-msg exec "picom"
        ;;
    "blur")
        i3-msg exec "picom --config ${HOME}/.config/picom/picom_blur.conf"
        ;;
    "transparency")
        i3-msg exec "picom --config ${HOME}/.config/picom/picom_transparency.conf"
        ;;
    *)
        echo $0
esac
