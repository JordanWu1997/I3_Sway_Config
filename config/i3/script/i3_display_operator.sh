#!/usr/bin/env bash

# ICON
ICON="$HOME/.config/i3/share/64x64/monitor.png"

display_run () {
    local description=$1 status
    shift
    if "$@"; then
        notify-send -u low "Set Display" "$description" --icon="$ICON" || true
    else
        status=$?
        notify-send -u critical "Display change failed" "$description" --icon="$ICON" || true
        return "$status"
    fi
}

# Read one XRandR snapshot so connector names and connection states agree.
XRANDR_QUERY=$(xrandr --query) || {
    notify-send -u critical "Display change failed" "Could not read display outputs" --icon="$ICON" || true
    exit 1
}
eDP1=$(awk '$1 ~ /^eDP-?[0-9]+$/ && $2 ~ /^(connected|disconnected)$/ {print $1; exit}' <<< "$XRANDR_QUERY")
HAS_INTERNAL_OUTPUT=${eDP1:+yes}
[[ -n "$eDP1" ]] || eDP1=eDP-1
eDP1_STATUS=$(awk -v output="$eDP1" '$1 == output {print $2; exit}' <<< "$XRANDR_QUERY")
HDMI1=$(awk '$1 ~ /^HDMI-?1$/ && $2 ~ /^(connected|disconnected)$/ {print $1; exit}' <<< "$XRANDR_QUERY")
[[ -n "$HDMI1" ]] || { [[ "$eDP1" == eDP1 ]] && HDMI1=HDMI1 || HDMI1=HDMI-1; }
read -r HDMI1_STATUS HDMI1_WIDTH HDMI1_HEIGHT < <(
    awk -v output="$HDMI1" '$1 == output {
        if ($2 == "connected" && NF >= 5) print $2, $(NF-2), $NF
        else print $2
        exit
    }' <<< "$XRANDR_QUERY"
)

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
    echo "      [eDP1_1440x810_60]: activate eDP1 in shrink mode (1440x810_60)"
    echo "      [eDP1_1368x768_60]: activate eDP1 in shrink mode (1368x768_60)"
    echo "      [eDP1_primary]: set eDP1 as primary display"
    echo "      [eDP1_off]: deactivate eDP1"
    echo "  [HDMI1]"
    echo "      [HDMI1_auto]: activate HDMI1"
    echo "      [HDMI1_default]: activate HDMI1 in default mode"
    echo "      [HDMI1_1912x960_60]: activate HDMI1 in shrink mode (1912x960_60)"
    echo "      [HDMI1_1920x1200_50]: activate HDMI1 in extended mode (1920x1080_50)"
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

HDMI0_1440x810_60 () {
    # Create new mode
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode "HDMI-0" "1440x810_60.00"
}

HDMI1_1912x960_60 () {
    # Create new mode
    xrandr --newmode "1912x960_60.00"  152.20  1912 2024 2232 2552  960 961 964 994  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode "${HDMI1}" "1912x960_60.00"
}

HDMI1_1920x1200_50 () {
    # Create new mode
    xrandr --newmode "1920x1200_50.00"  158.08  1920 2032 2240 2560  1200 1201 1204 1235  -HSync +Vsync
    # Add new mode to HDMI1
    xrandr --addmode "${HDMI1}" "1920x1200_50.00"
}

eDP1_1440x810_60 () {
    # Create new mode
    xrandr --newmode "1440x810_60.00"  95.04  1440 1512 1664 1888  810 811 814 839  -HSync +Vsync
    # Add new mode to eDP1
    xrandr --addmode "${eDP1}" "1440x810_60.00"
}

