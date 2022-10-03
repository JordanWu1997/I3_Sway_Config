#!/usr/bin/env bash

# i3bar
BAR_CONFIG="$HOME/.config/i3/configs/i3_bar.config"
BAR_ID="bar_status"
COL_BAR_VIS=$(expr $(awk '$0~/Bar visibility/{print NR}' $BAR_CONFIG) + 1)
BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')

# Conky
CONKY_CONFIG="$HOME/.config/conky/conky_config_system"
CONKY_DEFAULT_YOFFSET=$(awk '$0~/default_conky_gap_y/ {print $3}' $HOME/.config/i3/config | awk 'NR==1')
CONKY_YOFFSET=$(awk '$0~/gap_y/ {print $3}' $CONKY_CONFIG | cut -d ',' -f 1)

bar_operation () {
    case $1 in
        "default_hide")
            $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $CONKY_DEFAULT_YOFFSET
            sed -i "$COL_BAR_VIS s/.*/    mode hide/" $BAR_CONFIG
            ;;
        "default_dock")
            $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            sed -i "$COL_BAR_VIS s/.*/    mode dock/" $BAR_CONFIG
            ;;
        "bar_hide")
            $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $CONKY_DEFAULT_YOFFSET
            i3-msg "bar mode hide $BAR_ID"
            ;;
        "bar_dock")
            $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
            i3-msg "bar mode dock $BAR_ID"
            ;;
        "bar_toggle")
            if [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == 0 ]; then
                $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $(expr $CONKY_DEFAULT_YOFFSET + $BAR_HEIGHT)
                i3-msg "bar mode dock $BAR_ID"
            elif [ $(expr $CONKY_YOFFSET - $CONKY_DEFAULT_YOFFSET) == $BAR_HEIGHT ]; then
                $I3_SCRIPT/i3_conky_colorchanger.sh system gap_y $CONKY_DEFAULT_YOFFSET
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
