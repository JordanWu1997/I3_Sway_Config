#!/bin/bash

# Get HDMI1 Parameter
# Note: xrandr HDMI1 display information is added when HDMI1 is plugged
HDMI_POS=$1
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_STATUS_LEN=$(xrandr | awk '$1~/HDMI1/ {print NF}')
HDMI1_HEIGHT_ID=$HDMI1_STATUS_LEN
HDMI1_WIDTH_ID=$(($HDMI1_HEIGHT_ID - 2))
HDMI1_HEIGHT=$(xrandr | awk -v var=$HDMI1_HEIGHT_ID '$1~/HDMI1/ {print $var}')
HDMI1_WIDTH=$(xrandr | awk -v var=$HDMI1_WIDTH_ID '$1~/HDMI1/ {print $var}')
echo HDMI1 HxW: $HDMI1_HEIGHT, $HDMI1_WIDTH

# Joint Display
if [ $HDMI1_STATUS == 'connected' ]; then
    if [ $HDMI_POS == 'right' ]; then

        # IOA 24': 520mm x 290mm
        if [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
            echo "IOA 24'"
            # Locate eDP1 & HDMI1
            $I3_SCRIPT/i3_extend_HDMI1.sh && $I3_SCRIPT/i3_shrink_eDP1.sh && xrandr \
                --output eDP1 --pos 0x195 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1200_50.00 --primary

        # ACER 27': 600mm x 340mm
        elif [ $HDMI1_WIDTH == "600mm" ] && [ $HDMI1_HEIGHT == "340mm" ]; then
            echo "ACER 27'"
            # Locate eDP1 & HDMI1
            $I3_SCRIPT/i3_shrink_eDP1.sh && xrandr \
                --output eDP1 --pos 0x270 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1080 --primary

        # Other HDMI:
        else
            echo "Unknown HDMI1 input"
            xrandr --output HDMI1 --auto --primary --right-of eDP1
        fi
    fi

# Laptop display only
else
    echo "eDP1 only; all HDMI input disabled"
    xrandr --output eDP1 --mode 1920x1080 --primary --output HDMI1 --off
fi

## Reload wallpaper
feh --bg-fill $HOME/.config/i3/share/default_wallpaper

 #Reload compositor
killall picom
picom
