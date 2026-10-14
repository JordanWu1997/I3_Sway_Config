#!/usr/bin/env bash

WINDOW_ROFI_CONFIG="$HOME/.config/rofi/config_i3window.rasi"

window_rofi () {
    local output_width window_width window_height window_size menu_width=760 monitor=-2

    # Keep the menu within the focused output on narrow displays.
    output_width=$(i3-msg -t get_workspaces 2>/dev/null |
        jq -r '.[] | select(.focused) | .rect.width' 2>/dev/null)
    if [[ $output_width =~ ^[0-9]+$ ]] && (( output_width > 48 && output_width - 48 < menu_width )); then
        menu_width=$((output_width - 48))
    fi

    # Fall back to the focused display if the window cannot contain the menu.
    window_size=$(i3-msg -t get_tree 2>/dev/null |
        jq -r 'first(.. | objects | select(.focused? == true and .rect? != null) | .rect | "\(.width) \(.height)") // empty' 2>/dev/null)
    read -r window_width window_height <<< "$window_size"
    if [[ ! $window_width =~ ^[0-9]+$ || ! $window_height =~ ^[0-9]+$ ]] ||
        (( window_width < menu_width || window_height < 420 )); then
        monitor=-4
    fi

    if [[ -f $WINDOW_ROFI_CONFIG ]]; then
        rofi -config "$WINDOW_ROFI_CONFIG" -monitor "$monitor" "$@" -theme-str "window { width: ${menu_width}px; }"
    else
        rofi -monitor "$monitor" "$@" -theme-str "window { width: ${menu_width}px; }"
    fi
}

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
    echo "       choose a floating placement or tiled size, or enter custom geometry"
    echo "       floating: X,Y,W,H; tiled: W,H (blank fields keep their current values)"
    echo "       tiled choices follow the available split directions"
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
        INPUT_WIDTH=$(window_rofi -dmenu -p "Set WD width to")
        if [[ -n ${INPUT_WIDTH} ]]; then
            INPUT_WIDTH=$(_floating_coordinate_to_absolute "${INPUT_WIDTH}" 0 "${WIDTH}") || return 1
        fi
        [[ -n ${INPUT_WIDTH} ]] && i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px"
    fi

    # INPUT_HEIGHT
    if [[ ${FLOATING_STATUS} == '"user_on"' ]] || [[ $(echo "(${HEIGHT} - ${WINDOW_HEIGHT}) >= ${THRESHOLD}" | bc -l) == "1" ]]; then
        INPUT_HEIGHT=$(window_rofi -dmenu -p "Set WD height to")
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
    INPUT_X=$(window_rofi -dmenu -p "Set WD Top-Left X to") || return 0
    INPUT_Y=$(window_rofi -dmenu -p "Set WD Top-Left Y to") || return 0
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

# Give familiar names to the bundled layouts. User-added presets still work.
_window_geometry_preset_label () {
    case $1 in
        '0,0,1/2,1'|'0,0,2/4,1') echo 'Left half' ;;
        '1/2,0,1/2,1'|'2/4,0,2/4,1') echo 'Right half' ;;
        '1/4,0,1/2,1'|'1/4,0,2/4,1') echo 'Centered half' ;;
        '0,0,1/3,1') echo 'Left third' ;;
        '1/3,0,1/3,1') echo 'Middle third' ;;
        '2/3,0,1/3,1') echo 'Right third' ;;
        '0,0,2/3,1') echo 'Left two thirds' ;;
        '1/3,0,2/3,1') echo 'Right two thirds' ;;
        '1/6,0,2/3,1') echo 'Centered two thirds' ;;
        '0,0,1/4,1') echo 'Left quarter' ;;
        '1/4,0,1/4,1') echo 'Second quarter' ;;
        '2/4,0,1/4,1') echo 'Third quarter' ;;
        '3/4,0,1/4,1') echo 'Right quarter' ;;
        '0,0,3/4,1') echo 'Left three quarters' ;;
        '1/4,0,3/4,1') echo 'Right three quarters' ;;
        '1/8,0,3/4,1') echo 'Centered three quarters' ;;
        '0,0,1,1/2'|'0,0,1,2/4') echo 'Top half' ;;
        '0,1/2,1,1/2'|'0,2/4,1,2/4') echo 'Bottom half' ;;
        '0,1/4,1,1/2'|'0,1/4,1,2/4') echo 'Centered half' ;;
        '0,0,1,1/3') echo 'Top third' ;;
        '0,1/3,1,1/3') echo 'Middle third' ;;
        '0,2/3,1,1/3') echo 'Bottom third' ;;
        '0,0,1,2/3') echo 'Top two thirds' ;;
        '0,1/3,1,2/3') echo 'Bottom two thirds' ;;
        '0,1/6,1,2/3') echo 'Centered two thirds' ;;
        '0,0,1,1/4') echo 'Top quarter' ;;
        '0,1/4,1,1/4') echo 'Second quarter' ;;
        '0,2/4,1,1/4') echo 'Third quarter' ;;
        '0,3/4,1,1/4') echo 'Bottom quarter' ;;
        '0,0,1,3/4') echo 'Top three quarters' ;;
        '0,1/4,1,3/4') echo 'Bottom three quarters' ;;
        *)
            local x y w h
            IFS=, read -r x y w h <<< "$1"
            printf 'Position %s,%s; size %s x %s\n' "$x" "$y" "$w" "$h"
            ;;
    esac
}

