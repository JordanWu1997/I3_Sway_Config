#!/usr/bin/env bash

case $1 in
    "enable")
        awk 'NR==2 {print $4}' ~/.fehbg | xargs -I {} wal -i {} --nine
        ;;
    "disable")
        rm -rf $HOME/.cache/wal
        ;;
esac
