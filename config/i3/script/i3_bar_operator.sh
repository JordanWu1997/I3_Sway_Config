#!/usr/bin/env bash

# i3bar
BAR_CONFIG="$HOME/.config/i3/config"
BAR_ID="bar_status"
BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print $3}' $BAR_CONFIG | awk 'NR==1')
BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print $3}' $BAR_CONFIG | awk 'NR==1')
BAR_POS=$(awk '$0~/default_i3bar_position/ {print $3}' $BAR_CONFIG | awk 'NR==1')

# Conky config
CONKY_TO_OFFSET="system"
if [ $BAR_POS == "bottom" ]; then
    CONKY_TO_OFFSET="bindkey"
fi
CONKY_CONFIG="$HOME/.config/conky/conky_config_$CONKY_TO_OFFSET"
CONKY_YOFFSET=$(awk '$0~/gap_y/ {print $3}' $CONKY_CONFIG | cut -d ',' -f 1)
CONKY_DEFAULT_YOFFSET=$(awk '$0~/default_conky_gap_y/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')

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
            $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_mode hide
            ;;
        "default_mode_dock")
            $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_mode dock
            ;;
        "default_pos_top")
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_position top
            ;;
        "default_pos_bottom")
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_position bottom
            ;;
        "bar_hide")
            $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
            i3-msg "bar mode hide $BAR_ID"
            ;;
        "bar_dock")
            $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            i3-msg "bar mode dock $BAR_ID"
            ;;
        "bar_toggle")
            if [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == 0 ]; then
                $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
                i3-msg "bar mode dock $BAR_ID"
            elif [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == $BAR_HEIGHT ]; then
                $I3_SCRIPT/i3_conky_valuechanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
                i3-msg "bar mode hide $BAR_ID"
            fi
            ;;
        "bar_hidden_state_show")
            i3-msg "bar hidden_state show $BAR_ID"
            ;;
        "bar_hidden_state_hide")
            i3-msg "bar hidden_state hide $BAR_ID"
            ;;
        "bar_reload")
            i3-msg exec 'killall i3bar && sleep 0.5'
            i3-msg exec 'i3bar -b bar_status && sleep 0.5'
            i3-msg exec 'i3bar -b bar_mode'
            notify-send -u low "Bar Mode" "Reload i3bar" --icon="$HOME/.config/i3/share/64x64/reload.png"
            ;;
        "bar_refresh_with_crontab")
            # In `crontab -e`, add following line to refresh bar every hour
            # 0 * * * * /home/jordan/.config/i3/script/i3_bar_operator.sh bar_refresh_with_crontab
            # ENV varaible must be set since i3-msg communicates with i3wm via i3 IPC socket (associated with user's X session)
            #export DISPLAY=:0
            export DISPLAY=:1
            export XAUTHORITY=$HOME/.Xauthority
            # i3-msg
            i3-msg exec 'killall i3bar && sleep 0.5'
            i3-msg exec 'i3bar -b bar_status && sleep 0.5'
            i3-msg exec 'i3bar -b bar_mode'
            # Verbose
            if [[ $2 == 'verbose' ]]; then
                # Point to run time directory for user-specific data e.g., socket
                export XDG_RUNTIME_DIR=/run/user/$(id -u)
                notify-send -u low "Bar Mode" "Refresh i3bar w/ crontab" \
                    --icon="$HOME/.config/i3/share/64x64/reload.png"
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
