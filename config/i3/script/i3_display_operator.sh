#!/usr/bin/env bash

# Get HDMI1 Parameter
# NOTE: xrandr HDMI1 display information is added when HDMI1 is plugged
HDMI1_STATUS=$(xrandr | awk '$1~/HDMI-?1/ {print $2}')
HDMI1_STATUS_LEN=$(xrandr | awk '$1~/HDMI-?1/ {print NF}')
HDMI1_HEIGHT_ID=$HDMI1_STATUS_LEN
HDMI1_WIDTH_ID=$(($HDMI1_HEIGHT_ID - 2))
HDMI1_HEIGHT=$(xrandr | awk -v var="$HDMI1_HEIGHT_ID" '$1~/HDMI-?1/ {print $var}')
HDMI1_WIDTH=$(xrandr | awk -v var="$HDMI1_WIDTH_ID" '$1~/HDMI-?1/ {print $var}')
ICON="$HOME/.config/i3/share/64x64/monitor.png"

# eDP-1, eDP1; HDMI-1, HDMI1
if xrandr | grep eDP1 -q; then
    eDP1='eDP1'
    HDMI1='HDMI1'
else
    eDP1='eDP-1'
    HDMI1='HDMI-1'
fi

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
    echo "  [eDP1]"
    echo "      [eDP1_default]: activate HDMI1 in default mode"
    echo "      [eDP1_auto]: activate eDP1"
    echo "      [eDP1_shrink1]: activate eDP1 in shrink mode (1440x810_60)"
    echo "      [eDP1_shrink2]: activate eDP1 in shrink mode (1368x768)"
    echo "      [eDP1_primary]: set eDP1 as primary display"
    echo "      [eDP1_off]: deactivate eDP1"
    echo "  [HDMI1]"
    echo "      [HDMI1_auto]: activate HDMI1"
    echo "      [HDMI1_default]: activate HDMI1 in default mode"
    echo "      [HDMI1_extend]: activate HDMI1 in extended mode"
    echo "      [HDMI1_primary]: set HDMI1 as primary display"
    echo "      [HDMI1_off]: deactivate HDMI1"
    echo "  [Combination]"
    echo "      [eDP1_HDMI1_joint]: activate eDP1 and HDMI1 in joint mode (eDP1+HDMI1)"
    echo "      [HDMI1_eDP1_joint]: activate eDP1 and HDMI1 in joint mode (HDMI1+eDP1)"
    echo "      [eDP1_HDMI1_mirror]: activate eDP1 and HDMi1 in mirror mode"
    echo "  [Preset/Auto]"
    echo "      [auto]: use preset configuration"
    echo "      [auto_in_office]: use preset configuration in office"
    echo "      [auto_at_home]: use preset configuration at home"
    echo "  [Interactive Selection]"
    echo "      [select_display_position]: select display position (top-left)"
    echo "      [select_display_mode]: select display mode"
    echo "      [select_display_as_primary]: select display as primary display"
    echo "      [select_display_orientation]: select display orientation"
    echo "      [select_display_scale]: select display scale"
    echo "      [show_display_layout]: show display layout"
    echo ""
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
    feh --bg-fill "$HOME/.config/i3/share/default_wallpaper"
    # Reload compositor
    "$I3_SCRIPT/i3_picom_operator.sh" default
}

HDMI1_shrink () {
    # Create new mode
    xrandr --newmode "1912x960_60.00"  152.20  1912 2024 2232 2552  960 961 964 994  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode "${HDMI1}" "1912x960_60.00"
}

HDMI1_extend () {
    # Create new mode
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode "${HDMI1}" "1920x1200_50.00"
}

eDP1_shrink () {
    # Create new mode
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    # Add new mode to eDP1
    xrandr --addmode "${eDP1}" "1440x810_60.00"
}

