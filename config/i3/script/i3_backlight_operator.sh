#!/bin/bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_backlight_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [set_focused_display]: set focused output backlight to input value [0~100]"
    echo "  [set_xbacklight]: set xbacklight to input value [0~100]"
}

backlight_operation () {
    case $1 in
        "set_focused_display_backlight")
            # Get backlight input level from user input via rofi
            INPUT_LEVEL=$(rofi -dmenu -p "Set focused display backlight to [0~100]: ")
            if (( $(echo "${INPUT_LEVEL} < 0" | bc -l) )); then
                INPUT_LEVEL=1
            elif (( $(echo "${INPUT_LEVEL} > 100" | bc -l) )); then
                INPUT_LEVEL=100
            fi
            # Get focues output display
            INPUT_LEVEL=$(echo "scale=1; ${INPUT_LEVEL}/100" | bc)
            FOCUS_OUTPUT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).output')
            # Set backlight
            xrandr \
                --output ${FOCUS_OUTPUT} \
                --brightness ${INPUT_LEVEL}:${INPUT_LEVEL}:${INPUT_LEVEL}
            ;;
        "set_xbacklight")
            # Get backlight input level from user input via rofi
            INPUT_LEVEL=$(rofi -dmenu -p "Set xbacklight to [0~100]:")
            if (( $(echo "${INPUT_LEVEL} < 0" | bc -l) )); then
                INPUT_LEVEL=1
            elif (( $(echo "${INPUT_LEVEL} > 100" | bc -l) )); then
                INPUT_LEVEL=100
            fi
            # Set backlight
            xbacklight -set ${INPUT_LEVEL}
            $I3_SCRIPT/i3_xbacklight_notification.sh
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

backlight_operation $1