# Guide custom input one dimension at a time. Empty input preserves it.
_window_geometry_ask () {
    local label=$1 current=$2 extent=$3 positive=$4 value pixels
    while true; do
        value=$(window_rofi -dmenu -p "$label" -mesg "Current: $current px. Enter pixels, a fraction (1/2), or a percentage (50%). Leave empty to keep it.") || return 1
        value=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$value")
        if [[ -z $value ]]; then printf '\n'; return 0; fi
        pixels=$(_floating_coordinate_to_absolute "$value" 0 "$extent" 2>/dev/null) || {
            window_rofi -e "Invalid $label: $value"
            continue
        }
        if (( positive && pixels < 1 )); then
            window_rofi -e "$label must be greater than zero."
            continue
        fi
        printf '%s\n' "$value"
        return 0
    done
}

# A tiled resize can redistribute space only at a split with another tiled
# window. Check every ancestor so nested horizontal and vertical splits work.
_window_tiled_resize_axes () {
    local tree=$1 focus_window_id=$2
    jq -r --argjson wid "$focus_window_id" '
        ([.. | objects
            | select(.type? == "workspace"
                and any(.nodes[]? | .. | objects; .window? == $wid))] | first) as $workspace
        | if $workspace == null then error("Focused tiled window has no workspace") else
            ([$workspace.nodes[]? | .. | objects | select(.window? != null)] | length) as $count
            | ([$workspace | paths(objects | select(.window? == $wid))] | first) as $path
            | reduce range(0; ($path | length)) as $depth
                ({width: 0, height: 0};
                    ($workspace | getpath($path[:$depth])) as $ancestor
                    | if ($ancestor | type) != "object" then .
                      else
                        ([$ancestor.nodes[]? | select(any(.. | objects; .window? != null))] | length) as $occupied
                        | if $occupied > 1 and $ancestor.layout == "splith" then .width = 1
                          elif $occupied > 1 and $ancestor.layout == "splitv" then .height = 1
                          else . end
                      end)
            | [$count, .width, .height] | @tsv
          end
    ' <<< "$tree"
}