auto_adjust () {
    if [ "${HDMI1_STATUS}" == 'connected' ]; then
        # Rent: 520mm x 290mm, IOA 24': 520mm x 290mm
        if [ "${HDMI1_WIDTH}" == "520mm" ] && [ "${HDMI1_HEIGHT}" == "290mm" ]; then
            #notify-send -u low "Set Display Automatically" "IOA 24' connected" --icon="${ICON}"
            notify-send -u low "Set Display Automatically" "Rent 24' connected" --icon="${ICON}"
            # Adjust eDP1 & HDMI1
            HDMI1_extend; eDP1_shrink
            # Set-1: Locate eDP1 (1440x810) & HDMI1 (1920x1200)
            #xrandr \
                #--output "${HDMI1}" --mode 1920x1080 --pos 1440x0 --rotate normal --primary \
                #--output "${eDP1}" --mode 1440x810_60.00 --pos 0x135 --rotate normal
            # Set-2: Locate eDP1 (1440x810) & HDMI1 (1920x1080)
            #xrandr \
                #--output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary \
                #--output "${eDP1}" --mode 1440x810_60.00 --pos 0x195 --rotate normal
            # Set-3: Locate eDP1 (auto) & HDMI1 (1920x1080)
            xrandr \
                --output "${HDMI1}" --mode 1920x1080 --primary \
                --output "${eDP1}" --auto --left-of ${HDMI1}
            # Set-4: Disable eDP1 & enable HDMI1 (1920x1080)
            #xrandr \
               #--output "${HDMI1}" --mode 1920x1080 --rotate normal --primary \
               #--output "${eDP1}" --off
        # ACER 27': 600mm x 340mm
        elif [ "${HDMI1_WIDTH}" == "600mm" ] && [ "${HDMI1_HEIGHT}" == "340mm" ]; then
            notify-send -u low "Set Display Automatically" "ACER 27' connected" --icon="${ICON}"
            # Adjust eDP1
            eDP1_shrink
            # Locate eDP1 & HDMI1
            xrandr \
                --output "${eDP1}" --mode 1440x810_60.00 --pos 0x270 --rotate normal \
                --output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary
        # Rent: 0mm x 0mm (unknown)
        elif [ "${HDMI1_WIDTH}" == "0mm" ] && [ "${HDMI1_HEIGHT}" == "0mm" ]; then
            notify-send -u low "Set Display Automatically" "Rent unknown connected" --icon="${ICON}"
            # Adjust eDP1 & HDMI1
            HDMI1_extend; eDP1_shrink
            # Locate eDP1 & HDMI1 (extented)
            xrandr \
                --output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary \
                --output "${eDP1}" --mode 1440x810_60.00 --pos 0x390 --rotate normal
        # Other HDMI:
        else
            notify-send -u low "Set Display Automatically" "External HDMI1 connected" --icon="${ICON}"
            xrandr --output "${HDMI1}" --auto --primary --right-of "${eDP1}"
        fi
    # Laptop display only
    else
        #notify-send -u low "Set Display Automatically" "No HDMI1 connected, eDP1 connected" --icon="${ICON}"
        #xrandr --output "${eDP1}" --mode 1920x1080 --primary --output "${HDMI1}" --off
        notify-send -u low "Set Display Automatically" "Connect to DP-1 (normal), DP-4 (normal), HDMI-0 (right)" --icon="${ICON}"
        xrandr \
            --output "DP-1" --mode 1920x1080 --pos 0x280 --rotate inverted --brightness 0.9:0.9:0.9 --primary \
            --output "DP-4" --mode 1920x1200 --scale 0.8x0.8 --pos 0x1360 --rotate normal \
            --output "HDMI-0" --mode 1360x768 --pos 1920x0 --rotate right --brightness 0.8:0.8:0.8
    fi
}

select_display_mode () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/connected/ {print $1}'))
    DISPLAY_NLS=($(xrandr | awk '$0~/connected/ {print NR}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[MODE] Select DISPLAY')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    # Select DISPLAY mode
    SELECTED_DISPLAY_ID=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | awk -v SELECTED_DISPLAY="${SELECTED_DISPLAY}" '$1 == SELECTED_DISPLAY {print NR}')
    AWK_START=$(expr ${DISPLAY_NLS[$(expr ${SELECTED_DISPLAY_ID} - 1)]} + 1)
    if [[ ${SELECTED_DISPLAY_ID} == ${#DISPLAYS[@]} ]]; then
        AWK_END=$(xrandr | wc -l)
    else
        AWK_END=${DISPLAY_NLS[$(expr ${SELECTED_DISPLAY_ID})]}
    fi
    DISPLAY_MODES=$(xrandr | awk -v start_NL="${AWK_START}" -v end_NL="${AWK_END}" 'NR >= start_NL && NR < end_NL {print $1}')
    if [[ -z "${DISPLAY_MODES}" ]]; then
        # Early stop
        echo "[ERROR] NO Available DISPLAY Mode for ${SELECTED_DISPLAY}. Exiting ..."
        return
    fi
    # Add "off" option
    SELECTED_DISPLAY_MODE=$(echo "${DISPLAY_MODES[*]} off" | tr ' ' '\n' | rofi -dmenu -i -p "Select ${SELECTED_DISPLAY} mode")
    if [[ ${SELECTED_DISPLAY_MODE} == 'off' ]]; then
        xrandr --output "${SELECTED_DISPLAY}" --off
    else
        xrandr --output "${SELECTED_DISPLAY}" --mode "${SELECTED_DISPLAY_MODE}"
    fi
}

select_display_position () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/connected/ {print $1}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[POSITION] Select DISPLAY')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    # Input DISPLAY position
    INPUT_POS=$(xrandr | grep ' connected' | rofi -dmenu -i -p "Set ${SELECTED_DISPLAY} Position (x,y)")
    if [[ -z "${INPUT_POS}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY Position for ${SELECTED_DISPLAY} is set. Exiting ..."
        return
    fi
    INPUT_POS_X=$(echo "${INPUT_POS}" | cut -d, -f1)
    INPUT_POS_Y=$(echo "${INPUT_POS}" | cut -d, -f2)
    POS_X=$(printf "%.0f" $(echo "scale=2; ${INPUT_POS_X}" | bc -l))
    POS_Y=$(printf "%.0f" $(echo "scale=2; ${INPUT_POS_Y}" | bc -l))
    xrandr --output "${SELECTED_DISPLAY}" --pos "${POS_X}x${POS_Y}"
}

select_display_as_primary () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[PRIMARY] Select DISPLAY as primary')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    xrandr --output "${SELECTED_DISPLAY}" --primary
}

select_display_scale () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[SCALE] Select DISPLAY')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    # Select scale
    SELECTED_SCALE=$(rofi -dmenu -p 'Set DISPLAY scale')
    if [[ ! $(echo "${SELECTED_SCALE}" | bc -l) == "0" ]]; then
        xrandr --output "${SELECTED_DISPLAY}" --scale "${SELECTED_SCALE}x${SELECTED_SCALE}"
    fi
}

select_display_orientation () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[ORIENTATION] Select DISPLAY')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    # Select orientation
    SELECTED_ORIENTATION=$(echo 'normal left right inverted' | tr ' ' '\n' | rofi -dmenu -i -auto-select -p 'Select DISPLAY orientation')
    if [[ -n "${SELECTED_ORIENTATION}" ]]; then
        xrandr --output "${SELECTED_DISPLAY}" --rotate "${SELECTED_ORIENTATION}"
    fi
}

