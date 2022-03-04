#!/usr/bin/env bash

GAP_CONFIG="$HOME/.config/i3/configs/i3_gap.config"
COL_SMART_GAP=$(awk '$1~/smart_gaps/ {print NR}' $GAP_CONFIG)

echo $COL_SMART_GAP

case $1 in
    "smart_gaps_on")
        sed -i "$COL_SMART_GAP s/.*/smart_gaps on/" $GAP_CONFIG
        ;;
    "smart_gaps_inverse_outer")
        sed -i "$COL_SMART_GAP s/.*/smart_gaps inverse_outer/" $GAP_CONFIG
        ;;
    "smart_gaps_off")
        sed -i "$COL_SMART_GAP s/.*/\#smart_gaps on/" $GAP_CONFIG
        ;;
esac

i3-msg reload
