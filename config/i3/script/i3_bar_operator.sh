#!/usr/bin/env bash

# i3bar
BAR_CONFIG="$HOME/.config/i3/config"
BAR_ID="bar_status"
BAR_HEIGHT=$(awk '$2=="$default_i3bar_height" {print $3; exit}' "$BAR_CONFIG")
CONKY_DEFAULT_YOFFSET=$(awk '$2=="$default_conky_gap_y" {print $3; exit}' "$BAR_CONFIG")

bar_state () {
    i3-msg -t get_bar_config "$BAR_ID" |
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
        "$I3_SCRIPT/i3_conky_valuechanger.sh" "$role" gap_y "$gap" || return 1
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
    echo "  i3_bar_operator.sh [operations]"
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
    echo "  [bar_refresh_with_crontab]: script to reload i3bar with crontab"
}

# Bar operation
bar_operation () {
    case $1 in
        "default_mode_hide")
            "$I3_SCRIPT/i3_default_valuechanger.sh" i3bar_mode hide &&
                sync_conky_from_bar hide
            ;;
        "default_mode_dock")
            "$I3_SCRIPT/i3_default_valuechanger.sh" i3bar_mode dock &&
                sync_conky_from_bar dock
            ;;
        "default_pos_top")
            "$I3_SCRIPT/i3_default_valuechanger.sh" i3bar_position top &&
                sync_conky_from_bar '' top
            ;;
        "default_pos_bottom")
            "$I3_SCRIPT/i3_default_valuechanger.sh" i3bar_position bottom &&
                sync_conky_from_bar '' bottom
            ;;
        "bar_hide")
            i3-msg "bar mode hide $BAR_ID" >/dev/null &&
                sync_conky_from_bar hide
            ;;
        "bar_dock")
            i3-msg "bar mode dock $BAR_ID" >/dev/null &&
                sync_conky_from_bar dock
            ;;
        "bar_toggle")
            local state mode position next_mode
            state=$(bar_state) || return 1
            read -r mode position <<< "$state"
            if [[ $mode == dock ]]; then next_mode=hide; else next_mode=dock; fi
            i3-msg "bar mode $next_mode $BAR_ID" >/dev/null &&
                sync_conky_from_bar "$next_mode" "$position"
            ;;
        "bar_hidden_state_show")
            i3-msg "bar hidden_state show $BAR_ID"
            ;;
        "bar_hidden_state_hide")
            i3-msg "bar hidden_state hide $BAR_ID"
            ;;
        "bar_reload")
            if i3-msg exec 'killall i3bar && sleep 0.5' &&
                i3-msg exec 'i3bar -b bar_status && sleep 0.5' &&
                i3-msg exec 'i3bar -b bar_mode'; then
                notify-send -u low "Bar Mode" "i3bar restart requested" --icon="$HOME/.config/i3/share/64x64/reload.png" || true
            else
                notify-send -u critical "Bar Mode" "Could not request i3bar restart" --icon="$HOME/.config/i3/share/64x64/reload.png" || true
                return 1
            fi
            ;;
        "bar_refresh_with_crontab")
            # In `crontab -e`, add following line to refresh bar every hour
            # 0 * * * * /home/jordan/.config/i3/script/i3_bar_operator.sh bar_refresh_with_crontab
            # ENV varaible must be set since i3-msg communicates with i3wm via i3 IPC socket (associated with user's X session)
            #export DISPLAY=:0
            export DISPLAY=:1
            export XAUTHORITY=$HOME/.Xauthority
            # i3-msg
            if ! { i3-msg exec 'killall i3bar && sleep 0.5' &&
                i3-msg exec 'i3bar -b bar_status && sleep 0.5' &&
                i3-msg exec 'i3bar -b bar_mode'; }; then
                return 1
            fi
            # Verbose
            if [[ $2 == 'verbose' ]]; then
                # Point to run time directory for user-specific data e.g., socket
                export XDG_RUNTIME_DIR=/run/user/$(id -u)
                notify-send -u low "Bar Mode" "i3bar restart requested by cron" \
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