restore_laptop_display () {
    local display output_state
    local -a displays=()

    # Turn on the panel first. --auto only selects a preferred mode when
    # enabling a disabled output; --preferred also resets an active panel.
    if ! xrandr --output "$eDP1" --auto --primary --pos 0x0 --rotate normal --scale 1x1 ||
       ! xrandr --output "$eDP1" --preferred --primary --pos 0x0 --rotate normal --scale 1x1; then
        notify-send -u critical "Display change failed" "Could not enable $eDP1; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    output_state=$(xrandr --query) || return 1
    if ! awk -v output="$eDP1" '$1 == output && $2 == "connected" && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {found=1} END {exit !found}' <<< "$output_state"; then
        notify-send -u critical "Display change failed" "$eDP1 is not active; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    mapfile -t displays < <(awk -v internal="$eDP1" '$1 != internal && $2 ~ /^(connected|disconnected)$/ && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1}' <<< "$output_state")
    for display in "${displays[@]}"; do
        xrandr --output "$display" --off || {
            notify-send -u critical "Display change failed" "Could not disable $display" --icon="$ICON" || true
            return 1
        }
    done
    notify-send -u low "Set Display" "$eDP1 laptop layout applied" --icon="$ICON" || true
}

safe_connected_display () {
    local output=${1:-} state

    # A failed preset may have changed part of the layout; choose from a fresh snapshot.
    XRANDR_QUERY=$(xrandr --query) || {
        notify-send -u critical "Display change failed" "Could not recheck display outputs; keeping the current layout" --icon="$ICON" || true
        return 1
    }

    # Prefer the internal panel on laptops. Otherwise keep an already visible
    # primary output, then any visible output, before enabling a new one.
    if ! awk -v selected="$output" '$1 == selected && $2 == "connected" {found=1} END {exit !found}' <<< "$XRANDR_QUERY"; then
        output=$(awk '$2 == "connected" && $3 == "primary" && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1; exit}' <<< "$XRANDR_QUERY")
        [[ -n "$output" ]] || output=$(awk '$2 == "connected" && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {print $1; exit}' <<< "$XRANDR_QUERY")
        [[ -n "$output" ]] || output=$(awk '$2 == "connected" {print $1; exit}' <<< "$XRANDR_QUERY")
    fi
    if [[ -z "$output" ]]; then
        notify-send -u critical "Display change failed" "No connected display found; keeping the current layout" --icon="$ICON" || true
        return 1
    fi

    # Never disable another output in an unfamiliar display arrangement.
    if ! xrandr --output "$output" --auto --primary; then
        notify-send -u critical "Display change failed" "Could not enable $output; keeping the current layout" --icon="$ICON" || true
        return 1
    fi
    state=$(xrandr --query) || return 1
    if ! awk -v selected="$output" '$1 == selected && $2 == "connected" && $0 ~ /[0-9]+x[0-9]+\+[0-9]+\+[0-9]+/ {found=1} END {exit !found}' <<< "$state"; then
        notify-send -u critical "Display change failed" "$output did not become active; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    notify-send -u low "Set Display" "Safe layout: $output active; other outputs left unchanged" --icon="$ICON" || true
}

laptop_hdmi_profile_matches () {
    awk -v internal="$eDP1" -v external="$HDMI1" '
        $2 == "connected" {count++; if ($1 == internal || $1 == external) known++}
        END {exit !(count == 2 && known == 2)}
    ' <<< "$XRANDR_QUERY"
}

desktop_profile_matches () {
    awk '
        $2 == "connected" {count++; if ($1 == "DP-1" || $1 == "DP-2" || $1 == "HDMI-0") known++}
        END {exit !(count == 3 && known == 3)}
    ' <<< "$XRANDR_QUERY"
}

display_run_or_laptop () {
    display_run "$@" || safe_connected_display "$eDP1"
}

