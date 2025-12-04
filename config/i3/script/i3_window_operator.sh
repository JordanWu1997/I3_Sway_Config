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
    echo "  [float_then_fulfill_workspace]: make current window floating and resize to fulfill the workspace"
    echo "  [center_current]: make current window floating and move to center of monitor"
    echo "  [toggle_sticky_current]: toggle current window stickiness"
    echo "  [resize_to_input]: resize window to input width and height"
    echo "  [move_floating_to_input]: move floating window to input X and Y"
    echo "  [resize_to_input_and_move_floating_to_input]: including"
    echo "      (1) resize tiling or floating window to input width and height"
    echo "      (2) move floating window to input X and Y"
    echo "  [resize_to_input_and_move_floating_to_input_in_one]:"
    echo "       function the same as previous option but you only need to input once"
    echo "  [resize_and_move_floating]: CLI API that reads command line arguments as inputs (1 0 X Y W H)"
    echo "  [float_all]: make all windows in current workspace floating"
    echo "  [tile_all]: make all windows in current workspace tiled"
    echo "  [hide_all]: send all windows to scratchpad"
    echo "  [show_all_scratchpad]: show all windows in scratchpad"
    echo "  [hide_all_floating]: send all floating windows to scratchpad"
}

resize_to_input () {

    # Assign resize threshold for i3 stacking titlebars
    THRESHOLD="${1:-150}"

    # Get focus window
    FOCUS_WINDOW_ID=$(xdotool getwindowfocus)

    # Get default window border width
    I3_CONFIG="$HOME/.config/i3/config"
    BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' ${I3_CONFIG})

    # Get current window floating status
    FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${FOCUS_WINDOW_ID} -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)

    # Hide titlebar BEFORE requiring geometry
    if [[ ${FLOATING_STATUS} == '"user_on"' ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] border pixel ${BORDER_WIDTH}"
    fi

    # Get window geometry
    WINDOW_GEOMETRY=$(xdotool getwindowgeometry ${FOCUS_WINDOW_ID} | grep Geometry | tr -d ' ' | cut -d: -f2)
    WINDOW_WIDTH=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f1)
    WINDOW_HEIGHT=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f2)

    # Get workspace geometry (NOTE: i3 gap_size, bar_height are all included)
    I3_WORKSPACES=$(i3-msg -t get_workspaces)
    WIDTH=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.width')
    HEIGHT=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.height')

    # INPUT_WIDTH
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${WIDTH} - ${WINDOW_WIDTH}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_WIDTH=$(rofi -dmenu -p "Set WD width to")
        if [[ -n ${INPUT_WIDTH} ]]; then
            if [[ ${INPUT_WIDTH: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_WIDTH} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                RATIO_INPUT_WIDTH=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_WIDTH} * ${WIDTH}" | bc -l))
            elif [[ $(echo "${INPUT_WIDTH} <= 1" | bc -l) == "1" ]]; then
                RATIO_INPUT_WIDTH=${INPUT_WIDTH}
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_WIDTH} * ${WIDTH}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_WIDTH} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px"
    fi

    # INPUT_HEIGHT
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${HEIGHT} - ${WINDOW_HEIGHT}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_HEIGHT=$(rofi -dmenu -p "Set WD height to")
        if [[ -n ${INPUT_HEIGHT} ]]; then
            if [[ ${INPUT_HEIGHT: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_HEIGHT} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                RATIO_INPUT_HEIGHT=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_HEIGHT} * ${HEIGHT}" | bc -l))
            elif [[ $(echo "${INPUT_HEIGHT} <= 1" | bc -l) == "1" ]]; then
                RATIO_INPUT_HEIGHT=${INPUT_HEIGHT}
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_HEIGHT} * ${HEIGHT}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_HEIGHT} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set height ${INPUT_HEIGHT} px"
    fi

    # For floating window, restore titlebar AFTER resizing the window
    DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' ${I3_CONFIG} | awk 'NR==1')
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] && [[ ${DEFAULT_FLOATING_STYLE} == "normal" ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] border normal ${BORDER_WIDTH}"
    fi

    # Force to switch focus back (for floating window)
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus"

}

