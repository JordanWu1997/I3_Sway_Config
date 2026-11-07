#!/bin/bash
# Ported from i3_backlight_operator.sh for sway.
# Replaced X11 tools:
#   - xbacklight                 -> brightnessctl (internal panel backlight, works on Wayland)
#   - xrandr --brightness (gamma) -> per output:
#       * internal panel (eDP/LVDS/DSI): brightnessctl
#       * external monitor: ddcutil setvcp 10 (real DDC/CI hardware brightness)
#       * fallback when ddcutil is missing/fails: gammastep -O 6500 -b <0.1..1.0>
#         (software gamma; wlroots gamma is GLOBAL to all outputs and lasts only while
#          gammastep runs, so it replaces any running gammastep instance)
#   - i3-msg -t get_workspaces   -> swaymsg -t get_workspaces
# Subcommands and arguments are identical to the i3 version (names still say "xbacklight").

ICON="$HOME/.config/i3/share/64x64/lightbulb_icon.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_backlight_operator.sh [operations] [backlight_levels]"
    echo ""
    echo "OPERATIONS"
    echo "  [set_focused_display_backlight_with_rofi]: set focused output brightness to input value [0~100]"
    echo "  [set_all_connected_displays_backlight_with_rofi]: set all active outputs brightness to input value [0~100]"
    echo "  [set_xbacklight_with_rofi]: set backlight (brightnessctl) to input value [0~100]"
    echo "  [set_xbacklight]: set backlight to argument backlight_levels"
    echo "  [inc_xbacklight]: increase backlight in amount argument backlight_levels"
    echo "  [dec_xbacklight]: decrease backlight in amount argument backlight_levels"
    echo "  [show_xbacklight]: show current backlight level"
    echo ""
    echo "BACKLIGHT_LEVELS"
    echo "  [0~100]: number between 0 and 100"
}

require_brightnessctl () {
    command -v brightnessctl > /dev/null && return 0
    notify-send -u normal "sway_backlight_operator.sh" "brightnessctl is not installed" --icon="${ICON}"
    exit 1
}

show_xbacklight () {
    require_brightnessctl
    # Machine readable: device,class,current,percent%,max
    BACKLIGHT=$(brightnessctl -m -c backlight 2>/dev/null | head -n1 | cut -d, -f4 | tr -d '%')
    [[ -n "${BACKLIGHT}" ]] || BACKLIGHT=$(brightnessctl -m | head -n1 | cut -d, -f4 | tr -d '%')
    # Send notification (replace previous one when notify-send supports -r)
    NOTIFY_SEND_VERSION=$(notify-send -v 2>/dev/null | tr ' ' '\n' | grep '\.' | cut -d. -f 2)
    if [[ "${NOTIFY_SEND_VERSION}" =~ ^[0-9]+$ ]] && (( NOTIFY_SEND_VERSION > 7 )); then
        NOTIFY_ID=19970920
        notify-send -r ${NOTIFY_ID} -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
    else
        notify-send -u low -a "Backlight" "${BACKLIGHT}%" --icon="${ICON}"
    fi
}

# Set absolute level in percent (float allowed). Any value > 0 keeps at least 1 raw
# step so that e.g. "set_xbacklight 0.1" means "minimum, not off" like xbacklight.
set_backlight_percent () {
    local level=$1 max raw
    require_brightnessctl
    max=$(brightnessctl -c backlight max 2>/dev/null || brightnessctl max)
    raw=$(awk -v l="$level" -v m="$max" 'BEGIN {
        r = int(l * m / 100 + 0.5); if (l > 0 && r < 1) r = 1; if (r > m) r = m; if (r < 0) r = 0; print r }')
    brightnessctl -q -c backlight set "$raw" 2>/dev/null || brightnessctl -q set "$raw"
}

# Read a level from rofi, clamp it like the i3 version (prints nothing on cancel)
read_level_with_rofi () {
    local input
    input=$(rofi -dmenu -p "$1")
    [[ -z ${input} ]] && return 1
    [[ ${input} =~ ^[0-9]+([.][0-9]+)?$ ]] || return 1
    if (( $(echo "${input} < 0" | bc -l) )); then
        input=1
    elif (( $(echo "${input} > 100" | bc -l) )); then
        input=100
    fi
    printf '%s\n' "${input}"
}

