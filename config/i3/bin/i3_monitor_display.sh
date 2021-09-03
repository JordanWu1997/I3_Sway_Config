#!/bin/bash

# HDMI1 Parameter
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_WIDTH=$(xrandr | awk '$1~/HDMI1/ {print $13}')
HDMI1_HEIGHT=$(xrandr | awk '$1~/HDMI1/ {print $15}')

# Joint Display
if [ $HDMI1_STATUS == 'connected' ]; then
    # ACER 27': 600mm x 340mm
    if [ $HDMI1_WIDTH == "600mm" ] && [ $HDMI1_HEIGHT == "340mm" ]; then
        echo "ACER 27'"
        xrandr --output HDMI1 --mode 1920x1080 --primary --right-of eDP1
    #  IOA 24':
    elif [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
        echo "IOA 24'"
        $I3_BIN/i3_extend_HDMI1.sh
        $I3_BIN/i3_shrink_eDP1.sh
        xrandr --output eDP1 --mode 1440x810_60.00
        xrandr --output HDMI1 --mode 1920x1200_50.00 --primary --right-of eDP1
    else
        echo "Unknow HDMI1 input"
        xrandr --output HDMI1 --auto --primary --right-of eDP1
    fi
else
    echo "eDP1 Only"
fi
