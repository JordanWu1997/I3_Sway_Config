#!/usr/bin/env bash
# Ported from i3_display_operator.sh for sway.
# Replaced X11 tools:
#   - xrandr --query/--output/--mode/--pos/--rotate/--scale -> swaymsg -t get_outputs + swaymsg output ...
#   - xrandr --newmode/--addmode modelines                    -> swaymsg output X mode --custom WxH@RHz
#     (internal panels: shrink modes are emulated with fractional output scale)
#   - xrandr --same-as (mirror)                              -> wl-mirror --fullscreen-output
#   - xrandr --primary                                       -> emulated (see set_primary)
#   - xrandr --brightness (desktop profile)                  -> dropped (see sway_backlight_operator.sh)
#   - xrandr physical size (mm) for monitor detection        -> wlr-randr --json (optional)
#   - xinput map-to-output                                   -> swaymsg input <id> map_to_output
#   - feh --bg-fill / picom                                  -> swaymsg output * bg ... fill / (no compositor)
#   - setup_monitors.sh auto_in_office|auto_at_home          -> kanshictl switch office|home
# Usage and arguments are identical to the i3 version:
#   sway_display_operator.sh <operation> [enable|disable]

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"

# ICON
ICON="$HOME/.config/i3/share/64x64/monitor.png"
WALLPAPER="$HOME/.config/i3/share/default_wallpaper"
PRIMARY_STATE="${XDG_RUNTIME_DIR:-/tmp}/sway_primary_output"
# Desktop (no internal panel) profile: DRM names of the X outputs DP-1, DP-2, HDMI-0
DESKTOP_OUT_A="${SWAY_DESKTOP_OUT_A:-DP-1}"
DESKTOP_OUT_B="${SWAY_DESKTOP_OUT_B:-DP-2}"
DESKTOP_OUT_C="${SWAY_DESKTOP_OUT_C:-HDMI-A-1}"
# kanshi profile names used by auto_in_office / auto_at_home
KANSHI_OFFICE_PROFILE="${SWAY_KANSHI_OFFICE_PROFILE:-office}"
KANSHI_HOME_PROFILE="${SWAY_KANSHI_HOME_PROFILE:-home}"

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

# ---------------------------------------------------------------------------
# Output snapshot helpers (sway lists only connected outputs, active or not)
# ---------------------------------------------------------------------------
refresh_outputs () {
    OUTPUTS_JSON=$(swaymsg -t get_outputs -r 2>/dev/null) && [[ -n "$OUTPUTS_JSON" ]]
}

output_exists () {
    jq -e --arg n "$1" 'any(.[]; .name == $n)' <<< "$OUTPUTS_JSON" > /dev/null
}

output_active () {
    jq -e --arg n "$1" 'any(.[]; .name == $n and .active)' <<< "$OUTPUTS_JSON" > /dev/null
}

connected_outputs () {
    jq -r '.[].name' <<< "$OUTPUTS_JSON"
}

active_output_names () {
    jq -r '.[] | select(.active) | .name' <<< "$OUTPUTS_JSON"
}

first_output_matching () {
    jq -r --arg re "$1" '[.[] | select(.name | test($re))][0].name // empty' <<< "$OUTPUTS_JSON"
}

# Logical size (after scale/transform) of an active output: "W H"
logical_size () {
    jq -r --arg n "$1" '.[] | select(.name == $n and .active) | "\(.rect.width) \(.rect.height)"' <<< "$OUTPUTS_JSON"
}

# Logical geometry "W H X Y" of an active output
logical_geometry () {
    jq -r --arg n "$1" '.[] | select(.name == $n and .active) | "\(.rect.width) \(.rect.height) \(.rect.x) \(.rect.y)"' <<< "$OUTPUTS_JSON"
}

