#!/usr/bin/env bash

case $1 in
    "enable")
        notify-send -u "low" "i3 Autotiling" "i3 autotiling is enabled"
        python $PYTHON_BIN/autotiling
        ;;
    "disable")
        notify-send -u "low" "i3 Autotiling" "i3 autotiling is disabled"
        kill $(ps -aux | grep "python $PYTHON_BIN/autotiling")
        ;;
    *)
        echo $0
esac