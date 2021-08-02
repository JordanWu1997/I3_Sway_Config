#!/bin/bash

# Note: For monitor in IOA, 1920x1200 maximal refresh rate is 50

if [ $1 == "extend" ]; then
    # Create new mode and save to VIRTUAL1
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode HDMI1 "1920x1200_50.00"
    # Shrink HDMI1 display from 1920x1080 to 1440x810
    xrandr --output HDMI1 --mode "1920x1200_50.00"
elif [ $1 == "reset" ]; then
    xrandr --output HDMI1 --mode "1650x1080"
else
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    xrandr --addmode HDMI1 "1920x1200_50.00"
fi
