#!/usr/bin/env bash

# Source code
# -- https://www.reddit.com/r/i3wm/comments/jct4ti/i3wm_gaps_cant_switch_ibus_method/

EN_ibus="xkb:us::eng"
CH_ibus="chewing"
lang=`ibus engine`

if [ $lang = $EN_ibus ]; then
    notify-send "[ibus-CH]: Chinese (chewing)"
    ibus engine $CH_ibus
fi

if [ $lang = $CH_ibus ]; then
    notify-send "[ibus-EN]: English (xkb:us::eng)"
    ibus engine $EN_ibus
fi
