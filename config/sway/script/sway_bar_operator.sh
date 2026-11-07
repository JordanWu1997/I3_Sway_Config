#!/usr/bin/env bash
# Ported from i3_bar_operator.sh for sway.
# Replaced X11 tools / i3-isms:
#   i3-msg -t get_bar_config            -> swaymsg -t get_bar_config
#   i3-msg "bar mode X bar_status"      -> swaymsg "bar bar_status mode X"
#   i3-msg "bar hidden_state X ..."     -> swaymsg "bar bar_status hidden_state X"
#   killall i3bar + i3bar -b <id>       -> swaymsg reload (sway respawns every swaybar
#                                          defined in the config on reload)
#   DISPLAY/XAUTHORITY for cron         -> SWAYSOCK discovered in $XDG_RUNTIME_DIR
#   ~/.config/i3/config                 -> ~/.config/sway/config
#   i3_default_valuechanger.sh          -> sway_default_valuechanger.sh

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"

# swaybar
BAR_CONFIG="$HOME/.config/sway/config"
BAR_ID="bar_status"
BAR_HEIGHT=$(awk '$2=="$default_i3bar_height" {print $3; exit}' "$BAR_CONFIG")
CONKY_DEFAULT_YOFFSET=$(awk '$2=="$default_conky_gap_y" {print $3; exit}' "$BAR_CONFIG")

# Conky value changer (prefer a sway port if one exists)
if [[ -x "$SWAY_SCRIPT/sway_conky_valuechanger.sh" ]]; then
    CONKY_VALUECHANGER="$SWAY_SCRIPT/sway_conky_valuechanger.sh"
else
    CONKY_VALUECHANGER="$I3_SCRIPT/i3_conky_valuechanger.sh"
fi

bar_state () {
    swaymsg -t get_bar_config "$BAR_ID" |
        jq -er 'select((.mode == "dock" or .mode == "hide") and
            (.position == "top" or .position == "bottom")) |
            [.mode, .position] | @tsv'
}

# Conky's gap_y is measured from its aligned edge. Update both Conky roles
# so moving the bar also clears the offset at its former position.
sync_conky_offsets () {
    local mode=$1 position=$2 role alignment gap config
    local -A alignments=()

    if [[ ! $BAR_HEIGHT =~ ^[0-9]+$ || ! $CONKY_DEFAULT_YOFFSET =~ ^[0-9]+$ ]]; then
        printf 'Invalid bar height or Conky base gap in %s\n' "$BAR_CONFIG" >&2
        return 1
    fi

    for role in system bindkey; do
        config="$HOME/.config/conky/conky_config_$role"
        alignment=$(awk -F "'" '$1 ~ /^[[:space:]]*alignment[[:space:]]*=/ {print $2; exit}' "$config") || return 1
        [[ -n $alignment ]] || { printf 'No Conky alignment in %s\n' "$config" >&2; return 1; }
        alignments[$role]=$alignment
    done

    for role in system bindkey; do
        gap=$CONKY_DEFAULT_YOFFSET
        if [[ $mode == dock && ${alignments[$role]} == "$position"_* ]]; then
            gap=$((gap + BAR_HEIGHT))
        fi
        "$CONKY_VALUECHANGER" "$role" gap_y "$gap" || return 1
    done
}

sync_conky_from_bar () {
    local expected_mode=${1:-} expected_position=${2:-} state mode position
    state=$(bar_state) || return 1
    read -r mode position <<< "$state"
    if [[ -n $expected_mode && $mode != "$expected_mode" ]] ||
        [[ -n $expected_position && $position != "$expected_position" ]]; then
        printf 'bar_status has mode=%s position=%s; expected mode=%s position=%s\n' \
            "$mode" "$position" "$expected_mode" "$expected_position" >&2
        return 1
    fi
    sync_conky_offsets "$mode" "$position"
}