# Preferred mode string "WxH@R.RRRHz": wlr-randr's preferred flag if available,
# otherwise the largest mode with the highest refresh rate.
preferred_mode () {
    local out=$1 mode=""
    if command -v wlr-randr > /dev/null; then
        mode=$(wlr-randr --json 2>/dev/null | jq -r --arg n "$out" '
            .[] | select(.name == $n) | [.modes[] | select(.preferred)][0]
            | select(. != null) | "\(.width)x\(.height)@\(.refresh)Hz"' 2>/dev/null)
    fi
    if [[ -z "$mode" ]]; then
        mode=$(jq -r --arg n "$out" '
            .[] | select(.name == $n) | .modes | sort_by(.width * .height, .refresh) | last
            | select(. != null) | "\(.width)x\(.height)@\(.refresh / 1000)Hz"' <<< "$OUTPUTS_JSON")
    fi
    printf '%s\n' "$mode"
}

# Physical size "WIDTHmm HEIGHTmm" via wlr-randr (sway's IPC does not expose it)
physical_size () {
    command -v wlr-randr > /dev/null || return 0
    wlr-randr --json 2>/dev/null | jq -r --arg n "$1" '
        .[] | select(.name == $n) | "\(.physical_size.width // 0)mm \(.physical_size.height // 0)mm"' 2>/dev/null
}

is_internal () {
    [[ "$1" =~ ^(eDP|LVDS|DSI) ]]
}

# Command fragment that enables an output in its preferred mode (xrandr --auto)
auto_fragment () {
    local mode
    mode=$(preferred_mode "$1")
    if [[ -n "$mode" ]]; then
        printf 'output "%s" enable mode %s' "$1" "$mode"
    else
        printf 'output "%s" enable' "$1"
    fi
}

# Command fragment for "WxH at R Hz": existing mode, else scale emulation on internal
# panels (custom modes are rarely accepted by eDP panels), else a custom mode.
mode_fragment () {
    local out=$1 w=$2 h=$3 r=$4 native_w scale
    if jq -e --arg n "$out" --argjson w "$w" --argjson h "$h" \
        'any(.[] | select(.name == $n) | .modes[]; .width == $w and .height == $h)' <<< "$OUTPUTS_JSON" > /dev/null; then
        # Existing mode: let sway pick the matching refresh rate
        printf 'output "%s" enable mode %sx%s scale 1' "$out" "$w" "$h"
    elif is_internal "$out"; then
        native_w=$(preferred_mode "$out"); native_w=${native_w%%x*}
        if [[ "$native_w" =~ ^[0-9]+$ ]]; then
            scale=$(awk -v a="$native_w" -v b="$w" 'BEGIN {printf "%.4f", a / b}')
            printf '%s scale %s' "$(auto_fragment "$out")" "$scale"
        else
            printf 'output "%s" enable mode --custom %sx%s@%sHz' "$out" "$w" "$h" "${r:-60}"
        fi
    else
        printf 'output "%s" enable mode --custom %sx%s@%sHz' "$out" "$w" "$h" "${r:-60}"
    fi
}

sway_out () {
    swaymsg "$@" > /dev/null
}

# ---------------------------------------------------------------------------
# Detect output names (map X names eDP1/HDMI1 to DRM names)
# ---------------------------------------------------------------------------
refresh_outputs || {
    notify-send -u critical "Display change failed" "Could not read display outputs" --icon="$ICON" || true
    exit 1
}
SYSFS_EDP=$(for f in /sys/class/drm/card*-eDP-*; do [[ -e "$f" ]] && basename "$f"; done | head -n1)
eDP1=$(first_output_matching '^eDP')
[[ -n "$eDP1" ]] || eDP1=$(first_output_matching '^(LVDS|DSI)')
HAS_INTERNAL_OUTPUT=
[[ -n "$eDP1" || -n "$SYSFS_EDP" ]] && HAS_INTERNAL_OUTPUT=yes
[[ -n "$eDP1" ]] || eDP1=${SYSFS_EDP#card*-}
[[ -n "$eDP1" ]] || eDP1=eDP-1
eDP1_STATUS=disconnected; output_exists "$eDP1" && eDP1_STATUS=connected
HDMI1=$(first_output_matching '^HDMI-A-1$')
[[ -n "$HDMI1" ]] || HDMI1=$(first_output_matching '^HDMI')
[[ -n "$HDMI1" ]] || HDMI1=HDMI-A-1
HDMI1_STATUS=disconnected; output_exists "$HDMI1" && HDMI1_STATUS=connected
read -r HDMI1_WIDTH HDMI1_HEIGHT < <(physical_size "$HDMI1")

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_display_operator.sh [options] [conky]"
    echo ""
    echo "OPTIONS (eDP1 = $eDP1, HDMI1 = $HDMI1 on this machine)"
    echo "  [eDP1]"
    echo "      [eDP1_default]: set eDP1 to 1920x1080"
    echo "      [eDP1_auto]: activate eDP1"
    echo "      [eDP1_1440x810_60]: eDP1 in shrink mode (1440x810, emulated by scaling)"
    echo "      [eDP1_1368x768_60]: eDP1 in shrink mode (1368x768)"
    echo "      [eDP1_primary]: set eDP1 as primary display (emulated)"
    echo "      [eDP1_off]: deactivate eDP1"
    echo "  [HDMI1]"
    echo "      [HDMI1_auto]: activate HDMI1"
    echo "      [HDMI1_default]: activate HDMI1 in default mode (1920x1080)"
    echo "      [HDMI1_1912x960_60]: activate HDMI1 in shrink mode (custom 1912x960@60)"
    echo "      [HDMI1_1920x1200_50]: activate HDMI1 in extended mode (custom 1920x1200@50)"
    echo "      [HDMI1_primary]: set HDMI1 as primary display (emulated)"
    echo "      [HDMI1_off]: deactivate HDMI1"
    echo "  [Combination]"
    echo "      [eDP1_HDMI1_joint]: activate eDP1 and HDMI1 in joint mode (eDP1+HDMI1)"
    echo "      [HDMI1_eDP1_joint]: activate eDP1 and HDMI1 in joint mode (HDMI1+eDP1)"
    echo "      [eDP1_HDMI1_mirror]: mirror eDP1 onto HDMI1 (wl-mirror)"
    echo "  [Preset/Auto]"
    echo "      [auto]: use preset configuration"
    echo "      [auto_in_office]: kanshi profile '$KANSHI_OFFICE_PROFILE'"
    echo "      [auto_at_home]: kanshi profile '$KANSHI_HOME_PROFILE'"
    echo "  [Interactive Selection]"
    echo "      [select_display_position]: select display position (top-left)"
    echo "      [select_display_mode]: select display mode"
    echo "      [select_display_as_primary]: select display as primary display (emulated)"
    echo "      [select_display_orientation]: select display orientation"
    echo "      [select_display_scale]: select display scale"
    echo "      [select_input_to_output]: map a pointer/touch/tablet input to an output"
    echo "      [show_display_layout]: show display layout"
    echo ""
    echo "CONKY"
    echo "  [enable]: show conky after changing"
    echo "  [disable]: do not show conky after changing"
}

# Reload conky after monitor display is set
reload_conky () {
    "$SWAY_SCRIPT/sway_conky_monitor_display.sh" primary_only
}

reload_misc () {
    # Reload wallpaper (sway starts swaybg itself); there is no picom on sway
    [[ -r "$WALLPAPER" ]] && swaymsg "output * bg \"$WALLPAPER\" fill" > /dev/null
    return 0
}

# "Primary" does not exist on sway. Emulation: remember the output (read by
# sway_conky_monitor_display.sh), move workspace 1 there and focus it. XWayland
# clients that query RandR primary also get it via xrandr when available.
set_primary () {
    local out=$1
    printf '%s\n' "$out" > "$PRIMARY_STATE" 2>/dev/null
    swaymsg "workspace number 1; move workspace to output \"$out\"; focus output \"$out\"" > /dev/null || return 1
    if command -v xrandr > /dev/null && [[ -n "$DISPLAY" ]]; then
        xrandr --output "$out" --primary &> /dev/null || true
    fi
    return 0
}

stop_mirror () {
    pkill -x wl-mirror &> /dev/null || true
}

# Place two active outputs side by side at y=0 (left at x=0)
side_by_side () {
    local left=$1 right=$2 lw
    refresh_outputs || return 1
    read -r lw _ < <(logical_size "$left")
    [[ "$lw" =~ ^[0-9]+$ ]] || return 1
    sway_out "output \"$left\" pos 0 0; output \"$right\" pos $lw 0"
}

# xrandr --right-of/--left-of/--above/--below for active outputs
place_relative () {
    local sel=$1 dir=$2 ref=$3 sw sh rw rh rx ry x y
    refresh_outputs || return 1
    read -r sw sh _ _ < <(logical_geometry "$sel")
    read -r rw rh rx ry < <(logical_geometry "$ref")
    [[ "$sw" =~ ^[0-9]+$ && "$rw" =~ ^[0-9]+$ ]] || return 1
    case $dir in
        right-of) x=$((rx + rw)); y=$ry ;;
        left-of)  x=$((rx - sw)); y=$ry ;;
        above)    x=$rx; y=$((ry - sh)) ;;
        below)    x=$rx; y=$((ry + rh)) ;;
        *) return 1 ;;
    esac
    # Keep coordinates non-negative: shift the reference instead
    if (( x < 0 )); then
        sway_out "output \"$sel\" pos 0 $y; output \"$ref\" pos $((rx - x)) $ry"
    elif (( y < 0 )); then
        sway_out "output \"$sel\" pos $x 0; output \"$ref\" pos $rx $((ry - y))"
    else
        sway_out "output \"$sel\" pos $x $y"
    fi
}