# Floating windows can be placed; tiled windows can only be resized here.
resize_to_input_and_move_floating_to_input_in_one () {
    local focus_window_id tree floating_rect window_rect workspace_rect
    local ws_x ws_y ws_width ws_height win_x win_y win_width win_height
    local is_floating=0 preset_file choice spec prompt message label
    local input_x input_y input_width input_height value converted menu_screen=quick
    local index seen duplicate found
    local tiled_axes tiled_count can_resize_width=0 can_resize_height=0
    local -a rofi_args menu_items menu_specs

    focus_window_id=$(xdotool getwindowfocus) || return 1
    tree=$(i3-msg -t get_tree) || return 1
    floating_rect=$(jq -c --argjson wid "$focus_window_id" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ' <<< "$tree")
    window_rect=$(jq -c --argjson wid "$focus_window_id" '
        first(.. | objects | select(.window? == $wid) | .rect) // empty
    ' <<< "$tree")
    [[ -n $window_rect ]] || { echo 'Focused window is not managed by i3.' >&2; return 1; }

    workspace_rect=$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused) | .rect')
    [[ -n $workspace_rect ]] || { echo 'Cannot get focused workspace geometry.' >&2; return 1; }
    read -r ws_x ws_y ws_width ws_height < <(
        jq -r '[.x,.y,.width,.height] | @tsv' <<< "$workspace_rect"
    )

    if [[ -n $floating_rect ]]; then
        is_floating=1
        read -r win_x win_y win_width win_height < <(
            jq -r '[.x,.y,.width,.height] | @tsv' <<< "$floating_rect"
        )
        preset_file="$HOME/.config/i3/share/i3_window_geometry_vertical.txt"
        if (( ws_width > ws_height )); then
            preset_file="$HOME/.config/i3/share/i3_window_geometry_horizontal.txt"
        fi
        prompt='Place floating window'
        message="Current position $((win_x-ws_x)),$((win_y-ws_y)) and size ${win_width}x${win_height} px. Choose a layout; type X,Y,W,H for direct entry."
    else
        tiled_axes=$(_window_tiled_resize_axes "$tree" "$focus_window_id") || return 1
        read -r tiled_count can_resize_width can_resize_height <<< "$tiled_axes"
        if (( tiled_count <= 1 )); then
            notify-send -u low 'Resize tiled window' 'Only one tiled window is present.'
            return 0
        fi
        if (( ! can_resize_width && ! can_resize_height )); then
            notify-send -u low 'Resize tiled window' 'No horizontal or vertical split can be resized here.'
            return 0
        fi
        read -r win_x win_y win_width win_height < <(
            jq -r '[.x,.y,.width,.height] | @tsv' <<< "$window_rect"
        )
        prompt='Resize tiled window'
        if (( can_resize_width && can_resize_height )); then
            message="Current size ${win_width}x${win_height} px. Choose a size or type W,H. Tiling keeps the window position."
        elif (( can_resize_width )); then
            message="Current width ${win_width} px. Only width can change here; choose a size or type a width."
        else
            message="Current height ${win_height} px. Only height can change here; choose a size or type a height."
        fi
    fi

    while true; do
        menu_items=(); menu_specs=()
        if (( is_floating )); then
            if [[ $menu_screen == quick ]]; then
                if (( ws_width > ws_height )); then
                    menu_items=('Left half' 'Right half' 'Centered half' 'Left third' 'Middle third' 'Right third' 'Fill workspace')
                    menu_specs=('0,0,1/2,1' '1/2,0,1/2,1' '1/4,0,1/2,1' '0,0,1/3,1' '1/3,0,1/3,1' '2/3,0,1/3,1' '0,0,1,1')
                else
                    menu_items=('Top half' 'Bottom half' 'Centered half' 'Top third' 'Middle third' 'Bottom third' 'Fill workspace')
                    menu_specs=('0,0,1,1/2' '0,1/2,1,1/2' '0,1/4,1,1/2' '0,0,1,1/3' '0,1/3,1,1/3' '0,2/3,1,1/3' '0,0,1,1')
                fi
                menu_items+=('More placements...')
                menu_specs+=('')
            else
                menu_items=('Back to quick layouts')
                menu_specs=('')
                if [[ -f $preset_file ]]; then
                    while IFS= read -r spec; do
                        [[ -z $spec || $spec == \#* ]] && continue
                        label=$(_window_geometry_preset_label "$spec")
                        duplicate=0
                        for seen in "${menu_items[@]}"; do
                            [[ $seen == "$label" ]] && { duplicate=1; break; }
                        done
                        (( duplicate )) && continue
                        menu_items+=("$label")
                        menu_specs+=("$spec")
                    done < "$preset_file"
                fi
            fi
            menu_items+=('Move to a custom position...' 'Set a custom size...' 'Set custom position and size...')
            menu_specs+=('' '' '')
        else
            if (( can_resize_width )); then
                menu_items+=('Half workspace width' 'One-third workspace width' 'Two-thirds workspace width' 'Quarter workspace width' 'Three-quarters workspace width')
                menu_specs+=(',,1/2,' ',,1/3,' ',,2/3,' ',,1/4,' ',,3/4,')
            fi
            if (( can_resize_height )); then
                menu_items+=('Half workspace height' 'One-third workspace height' 'Two-thirds workspace height' 'Quarter workspace height' 'Three-quarters workspace height')
                menu_specs+=(',,,1/2' ',,,1/3' ',,,2/3' ',,,1/4' ',,,3/4')
            fi
            if (( can_resize_width && can_resize_height )); then
                menu_items+=('Half width and height' 'Two-thirds width and height' 'Set a custom size...')
                menu_specs+=(',,1/2,1/2' ',,2/3,2/3' '')
            elif (( can_resize_width )); then
                menu_items+=('Set a custom width...')
                menu_specs+=('')
            else
                menu_items+=('Set a custom height...')
                menu_specs+=('')
            fi
        fi

        rofi_args=(-dmenu -i -p "$prompt" -mesg "$message")
        choice=$(printf '%s\n' "${menu_items[@]}" | window_rofi "${rofi_args[@]}") || return 0
        [[ -n $choice ]] || return 0
        if [[ $choice == 'More placements...' ]]; then menu_screen=more; continue; fi
        if [[ $choice == 'Back to quick layouts' ]]; then menu_screen=quick; continue; fi

        # Rofi returns the visible label. Direct typed geometry remains available.
        spec=$choice
        found=0
        for index in "${!menu_items[@]}"; do
            if [[ $choice == "${menu_items[$index]}" ]]; then
                spec=${menu_specs[$index]}
                found=1
                break
            fi
        done
        break
    done

    if (( found )) && [[ -z $spec ]]; then
        case $choice in
            'Move to a custom position...')
                input_x=$(_window_geometry_ask 'Left edge from workspace' "$((win_x-ws_x))" "$ws_width" 0) || return 0
                input_y=$(_window_geometry_ask 'Top edge from workspace' "$((win_y-ws_y))" "$ws_height" 0) || return 0
                spec="$input_x,$input_y,,"
                ;;
            'Set a custom size...')
                input_width=$(_window_geometry_ask 'Width' "$win_width" "$ws_width" 1) || return 0
                input_height=$(_window_geometry_ask 'Height' "$win_height" "$ws_height" 1) || return 0
                spec=",,$input_width,$input_height"
                ;;
            'Set a custom width...')
                input_width=$(_window_geometry_ask 'Width' "$win_width" "$ws_width" 1) || return 0
                spec=",,$input_width,"
                ;;
            'Set a custom height...')
                input_height=$(_window_geometry_ask 'Height' "$win_height" "$ws_height" 1) || return 0
                spec=",,,$input_height"
                ;;
            'Set custom position and size...')
                input_x=$(_window_geometry_ask 'Left edge from workspace' "$((win_x-ws_x))" "$ws_width" 0) || return 0
                input_y=$(_window_geometry_ask 'Top edge from workspace' "$((win_y-ws_y))" "$ws_height" 0) || return 0
                input_width=$(_window_geometry_ask 'Width' "$win_width" "$ws_width" 1) || return 0
                input_height=$(_window_geometry_ask 'Height' "$win_height" "$ws_height" 1) || return 0
                spec="$input_x,$input_y,$input_width,$input_height"
                ;;
        esac
    fi

    if (( ! is_floating )); then
        if [[ $spec != *,* ]]; then
            if (( can_resize_width && ! can_resize_height )); then
                spec=",,$spec,"
            elif (( can_resize_height && ! can_resize_width )); then
                spec=",,,$spec"
            fi
        elif [[ $spec =~ ^([^,]*),([^,]*)$ ]]; then
            spec=",,$spec"
        fi
    fi
    if [[ ! $spec =~ ^([^,]*),([^,]*),([^,]*),([^,]*)$ ]]; then
        window_rofi -e 'Enter X,Y,W,H for floating windows or W,H for tiled windows.'
        return 1
    fi
    input_x=${BASH_REMATCH[1]}; input_y=${BASH_REMATCH[2]}
    input_width=${BASH_REMATCH[3]}; input_height=${BASH_REMATCH[4]}
    input_x=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$input_x")
    input_y=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$input_y")
    input_width=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$input_width")
    input_height=$(sed 's/^[[:space:]]*//; s/[[:space:]]*$//' <<< "$input_height")
    if (( ! is_floating )) && [[ -n $input_x || -n $input_y ]]; then
        window_rofi -e 'Tiled windows have no absolute position. Enter W,H only.'
        return 1
    fi
    if (( ! is_floating )); then
        if (( ! can_resize_width )) && [[ -n $input_width ]]; then
            window_rofi -e 'Width cannot change without a horizontal split.'
            return 1
        fi
        if (( ! can_resize_height )) && [[ -n $input_height ]]; then
            window_rofi -e 'Height cannot change without a vertical split.'
            return 1
        fi
    fi

    # Validate all four fields before changing either size or position.
    for value in "$input_x" "$input_width"; do
        [[ -z $value ]] && continue
        if ! _floating_coordinate_to_absolute "$value" 0 "$ws_width" >/dev/null 2>&1; then
            window_rofi -e "Invalid coordinate or size: $value"
            return 1
        fi
    done
    for value in "$input_y" "$input_height"; do
        [[ -z $value ]] && continue
        if ! _floating_coordinate_to_absolute "$value" 0 "$ws_height" >/dev/null 2>&1; then
            window_rofi -e "Invalid coordinate or size: $value"
            return 1
        fi
    done
    if [[ -n $input_width ]]; then
        converted=$(_floating_coordinate_to_absolute "$input_width" 0 "$ws_width")
        if (( converted < 1 )); then window_rofi -e 'Width must be positive.'; return 1; fi
    fi
    if [[ -n $input_height ]]; then
        converted=$(_floating_coordinate_to_absolute "$input_height" 0 "$ws_height")
        if (( converted < 1 )); then window_rofi -e 'Height must be positive.'; return 1; fi
    fi

    I3_WINDOW_TARGET_ID=$focus_window_id I3_WINDOW_WORKSPACE_RECT=$workspace_rect \
        resize_to_input_and_move_floating_to_input 1 0 \
        "$input_x" "$input_y" "$input_width" "$input_height"
}

