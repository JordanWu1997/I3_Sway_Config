#!/bin/bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_backlight_operator.sh [operations] [backlight_levels]"
    echo ""
    echo "OPERATIONS"
    echo "  [set_focused_display_backlight_with_rofi]: set focused output backlight to input value [0~100]"
    echo "  [set_all_connected_displays_backlight_with_rofi]: set all connected outputs backlight to input value [0~100]"
    echo "  [set_xbacklight_with_rofi]: set xbacklight to input value [0~100]"
    echo "  [set_xbacklight]: set xbacklight to argument backlight_levels"
    echo "  [inc_xbacklight]: increase xbacklight in amount argument backlight_levels"
    echo "  [dec_xbacklight]: decrease xbacklight in amount argument backlight_levels"
    echo "  [show_xbacklight]: show current xbacklight backlight levels"
    echo ""
    echo "BACKLIGHT_LEVELS"
    echo "  [0~100]: number between 0 and 100"
}

show_xbacklight () {
    # Try xbacklight first, and then brightnessctl
    command -v xbacklight && printf -v BACKLIGHT "%0.0f" "$(xbacklight)"
    command -v brightnessctl && printf -v BACKLIGHT "%0.0f" "$(brightnessctl | grep 'Current brightness' | tr '()%' '\n\n ' | awk 'NR==2')"
    # Send notification
    ICON="$HOME/.config/i3/share/64x64/lightbulb_icon.png"
    NOTIFY_SEND_VERSION=$(notify-send -v | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
    if (( $(echo ${NOTIFY_SEND_VERSION}) > 7 | bc -l )); then
        NOTIFY_ID=19970920
        notify-send -r ${NOTIFY_ID} -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
    else
        notify-send -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
    fi
}

backlight_operation () {
    case $1 in
        "set_focused_display_backlight_with_rofi")
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
                --output "${FOCUS_OUTPUT}" \
                --brightness "${INPUT_LEVEL}:${INPUT_LEVEL}:${INPUT_LEVEL}"
            ;;
        "set_all_connected_displays_backlight_with_rofi")
            # Get backlight input level from user input via rofi
            INPUT_LEVEL=$(rofi -dmenu -p "Set all connected displays backlight to [0~100]: ")
            if (( $(echo "${INPUT_LEVEL} < 0" | bc -l) )); then
                INPUT_LEVEL=1
            elif (( $(echo "${INPUT_LEVEL} > 100" | bc -l) )); then
                INPUT_LEVEL=100
            fi
            INPUT_LEVEL=$(echo "scale=1; ${INPUT_LEVEL}/100" | bc)
            for FOCUS_OUTPUT in $(xrandr | grep ' connected' | awk '{print $1}'); do
                # Set backlight
                xrandr \
                    --output "${FOCUS_OUTPUT}" \
                    --brightness "${INPUT_LEVEL}:${INPUT_LEVEL}:${INPUT_LEVEL}"
            done
            ;;
        "set_xbacklight_with_rofi")
            # Get backlight input level from user input via rofi
            INPUT_LEVEL=$(rofi -dmenu -p "Set xbacklight to [0~100]:")
            if (( $(echo "${INPUT_LEVEL} < 0" | bc -l) )); then
                INPUT_LEVEL=1
            elif (( $(echo "${INPUT_LEVEL} > 100" | bc -l) )); then
                INPUT_LEVEL=100
            fi
            # Set backlight
            command -v xbacklight && xbacklight -set "${INPUT_LEVEL}"
            command -v brightnessctl && brightnessctl set "${INPUT_LEVEL}%"
            # Show backlight
            show_xbacklight
            ;;
        "set_xbacklight")
            INPUT_LEVEL=$2
            # Set backlight
            command -v xbacklight && xbacklight -set "${INPUT_LEVEL}"
            command -v brightnessctl && brightnessctl set "${INPUT_LEVEL}%"
            # Show backlight
            show_xbacklight
            ;;
        "inc_xbacklight")
            INPUT_LEVEL=$2
            # Set backlight
            command -v xbacklight && xbacklight -inc "${INPUT_LEVEL}" && show_xbacklight && exit
            command -v brightnessctl && brightnessctl set "+${INPUT_LEVEL}%" && show_xbacklight && exit
            ;;
        "dec_xbacklight")
            INPUT_LEVEL=$2
            # Set backlight
            command -v xbacklight && xbacklight -dec "${INPUT_LEVEL}" && show_xbacklight && exit
            command -v brightnessctl && brightnessctl set "${INPUT_LEVEL}%-" && show_xbacklight && exit
            ;;
        "show_xbacklight")
            show_xbacklight
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

backlight_operation $1 $2