move_floating_to_input () {

    # Get focus window
    FOCUS_WINDOW_ID=$(xdotool getwindowfocus)

    # Get current window floating status
    FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${FOCUS_WINDOW_ID} -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)

    ## If window is not floating -> return
    #if [[ ! ${FLOATING_STATUS} == '"user_on"' ]]; then
    #    return
    #fi

    # Get default window border width
    I3_CONFIG="$HOME/.config/i3/config"
    BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' ${I3_CONFIG})

    # Hide titlebar BEFORE requiring geometry
    i3-msg "[id=${FOCUS_WINDOW_ID}] border pixel ${BORDER_WIDTH}"

    # Get workspace location and geometry (NOTE: i3 gap_size, bar_height are all included)
    I3_WORKSPACES=$(i3-msg -t get_workspaces)
    X=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.x')
    Y=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.y')
    WIDTH=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.width')
    HEIGHT=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.height')

    # Get window position
    WINDOW_POSITION=$(xdotool getwindowgeometry ${FOCUS_WINDOW_ID} | grep Position | cut -d' ' -f4)
    WINDOW_X=$(echo ${WINDOW_POSITION} | cut -d',' -f1)
    WINDOW_Y=$(echo ${WINDOW_POSITION} | cut -d',' -f2)

    # INPUT_X
    INPUT_X=$(rofi -dmenu -p "Set WD Top-Left X to")
    if [[ -n ${INPUT_X} ]]; then
        if [[ ${INPUT_X: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_X} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            RATIO_INPUT_X=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
            INPUT_X=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_X} * ${WIDTH}" | bc -l))
        elif [[ $(echo "${INPUT_X} <= 1" | bc -l) == "1" ]]; then
            RATIO_INPUT_X=${INPUT_X}
            INPUT_X=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_X} * ${WIDTH}" | bc -l))
        fi
        # Add workspace offset
        INPUT_X=$(expr ${INPUT_X} + ${X})
    else
        # Add border offset
        INPUT_X=$(expr ${WINDOW_X} - ${BORDER_WIDTH})
        INPUT_X=$(expr ${INPUT_X} - ${BORDER_WIDTH})
    fi

    # INPUT_Y
    INPUT_Y=$(rofi -dmenu -p "Set WD Top-Left Y to")
    if [[ -n ${INPUT_Y} ]]; then
        if [[ ${INPUT_Y: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_Y} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            RATIO_INPUT_Y=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
            INPUT_Y=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_Y} * ${HEIGHT}" | bc -l))
        elif [[ $(echo "${INPUT_Y} <= 1" | bc -l) == "1" ]]; then
            RATIO_INPUT_Y=${INPUT_Y}
            INPUT_Y=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_Y} * ${HEIGHT}" | bc -l))
        fi
        # Add workspace offset
        INPUT_Y=$(expr ${INPUT_Y} + ${Y})
    else
        # Add border offset
        INPUT_Y=$(expr ${WINDOW_Y} - ${BORDER_WIDTH})
        INPUT_Y=$(expr ${INPUT_Y} - ${BORDER_WIDTH})
    fi

    # Move window location to X, Y (Note: x, y here mean x, y of top-left corner of titlebar)
    i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${INPUT_X} px ${INPUT_Y} px"

    # Restore titlebar AFTER moving the window
    DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' ${I3_CONFIG} | awk 'NR==1')
    if [[ ${DEFAULT_FLOATING_STYLE} == "normal" ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] border normal ${BORDER_WIDTH}"
    fi

    # Switch focus back to window
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus"

}

