#!/bin/bash

if [ $1 == "shrink" ]; then
    # Create new mode and save to VIRTUAL1
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    # Add new mode to eDP1
    xrandr --addmode eDP1 "1440x810_60.00"
    # Shrink eDP1 display from 1920x1080 to 1440x810
    xrandr --output eDP1 --mode "1440x810_60.00"
elif [ $1 == "reset" ]; then
    xrandr --output eDP1 --mode "1920x1080"
else
    # Default behavior: Add new mode to eDP1
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    xrandr --addmode eDP1 "1440x810_60.00"
fi
