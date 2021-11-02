#!/bin/bash

# Get HDMI1 Parameter
HDMI_POS=$1
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_WIDTH=$(xrandr | awk '$1~/HDMI1/ {print $13}')
HDMI1_HEIGHT=$(xrandr | awk '$1~/HDMI1/ {print $15}')

# Joint Display
if [ $HDMI1_STATUS == 'connected' ]; then
    if [ $HDMI_POS == 'right' ]; then

        # ACER 27': 600mm x 340mm
        if [ $HDMI1_WIDTH == "600mm" ] && [ $HDMI1_HEIGHT == "340mm" ]; then
            echo "ACER 27'"
            # Locate eDP1 & HDMI1
            $I3_BIN/i3_shrink_eDP1.sh && xrandr \
                --output eDP1 --pos 0x270 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1080 --primary

        # IOA 24': 520mm x 290mm
        elif [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
            echo "IOA 24'"
            # Locate eDP1 & HDMI1
            $I3_BIN/i3_extend_HDMI1.sh && $I3_BIN/i3_shrink_eDP1.sh && xrandr \
                --output eDP1 --pos 0x195 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1200_50.00 --primary

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

# Reload wallpaper
feh --bg-fill $HOME/.config/i3/share/default_wallpaper

# Reload compositor
/usr/local/bin/picom --config $HOME/.config/picom/picom_blur.conf
#/usr/local/bin/picom --config $HOME/.config/picom/picom_transparency.conf