joint () {
    # joint <left> <right> <primary>
    sway_out "$(auto_fragment "$1"); $(auto_fragment "$2")" &&
        side_by_side "$1" "$2" &&
        set_primary "$3"
}

mirror () {
    # Keep both outputs on, mirror eDP1 fullscreen onto HDMI1
    command -v wl-mirror > /dev/null || {
        notify-send -u normal "sway_display_operator.sh" "eDP1_HDMI1_mirror: wl-mirror is not installed" --icon="$ICON"
        return 1
    }
    sway_out "$(auto_fragment "$eDP1"); $(auto_fragment "$HDMI1")" &&
        side_by_side "$eDP1" "$HDMI1" || return 1
    stop_mirror
    setsid -f wl-mirror --fullscreen-output "$HDMI1" "$eDP1" &> /dev/null
}

restore_laptop_display () {
    local display

    if ! sway_out "$(auto_fragment "$eDP1") pos 0 0 transform normal scale 1"; then
        notify-send -u critical "Display change failed" "Could not enable $eDP1; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    refresh_outputs || return 1
    if ! output_active "$eDP1"; then
        notify-send -u critical "Display change failed" "$eDP1 is not active; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    set_primary "$eDP1"
    while read -r display; do
        [[ -z "$display" || "$display" == "$eDP1" ]] && continue
        sway_out "output \"$display\" disable" || {
            notify-send -u critical "Display change failed" "Could not disable $display" --icon="$ICON" || true
            return 1
        }
    done < <(active_output_names)
    notify-send -u low "Set Display" "$eDP1 laptop layout applied" --icon="$ICON" || true
}