display_operation () {
    case $1 in
        # Combination of HDMI1, eDP1
        "eDP1_HDMI1_joint")
            notify-send -u low "Set Display" "Activate eDP1-HDMI1 joint mode" --icon="${ICON}"
            xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --right-of "${eDP1}"
            ;;
        "eDP1_HDMI1_mirror")
            notify-send -u low "Set Display" "Activate eDP1-HDMI1 mirror mode" --icon="${ICON}"
            xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --same-as "${eDP1}"
            ;;
        "HDMI1_eDP1_joint")
            notify-send -u low "Set Display" "Activate eDP1-HDMI1 joint mode" --icon="${ICON}"
            xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --left-of "${eDP1}"
            ;;
        # HDMI1
        "HDMI1_auto")
            notify-send -u low "Set Display" "Activate HDMI1 (auto)" --icon="${ICON}"
            xrandr --output "${HDMI1}" --auto
            ;;
        "HDMI1_off")
            notify-send -u low "Set Display" "Deactivate HDMI1 (off)" --icon="${ICON}"
            xrandr --output "${HDMI1}" --off
            ;;
        "HDMI1_extend")
            notify-send -u low "Set Display" "Activate HDMI1 extend mode (1920x1200_50.00)" --icon="${ICON}"
            HDMI1_extend
            xrandr --output "${HDMI1}" --mode "1920x1200_50.00"
            ;;
        "HDMI1_default")
            notify-send -u low "Set Display" "Activate HDMI1 default mode (1920x1080)" --icon="${ICON}"
            xrandr --output "${HDMI1}" --mode "1920x1080"
            ;;
        "HDMI1_primary")
            notify-send -u low "Set Display" "Set HDMI1 as primary display" --icon="${ICON}"
            xrandr --output "${HDMI1}" --primary
            ;;
        # eDP1
        "eDP1_auto")
        notify-send -u low "Set Display" "Activate eDP1 (auto)" --icon="${ICON}"
            xrandr --output "${eDP1}" --auto
            ;;
        "eDP1_off")
            notify-send -u low "Set Display" "Deactivate eDP1 (off)" --icon="${ICON}"
            xrandr --output "${eDP1}" --off
            ;;
        "eDP1_shrink1")
            notify-send -u low "Set Display" "Activate eDP1 shrink mode (1440x810)" --icon="${ICON}"
            eDP1_shrink
            xrandr --output "${eDP1}" --mode "1440x810_60.00"
            ;;
        "eDP1_shrink2")
            notify-send -u low "Set Display" "Activate eDP1 shrink mode (1368x768)" --icon="${ICON}"
            xrandr --output "${eDP1}" --mode "1368x768"
            ;;
        "eDP1_default")
            notify-send -u low "Set Display" "Activate eDP1 default mode (1920x1080)" --icon="${ICON}"
            xrandr --output "${eDP1}" --mode "1920x1080"
            ;;
        "eDP1_primary")
            notify-send -u low "Set Display" "Set eDP1 as primary display" --icon="${ICON}"
            xrandr --output "${eDP1}" --primary
            ;;
        # Interactive selection
        "select_display_position")
            select_display_position
            ;;
        "select_display_mode")
            select_display_mode
            ;;
        "select_display_as_primary")
            select_display_as_primary
            ;;
        "select_display_orientation")
            select_display_orientation
            ;;
        "select_display_scale")
            select_display_scale
            ;;
        "show_display_layout")
            notify-send -u low "Display Mode" "$(xrandr --listmonitors)" --icon="${ICON}"
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
    case $1 in
        "auto")
            auto_adjust
            ;;
        "auto_in_office")
            setup_monitors.sh auto_in_office
            ;;
        "auto_at_home")
            setup_monitors.sh auto_at_home
            ;;
        *)
            display_operation "$1"
    esac

    # Reload conky
    [[ "$2" == "enable" ]] && reload_conky

    # Miscellaneous
    sleep 1; reload_misc
}

# Main
main "$@"
