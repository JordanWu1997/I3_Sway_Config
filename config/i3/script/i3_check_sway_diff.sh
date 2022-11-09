#!/usr/bin/env bash

I3_DIR="$HOME/.config/i3"
SWAY_DIR="$HOME/.config/sway"

I3_CONFIG=("$I3_DIR/config")
for config in $I3_DIR/config.d/*; do
    I3_CONFIG+=($config)
done

SWAY_CONFIG=("$SWAY_DIR/config")
for config in $SWAY_DIR/config.d/*; do
    SWAY_CONFIG+=($config)
done

for (( i=0; i<${#I3_CONFIG[@]}; i++ )); do
    echo $( expr $i + 1 )/${#I3_CONFIG[@]} ${I3_CONFIG[i]} ${SWAY_CONFIG[i]}

    if ! command -v nvim; then
        vimdiff ${I3_CONFIG[i]} ${SWAY_CONFIG[i]}
    else
        nvim -d ${I3_CONFIG[i]} ${SWAY_CONFIG[i]}
    fi

    sleep 1
done
