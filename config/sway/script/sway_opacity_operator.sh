#!/usr/bin/env bash
# Ported from i3_picom_operator.sh for sway.
# Replaced X11 tools:
#   - picom (X compositor)            -> sway's built-in compositor: "opacity" command +
#                                        runtime "for_window" rules for new windows
#   - picom opacity-rule "NN:class_g = 'X'"
#                                     -> [app_id="(?i)^X$"] / [class="(?i)^X$"] opacity 0.NN
#                                        (rules are read from the same picom config files)
#   - picom blur                      -> SwayFX "blur enable" (plain sway has no blur: notify,
#                                        the opacity rules are still applied)
#   - killall picom                   -> "off" subcommand: every window opaque, blur disabled
#   - after_i3_restart (xprop I3_PID) -> re-apply the current (or default) mode; run it with
#                                        exec_always, because a sway reload drops runtime rules
# Subcommands are identical to the i3 version, plus "off".
#
# Note: sway always renders client-side alpha (e.g. kitty background_opacity), with or
# without any of these modes; picom was needed for that on X11.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
PICOM_DIR="$HOME/.config/picom"
ICON="$HOME/.config/i3/share/64x64/notification.png"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/sway_opacity_mode"
# Opacity of windows without a picom rule (picom: active-opacity, default 1.0)
SWAY_OPACITY_DEFAULT="${SWAY_OPACITY_DEFAULT:-}"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_opacity_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: apply the default mode (picom.conf -> picom_<mode>.conf, set with 'Set default picom')"
    echo "  [transparency]: apply opacity rules of picom_transparency.conf"
    echo "  [blur]: apply opacity rules of picom_blur.conf and enable blur (SwayFX only)"
    echo "  [off]: all windows opaque, blur disabled (i3: killall picom)"
    echo "  [restart_running]: re-apply the current mode"
    echo "  [after_i3_restart]: re-apply the current mode, or the default one at login (exec_always)"
}

is_swayfx () {
    swaymsg -t get_version -r 2>/dev/null | jq -r '.human_readable // ""' | grep -qi 'swayfx'
}

# Default mode from the picom.conf symlink chosen with "Set default picom"
default_mode () {
    local target
    target=$(readlink -f "$PICOM_DIR/picom.conf" 2>/dev/null)
    case $(basename "${target:-}") in
        picom_blur.conf) echo blur ;;
        *) echo transparency ;;
    esac
}

# Print "<opacity> <class>" for every "NN:class_g = 'X'" opacity-rule of a picom config
picom_class_rules () {
    [[ -f $1 ]] || return 0
    awk '
        /^[[:space:]]*opacity-rule[[:space:]]*=/ { inside = 1 }
        inside {
            line = $0
            sub(/#.*/, "", line)
            if (match(line, /"[0-9]+:[[:space:]]*class_g[[:space:]]*=[[:space:]]*\047[^\047]+\047"/)) {
                rule = substr(line, RSTART + 1, RLENGTH - 2)
                split(rule, parts, ":")
                cls = rule
                sub(/^[^\047]*\047/, "", cls); sub(/\047.*$/, "", cls)
                printf "%.2f %s\n", parts[1] / 100, cls
            }
            if (line ~ /\]/) inside = 0
        }' "$1"
}

# active-opacity of a picom config (opacity of windows without a rule)
picom_active_opacity () {
    local value
    value=$(awk -F= '/^[[:space:]]*active-opacity[[:space:]]*=/ {gsub(/[ ;]/, "", $2); print $2; exit}' "$1" 2>/dev/null)
    echo "${SWAY_OPACITY_DEFAULT:-${value:-1.0}}"
}

# Run a sway command now for existing windows and as a for_window rule for new ones
apply_rule () {
    local criteria=$1 command=$2
    swaymsg "$criteria $command" >/dev/null 2>&1
    swaymsg "for_window $criteria $command" >/dev/null 2>&1
}

apply_opacity_rules () {
    local config=$1 opacity cls regex
    apply_rule '[all]' "opacity $(picom_active_opacity "$config")"
    while read -r opacity cls; do
        [[ -n $cls ]] || continue
        # class_g -> Wayland app_id (native) and X11 class (XWayland), case-insensitive
        regex="(?i)^${cls//\"/}\$"
        apply_rule "[app_id=\"$regex\"]" "opacity $opacity"
        apply_rule "[class=\"$regex\"]" "opacity $opacity"
    done < <(picom_class_rules "$config")
}

set_blur () {
    if is_swayfx; then
        swaymsg "blur $1" >/dev/null
        return 0
    fi
    return 1
}

apply_mode () {
    local mode=$1
    case $mode in
        "transparency")
            apply_opacity_rules "$PICOM_DIR/picom_transparency.conf"
            set_blur disable
            ;;
        "blur")
            apply_opacity_rules "$PICOM_DIR/picom_blur.conf"
            if ! set_blur enable; then
                notify-send -u normal -i "$ICON" "sway_opacity_operator.sh" \
                    "blur: not supported on sway/Wayland – blur needs SwayFX; opacity rules applied without blur" || true
            fi
            ;;
        "off")
            apply_rule '[all]' 'opacity 1'
            set_blur disable
            ;;
        *)
            return 1
            ;;
    esac
    echo "$mode" > "$STATE_FILE"
}

current_mode () {
    [[ -r $STATE_FILE ]] && head -n 1 "$STATE_FILE"
}

opacity_operation () {
    case $1 in
        "restart_running")
            local mode
            mode=$(current_mode)
            [[ -n $mode ]] && apply_mode "$mode"
            ;;
        "after_i3_restart")
            # Login: apply the default mode. Reload: runtime for_window rules are gone,
            # so re-apply the mode that was active.
            local mode
            mode=$(current_mode)
            apply_mode "${mode:-$(default_mode)}"
            ;;
        "default")
            apply_mode "$(default_mode)"
            ;;
        "transparency")
            apply_mode transparency
            ;;
        "blur")
            apply_mode blur
            ;;
        "off")
            apply_mode off
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
opacity_operation "$1"