safe_connected_display () {
    local output=${1:-} primary=""

    refresh_outputs || {
        notify-send -u critical "Display change failed" "Could not recheck display outputs; keeping the current layout" --icon="$ICON" || true
        return 1
    }
    if [[ -z "$output" ]] || ! output_exists "$output"; then
        [[ -r "$PRIMARY_STATE" ]] && primary=$(<"$PRIMARY_STATE")
        if [[ -n "$primary" ]] && output_active "$primary"; then
            output=$primary
        else
            output=$(active_output_names | head -n1)
            [[ -n "$output" ]] || output=$(connected_outputs | head -n1)
        fi
    fi
    if [[ -z "$output" ]]; then
        notify-send -u critical "Display change failed" "No connected display found; keeping the current layout" --icon="$ICON" || true
        return 1
    fi
    # Never disable another output in an unfamiliar display arrangement.
    if ! sway_out "$(auto_fragment "$output")"; then
        notify-send -u critical "Display change failed" "Could not enable $output; keeping the current layout" --icon="$ICON" || true
        return 1
    fi
    refresh_outputs || return 1
    if ! output_active "$output"; then
        notify-send -u critical "Display change failed" "$output did not become active; other outputs were left on" --icon="$ICON" || true
        return 1
    fi
    set_primary "$output"
    notify-send -u low "Set Display" "Safe layout: $output active; other outputs left unchanged" --icon="$ICON" || true
}

laptop_hdmi_profile_matches () {
    local count
    count=$(jq 'length' <<< "$OUTPUTS_JSON")
    [[ "$count" == 2 ]] && output_exists "$eDP1" && output_exists "$HDMI1"
}

desktop_profile_matches () {
    local count
    count=$(jq 'length' <<< "$OUTPUTS_JSON")
    [[ "$count" == 3 ]] && output_exists "$DESKTOP_OUT_A" &&
        output_exists "$DESKTOP_OUT_B" && output_exists "$DESKTOP_OUT_C"
}

