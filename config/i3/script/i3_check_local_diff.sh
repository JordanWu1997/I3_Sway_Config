#!/usr/bin/env bash

GIT_DIR="$HOME/Desktop/I3_Sway_Config/config/i3"
LOC_DIR="$HOME/.config/i3"

GIT_CONFIG=("$GIT_DIR/config")
for config in $GIT_DIR/configs/*; do
    GIT_CONFIG+=($config)
done

LOC_CONFIG=("$LOC_DIR/config")
for config in $LOC_DIR/configs/*; do
    LOC_CONFIG+=($config)
done

for (( i=0; i<${#GIT_CONFIG[@]}; i++ )); do
    echo $( expr $i + 1 )/${#GIT_CONFIG[@]} ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}

    if ! command -v nvim; then
        vimdiff ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}
    else
        nvim -d ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}
    fi

    sleep 1
done
