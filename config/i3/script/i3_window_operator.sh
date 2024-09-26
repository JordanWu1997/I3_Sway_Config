#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_window_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [float_then_fullfil_workspace]: make current window floating and resize to fullfil the workspace"
    echo "  [center_current]: make current window floating and move to center of monitor"
    echo "  [toggle_sticky_current]: toggle current window stickiness"
    echo "  [resize_to_input]: resize window to input width and height"
    echo "  [move_floating_to_input]: move floating window to input X and Y"
    echo "  [resize_to_input_and_move_floating_to_input]: including"
    echo "      (1) resize tiling or floating window to input width and height"
    echo "      (2) move floating window to input X and Y"
    echo "  [float_all]: make all windows in current workspace floating"
    echo "  [tile_all]: make all windows in current workspace tiled"
    echo "  [hide_all]: send all windows to scratchpad"
    echo "  [show_all_scratchpad]: show all windows in scratchpad"
    echo "  [hide_all_floating]: send all floating windows to scratchpad"
}

resize_to_input () {
    # Assign resize threshold
    THRESHOLD="${1:-100}"
    # Get focus window
    FOCUS_WINDOW_ID=$(xdotool getwindowfocus)
    WINDOW_GEOMETRY=$(xdotool getwindowgeometry $(xdotool getwindowfocus) | grep Geometry | tr -d ' ' | cut -d: -f2)
    WINDOW_HEIGHT=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f2)
    WINDOW_WIDTH=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f1)
    # Get workspace width and height (NOTE: i3 gap size is included)
    HEIGHT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.height')
    WIDTH=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.width')
    # Resize window width
    if [[ $(echo "(${WIDTH} - ${WINDOW_WIDTH}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_WIDTH=$(rofi -dmenu -p "Set WD width to")
        if [[ -n ${INPUT_WIDTH} ]]; then
            if [[ ${INPUT_WIDTH: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_WIDTH} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=2; ${PERCENTAGE} / 100 * ${WIDTH}" | bc -l))
            elif [[ $(echo "${INPUT_WIDTH} <= 1" | bc -l) == "1" ]]; then
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=2; ${INPUT_WIDTH} * ${WIDTH}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_WIDTH} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px"
    fi
    # Resize window height
    if [[ $(echo "(${HEIGHT} - ${WINDOW_HEIGHT}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_HEIGHT=$(rofi -dmenu -p "Set WD height to")
        if [[ -n ${INPUT_HEIGHT} ]]; then
            if [[ ${INPUT_HEIGHT: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_HEIGHT} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=2; ${PERCENTAGE} / 100 * ${HEIGHT}" | bc -l))
            elif [[ $(echo "${INPUT_HEIGHT} <= 1" | bc -l) == "1" ]]; then
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=2; ${INPUT_HEIGHT} * ${HEIGHT}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_HEIGHT} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set height ${INPUT_HEIGHT} px"
    fi
    # Force to switch focus back (for floating window)
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus"
}

move_floating_to_input () {
    # Get focus window
    FOCUS_WINDOW_ID=$(xdotool getwindowfocus)
    WINDOW_LOCATION=$(xdotool getwindowgeometry ${FOCUS_WINDOW_ID} | grep Position | cut -d' ' -f4)
    # Get window border width
    I3_CONFIG="$HOME/.config/i3/config"
    BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' ${I3_CONFIG})
    # Get window location
    WINDOW_X=$(echo ${WINDOW_LOCATION} | cut -d',' -f1)
    WINDOW_Y=$(echo ${WINDOW_LOCATION} | cut -d',' -f2)
    # Get workspace location and size (NOTE: i3 gap size is included)
    X=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.x')
    Y=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.y')
    WIDTH=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.width')
    HEIGHT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.height')
    # INPUT X, Y
    INPUT_X=$(rofi -dmenu -p "Set WD Top-Left X to")
    INPUT_Y=$(rofi -dmenu -p "Set WD Top-Left Y to")
    # Validate X, Y
    if [[ -n ${INPUT_X} ]]; then
        if [[ ${INPUT_X: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_X} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            INPUT_X=$(printf "%.0f" $(echo "scale=2; ${PERCENTAGE} / 100 * ${WIDTH}" | bc -l))
        elif [[ $(echo "${INPUT_X} <= 1" | bc -l) == "1" ]]; then
            INPUT_X=$(printf "%.0f" $(echo "scale=2; ${INPUT_X} * ${WIDTH}" | bc -l))
        fi
        # Add workspace offset
        INPUT_X=$(expr ${INPUT_X} + ${X})
    else
        # Add border offset
        INPUT_X=$(expr ${WINDOW_X} - ${BORDER_WIDTH})
    fi
    if [[ -n ${INPUT_Y} ]]; then
        if [[ ${INPUT_Y: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_Y} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            INPUT_Y=$(printf "%.0f" $(echo "scale=2; ${PERCENTAGE} / 100 * ${HEIGHT}" | bc -l))
        elif [[ $(echo "${INPUT_Y} <= 1" | bc -l) == "1" ]]; then
            INPUT_Y=$(printf "%.0f" $(echo "scale=2; ${INPUT_Y} * ${HEIGHT}" | bc -l))
        fi
        # Add workspace offset
        INPUT_Y=$(expr ${INPUT_Y} + ${Y})
    else
        # Add border offset
        INPUT_Y=$(expr ${WINDOW_Y} - ${BORDER_WIDTH})
        # Add bar offset
        DEFAULT_BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
        DEFAULT_BAR_POS=$(awk '$0~/default_i3bar_position/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
        if [[ ${DEFAULT_BAR_MODE} == 'dock' ]] && [[ ${DEFAULT_BAR_POS} == 'top' ]]; then
            DEFAULT_BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
            INPUT_Y=$(expr ${INPUT_Y} - ${DEFAULT_BAR_HEIGHT})
        fi
    fi
    # Move window location to X, Y
    i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${INPUT_X} px ${INPUT_Y} px"
}

window_operation () {
    ICON="$HOME/.config/i3/share/64x64/window.png"
    case $1 in
        "float_then_fullfil_workspace")
            # Get focus window ID
            CURRENT_WINDOW_ID=$(xdotool getwindowfocus)
            # Get workspace width and height
            WIDTH=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.width')
            HEIGHT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.height')
            # Get window border width
            I3_CONFIG="$HOME/.config/i3/config"
            BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' ${I3_CONFIG})
            # Open an empty window to occupy the space to keep the tiling layout in tact
            CURRENT_FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${CURRENT_WINDOW_ID} -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)
            if [[ ! ${CURRENT_FLOATING_STATUS} == '"user_on"' ]]; then
                i3-msg open
            fi
            # Floating
            i3-msg "[id=${CURRENT_WINDOW_ID}] floating enable"
            i3-msg "[id=${CURRENT_WINDOW_ID}] border pixel ${BORDER_WIDTH}"
            # Resize to fulfil lfullscreen
            i3-msg "[id=${CURRENT_WINDOW_ID}] resize set width ${WIDTH} px height ${HEIGHT} px"
            i3-msg "[id=${CURRENT_WINDOW_ID}] move position center, focus"
            ;;
        "center_current")
            # Floating
            i3-msg "floating enable"
            # Center window
            i3-msg "move position center"
            ;;
        "toggle_sticky_current")
            # Get window information
            CURRENT_WINDOW_ID=$(xdotool getwindowfocus)
            CURRENT_STICKY_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${CURRENT_WINDOW_ID} -A1 | tr \, '\n' | grep '"sticky":' | cut -d: -f2)
            CURRENT_FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${CURRENT_WINDOW_ID} -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)
            DEFAULT_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
            # Sticky status
            if [[ ${CURRENT_STICKY_STATUS} == "true" ]]; then
                i3-msg "sticky disable"; i3-msg 'title_format "%title"'
                # Restore titlebar style to default
                DEFAULT_STYLE=$(awk '$0~/default_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
                DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
                if [[ ${CURRENT_FLOATING_STATUS} == '"user_on"' ]]; then
                    i3-msg border ${DEFAULT_FLOATING_STYLE} ${DEFAULT_WIDTH}
                else
                    i3-msg border ${DEFAULT_STYLE} ${DEFAULT_WIDTH}
                fi
                # Send notification if there is no titlebar
                if [[ ${DEFAULT_FLOATING_STYLE} == "pixel" ]]; then
                     notify-send -u low "i3 Window Manager" "Focused window is NO LONGER sticky" --icon=${ICON}
                fi
            elif [[ ${CURRENT_STICKY_STATUS} == "false" ]]; then
                i3-msg "sticky enable"; i3-msg 'title_format "[STICKY] %title [STICKY]"'
                i3-msg border normal ${DEFAULT_WIDTH}
            else
                i3-msg "sticky toggle"
                notify-send -u low "i3 Window Manager" "Cannot get focused window sticky status\nWindow stickiness is just toggled" --icon=${ICON}
            fi
            ;;
        "show_geometry")
            FOCUS_WINDOW_ID=$(xdotool getwindowfocus)
            WINDOW_GEOMETRY=$(xdotool getwindowgeometry $(xdotool getwindowfocus) | grep Geometry | tr -d ' ' | cut -d: -f2)
            HEIGHT=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.height')
            WIDTH=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).rect.width')
            NAME=$(i3-msg -t get_workspaces | jq -r '.[] | select(.focused).name')
            notify-send -u low "i3 Window Manager" "Current WD: ${WINDOW_GEOMETRY} (ID: ${FOCUS_WINDOW_ID})\nCurrent WS: ${WIDTH}x${HEIGHT} (NAME: ${NAME})" --icon=${ICON}
            ;;
        "resize_to_input")
            resize_to_input 50
            ;;
        "move_floating_to_input")
            move_floating_to_input
            ;;
        "resize_to_input_and_move_floating_to_input")
            FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep $(xdotool getwindowfocus) -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)
            if [[ ${FLOATING_STATUS} == '"user_on"' ]]; then
                resize_to_input 0
                move_floating_to_input
            else
                resize_to_input 50
            fi
            ;;
        "float_all")
            i3-msg [workspace='__focused__'] floating enable
            ;;
        "tile_all")
            i3-msg [workspace='__focused__'] floating disable
            ;;
        "hide_all")
            i3-msg [workspace='__focused__'] floating enable
            i3-msg [floating] move scratchpad
            ;;
        "show_all_scratchpad")
            i3-msg [all] scratchpad show
            ;;
        "hide_all_floating")
            i3-msg [floating] move scratchpad
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
flash_window
window_operation $@
flash_window