# ddcutil display number for a DRM connector name (e.g. HDMI-A-1)
ddc_display_for_output () {
    command -v ddcutil > /dev/null || return 1
    ddcutil detect --terse 2>/dev/null | awk -v out="$1" '
        /^Display[[:space:]]+[0-9]+/ {disp = $2}
        /DRM[_ ]connector:/ {conn = $NF; sub(/^card[0-9]+-/, "", conn); if (conn == out && disp != "") {print disp; exit}}'
}

GAMMA_FALLBACK_LEVEL=""

# Set "brightness" of one output to percent; returns 2 if only gamma fallback is possible
set_output_brightness () {
    local out=$1 level=$2 disp
    if [[ "$out" =~ ^(eDP|LVDS|DSI) ]] && command -v brightnessctl > /dev/null; then
        set_backlight_percent "$level"
        return
    fi
    disp=$(ddc_display_for_output "$out")
    if [[ -n "$disp" ]] && ddcutil --display "$disp" setvcp 10 "$(printf '%.0f' "$level")" &> /dev/null; then
        return 0
    fi
    GAMMA_FALLBACK_LEVEL=$level
    return 2
}

# Global software dimming (all outputs) via gammastep
apply_gamma_fallback () {
    local level=$1 factor temp
    command -v gammastep > /dev/null || {
        notify-send -u normal "sway_backlight_operator.sh" \
            "No ddcutil/brightnessctl control for this output and gammastep is missing – software brightness is not supported natively on sway" --icon="${ICON}"
        return 1
    }
    factor=$(awk -v l="$level" 'BEGIN {f = l / 100; if (f < 0.1) f = 0.1; if (f > 1) f = 1; printf "%.2f", f}')
    # Keep the colour temperature of a running night light (sway_nightlight.sh: gammastep -O K)
    temp=$(pgrep -u "$USER" -a -x gammastep | grep -oE -- '-O +[0-9]+' | head -n1 | grep -oE '[0-9]+')
    pkill -u "$USER" -x gammastep &> /dev/null; sleep 0.2
    if [[ "$factor" == "1.00" ]]; then
        # Full brightness: only restore the night light, if there was one
        [[ -n "$temp" && "$temp" != 6500 ]] && setsid -f gammastep -m wayland -P -O "$temp" &> /dev/null
        return 0
    fi
    setsid -f gammastep -m wayland -P -O "${temp:-6500}" -b "$factor" &> /dev/null
    notify-send -u low -a "Backlight" "Software brightness ${factor} (all outputs, gammastep)" --icon="${ICON}"
}

backlight_operation () {
    case $1 in
        "set_focused_display_backlight_with_rofi")
            INPUT_LEVEL=$(read_level_with_rofi "Set focused display backlight to [0~100]") || return
            # Get focused output display
            FOCUS_OUTPUT=$(swaymsg -t get_workspaces -r | jq -r '.[] | select(.focused).output')
            set_output_brightness "${FOCUS_OUTPUT}" "${INPUT_LEVEL}"
            [[ $? -eq 2 ]] && apply_gamma_fallback "${INPUT_LEVEL}"
            ;;
        "set_all_connected_displays_backlight_with_rofi")
            INPUT_LEVEL=$(read_level_with_rofi "Set all connected displays backlight to [0~100]") || return
            while read -r FOCUS_OUTPUT; do
                [[ -n "${FOCUS_OUTPUT}" ]] && set_output_brightness "${FOCUS_OUTPUT}" "${INPUT_LEVEL}"
            done < <(swaymsg -t get_outputs -r | jq -r '.[] | select(.active) | .name')
            [[ -n "${GAMMA_FALLBACK_LEVEL}" ]] && apply_gamma_fallback "${GAMMA_FALLBACK_LEVEL}"
            ;;
        "set_xbacklight_with_rofi")
            INPUT_LEVEL=$(read_level_with_rofi "Set backlight to [0~100]") || return
            set_backlight_percent "${INPUT_LEVEL}"
            show_xbacklight
            ;;
        "set_xbacklight")
            set_backlight_percent "$2"
            show_xbacklight
            ;;
        "inc_xbacklight")
            require_brightnessctl
            brightnessctl -q -c backlight set "+${2}%" 2>/dev/null || brightnessctl -q set "+${2}%"
            show_xbacklight
            ;;
        "dec_xbacklight")
            require_brightnessctl
            # -n1 keeps the panel from switching fully off
            brightnessctl -q -n1 -c backlight set "${2}%-" 2>/dev/null || brightnessctl -q -n1 set "${2}%-"
            show_xbacklight
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

backlight_operation "$1" "$2"
