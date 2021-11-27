#!/usr/bin/env bash

# Get HDMI1 Parameter
# Note: xrandr HDMI1 display information is added when HDMI1 is plugged
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_STATUS_LEN=$(xrandr | awk '$1~/HDMI1/ {print NF}')
HDMI1_HEIGHT_ID=$HDMI1_STATUS_LEN
HDMI1_WIDTH_ID=$(($HDMI1_HEIGHT_ID - 2))
HDMI1_HEIGHT=$(xrandr | awk -v var=$HDMI1_HEIGHT_ID '$1~/HDMI1/ {print $var}')
HDMI1_WIDTH=$(xrandr | awk -v var=$HDMI1_WIDTH_ID '$1~/HDMI1/ {print $var}')
echo HDMI1 HxW: $HDMI1_HEIGHT, $HDMI1_WIDTH

# Reload conky after monitor display is set
function reload_conky () {
    # Reload conky
    killall conky
    i3-msg exec "conky -c $HOME/.config/conky/conky_config_hotkey"
    i3-msg exec "conky -c $HOME/.config/conky/conky_config_system"
}

# Joint Display
if [ $1 == 'auto' ]; then
    if [ $HDMI1_STATUS == 'connected' ]; then
        # IOA 24': 520mm x 290mm
        if [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
            echo "IOA 24'"
            # Locate eDP1 & HDMI1
            $I3_SCRIPT/i3_display_operator.sh HDMI1 extend && \
                $I3_SCRIPT/i3_display_operator.sh eDP1 shrink && \
                xrandr \
                --output eDP1 --pos 0x195 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1200_50.00 --primary
            reload_conky
        # ACER 27': 600mm x 340mm
        elif [ $HDMI1_WIDTH == "600mm" ] && [ $HDMI1_HEIGHT == "340mm" ]; then
            echo "ACER 27'"
            # Locate eDP1 & HDMI1
            $I3_SCRIPT/i3_display_operator.sh eDP1 shrink && xrandr \
                --output eDP1 --pos 0x270 --output HDMI1 --pos 1440x0 \
                --output eDP1 --mode 1440x810_60.00 \
                --output HDMI1 --mode 1920x1080 --primary
            reload_conky
        # Other HDMI:
        else
            echo "Unknown HDMI1 input"
            xrandr --output HDMI1 --auto --primary --right-of eDP1
        fi
    # Laptop display only
    else
        echo "eDP1 only; all HDMI input disabled"
        xrandr --output eDP1 --mode 1920x1080 --primary --output HDMI1 --off
        reload_conky
    fi
# Additional display option
elif [ $1 == 'option' ] && [ ! -z $2 ]; then
    case $2 in
        "eDP1_only" )
            xrandr --output HDMI1 --off --output eDP1 --auto --primary
            reload_conky
            ;;
        "HDMI1_only" )
            xrandr --output eDP1 --off --output HDMI1 --auto --primary
            reload_conky
            ;;
        "eDP1_HDMI1_joint" )
            xrandr --output eDP1 --auto --output HDMI1 --auto --primary --right-of eDP1
            reload_conky
            ;;
        "eDP1_HDMI1_mirror" )
            xrandr --output eDP1 --auto --output HDMI1 --auto --primary --same-as eDP1
            reload_conky
            ;;
        "HDMI1_extend" )
            $I3_SCRIPT/i3_display_operator.sh HDMI1 extend
            xrandr --output HDMI1 --mode "1920x1200_50.00"
            reload_conky
            ;;
        "HDMI1_default" )
            $I3_SCRIPT/i3_display_operator.sh HDMI1 default
            reload_conky
            ;;
        "eDP1_shrink" )
            $I3_SCRIPT/i3_display_operator.sh eDP1 shrink
            xrandr --output eDP1 --mode "1440x810_60.00"
            reload_conky
            ;;
        "eDP1_default" )
            $I3_SCRIPT/i3_display_operator.sh eDP1 default
            reload_conky
            ;;
        "HDMI1_primary" )
            xrandr --output HDMI1 --primary
            ;;
        "eDP1_primary" )
            xrandr --output eDP1 --primary
            ;;
        *) echo $2
    esac
fi


# Reload wallpaper
feh --bg-fill $HOME/.config/i3/share/default_wallpaper

# Reload compositor
$I3_SCRIPT/i3_picom_operator.sh default