# Wrong usage message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_bar_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default_mode_hide]: set bar default mode to hide"
    echo "  [default_mode_dock]: set bar default mode to dock"
    echo "  [default_pos_top]: set bar default position to top"
    echo "  [default_pos_bottom]: set bar default position to bottom"
    echo "  [bar_hide]: hide status bar"
    echo "  [bar_dock]: show status bar"
    echo "  [bar_toggle]: toggle bar visibility (hide/dock)"
    echo "  [bar_hidden_state_show]: set hidden state to show"
    echo "  [bar_hidden_state_hide]: set hidden state to hide"
    echo "  [bar_reload]: reload bar"
    echo "  [bar_refresh_with_crontab]: script to reload swaybar with crontab"
}

# Restart all swaybar instances (sway respawns them on reload)
reload_swaybars () {
    swaymsg reload >/dev/null
}

# Bar operation
bar_operation () {
    case $1 in
        "default_mode_hide")
            "$SWAY_SCRIPT/sway_default_valuechanger.sh" i3bar_mode hide &&
                sync_conky_from_bar hide
            ;;
        "default_mode_dock")
            "$SWAY_SCRIPT/sway_default_valuechanger.sh" i3bar_mode dock &&
                sync_conky_from_bar dock
            ;;
        "default_pos_top")
            "$SWAY_SCRIPT/sway_default_valuechanger.sh" i3bar_position top &&
                sync_conky_from_bar '' top
            ;;
        "default_pos_bottom")
            "$SWAY_SCRIPT/sway_default_valuechanger.sh" i3bar_position bottom &&
                sync_conky_from_bar '' bottom
            ;;
        "bar_hide")
            swaymsg "bar $BAR_ID mode hide" >/dev/null &&
                sync_conky_from_bar hide
            ;;
        "bar_dock")
            swaymsg "bar $BAR_ID mode dock" >/dev/null &&
                sync_conky_from_bar dock
            ;;
        "bar_toggle")
            local state mode position next_mode
            state=$(bar_state) || return 1
            read -r mode position <<< "$state"
            if [[ $mode == dock ]]; then next_mode=hide; else next_mode=dock; fi
            swaymsg "bar $BAR_ID mode $next_mode" >/dev/null &&
                sync_conky_from_bar "$next_mode" "$position"
            ;;
        "bar_hidden_state_show")
            swaymsg "bar $BAR_ID hidden_state show"
            ;;
        "bar_hidden_state_hide")
            swaymsg "bar $BAR_ID hidden_state hide"
            ;;
        "bar_reload")
            if reload_swaybars; then
                notify-send -u low "Bar Mode" "swaybar restart requested" --icon="$HOME/.config/i3/share/64x64/reload.png" || true
            else
                notify-send -u critical "Bar Mode" "Could not request swaybar restart" --icon="$HOME/.config/i3/share/64x64/reload.png" || true
                return 1
            fi
            ;;
        "bar_refresh_with_crontab")
            # In `crontab -e`, add following line to refresh bar every hour
            # 0 * * * * /home/jordan/.config/sway/script/sway_bar_operator.sh bar_refresh_with_crontab
            # cron has no sway environment: locate the sway IPC socket of this user.
            export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
            if [[ -z ${SWAYSOCK:-} || ! -S $SWAYSOCK ]]; then
                SWAYSOCK=$(ls -t "$XDG_RUNTIME_DIR"/sway-ipc."$(id -u)".*.sock 2>/dev/null | head -n 1)
                export SWAYSOCK
            fi
            [[ -S $SWAYSOCK ]] || return 1
            reload_swaybars || return 1
            # Verbose
            if [[ $2 == 'verbose' ]]; then
                # notify-send needs the user's session bus
                export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$XDG_RUNTIME_DIR/bus}
                notify-send -u low "Bar Mode" "swaybar restart requested by cron" \
                    --icon="$HOME/.config/i3/share/64x64/reload.png" || true
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
bar_operation "$@"