display_run_or_laptop () {
    display_run "$@" || safe_connected_display "$eDP1"
}

layout_rent_24 () {
    # HDMI1 1920x1080 primary, eDP1 auto on its left
    sway_out "output \"$HDMI1\" enable mode 1920x1080 scale 1 transform normal; $(auto_fragment "$eDP1") transform normal" &&
        side_by_side "$eDP1" "$HDMI1" &&
        set_primary "$HDMI1"
}

layout_acer_27 () {
    sway_out "$(mode_fragment "$eDP1" 1440 810 60) pos 0 270 transform normal; $(mode_fragment "$HDMI1" 1920 1200 50) pos 1440 0 transform normal" &&
        set_primary "$HDMI1"
}

layout_unknown_hdmi () {
    sway_out "$(mode_fragment "$HDMI1" 1920 1200 50) pos 1440 0 transform normal; $(mode_fragment "$eDP1" 1440 810 60) pos 0 390 transform normal" &&
        set_primary "$HDMI1"
}

layout_other_hdmi () {
    sway_out "$(auto_fragment "$eDP1"); $(auto_fragment "$HDMI1")" &&
        place_relative "$HDMI1" right-of "$eDP1" &&
        set_primary "$HDMI1"
}

layout_desktop () {
    # X: DP-1 1920x1080 inverted @0x840, DP-2 1920x1200 --scale 0.8 @0x1920,
    #    HDMI-0 1920x1080 --scale-from 1536x864 rotated right @1920x0.
    # xrandr --scale 0.8 / --scale-from 1536x864 both equal sway scale 1.25.
    # Per-output --brightness is not available (see sway_backlight_operator.sh).
    sway_out "output \"$DESKTOP_OUT_A\" enable mode 1920x1080 scale 1 transform 180 pos 0 840; \
output \"$DESKTOP_OUT_B\" enable mode 1920x1200 scale 1.25 transform normal pos 0 1920; \
output \"$DESKTOP_OUT_C\" enable mode 1920x1080 scale 1.25 transform 90 pos 1920 0" &&
        set_primary "$DESKTOP_OUT_A"
}

auto_adjust () {
    local attempt

    stop_mirror
    # An internal output briefly missing during hotplug must never fall through
    # to the hardcoded desktop profile.
    if [[ "$HAS_INTERNAL_OUTPUT" == yes && "$eDP1_STATUS" != connected ]]; then
        for (( attempt=0; attempt<5; attempt++ )); do
            sleep 0.2
            refresh_outputs || return 1
            output_exists "$eDP1" && { eDP1_STATUS=connected; break; }
        done
        if [[ "$eDP1_STATUS" != connected ]]; then
            notify-send -u critical "Display change failed" "$eDP1 is not connected; keeping the current layout" --icon="$ICON" || true
            return 1
        fi
        HDMI1_STATUS=disconnected; output_exists "$HDMI1" && HDMI1_STATUS=connected
        read -r HDMI1_WIDTH HDMI1_HEIGHT < <(physical_size "$HDMI1")
    fi

    # Case 1: Laptop + HDMI Display
    if [ "${eDP1_STATUS}" == 'connected' ] && [ "${HDMI1_STATUS}" == 'connected' ]; then
        if ! laptop_hdmi_profile_matches; then
            safe_connected_display "$eDP1"
            return $?
        fi
        # Rent: 520mm x 290mm, IOA 24': 520mm x 290mm (physical size needs wlr-randr)
        if [ "${HDMI1_WIDTH}" == "520mm" ] && [ "${HDMI1_HEIGHT}" == "290mm" ]; then
            display_run_or_laptop "Rent 24' layout applied" layout_rent_24
        # ACER 27': 600mm x 340mm
        elif [ "${HDMI1_WIDTH}" == "600mm" ] && [ "${HDMI1_HEIGHT}" == "340mm" ]; then
            display_run_or_laptop "ACER 27' layout applied" layout_acer_27
        # Rent: 0mm x 0mm (unknown)
        elif [ "${HDMI1_WIDTH}" == "0mm" ] && [ "${HDMI1_HEIGHT}" == "0mm" ]; then
            display_run_or_laptop "External display layout applied" layout_unknown_hdmi
        # Other HDMI:
        else
            display_run_or_laptop "External ${HDMI1} layout applied" layout_other_hdmi
        fi
        return
    fi

    # Case 2: Laptop only
    if [ "${eDP1_STATUS}" == 'connected' ]; then
        if connected_outputs | grep -vqxF "$eDP1"; then
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
        display_run "Desktop display layout applied" layout_desktop || safe_connected_display
        return $?
    fi
}

