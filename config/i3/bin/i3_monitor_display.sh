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
    elif [ $HDMI1_WIDTH == "xxxmm" ] && [ $HDMI1_HEIGHT == "xxxmm" ]; then
        echo "IOA 24'"
        xrandr --output HDMI1 --mode 1920x1200 --primary --right-of eDP1
    else
        echo "Unknow HDMI1 input"
        xrandr --output HDMI1 --auto --primary --right-of eDP1
    fi
else
    echo "eDP1 Only"
fi
