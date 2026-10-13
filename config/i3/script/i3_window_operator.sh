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
    echo "  [move_floating_to_corner] [top_left|top_right|bottom_left|bottom_right]: move focused floating window to a workspace corner"
    echo "  [toggle_sticky_current]: toggle current window stickiness"
    echo "  [resize_to_input]: resize window to input width and height"
    echo "  X,Y,W,H accept pixels (150), ratios (0.5), fractions (1/2), or percentages (50%)"
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
            INPUT_WIDTH=$(_floating_coordinate_to_absolute "${INPUT_WIDTH}" 0 "${WIDTH}") || return 1
        fi
        [[ -n ${INPUT_WIDTH} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px"
    fi

    # INPUT_HEIGHT
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${HEIGHT} - ${WINDOW_HEIGHT}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_HEIGHT=$(rofi -dmenu -p "Set WD height to")
        if [[ -n ${INPUT_HEIGHT} ]]; then
            INPUT_HEIGHT=$(_floating_coordinate_to_absolute "${INPUT_HEIGHT}" 0 "${HEIGHT}") || return 1
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
    local FOCUS_WINDOW_ID FLOATING_RECT WORKSPACE_RECT
    local WS_X WS_Y WS_WIDTH WS_HEIGHT WIN_X WIN_Y
    local INPUT_X INPUT_Y TARGET_X TARGET_Y

    FOCUS_WINDOW_ID=$(xdotool getwindowfocus) || return 1

    # Use the i3 floating container's position, not X11 client geometry.
    FLOATING_RECT=$(i3-msg -t get_tree | jq -c --argjson wid "${FOCUS_WINDOW_ID}" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ')
    if [[ -z ${FLOATING_RECT} ]]; then
        echo "Focused window is not floating (or not managed by i3)." >&2
        return 1
    fi

    WORKSPACE_RECT=$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused) | .rect')
    if [[ -z ${WORKSPACE_RECT} ]]; then
        echo "Cannot get focused workspace geometry." >&2
        return 1
    fi

    read -r WS_X WS_Y WS_WIDTH WS_HEIGHT < <(
        jq -r '[.x, .y, .width, .height] | @tsv' <<< "${WORKSPACE_RECT}"
    )
    read -r WIN_X WIN_Y < <(
        jq -r '[.x, .y] | @tsv' <<< "${FLOATING_RECT}"
    )

    # Empty input keeps the current coordinate exactly unchanged.
    INPUT_X=$(rofi -dmenu -p "Set WD Top-Left X to") || return 0
    INPUT_Y=$(rofi -dmenu -p "Set WD Top-Left Y to") || return 0
    TARGET_X=${WIN_X}
    TARGET_Y=${WIN_Y}

    # Inputs are workspace-relative: pixels (>1), fractions (0..1), or percents.
    # The final i3 coordinates are absolute across all monitors.
    if [[ -n ${INPUT_X} ]]; then
        TARGET_X=$(_floating_coordinate_to_absolute "${INPUT_X}" "${WS_X}" "${WS_WIDTH}") || return 1
    fi
    if [[ -n ${INPUT_Y} ]]; then
        TARGET_Y=$(_floating_coordinate_to_absolute "${INPUT_Y}" "${WS_Y}" "${WS_HEIGHT}") || return 1
    fi

    i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${TARGET_X} px ${TARGET_Y} px"
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus"
}

# Convert a workspace-relative coordinate/size to integer i3 pixels.
# 1/2, 0.5, 50% => half of workspace extent; 150 => 150 pixels.
# A bare 0 or 1 retains the script's original ratio interpretation.
_floating_coordinate_to_absolute () {
    local input=$1 offset=$2 extent=$3 value numerator denominator

    # Fraction expressions must have a nonzero denominator.
    if [[ ${input} =~ ^([0-9]+)/([0-9]+)$ ]]; then
        numerator=${BASH_REMATCH[1]}
        denominator=${BASH_REMATCH[2]}
        if ! awk -v d="${denominator}" 'BEGIN { exit !(d > 0) }'; then
            echo "Invalid fraction (zero denominator): ${input}" >&2
            return 1
        fi
        value=$(awk -v n="${numerator}" -v d="${denominator}" -v dim="${extent}" \
            'BEGIN { printf "%.0f", (n / d) * dim }')
    elif [[ ${input} =~ ^([0-9]+([.][0-9]+)?)%$ ]]; then
        value=$(awk -v n="${BASH_REMATCH[1]}" -v dim="${extent}" \
            'BEGIN { printf "%.0f", n * dim / 100 }')
    elif [[ ${input} =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        if awk -v n="${input}" 'BEGIN { exit !(n <= 1) }'; then
            value=$(awk -v n="${input}" -v dim="${extent}" \
                'BEGIN { printf "%.0f", n * dim }')
        else
            value=$(awk -v n="${input}" 'BEGIN { printf "%.0f", n }')
        fi
    else
        echo "Invalid coordinate/size input: ${input}" >&2
        return 1
    fi
    printf '%d\n' "$((offset + value))"
}

resize_to_input_and_move_floating_to_input () {
    local FOCUS_WINDOW_ID FLOATING_RECT WORKSPACE_RECT WINDOW_GEOMETRY
    local X Y WIDTH HEIGHT WINDOW_WIDTH WINDOW_HEIGHT WINDOW_X WINDOW_Y
    local ONE_INPUT_FOR_ALL THRESHOLD INPUTS INPUT_X INPUT_Y INPUT_WIDTH INPUT_HEIGHT
    local ROFI_CONFIG WINDOW_GEOMETRY_TXT PROMPT TARGET_X TARGET_Y
    local HAS_CLI_INPUTS=0 IS_FLOATING=0

    FOCUS_WINDOW_ID=$(xdotool getwindowfocus) || return 1

    # Read the actual i3 floating container (including decorations).
    FLOATING_RECT=$(i3-msg -t get_tree | jq -c --argjson wid "${FOCUS_WINDOW_ID}" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ')
    [[ -n ${FLOATING_RECT} ]] && IS_FLOATING=1

    WORKSPACE_RECT=$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused) | .rect')
    [[ -n ${WORKSPACE_RECT} ]] || { echo "Cannot get focused workspace geometry." >&2; return 1; }
    read -r X Y WIDTH HEIGHT < <(jq -r '[.x,.y,.width,.height] | @tsv' <<< "${WORKSPACE_RECT}")

    if (( IS_FLOATING )); then
        read -r WINDOW_X WINDOW_Y WINDOW_WIDTH WINDOW_HEIGHT < <(
            jq -r '[.x,.y,.width,.height] | @tsv' <<< "${FLOATING_RECT}")
    else
        # Retain the original tiling-window resize threshold behavior.
        WINDOW_GEOMETRY=$(xdotool getwindowgeometry --shell "${FOCUS_WINDOW_ID}") || return 1
        WINDOW_WIDTH=$(sed -n 's/^WIDTH=//p' <<< "${WINDOW_GEOMETRY}")
        WINDOW_HEIGHT=$(sed -n 's/^HEIGHT=//p' <<< "${WINDOW_GEOMETRY}")
    fi

    ONE_INPUT_FOR_ALL=${1:-0}
    THRESHOLD=${2:-150}
    (( IS_FLOATING )) && THRESHOLD=0

    # Keep the six-argument API: 1 0 X Y W H (or 0 0 X Y W H).
    if (( $# == 6 )); then
        HAS_CLI_INPUTS=1
        INPUT_X=$3; INPUT_Y=$4; INPUT_WIDTH=$5; INPUT_HEIGHT=$6
    elif [[ ${ONE_INPUT_FOR_ALL} == 1 ]]; then
        ROFI_CONFIG="$HOME/.config/rofi/config_i3window_vertical.rasi"
        WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_vertical.txt"
        PROMPT="Set Vertical WD TL_X,TL_Y,W,H to"
        if (( WIDTH > HEIGHT )); then
            WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_horizontal.txt"
            ROFI_CONFIG="$HOME/.config/rofi/config_i3window_horizontal.rasi"
            PROMPT="Set Horizontal WD TL_X,TL_Y,W,H to"
        fi
        if [[ -f ${WINDOW_GEOMETRY_TXT} ]]; then
            INPUTS=$(rofi -dmenu -input "${WINDOW_GEOMETRY_TXT}" -config "${ROFI_CONFIG}" -p "${PROMPT}") || return 0
        else
            INPUTS=$(rofi -dmenu -p "Set WD TL_X,TL_Y,W,H to") || return 0
        fi
        [[ -n ${INPUTS} ]] || return 0
        IFS=, read -r INPUT_X INPUT_Y INPUT_WIDTH INPUT_HEIGHT <<< "${INPUTS}"
    fi

    # Resize using the same size conventions as the original script.
    if (( IS_FLOATING )) || (( WIDTH - WINDOW_WIDTH >= THRESHOLD )); then
        if (( ! HAS_CLI_INPUTS )) && [[ ${ONE_INPUT_FOR_ALL} != 1 ]]; then
            INPUT_WIDTH=$(rofi -dmenu -p "Set WD width to") || return 0
        fi
        if [[ -n ${INPUT_WIDTH} ]]; then
            INPUT_WIDTH=$(_floating_coordinate_to_absolute "${INPUT_WIDTH}" 0 "${WIDTH}") || return 1
            i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px" >/dev/null
        fi
    fi
    if (( IS_FLOATING )) || (( HEIGHT - WINDOW_HEIGHT >= THRESHOLD )); then
        if (( ! HAS_CLI_INPUTS )) && [[ ${ONE_INPUT_FOR_ALL} != 1 ]]; then
            INPUT_HEIGHT=$(rofi -dmenu -p "Set WD height to") || return 0
        fi
        if [[ -n ${INPUT_HEIGHT} ]]; then
            INPUT_HEIGHT=$(_floating_coordinate_to_absolute "${INPUT_HEIGHT}" 0 "${HEIGHT}") || return 1
            i3-msg "[id=${FOCUS_WINDOW_ID}] resize set height ${INPUT_HEIGHT} px" >/dev/null
        fi
    fi

    # A tiled window can be resized but cannot be positioned absolutely.
    if (( ! IS_FLOATING )); then
        i3-msg "[id=${FOCUS_WINDOW_ID}] focus" >/dev/null
        return 0
    fi

    if (( ! HAS_CLI_INPUTS )) && [[ ${ONE_INPUT_FOR_ALL} != 1 ]]; then
        INPUT_X=$(rofi -dmenu -p "Set WD Top-Left X to") || return 0
        INPUT_Y=$(rofi -dmenu -p "Set WD Top-Left Y to") || return 0
    fi

    # Re-read after resizing: keep the actual container position for blank inputs.
    FLOATING_RECT=$(i3-msg -t get_tree | jq -c --argjson wid "${FOCUS_WINDOW_ID}" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ')
    [[ -n ${FLOATING_RECT} ]] || { echo "Floating window no longer found." >&2; return 1; }
    read -r TARGET_X TARGET_Y < <(jq -r '[.x,.y] | @tsv' <<< "${FLOATING_RECT}")

    if [[ -n ${INPUT_X} ]]; then
        TARGET_X=$(_floating_coordinate_to_absolute "${INPUT_X}" "${X}" "${WIDTH}") || return 1
    fi
    if [[ -n ${INPUT_Y} ]]; then
        TARGET_Y=$(_floating_coordinate_to_absolute "${INPUT_Y}" "${Y}" "${HEIGHT}") || return 1
    fi

    # No temporary pixel/normal border conversion: no decoration offsets.
    if [[ -n ${INPUT_X} || -n ${INPUT_Y} ]]; then
        i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${TARGET_X} px ${TARGET_Y} px" >/dev/null
    fi
    i3-msg "[id=${FOCUS_WINDOW_ID}] focus" >/dev/null
}

move_floating_to_corner () {
    local CORNER="${1:-}"
    local FOCUS_WINDOW_ID WORKSPACE_RECT FLOATING_RECT
    local WS_X WS_Y WS_WIDTH WS_HEIGHT WIN_WIDTH WIN_HEIGHT TARGET_X TARGET_Y

    case "${CORNER}" in
        top_left|top_right|bottom_left|bottom_right) ;;
        *) echo "Usage: $0 move_floating_to_corner {top_left|top_right|bottom_left|bottom_right}" >&2; return 1 ;;
    esac

    FOCUS_WINDOW_ID=$(xdotool getwindowfocus) || return 1

    # Look up the wrapper of the focused X11 window in i3's tree.
    # A missing wrapper means the focused window is not floating.
    FLOATING_RECT=$(i3-msg -t get_tree | jq -c --argjson wid "${FOCUS_WINDOW_ID}" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ')
    if [[ -z ${FLOATING_RECT} ]]; then
        echo "Focused window is not floating (or not managed by i3)." >&2
        return 1
    fi

    WORKSPACE_RECT=$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused) | .rect')
    if [[ -z ${WORKSPACE_RECT} ]]; then
        echo "Cannot get focused workspace geometry." >&2
        return 1
    fi

    read -r WS_X WS_Y WS_WIDTH WS_HEIGHT < <(
        jq -r '[.x, .y, .width, .height] | @tsv' <<< "${WORKSPACE_RECT}"
    )
    read -r WIN_WIDTH WIN_HEIGHT < <(
        jq -r '[.width, .height] | @tsv' <<< "${FLOATING_RECT}"
    )

    TARGET_X=${WS_X}
    TARGET_Y=${WS_Y}
    case "${CORNER}" in
        top_right|bottom_right) TARGET_X=$((WS_X + WS_WIDTH - WIN_WIDTH)) ;;
    esac
    case "${CORNER}" in
        bottom_left|bottom_right) TARGET_Y=$((WS_Y + WS_HEIGHT - WIN_HEIGHT)) ;;
    esac

    # Avoid moving a window past the top/left edge if it is oversized.
    (( TARGET_X < WS_X )) && TARGET_X=${WS_X}
    (( TARGET_Y < WS_Y )) && TARGET_Y=${WS_Y}

    i3-msg "[id=${FOCUS_WINDOW_ID}] move position ${TARGET_X} px ${TARGET_Y} px"
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
        "move_floating_to_corner")
            move_floating_to_corner "$2"
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
                ## Send notification if there is no titlebar
                #if [[ ${DEFAULT_FLOATING_STYLE} == "pixel" ]]; then
                #     notify-send -u low "i3 Window Manager" "Focused window is NO LONGER sticky" --icon=${ICON}
                #fi
            elif [[ ${CURRENT_STICKY_STATUS} == "false" ]]; then
                i3-msg "sticky enable"; i3-msg 'title_format "[STICKY] %title [STICKY]"'
                i3-msg border normal ${DEFAULT_WIDTH}
                i3_cursor_operator.sh move_cursor_inside_window top_titlebar
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
