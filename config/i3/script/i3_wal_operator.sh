#!/usr/bin/env bash

if [ -z $1 ]; then
    echo $0
elif [ $1 == "enable" ]; then
    awk 'NR==2 {print $4}' ~/.fehbg | xargs -I {} wal -i {} --nine
elif [ $1 == "disable" ]; then
    rm -rf ${HOME}/.cache/wal
elif [ $1 == "restart" ]; then
    # Kill picom/flashfocus
    killall picom
    killall flashfocus
    # Restart i3
    i3-msg restart
    # Appy changes
    picom
    i3_automark_operation.sh enable
    i3_conky_colorchanger.sh
    i3_dunst_colorchanger.sh
else
    echo $0
fi
