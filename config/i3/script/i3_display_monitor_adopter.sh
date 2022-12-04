#!/usr/bin/env bash

# Get HDMI1 Parameter
# Note: xrandr HDMI1 display information is added when HDMI1 is plugged
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI1/ {print $2}')
HDMI1_STATUS_LEN=$(xrandr | awk '$1~/HDMI1/ {print NF}')
HDMI1_HEIGHT_ID=$HDMI1_STATUS_LEN
HDMI1_WIDTH_ID=$(($HDMI1_HEIGHT_ID - 2))
HDMI1_HEIGHT=$(xrandr | awk -v var=$HDMI1_HEIGHT_ID '$1~/HDMI1/ {print $var}')
HDMI1_WIDTH=$(xrandr | awk -v var=$HDMI1_WIDTH_ID '$1~/HDMI1/ {print $var}')

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_display_monitor_adopter.sh [adoption] [options]"
    echo ""
    echo "ADOPTION"
    echo "  [auto]: adopt preset configuration"
    echo "  [options]: adopt following input options"
    echo
    echo "OPTIONS"
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

display_monitor_adoption () {
    # Joint Display
    case $1 in
        # Automatically setup display
        "auto")
            if [ $HDMI1_STATUS == 'connected' ]; then
                # IOA 24': 520mm x 290mm
                if [ $HDMI1_WIDTH == "520mm" ] && [ $HDMI1_HEIGHT == "290mm" ]; then
                    notify-send -u low "Set Display Automatically" "IOA 24' connected"
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
                    notify-send -u low "Set Display Automatically" "ACER 27' connected"
                    # Locate eDP1 & HDMI1
                    $I3_SCRIPT/i3_display_operator.sh eDP1 shrink && xrandr \
                        --output eDP1 --pos 0x270 --output HDMI1 --pos 1440x0 \
                        --output eDP1 --mode 1440x810_60.00 \
                        --output HDMI1 --mode 1920x1080 --primary
                    reload_conky
                # Other HDMI:
                else
                    notify-send -u low "Set Display Automatically" "External HDMI1 connected"
                    xrandr --output HDMI1 --auto --primary --right-of eDP1
                fi
            # Laptop display only
            else
                notify-send -u low "Set Display Automatically" "No HDMI1 connected, eDP1 connected"
                xrandr --output eDP1 --mode 1920x1080 --primary --output HDMI1 --off
                reload_conky
            fi
            ;;
        # Additional display option
        "option")
            case $2 in
                "eDP1_only" )
                    notify-send -u low "Set Display" "Activate eDP1 only"
                    xrandr --output HDMI1 --off --output eDP1 --auto --primary
                    reload_conky
                    ;;
                "HDMI1_only" )
                    notify-send -u low "Set Display" "Activate HDMI1 only"
                    xrandr --output eDP1 --off --output HDMI1 --auto --primary
                    reload_conky
                    ;;
                "eDP1_HDMI1_joint" )
                    notify-send -u low "Set Display" "Activate HDMI1 joint mode"
                    xrandr --output eDP1 --auto --output HDMI1 --auto --primary --right-of eDP1
                    reload_conky
                    ;;
                "eDP1_HDMI1_mirror" )
                    notify-send -u low "Set Display" "Activate HDMI1 mirror mode"
                    xrandr --output eDP1 --auto --output HDMI1 --auto --primary --same-as eDP1
                    reload_conky
                    ;;
                "HDMI1_extend" )
                    notify-send -u low "Set Display" "Activate HDMI1 extend mode (1920x1200)"
                    $I3_SCRIPT/i3_display_operator.sh HDMI1 extend
                    xrandr --output HDMI1 --mode "1920x1200_50.00"
                    reload_conky
                    ;;
                "HDMI1_default" )
                    notify-send -u low "Set Display" "Activate HDMI1 default mode (1920x1080)"
                    $I3_SCRIPT/i3_display_operator.sh HDMI1 default
                    reload_conky
                    ;;
                "eDP1_shrink" )
                    notify-send -u low "Set Display" "Activate eDP1 shrink mode (1440x810)"
                    $I3_SCRIPT/i3_display_operator.sh eDP1 shrink
                    xrandr --output eDP1 --mode "1440x810_60.00"
                    reload_conky
                    ;;
                "eDP1_default" )
                    notify-send -u low "Set Display" "Activate eDP1 default mode (1920x1080)"
                    $I3_SCRIPT/i3_display_operator.sh eDP1 default
                    reload_conky
                    ;;
                "HDMI1_primary" )
                    notify-send -u low "Set Display" "Set HDMI1 as primary display"
                    xrandr --output HDMI1 --primary
                    ;;
                "eDP1_primary" )
                    notify-send -u low "Set Display" "Set eDP1 as primary display"
                    xrandr --output eDP1 --primary
                    ;;
                *)
                    show_wrong_usage_message
                    echo
                    show_help_message
                    exit
            esac
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
    reload_misc
}

# Main
display_monitor_adoption $1 $2