auto_adjust () {
    local attempt

    # An internal output briefly reported as disconnected during hotplug must
    # never fall through to the hardcoded desktop profile.
    if [[ "$HAS_INTERNAL_OUTPUT" == yes && "$eDP1_STATUS" != connected ]]; then
        for (( attempt=0; attempt<5; attempt++ )); do
            sleep 0.2
            XRANDR_QUERY=$(xrandr --query) || return 1
            eDP1_STATUS=$(awk -v output="$eDP1" '$1 == output {print $2; exit}' <<< "$XRANDR_QUERY")
            [[ "$eDP1_STATUS" == connected ]] && break
        done
        if [[ "$eDP1_STATUS" != connected ]]; then
            notify-send -u critical "Display change failed" "$eDP1 is not connected; keeping the current layout" --icon="$ICON" || true
            return 1
        fi
        HDMI1_STATUS=$(awk -v output="$HDMI1" '$1 == output {print $2; exit}' <<< "$XRANDR_QUERY")
        read -r _ HDMI1_WIDTH HDMI1_HEIGHT < <(awk -v output="$HDMI1" '$1 == output {print $2, $(NF-2), $NF; exit}' <<< "$XRANDR_QUERY")
    fi

    # Case 1: Laptop + HDMI Display
    if [ "${eDP1_STATUS}" == 'connected' ] && [ "${HDMI1_STATUS}" == 'connected' ]; then
        if ! laptop_hdmi_profile_matches; then
            safe_connected_display "$eDP1"
            return $?
        fi
        # Rent: 520mm x 290mm, IOA 24': 520mm x 290mm
        if [ "${HDMI1_WIDTH}" == "520mm" ] && [ "${HDMI1_HEIGHT}" == "290mm" ]; then
            #notify-send -u low "Set Display Automatically" "IOA 24' connected" --icon="${ICON}"
            # Adjust eDP1 & HDMI1
            HDMI1_1920x1200_50; eDP1_1440x810_60
            # Set-1: Locate eDP1 (1440x810) & HDMI1 (1920x1200)
            #xrandr \
                #--output "${HDMI1}" --mode 1920x1080 --pos 1440x0 --rotate normal --primary \
                #--output "${eDP1}" --mode 1440x810_60.00 --pos 0x135 --rotate normal
            # Set-2: Locate eDP1 (1440x810) & HDMI1 (1920x1080)
            #xrandr \
                #--output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary \
                #--output "${eDP1}" --mode 1440x810_60.00 --pos 0x195 --rotate normal
            # Set-3: Locate eDP1 (auto) & HDMI1 (1920x1080)
            display_run_or_laptop "Rent 24' layout applied" xrandr \
                --output "${HDMI1}" --mode 1920x1080 --primary \
                --output "${eDP1}" --auto --left-of ${HDMI1}
            # Set-4: Disable eDP1 & enable HDMI1 (1920x1080)
            #xrandr \
               #--output "${HDMI1}" --mode 1920x1080 --rotate normal --primary \
               #--output "${eDP1}" --off
        # ACER 27': 600mm x 340mm
        elif [ "${HDMI1_WIDTH}" == "600mm" ] && [ "${HDMI1_HEIGHT}" == "340mm" ]; then
            # Adjust eDP1 & HDMI1
            HDMI1_1920x1200_50; eDP1_1440x810_60
            # Locate eDP1 & HDMI1
            display_run_or_laptop "ACER 27' layout applied" xrandr \
                --output "${eDP1}" --mode 1440x810_60.00 --pos 0x270 --rotate normal \
                --output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary
        # Rent: 0mm x 0mm (unknown)
        elif [ "${HDMI1_WIDTH}" == "0mm" ] && [ "${HDMI1_HEIGHT}" == "0mm" ]; then
            # Adjust eDP1 & HDMI1
            HDMI1_1920x1200_50; eDP1_1440x810_60
            # Locate eDP1 & HDMI1 (extented)
            display_run_or_laptop "External display layout applied" xrandr \
                --output "${HDMI1}" --mode 1920x1200_50.00 --pos 1440x0 --rotate normal --primary \
                --output "${eDP1}" --mode 1440x810_60.00 --pos 0x390 --rotate normal
        # Other HDMI:
        else
            display_run_or_laptop "External ${HDMI1} layout applied" xrandr --output "${HDMI1}" --auto --primary --right-of "${eDP1}"
        fi
        return
    fi

    # Case 2: Laptop only
    if [ "${eDP1_STATUS}" == 'connected' ]; then
        if awk -v internal="$eDP1" '$2 == "connected" && $1 != internal {found=1} END {exit !found}' <<< "$XRANDR_QUERY"; then
            safe_connected_display "$eDP1"
            return $?
        fi
        restore_laptop_display
        return $?
    fi

    # Case 3: No Laptop (PC at home 1 HDMI display + 2 DP displays)
    if [[ "$HAS_INTERNAL_OUTPUT" != yes ]]; then
        if ! desktop_profile_matches; then
            safe_connected_display
            return $?
        fi
        #notify-send -u low "Set Display Automatically" "Connect to DP-1 (normal), DP-4 (normal), HDMI-0 (right)" --icon="${ICON}"
        #xrandr \
            #--output "DP-1" --mode 1920x1080 --pos 0x280 --rotate inverted --brightness 0.9 --primary \
            #--output "DP-4" --mode 1920x1200 --scale 0.8x0.8 --pos 0x1360 --rotate normal --brightness 1.0 \
            #--output "HDMI-0" --mode 1360x768 --pos 1920x0 --rotate right --brightness 0.8

        # Render HDMI0 in 1536x864 and display in 1920x1080 mode
        display_run "Desktop display layout applied" xrandr \
            --output "DP-1" --mode 1920x1080 --pos 0x840 --rotate inverted --brightness 0.9 --primary \
            --output "DP-2" --mode 1920x1200 --scale 0.8x0.8 --pos 0x1920 --rotate normal --brightness 1.0 \
            --output "HDMI-0" --mode 1920x1080 --scale-from 1536x864 --pos 1920x0 --rotate right --brightness 0.9 || safe_connected_display
        return $?
    fi
}