auto_kanshi () {
    local profile=$1 subcmd=$2
    if command -v kanshictl > /dev/null && kanshictl switch "$profile"; then
        notify-send -u low "Set Display" "kanshi profile '$profile' applied" --icon="$ICON" || true
        return 0
    fi
    notify-send -u normal "sway_display_operator.sh" \
        "$subcmd: not supported on sway/Wayland without kanshi – start kanshi and define profile '$profile' (setup_monitors.sh is xrandr-only)" --icon="$ICON"
    return 1
}

# Keep output selection predictable: one connected output is selected silently,
# while two or more outputs require an explicit choice.
choose_connected_display () {
    local operation=$1 selected
    local -a displays=()
    mapfile -t displays < <(connected_outputs)
    if (( ${#displays[@]} == 0 )); then
        notify-send -u critical "Display change failed" "No connected outputs" --icon="$ICON" || true
        return 1
    fi
    DISPLAY_AUTO_SELECTED=no
    if (( ${#displays[@]} == 1 )); then
        SELECTED_DISPLAY=${displays[0]}
        DISPLAY_AUTO_SELECTED=yes
        return 0
    fi
    selected=$(printf '%s\n' "${displays[@]}" |
        rofi -dmenu -i -no-custom -p "$operation · Select output") || return 1
    [[ -n $selected ]] || return 1
    SELECTED_DISPLAY=$selected
}

display_target_hint () {
    if [[ $DISPLAY_AUTO_SELECTED == yes ]]; then
        printf 'Only connected output: %s' "$SELECTED_DISPLAY"
    else
        printf 'Target output: %s' "$SELECTED_DISPLAY"
    fi
}

# Preserve simple arithmetic in custom coordinates, but reject other bc input.
evaluate_coordinate () {
    local value
    [[ $1 =~ ^[[:space:]0-9+*/().-]+$ && $1 =~ [0-9] ]] || return 1
    value=$(printf 'scale=2; %s\n' "$1" | bc -l 2>/dev/null) || return 1
    [[ $value =~ ^[-+]?([0-9]+([.][0-9]*)?|[.][0-9]+)$ ]] || return 1
    printf '%.0f\n' "$value"
}

select_display_mode () {
    local selected_mode
    local -a modes=()
    choose_connected_display 'Resolution' || return 1
    mapfile -t modes < <(jq -r --arg n "$SELECTED_DISPLAY" '
        .[] | select(.name == $n) | .modes | sort_by(-(.width * .height), -.refresh) | .[]
        | "\(.width)x\(.height)@\(.refresh / 1000)Hz"' <<< "$OUTPUTS_JSON" | awk '!seen[$0]++')
    if (( ${#modes[@]} == 0 )); then
        notify-send -u critical "Display change failed" "No modes for $SELECTED_DISPLAY" --icon="$ICON" || true
        return 1
    fi
    selected_mode=$(printf '%s\n' "${modes[@]}" 'off' |
        rofi -dmenu -i -no-custom -p "Resolution · $SELECTED_DISPLAY" \
            -mesg "$(display_target_hint)") || return 1
    [[ -n $selected_mode ]] || return 1
    if [[ $selected_mode == off ]]; then
        display_run "$SELECTED_DISPLAY disabled" sway_out "output \"$SELECTED_DISPLAY\" disable"
    else
        display_run "$SELECTED_DISPLAY set to $selected_mode" sway_out "output \"$SELECTED_DISPLAY\" enable mode $selected_mode"
    fi
}

select_display_position () {
    local geometry current_position choice index reference direction input_pos x_expr y_expr pos_x pos_y
    local -a rows=() directions=() references=() active_displays=()
    choose_connected_display 'Position' || return 1
    geometry=$(logical_geometry "$SELECTED_DISPLAY")
    if [[ -z "$geometry" ]]; then
        notify-send -u critical "Display change failed" "Enable $SELECTED_DISPLAY before moving it" --icon="$ICON" || true
        return 1
    fi
    read -r _ _ pos_x pos_y <<< "$geometry"
    current_position="${pos_x},${pos_y}"
    rows=("Keep current ($current_position)" 'Custom X,Y')
    directions=('keep' 'custom')
    references=('' '')
    mapfile -t active_displays < <(active_output_names)
    for reference in "${active_displays[@]}"; do
        [[ $reference == "$SELECTED_DISPLAY" ]] && continue
        rows+=("Right of $reference" "Left of $reference" "Above $reference" "Below $reference")
        directions+=(right-of left-of above below)
        references+=("$reference" "$reference" "$reference" "$reference")
    done
    choice=$(printf '%s\n' "${rows[@]}" |
        rofi -dmenu -i -no-custom -format i -p "Position · $SELECTED_DISPLAY" \
            -mesg "$(display_target_hint) · Current: $current_position") || return 0
    [[ $choice =~ ^[0-9]+$ && $choice -lt ${#directions[@]} ]] || return 1
    index=$choice
    direction=${directions[index]}
    case $direction in
        keep) return 0 ;;
        custom)
            input_pos=$(rofi -dmenu -p "Position · $SELECTED_DISPLAY (X,Y)" \
                -mesg "Current: $current_position · Example: 1920,0 · Esc: cancel" </dev/null) || return 0
            [[ -n $input_pos ]] || return 0
            [[ $input_pos == *,* && ${input_pos#*,} != *,* ]] || {
                notify-send -u critical "Display change failed" "Enter two coordinates as X,Y" --icon="$ICON" || true
                return 1
            }
            x_expr=${input_pos%%,*}
            y_expr=${input_pos#*,}
            pos_x=$(evaluate_coordinate "$x_expr") && pos_y=$(evaluate_coordinate "$y_expr") || {
                notify-send -u critical "Display change failed" "Invalid position: $input_pos" --icon="$ICON" || true
                return 1
            }
            display_run "$SELECTED_DISPLAY moved to ${pos_x}x${pos_y}" \
                sway_out "output \"$SELECTED_DISPLAY\" pos $pos_x $pos_y"
            ;;
        *)
            display_run "$SELECTED_DISPLAY placed $direction ${references[index]}" \
                place_relative "$SELECTED_DISPLAY" "$direction" "${references[index]}"
            ;;
    esac
}

select_display_as_primary () {
    choose_connected_display 'Primary' || return 1
    display_run "$SELECTED_DISPLAY is primary (workspace 1 moved there)" set_primary "$SELECTED_DISPLAY"
}

select_display_scale () {
    local selected_scale
    choose_connected_display 'Scale' || return 1
    selected_scale=$(rofi -dmenu -p "Scale · $SELECTED_DISPLAY" \
        -mesg "$(display_target_hint) · Enter a positive value, e.g. 1 or 1.25 (sway: >1 = larger UI)" </dev/null) || return 0
    [[ -n $selected_scale ]] || return 0
    if [[ ! $selected_scale =~ ^([0-9]+([.][0-9]+)?|[.][0-9]+)$ ]] ||
        ! awk -v value="$selected_scale" 'BEGIN {exit !(value > 0)}'; then
        notify-send -u critical "Display change failed" "Scale must be a positive number" --icon="$ICON" || true
        return 1
    fi
    display_run "$SELECTED_DISPLAY scaled to $selected_scale" \
        sway_out "output \"$SELECTED_DISPLAY\" scale $selected_scale"
}

select_display_orientation () {
    local orientation transform
    choose_connected_display 'Orientation' || return 1
    orientation=$(printf '%s\n' normal left right inverted |
        rofi -dmenu -i -no-custom -p "Orientation · $SELECTED_DISPLAY" \
            -mesg "$(display_target_hint)") || return 0
    [[ -n $orientation ]] || return 0
    case $orientation in
        normal) transform=normal ;;
        left) transform=270 ;;
        right) transform=90 ;;
        inverted) transform=180 ;;
        *) return 1 ;;
    esac
    display_run "$SELECTED_DISPLAY rotated $orientation" \
        sway_out "output \"$SELECTED_DISPLAY\" transform $transform"
}

select_input_to_output () {
    local input_lines selected_line input_id
    # Pointer-like devices only (keyboards cannot be mapped meaningfully)
    input_lines=$(swaymsg -t get_inputs -r | jq -r '
        .[] | select(.type == "pointer" or .type == "touchpad" or .type == "touch" or .type == "tablet_tool")
        | "\(.name)\t[\(.type)]\tid=\(.identifier)"' | awk '!seen[$0]++')
    selected_line=$(printf '%s\n' "$input_lines" | rofi -dmenu -i -p '[MAPPING] Select INPUT device')
    if [[ -z "$selected_line" ]]; then
        echo "[ERROR] NO INPUT is selected. Exiting ..."
        return
    fi
    input_id=${selected_line##*id=}
    if [[ -z "$input_id" ]]; then
        echo "[ERROR] Could not parse INPUT ID. Exiting ..."
        return
    fi
    choose_connected_display 'Map pointer' || return 1
    display_run "Input ${input_id} mapped to ${SELECTED_DISPLAY}" \
        sway_out "input \"$input_id\" map_to_output \"$SELECTED_DISPLAY\""
}

show_display_layout () {
    local layout
    layout=$(jq -r '.[] | if .active then
            "\(.name): \(.current_mode.width)x\(.current_mode.height)@\(.current_mode.refresh / 1000 | floor)Hz +\(.rect.x)+\(.rect.y) scale \(.scale) \(.transform)\(if .focused then " *" else "" end)"
        else "\(.name): off" end' <<< "$OUTPUTS_JSON") || return 1
    [[ -r "$PRIMARY_STATE" ]] && layout+=$'\n'"primary: $(<"$PRIMARY_STATE")"
    notify-send -u low "Display Mode" "$layout" --icon="${ICON}"
}

display_operation () {
    case $1 in
        # Combination of HDMI1, eDP1
        "eDP1_HDMI1_joint")
            stop_mirror
            display_run "eDP1-HDMI1 joint mode activated" joint "$eDP1" "$HDMI1" "$HDMI1"
            ;;
        "eDP1_HDMI1_mirror")
            display_run "eDP1-HDMI1 mirror mode activated (wl-mirror)" mirror
            ;;
        "HDMI1_eDP1_joint")
            stop_mirror
            display_run "HDMI1-eDP1 joint mode activated" joint "$HDMI1" "$eDP1" "$HDMI1"
            ;;
        # HDMI1
        "HDMI1_auto")
            display_run "${HDMI1} activated (auto)" sway_out "$(auto_fragment "$HDMI1")"
            ;;
        "HDMI1_off")
            stop_mirror
            display_run "${HDMI1} disabled" sway_out "output \"$HDMI1\" disable"
            ;;
        "HDMI1_1920x1200_50")
            display_run "${HDMI1} set to 1920x1200@50" sway_out "$(mode_fragment "$HDMI1" 1920 1200 50)"
            ;;
        "HDMI1_1912x960_60")
            display_run "${HDMI1} set to 1912x960@60" sway_out "$(mode_fragment "$HDMI1" 1912 960 60)"
            ;;
        "HDMI1_default")
            display_run "${HDMI1} set to 1920x1080" sway_out "output \"$HDMI1\" enable mode 1920x1080 scale 1"
            ;;
        "HDMI1_primary")
            display_run "${HDMI1} is primary" set_primary "$HDMI1"
            ;;
        # eDP1
        "eDP1_auto")
            display_run "${eDP1} activated (auto)" sway_out "$(auto_fragment "$eDP1")"
            ;;
        "eDP1_off")
            stop_mirror
            display_run "${eDP1} disabled" sway_out "output \"$eDP1\" disable"
            ;;
        "eDP1_1440x810_60")
            display_run "${eDP1} set to 1440x810" sway_out "$(mode_fragment "$eDP1" 1440 810 60)"
            ;;
        "eDP1_1368x768_60")
            display_run "${eDP1} set to 1368x768" sway_out "$(mode_fragment "$eDP1" 1368 768 60)"
            ;;
        "eDP1_default")
            display_run "${eDP1} set to 1920x1080" sway_out "output \"$eDP1\" enable mode 1920x1080 scale 1"
            ;;
        "eDP1_primary")
            display_run "${eDP1} is primary" set_primary "$eDP1"
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
            show_display_layout
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
            auto_kanshi "$KANSHI_OFFICE_PROFILE" auto_in_office || return $?
            ;;
        "auto_at_home")
            auto_kanshi "$KANSHI_HOME_PROFILE" auto_at_home || return $?
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
