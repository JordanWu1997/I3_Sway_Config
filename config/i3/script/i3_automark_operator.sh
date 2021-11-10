#!/usr/bin/env bash

if [ -z $1 ]; then
    echo $0
elif [ $1 == "disable" ]; then
    kill $(ps -aux | grep "python3 $I3_SCRIPT/i3_automark.py")
elif [ $1 == "enable" ]; then
    python3 $I3_SCRIPT/i3_automark.py
else
    echo $0
fi
