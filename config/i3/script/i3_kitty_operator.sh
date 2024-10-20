#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_kitty_operator.sh [operations] [options]"
    echo ""
    echo "OPERATIONS"
    echo "  [attach_to_tmux_session]: create new kitty terminal and attach to tmux session"
    echo "  [attach_to_selected_tmux_session]: create new kitty terminal and attach to selected tmux session"
}

attach_to_tmux_session () {
    if [[ -z $1 ]]; then
        return
    fi

    if $(tmux list-sessions | grep -q -w $1); then
        i3-msg exec "kitty --class floating_kitty -e tmux attach -t $1"
    else
        i3-msg exec "kitty --class floating_kitty -e $1"
    fi
}

kitty_operation () {
    case $1 in
        "attach_to_tmux_session")
            attach_to_tmux_session $2
            ;;
        "attach_to_selected_tmux_session")
            SESSION=$(tmux list-sessions | \
                rofi -dmenu -config "$HOME/.config/rofi/config_singlecol.rasi" \
                -p "TMUX session" -i -auto-select | awk -F: '{print $1}')
            attach_to_tmux_session ${SESSION}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

kitty_operation $@
