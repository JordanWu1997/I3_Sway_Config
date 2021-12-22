#!/usr/bin/env bash

# Source code
# -- https://www.reddit.com/r/i3wm/comments/jct4ti/i3wm_gaps_cant_switch_ibus_method/

EN_IBUS="xkb:us::eng"
CH_IBUS="chewing"
INPUT_ENGINE=`ibus engine`

case $INPUT_ENGINE in
    $EN_IBUS)
        notify-send "[ibus-CH]: Chinese (chewing)"
        ibus engine $CH_IBUS
        ;;
    $CH_IBUS)
        notify-send "[ibus-EN]: English (xkb:us::eng)"
        ibus engine $EN_IBUS
esac