resize_to_input_and_move_floating_to_input () {
    local FOCUS_WINDOW_ID FLOATING_RECT WORKSPACE_RECT WINDOW_GEOMETRY
    local X Y WIDTH HEIGHT WINDOW_WIDTH WINDOW_HEIGHT WINDOW_X WINDOW_Y
    local ONE_INPUT_FOR_ALL THRESHOLD INPUTS INPUT_X INPUT_Y INPUT_WIDTH INPUT_HEIGHT
    local WINDOW_GEOMETRY_TXT PROMPT TARGET_X TARGET_Y
    local HAS_CLI_INPUTS=0 IS_FLOATING=0

    FOCUS_WINDOW_ID=${I3_WINDOW_TARGET_ID:-$(xdotool getwindowfocus)} || return 1

    # Read the actual i3 floating container (including decorations).
    FLOATING_RECT=$(i3-msg -t get_tree | jq -c --argjson wid "${FOCUS_WINDOW_ID}" '
        first(.. | objects
            | select(.type? == "floating_con" and any(.. | objects; .window? == $wid))
            | .rect) // empty
    ')
    [[ -n ${FLOATING_RECT} ]] && IS_FLOATING=1

    WORKSPACE_RECT=${I3_WINDOW_WORKSPACE_RECT:-$(i3-msg -t get_workspaces | jq -c '.[] | select(.focused) | .rect')}
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
        WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_vertical.txt"
        PROMPT="Set Vertical WD TL_X,TL_Y,W,H to"
        if (( WIDTH > HEIGHT )); then
            WINDOW_GEOMETRY_TXT="$HOME/.config/i3/share/i3_window_geometry_horizontal.txt"
            PROMPT="Set Horizontal WD TL_X,TL_Y,W,H to"
        fi
        if [[ -f ${WINDOW_GEOMETRY_TXT} ]]; then
            INPUTS=$(window_rofi -dmenu -input "${WINDOW_GEOMETRY_TXT}" -p "${PROMPT}") || return 0
        else
            INPUTS=$(window_rofi -dmenu -p "Set WD TL_X,TL_Y,W,H to") || return 0
        fi
        [[ -n ${INPUTS} ]] || return 0
        IFS=, read -r INPUT_X INPUT_Y INPUT_WIDTH INPUT_HEIGHT <<< "${INPUTS}"
    fi

    # Explicit CLI sizes have already been checked against the available splits.
    # The threshold only controls which prompts appear in the older interactive flow.
    if (( IS_FLOATING )) || { (( HAS_CLI_INPUTS )) && [[ -n $INPUT_WIDTH ]]; } ||
        (( WIDTH - WINDOW_WIDTH >= THRESHOLD )); then
        if (( ! HAS_CLI_INPUTS )) && [[ ${ONE_INPUT_FOR_ALL} != 1 ]]; then
            INPUT_WIDTH=$(window_rofi -dmenu -p "Set WD width to") || return 0
        fi
        if [[ -n ${INPUT_WIDTH} ]]; then
            INPUT_WIDTH=$(_floating_coordinate_to_absolute "${INPUT_WIDTH}" 0 "${WIDTH}") || return 1
            i3-msg "[id=${FOCUS_WINDOW_ID}] resize set width ${INPUT_WIDTH} px" >/dev/null
        fi
    fi
    if (( IS_FLOATING )) || { (( HAS_CLI_INPUTS )) && [[ -n $INPUT_HEIGHT ]]; } ||
        (( HEIGHT - WINDOW_HEIGHT >= THRESHOLD )); then
        if (( ! HAS_CLI_INPUTS )) && [[ ${ONE_INPUT_FOR_ALL} != 1 ]]; then
            INPUT_HEIGHT=$(window_rofi -dmenu -p "Set WD height to") || return 0
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
        INPUT_X=$(window_rofi -dmenu -p "Set WD Top-Left X to") || return 0
        INPUT_Y=$(window_rofi -dmenu -p "Set WD Top-Left Y to") || return 0
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
            resize_to_input_and_move_floating_to_input_in_one
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
if pgrep flashfocus >/dev/null; then flash_window; fi
window_operation "$@"
status=$?
if pgrep flashfocus >/dev/null; then flash_window; fi
exit "$status"
