#!/usr/bin/env bash

case $1 in
    "enable")
        awk 'NR==2 {print $4}' ~/.fehbg | xargs -I {} wal -i {} --nine
        ;;
    "disable")
        rm -rf $HOME/.cache/wal
        ;;
    "restart")
        # Kill picom/flashfocus
        killall picom
        killall flashfocus
        # Restart i3
        i3-msg restart
        # Appy changes
        picom
        i3_automark_operation.sh enable
        i3_dunst_colorchanger.sh both
        ;;
    *)
esac
