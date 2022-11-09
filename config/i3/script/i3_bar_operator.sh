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

# Bar operation
bar_operation () {
    case $1 in
        "default_mode_hide")
            $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_mode hide
            ;;
        "default_mode_dock")
            $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_mode dock
            ;;
        "default_pos_top")
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_position top
            ;;
        "default_pos_bottom")
            $I3_SCRIPT/i3_default_valuechanger.sh i3bar_position bottom
            ;;
        "bar_hide")
            $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
            i3-msg "bar mode hide $BAR_ID"
            ;;
        "bar_dock")
            $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            i3-msg "bar mode dock $BAR_ID"
            ;;
        "bar_toggle")
            if [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == 0 ]; then
                $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
                i3-msg "bar mode dock $BAR_ID"
            elif [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == $BAR_HEIGHT ]; then
                $I3_SCRIPT/i3_conky_colorchanger.sh $CONKY_TO_OFFSET gap_y $CONKY_DEFAULT_YOFFSET
                i3-msg "bar mode hide $BAR_ID"
            fi
            ;;
        "bar_reload")
            i3-msg exec 'killall i3bar && sleep 0.5'
            i3-msg exec 'i3bar -b bar_status && sleep 0.5'
            i3-msg exec 'i3bar -b bar_mode'
            ;;
    esac
}

# Main
bar_operation $1
