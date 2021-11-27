#!/usr/bin/env bash

# Note: For monitor in IOA, 1920x1200 maximal refresh rate is 50

if [ -z $1 ]; then
    echo $0
elif [ $1 == "HDMI1" ]; then
    if [ $2 == "default" ]; then
        xrandr --output HDMI1 --mode "1650x1080"
    elif [ $2 == "extend" ]; then
        # Create new mode and save to VIRTUAL1
        xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
        # Add new mode to HDMI1
        xrandr --addmode HDMI1 "1920x1200_50.00"
    else
        echo $0
    fi
elif [ $1 == "eDP1" ]; then
    if [ $2 == "default" ]; then
        xrandr --output eDP1 --mode "1920x1080"
    elif [ $2 == "shrink" ]; then
        # Create new mode and save to VIRTUAL1
        xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
        # Add new mode to eDP1
        xrandr --addmode eDP1 "1440x810_60.00"
    else
        echo $0
    fi
else
    echo $0
fi
