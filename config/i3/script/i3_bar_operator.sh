#!/usr/bin/env bash

BAR_CONFIG="$HOME/.config/i3/configs/i3_bar.config"
BAR_ID="bar_base"
COL_BAR_VIS=$(expr $(awk '$0~/Bar visibility/{print NR}' $BAR_CONFIG) + 1)
COL_BAR_HEIGHT=$(expr $(awk '$0~/Height/ {print NR}' $BAR_CONFIG) + 1)
BAR_HEIGHT=$(awk -v var=$COL_BAR_HEIGHT 'NR==var {print $2}' $BAR_CONFIG)

CONKY_CONFIG="$HOME/.config/conky/conky_config_system"
CONKY_DEFAULT_YOFFSET=30
CONKY_YOFFSET=$(awk '$0~/gap_y/ {print $3}' $CONKY_CONFIG | cut -d ',' -f 1)

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
esac
