#!/usr/bin/env bash

case $1 in
    "enable")
        python3 $I3_SCRIPT/i3_automark.py
        ;;
    "disable")
        kill $(ps -aux | grep "python3 $I3_SCRIPT/i3_automark.py")
        ;;
    *)
        echo $0
esac
