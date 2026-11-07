#!/usr/bin/env bash
# Ported from i3_terminal_operator.sh for sway.
# Replaced X11 tools:
#   - xprop -root _NET_ACTIVE_WINDOW / xprop WM_NAME -> swaymsg -t get_tree (focused node .name)
#   - xdotool getwindowfocus + [id=X] kill          -> focused node .id + [con_id=N] kill
#   - xclip -i                                      -> wl-copy
#   - i3-msg exec / reload                          -> swaymsg exec / reload
#   - edits $terminal in ~/.config/i3/config        -> edits $terminal in ~/.config/sway/config
# Subcommands and arguments are identical to the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
SWAY_CONFIG="$HOME/.config/sway/config"
ICON="$HOME/.config/i3/share/64x64/wrench.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  sway_terminal_operator.sh [operations] [options]"
    echo ""
    echo "OPERATIONS"
    echo "  [set_default_terminal]: set up default terminal to use in sway environment"
    echo "  [attach_to_tmux_session]: create new terminal and attach to tmux session"
    echo "  [attach_to_selected_tmux_session]: create new terminal terminal and attach to selected tmux session"
    echo "  [close_terminal_and_capture_tmux_cmd]: close terminal and copy tmux cmd if there is one"
}

attach_to_tmux_session () {
    if [[ -z $1 ]]; then
        return
    fi
    TERMINAL=$(grep -m 1 -w '^set $terminal' "${SWAY_CONFIG}" 2> /dev/null | cut -d' ' -f 3-)
    TERMINAL=${TERMINAL:-kitty}
    TERMINAL_OPTIONS=""
    if [[ $2 == 'floating' ]]; then
        # kitty --class sets the Wayland app_id; sway floats [app_id="floating_terminal"]
        TERMINAL_OPTIONS="${TERMINAL_OPTIONS} --class floating_terminal"
    fi
    if tmux list-sessions 2>/dev/null | grep -q -w "$1"; then
        swaymsg -- exec "${TERMINAL} ${TERMINAL_OPTIONS} -- tmux attach -t $1"
    else
        swaymsg -- exec "${TERMINAL} ${TERMINAL_OPTIONS} -- $1"
    fi
}

terminal_operation () {
    case $1 in
        "set_default_terminal")
            NEW_TERMINAL=$(printf '%s\n' kitty foot i3-sensible-terminal | rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                -p "Set Default Terminal to" -i | awk -F: '{print $1}')
            # Ignore empty selection
            if [[ -z "${NEW_TERMINAL}" ]]; then
                return
            fi
            # Check if input is vaild executable file
            if [[ ! $(command -v "${NEW_TERMINAL%% *}") ]]; then
                notify-send -u low "Sway Terminal Operator" "Your input ${NEW_TERMINAL} is not an executable file" --icon="${ICON}"
                return
            fi
            # Set new terminal as default ("set $terminal <cmd>" line in ~/.config/sway/config)
            COL=$(grep -n -m 1 -w '^set $terminal' "${SWAY_CONFIG}" 2> /dev/null | cut -d: -f1)
            if [[ -z $COL ]]; then
                notify-send -u normal "Sway Terminal Operator" "No 'set \$terminal' line found in ${SWAY_CONFIG}" --icon="${ICON}"
                return 1
            fi
            # Escape sed replacement metacharacters in the user input
            NEW_TERMINAL_ESCAPED=$(printf '%s' "$NEW_TERMINAL" | sed 's/[\/&]/\\&/g')
            # sed -i on the resolved file keeps the ~/.config/sway symlink intact
            sed -i "$COL s/.*/set \$terminal $NEW_TERMINAL_ESCAPED/" "$(readlink -f "${SWAY_CONFIG}")"
            # Reload configuration
            swaymsg reload
            # Notification
            notify-send -u low "Sway Terminal Operator" "Default terminal is set to $NEW_TERMINAL" --icon="${ICON}"
            ;;
        "attach_to_tmux_session")
            attach_to_tmux_session "$2" "$3"
            ;;
        "attach_to_selected_tmux_session")
            PROMPT="Attatch to TMUX session"
            if [[ $2 == 'tiling' ]]; then
                PROMPT="${PROMPT} [TILING]"
            else
                PROMPT="${PROMPT} [FLOATING]"
            fi
            SESSION=$(tmux list-sessions | \
                rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                -p "${PROMPT}" -i -auto-select | awk -F: '{print $1}')
            if [[ -z "${SESSION}" ]]; then
                return
            fi
            attach_to_tmux_session "${SESSION}" "$2"
            ;;
        "close_terminal_and_capture_tmux_cmd")
            # Get focused window con_id and title (native and XWayland windows alike)
            read -r FOCUS_WD_ID FOCUS_WD_NAME < <(swaymsg -t get_tree -r | jq -r '
                first(.. | objects | select(.focused? == true and (.type == "con" or .type == "floating_con"))
                    | "\(.id) \(.name // "")") // empty')
            if [[ ! ${FOCUS_WD_ID} =~ ^[0-9]+$ ]]; then
                return 1
            fi
            # Kill previously focused terminal with tmux session
            swaymsg "[con_id=${FOCUS_WD_ID}] kill"
            # If tmux session is on the focused terminal
            # (same title parsing as i3: second word, text after "|")
            TMUX_SESSION_NAME=$(echo "${FOCUS_WD_NAME}" | cut -d' ' -f2 | cut -d\| -f2)
            # Get attached TMUX session name
            if [[ -n ${TMUX_SESSION_NAME} ]] && tmux list-sessions -F '#S' 2>/dev/null | grep -q -x -F "$TMUX_SESSION_NAME"; then
                echo "tmux a -t ${TMUX_SESSION_NAME}" | wl-copy
            else
                echo "${FOCUS_WD_NAME}" | wl-copy
            fi
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

terminal_operation "$@"