select_display_mode () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
    DISPLAY_NLS=($(xrandr | awk '$0~/ connected/ {print NR}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[MODE] Select DISPLAY')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return 1
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
        return 1
    fi
    # Add "off" option
    SELECTED_DISPLAY_MODE=$(echo "${DISPLAY_MODES[*]} off" | tr ' ' '\n' | rofi -dmenu -i -p "Select ${SELECTED_DISPLAY} mode")
    if [[ -z "${SELECTED_DISPLAY_MODE}" ]]; then
        echo "[INFO] No display mode selected. Exiting ..."
        return 1
    fi
    if [[ ${SELECTED_DISPLAY_MODE} == 'off' ]]; then
        display_run "${SELECTED_DISPLAY} disabled" xrandr --output "${SELECTED_DISPLAY}" --off
    else
        display_run "${SELECTED_DISPLAY} set to ${SELECTED_DISPLAY_MODE}" xrandr --output "${SELECTED_DISPLAY}" --mode "${SELECTED_DISPLAY_MODE}"
    fi
}

select_display_position () {
    # Select DISPLAY
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
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
    display_run "${SELECTED_DISPLAY} moved to ${POS_X}x${POS_Y}" xrandr --output "${SELECTED_DISPLAY}" --pos "${POS_X}x${POS_Y}"
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
    display_run "${SELECTED_DISPLAY} is primary" xrandr --output "${SELECTED_DISPLAY}" --primary
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
    [[ -n $SELECTED_SCALE ]] || return 1
    if [[ ! $SELECTED_SCALE =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] ||
        ! awk -v value="$SELECTED_SCALE" 'BEGIN {exit !(value > 0)}'; then
        notify-send -u critical "Display change failed" "Scale must be a positive number" --icon="$ICON" || true
        return 1
    fi
    display_run "${SELECTED_DISPLAY} scaled to ${SELECTED_SCALE}" xrandr --output "${SELECTED_DISPLAY}" --scale "${SELECTED_SCALE}x${SELECTED_SCALE}"
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
        display_run "${SELECTED_DISPLAY} rotated ${SELECTED_ORIENTATION}" xrandr --output "${SELECTED_DISPLAY}" --rotate "${SELECTED_ORIENTATION}"
    fi
}

select_input_to_output () {
    # Select INPUT device
    # Filter for pointer devices to avoid mapping keyboards
    INPUT_LINES=$(xinput list | grep 'pointer' | grep 'id=')
    SELECTED_INPUT_LINE=$(echo "${INPUT_LINES}" | rofi -dmenu -i -p '[MAPPING] Select INPUT device')
    if [[ -z "${SELECTED_INPUT_LINE}" ]]; then
        # Early stop
        echo "[ERROR] NO INPUT is selected. Exiting ..."
        return
    fi
    # Extract ID from the selected line
    INPUT_ID=$(echo "${SELECTED_INPUT_LINE}" | sed -n 's/.*id=\([0-9]*\).*/\1/p')
    if [[ -z "${INPUT_ID}" ]]; then
        echo "[ERROR] Could not parse INPUT ID. Exiting ..."
        return
    fi
    # Select OUTPUT display
    DISPLAYS=($(xrandr | awk '$0~/ connected/ {print $1}'))
    SELECTED_DISPLAY=$(echo "${DISPLAYS[*]}" | tr ' ' '\n' | rofi -dmenu -i -auto-select -p '[MAPPING] Select OUTPUT display')
    if [[ -z "${SELECTED_DISPLAY}" ]]; then
        # Early stop
        echo "[ERROR] NO DISPLAY is selected. Exiting ..."
        return
    fi
    # Execute mapping
    display_run "Input ID ${INPUT_ID} mapped to ${SELECTED_DISPLAY}" xinput map-to-output "${INPUT_ID}" "${SELECTED_DISPLAY}"
}


display_operation () {
    case $1 in
        # Combination of HDMI1, eDP1
        "eDP1_HDMI1_joint")
            display_run "eDP1-HDMI1 joint mode activated" xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --right-of "${eDP1}"
            ;;
        "eDP1_HDMI1_mirror")
            display_run "eDP1-HDMI1 mirror mode activated" xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --same-as "${eDP1}"
            ;;
        "HDMI1_eDP1_joint")
            display_run "HDMI1-eDP1 joint mode activated" xrandr --output "${eDP1}" --auto --output "${HDMI1}" --auto --primary --left-of "${eDP1}"
            ;;
        # HDMI1
        "HDMI1_auto")
            display_run "${HDMI1} activated (auto)" xrandr --output "${HDMI1}" --auto
            ;;
        "HDMI1_off")
            display_run "${HDMI1} disabled" xrandr --output "${HDMI1}" --off
            ;;
        "HDMI1_1920x1200_50")
            HDMI1_1920x1200_50
            display_run "${HDMI1} set to 1920x1200_50.00" xrandr --output "${HDMI1}" --mode "1920x1200_50.00"
            ;;
        "HDMI1_default")
            display_run "${HDMI1} set to 1920x1080" xrandr --output "${HDMI1}" --mode "1920x1080"
            ;;
        "HDMI1_primary")
            display_run "${HDMI1} is primary" xrandr --output "${HDMI1}" --primary
            ;;
        # eDP1
        "eDP1_auto")
            display_run "${eDP1} activated (auto)" xrandr --output "${eDP1}" --auto
            ;;
        "eDP1_off")
            display_run "${eDP1} disabled" xrandr --output "${eDP1}" --off
            ;;
        "eDP1_1440x810_60")
            eDP1_1440x810_60
            display_run "${eDP1} set to 1440x810_60.00" xrandr --output "${eDP1}" --mode "1440x810_60.00"
            ;;
        "eDP1_1368x768_60")
            display_run "${eDP1} set to 1368x768" xrandr --output "${eDP1}" --mode "1368x768"
            ;;
        "eDP1_default")
            display_run "${eDP1} set to 1920x1080" xrandr --output "${eDP1}" --mode "1920x1080"
            ;;
        "eDP1_primary")
            display_run "${eDP1} is primary" xrandr --output "${eDP1}" --primary
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
        "select_input_to_output")
            select_input_to_output
            ;;
        "show_display_layout")
            local layout
            layout=$(xrandr --listmonitors) || return 1
            notify-send -u low "Display Mode" "$layout" --icon="${ICON}"
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
            auto_adjust || return $?
            ;;
        "auto_in_office")
            setup_monitors.sh auto_in_office || return $?
            ;;
        "auto_at_home")
            setup_monitors.sh auto_at_home || return $?
            ;;
        *)
            display_operation "$1" || return $?
    esac

    # Reload conky
    [[ "$2" == "enable" ]] && reload_conky

    # Miscellaneous
    sleep 1; reload_misc
}

# Main
main "$@"
