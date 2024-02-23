#!/usr/bin/env bash

# Get HDMI1 Parameter
# Note: xrandr HDMI1 display information is added when HDMI1 is plugged
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_STATUS_LEN=$(xrandr | awk '$1~/HDMI1/ {print NF}')
HDMI1_HEIGHT_ID=$HDMI1_STATUS_LEN
HDMI1_WIDTH_ID=$(($HDMI1_HEIGHT_ID - 2))
HDMI1_HEIGHT=$(xrandr | awk -v var=$HDMI1_HEIGHT_ID '$1~/HDMI1/ {print $var}')
HDMI1_WIDTH=$(xrandr | awk -v var=$HDMI1_WIDTH_ID '$1~/HDMI1/ {print $var}')
ICON="$HOME/.config/i3/share/32x32/monitor.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_display_operator.sh [options] [conky]"
    echo ""
    echo "OPTIONS"
    echo "  [auto]: use preset configuration"
    echo "  [eDP1_only]: activate eDP1 only"
    echo "  [HDMI1_only]: activate HDMI1 only"
    echo "  [eDP1_HDMI1_joint]: activate eDP1 and HDMI1 in joint mode"
    echo "  [eDP1_HDMI1_mirror]: activate eDP1 and HDMi1 in mirror mode"
    echo "  [HDMI1_default]: activate HDMI1 in default mode"
    echo "  [HDMI1_extend]: activate HDMI1 in extended mode"
    echo "  [HDMI1_primary]: set HDMI1 as primary display"
    echo "  [eDP1_default]: activate HDMI1 in default mode"
    echo "  [eDP1_shrink]: activate eDP1 in shrink mode"
    echo "  [eDP1_primary]: set eDP1 as primary display"
    echo
    echo "CONKY"
    echo "  [enable]: show conky after changing"
    echo "  [disable]: do not show conky after changing"
}

# Reload conky after monitor display is set
reload_conky () {
    # Reload conky
    killall conky; sleep 1
    i3-msg exec "conky -c $HOME/.config/conky/conky_config_bindkey"
    i3-msg exec "conky -c $HOME/.config/conky/conky_config_system"
}

reload_misc () {
    # Reload wallpaper
    feh --bg-fill $HOME/.config/i3/share/default_wallpaper
    # Reload compositor
    $I3_SCRIPT/i3_picom_operator.sh default
}

HDMI1_shrink () {
    # Create new mode
    xrandr --newmode "1912x960_60.00"  152.20  1912 2024 2232 2552  960 961 964 994  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode HDMI1 "1912x960_60.00"
}

HDMI1_extend () {
    # Create new mode
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode HDMI1 "1920x1200_50.00"
}

eDP1_shrink () {
    # Create new mode
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    # Add new mode to eDP1
    xrandr --addmode eDP1 "1440x810_60.00"
}

auto_adjust () {
    if [ $HDMI1_STATUS == 'connected' ]; then
        # IOA 24': 520mm x 290mm
        if [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
            notify-send -u low "Set Display Automatically" "IOA 24' connected" --icon=${ICON}
            # Adjust eDP1 & HDMI1
            HDMI1_extend; eDP1_shrink
            # Locate eDP1 & HDMI1
            xrandr \
                --output eDP1 --mode 1440x810_60.00 --pos 0x195 --rotate normal \
                --output HDMI1 --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary
        # ACER 27': 600mm x 340mm
        elif [ $HDMI1_WIDTH == "600mm" ] && [ $HDMI1_HEIGHT == "340mm" ]; then
            notify-send -u low "Set Display Automatically" "ACER 27' connected" --icon=${ICON}
            # Adjust eDP1
            eDP1_shrink
            # Locate eDP1 & HDMI1
            xrandr \
                --output eDP1 --mode 1440x810_60.00 --pos 0x270 --rotate normal \
                --output HDMI1 --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary
        # Rent: 0mm x 0mm (unknown)
        elif [ $HDMI1_WIDTH == "0mm" ] && [ $HDMI1_HEIGHT == "0mm" ]; then
            notify-send -u low "Set Display Automatically" "Rent unknown connected" --icon=${ICON}
            # Adjust eDP1 & HDMI1
            HDMI1_extend; eDP1_shrink
            # Locate eDP1 & HDMI1 (extented)
            xrandr \
                --output eDP1 --mode 1440x810_60.00 --pos 0x390 --rotate normal \
                --output HDMI1 --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary
        # Other HDMI:
        else
            notify-send -u low "Set Display Automatically" "External HDMI1 connected" --icon=${ICON}
            xrandr --output HDMI1 --auto --primary --right-of eDP1
        fi
    # Laptop display only
    else
        notify-send -u low "Set Display Automatically" "No HDMI1 connected, eDP1 connected" --icon=${ICON}
        xrandr --output eDP1 --mode 1920x1080 --primary --output HDMI1 --off
    fi
}

display_operation () {
    case $1 in
        "eDP1_only" )
            notify-send -u low "Set Display" "Activate eDP1 only" --icon=${ICON}
            xrandr --output HDMI1 --off --output eDP1 --auto --primary
            ;;
        "HDMI1_only" )
            notify-send -u low "Set Display" "Activate HDMI1 only" --icon=${ICON}
            xrandr --output eDP1 --off --output HDMI1 --auto --primary
            ;;
        "eDP1_HDMI1_joint" )
            notify-send -u low "Set Display" "Activate HDMI1 joint mode" --icon=${ICON}
            xrandr --output eDP1 --auto --output HDMI1 --auto --primary --right-of eDP1
            ;;
        "eDP1_HDMI1_mirror" )
            notify-send -u low "Set Display" "Activate HDMI1 mirror mode" --icon=${ICON}
            xrandr --output eDP1 --auto --output HDMI1 --auto --primary --same-as eDP1
            ;;
        "HDMI1_extend" )
            notify-send -u low "Set Display" "Activate HDMI1 extend mode (1920x1200)" --icon=${ICON}
            HDMI1_extend
            xrandr --output HDMI1 --mode "1920x1200_50.00"
            ;;
        "HDMI1_default" )
            notify-send -u low "Set Display" "Activate HDMI1 default mode (1920x1080)" --icon=${ICON}
            xrandr --output HDMI1 --mode "1920x1080"
            ;;
        "eDP1_shrink" )
            notify-send -u low "Set Display" "Activate eDP1 shrink mode (1440x810)" --icon=${ICON}
            eDP1_shrink
            xrandr --output eDP1 --mode "1440x810_60.00"
            ;;
        "eDP1_default" )
            notify-send -u low "Set Display" "Activate eDP1 default mode (1920x1080)" --icon=${ICON}
            xrandr --output eDP1 --mode "1920x1080"
            ;;
        "HDMI1_primary" )
            notify-send -u low "Set Display" "Set HDMI1 as primary display" --icon=${ICON}
            xrandr --output HDMI1 --primary
            ;;
        "eDP1_primary" )
            notify-send -u low "Set Display" "Set eDP1 as primary display" --icon=${ICON}
            xrandr --output eDP1 --primary
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
main () {
    # Automatically setup display
    if [ $1 == "auto" ]; then
        auto_adjust
    else
        display_operation $1
    fi
    # Conky
    if [ $2 == "enable" ]; then
        reload_conky
    fi
    # Miscellaneous
    reload_misc
}

# Main
main $1 $2