resize_to_input_and_move_floating_to_input () {

    # Get focus window
    FOCUS_WINDOW_ID=$(xdotool getwindowfocus)

    # Get default window border width
    I3_CONFIG="$HOME/.config/i3/config"
    BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' ${I3_CONFIG})

    # Get current window floating status
    FLOATING_STATUS=$(i3-msg -t get_tree | tr \} '\n' | grep ${FOCUS_WINDOW_ID} -A13 | tr \, '\n' | grep '"floating":' | grep 'user_' | cut -d: -f2)

    # Hide titlebar BEFORE requiring geometry
    if [[ ${FLOATING_STATUS} == '"user_on"' ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] border pixel ${BORDER_WIDTH}"
    fi

    # Get window geometry
    WINDOW_GEOMETRY=$(xdotool getwindowgeometry ${FOCUS_WINDOW_ID} | grep Geometry | tr -d ' ' | cut -d: -f2)
    WINDOW_WIDTH=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f1)
    WINDOW_HEIGHT=$(echo ${WINDOW_GEOMETRY} | cut -d'x' -f2)

    # Get window position
    WINDOW_POSITION=$(xdotool getwindowgeometry ${FOCUS_WINDOW_ID} | grep Position | cut -d' ' -f4)
    WINDOW_X=$(echo ${WINDOW_POSITION} | cut -d',' -f1)
    WINDOW_Y=$(echo ${WINDOW_POSITION} | cut -d',' -f2)

    # Get workspace location and geometry (NOTE: i3 gap size is included)
    I3_WORKSPACES=$(i3-msg -t get_workspaces)
    X=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.x')
    Y=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.y')
    WIDTH=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.width')
    HEIGHT=$(echo ${I3_WORKSPACES} | jq -r '.[] | select(.focused).rect.height')

    # One input or multiple inputs
    ONE_INPUT_FOR_ALL=${1:-0}

    # Assign resize threshold for i3 stacking titlebars
    if [[ ${FLOATING_STATUS} == '"user_on"' ]]; then
        THRESHOLD=0
    else
        THRESHOLD=${2:-150}
    fi

    # Input arguments
    if [[ $# -eq 6 ]]; then
        INPUT_X=$3
        INPUT_Y=$4
        INPUT_WIDTH=$5
        INPUT_HEIGHT=$6
    # One prompt for all
    elif [[ ${ONE_INPUT_FOR_ALL} == "1" ]]; then

        #if [[ ${FLOATING_STATUS} == '"user_on"' ]]; then
        #    INPUTS=$(rofi -dmenu -p "Set WD TL_X,TL_Y,W,H to")
        #    INPUT_X=$(echo ${INPUTS} | cut -d',' -f1)
        #    INPUT_Y=$(echo ${INPUTS} | cut -d',' -f2)
        #    INPUT_WIDTH=$(echo ${INPUTS} | cut -d',' -f3)
        #    INPUT_HEIGHT=$(echo ${INPUTS} | cut -d',' -f4)
        #else
        #    INPUTS=$(rofi -dmenu -p "Set WD W,H to")
        #    INPUT_WIDTH=$(echo ${INPUTS} | cut -d',' -f1)
        #    INPUT_HEIGHT=$(echo ${INPUTS} | cut -d',' -f2)
        #fi

        # Use pre-defined window geometry for both horizontal display and vertical display
        ROFI_CONFIG="$HOME/.config/rofi/config_i3window_vertical.rasi"
        WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_vertical.txt"
        PROMPT="Set Vertical WD TL_X,TL_Y,W,H to"
        if (( ${WIDTH} > ${HEIGHT} )); then
            WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_horizontal.txt"
            ROFI_CONFIG="$HOME/.config/rofi/config_i3window_horizontal.rasi"
            PROMPT="Set Horizontal WD TL_X,TL_Y,W,H to"
        fi
        if [[ -f ${WINDOW_GEOMETRY_TXT} ]]; then
            INPUTS=$(rofi -dmenu -input ${WINDOW_GEOMETRY_TXT} -config ${ROFI_CONFIG} -p "${PROMPT}")
        else
            INPUTS=$(rofi -dmenu -p "Set WD TL_X,TL_Y,W,H to")
        fi
        INPUT_X=$(echo ${INPUTS} | cut -d',' -f1)
        INPUT_Y=$(echo ${INPUTS} | cut -d',' -f2)
        INPUT_WIDTH=$(echo ${INPUTS} | cut -d',' -f3)
        INPUT_HEIGHT=$(echo ${INPUTS} | cut -d',' -f4)
    fi

    # INPUT_WIDTH
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${WIDTH} - ${WINDOW_WIDTH}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        [[ ! ${ONE_INPUT_FOR_ALL} == "1" ]] && INPUT_WIDTH=$(rofi -dmenu -p "Set WD width to")
        if [[ -n ${INPUT_WIDTH} ]]; then
            if [[ ${INPUT_WIDTH: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_WIDTH} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                RATIO_INPUT_WIDTH=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_WIDTH} * ${WIDTH}" | bc -l))
            elif [[ $(echo "${INPUT_WIDTH} <= 1" | bc -l) == "1" ]]; then
                RATIO_INPUT_WIDTH=${INPUT_WIDTH}
                INPUT_WIDTH=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_WIDTH} * ${WIDTH}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_WIDTH} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px"
    fi

    # INPUT_HEIGHT
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${HEIGHT} - ${WINDOW_HEIGHT}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        [[ ! ${ONE_INPUT_FOR_ALL} == "1" ]] && INPUT_HEIGHT=$(rofi -dmenu -p "Set WD height to")
        if [[ -n ${INPUT_HEIGHT} ]]; then
            if [[ ${INPUT_HEIGHT: -1} == '%' ]]; then
                TMP=$(echo ${INPUT_HEIGHT} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
                RATIO_INPUT_HEIGHT=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_HEIGHT} * ${HEIGHT}" | bc -l))
            elif [[ $(echo "${INPUT_HEIGHT} <= 1" | bc -l) == "1" ]]; then
                RATIO_INPUT_HEIGHT=${INPUT_HEIGHT}
                INPUT_HEIGHT=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_HEIGHT} * ${HEIGHT}" | bc -l))
            fi
        fi
        [[ -n ${INPUT_HEIGHT} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set height ${INPUT_HEIGHT} px"
    fi

    ## Early stop if window is not floating
    #if [[ ! ${FLOATING_STATUS} == '"user_on"' ]]; then
    #    return
    #fi

    # INPUT_X
    [[ ! ${ONE_INPUT_FOR_ALL} == "1" ]] && INPUT_X=$(rofi -dmenu -p "Set WD Top-Left X to")
    if [[ -n ${INPUT_X} ]]; then
        if [[ ${INPUT_X: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_X} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            RATIO_INPUT_X=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
            INPUT_X=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_X} * ${WIDTH}" | bc -l))
        elif [[ $(echo "${INPUT_X} <= 1" | bc -l) == "1" ]]; then
            RATIO_INPUT_X=${INPUT_X}
            INPUT_X=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_X} * ${WIDTH}" | bc -l))
        fi
        # Add workspace offset
        INPUT_X=$(expr ${INPUT_X} + ${X})
        #INPUT_X=$(printf "%.0f" $(echo "scale=3; ${INPUT_X} - ${BORDER_WIDTH}" | bc -l))
    fi

    # INPUT_Y
    [[ ! ${ONE_INPUT_FOR_ALL} == "1" ]] && INPUT_Y=$(rofi -dmenu -p "Set WD Top-Left Y to")
    if [[ -n ${INPUT_Y} ]]; then
        if [[ ${INPUT_Y: -1} == '%' ]]; then
            TMP=$(echo ${INPUT_Y} | rev); TMP=${TMP:1}; PERCENTAGE=$(echo ${TMP} | rev)
            RATIO_INPUT_Y=$(printf "%.3f" $(echo "scale=3; ${PERCENTAGE} / 100" | bc -l ))
            INPUT_Y=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_Y} * ${HEIGHT}" | bc -l))
        elif [[ $(echo "${INPUT_Y} <= 1" | bc -l) == "1" ]]; then
            RATIO_INPUT_Y=${INPUT_Y}
            INPUT_Y=$(printf "%.0f" $(echo "scale=3; ${RATIO_INPUT_Y} * ${HEIGHT}" | bc -l))
        fi
        # Add workspace offset
        INPUT_Y=$(expr ${INPUT_Y} + ${Y})
        #INPUT_Y=$(printf "%.0f" $(echo "scale=3; ${INPUT_Y} - ${BORDER_WIDTH}" | bc -l))
    fi

    # Move window location to X, Y (Note: x, y here mean x, y of top-left corner of titlebar)
    i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${INPUT_X} px ${INPUT_Y} px"

    # Restore titlebar AFTER moving the window
    DEFAULT_FLOATING_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print $3}' ${I3_CONFIG} | awk 'NR==1')
    if [[ ${DEFAULT_FLOATING_STYLE} == "normal" ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] border normal ${BORDER_WIDTH}"
    fi

    # Switch focus back to window
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus"

}


window_operation () {
    ICON="$HOME/.config/i3/share/64x64/window.png"
    case $1 in
        "float_then_fulfill_workspace")
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
            if [[ ! ${CURRENT_FLOATING_STATUS} == '"user_on"' ]] && [[ $2 == "with_placeholder" ]]; then
                i3-msg open
            fi
            # Floating
            i3-msg "[id=${CURRENT_WINDOW_ID}] floating enable"
            i3-msg "[id=${CURRENT_WINDOW_ID}] border pixel ${BORDER_WIDTH}"
            # Resize to fulfill fullscreen
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
            resize_to_input
            ;;
        "move_floating_to_input")
            move_floating_to_input
            ;;
        "resize_to_input_and_move_floating_to_input")
            resize_to_input_and_move_floating_to_input 0 0
            ;;
        "resize_to_input_and_move_floating_to_input_in_one")
            resize_to_input_and_move_floating_to_input 1 0
            ;;
        "resize_and_move_floating")
            resize_to_input_and_move_floating_to_input $2 $3 $4 $5 $6 $7
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
pgrep flashfocus && flash_window
window_operation $@
pgrep flashfocus && flash_window
