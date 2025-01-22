#!/usr/bin/env bash

I3_CONFIG="$HOME/.config/i3/config"
ICON="$HOME/.config/i3/share/64x64/wrench.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_terminal_operator.sh [operations] [options]"
    echo ""
    echo "OPERATIONS"
    echo "  [set_default_terminal]: set up default terminal to use in i3 environment"
    echo "  [attach_to_tmux_session]: create new terminal and attach to tmux session"
    echo "  [attach_to_selected_tmux_session]: create new terminal terminal and attach to selected tmux session"
}

attach_to_tmux_session () {
    if [[ -z $1 ]]; then
        return
    fi
    TERMINAL=$(grep -m 1 -w '^set $terminal' ${I3_CONFIG} 2> /dev/null | cut -d' ' -f 3-)
    TERMINAL=${TERMINAL:-kitty}
    if $(tmux list-sessions | grep -q -w $1); then
        i3-msg exec "${TERMINAL} --class floating_terminal -- tmux attach -t $1"
    else
        i3-msg exec "${TERMINAL} --class floating_terminal -- $1"
    fi
}

terminal_operation () {
    case $1 in
        "set_default_terminal")
            NEW_TERMINAL=$(echo i3-sensible-terminal | rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                -p "Set Default Terminal to" -i | awk -F: '{print $1}')
            # Ignore empty selection
            if [[ -z "${NEW_TERMINAL}" ]]; then
                return
            fi
            # Check if input is vaild executable file
            if [[ ! $(command -v "$NEW_TERMINAL") ]]; then
                notify-send -u low "i3 Terminal Operator" "Your input ${NEW_TERMINAL} is not an executable file" --icon="${ICON}"
                return
            fi
            # Set new terminal as default
            COL=$(grep -n -m 1 -w '^set $terminal' "${I3_CONFIG}" 2> /dev/null | cut -d: -f1)
            echo $COL
            sed -i "$COL s/.*/set \$terminal $NEW_TERMINAL/" "${I3_CONFIG}"
            # Reload configuration
            i3-msg reload
            # Notification
            notify-send -u low "i3 Terminal Operator" "Default terminal is set to $NEW_TERMINAL" --icon="${ICON}"
            ;;
        "attach_to_tmux_session")
            attach_to_tmux_session $2
            ;;
        "attach_to_selected_tmux_session")
            SESSION=$(tmux list-sessions | \
                rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                -p "TMUX session" -i -auto-select | awk -F: '{print $1}')
            if [[ -z "${SESSION}" ]]; then
                return
            fi
            attach_to_tmux_session ${SESSION}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

terminal_operation $@
