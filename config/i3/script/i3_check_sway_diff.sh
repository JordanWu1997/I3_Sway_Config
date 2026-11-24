#!/usr/bin/env bash

I3_DIR="$HOME/.config/i3"
SWAY_DIR="$HOME/.config/sway"

# Pair files by name (i3_<name> <-> sway_<name>), not by position: sway has
# config files i3 does not (e.g. sway_input_output.config), which would shift
# every later pair.
I3_CONFIG=("$I3_DIR/config")
SWAY_CONFIG=("$SWAY_DIR/config")
SWAY_ONLY=()
for config in "$SWAY_DIR"/config.d/*; do
    name=${config##*/sway_}
    if [[ -e "$I3_DIR/config.d/i3_$name" ]]; then
        I3_CONFIG+=("$I3_DIR/config.d/i3_$name")
        SWAY_CONFIG+=("$config")
    else
        SWAY_ONLY+=("$config")
    fi
done
I3_ONLY=()
for config in "$I3_DIR"/config.d/*; do
    name=${config##*/i3_}
    [[ -e "$SWAY_DIR/config.d/sway_$name" ]] || I3_ONLY+=("$config")
done

((${#I3_ONLY[@]})) && printf 'i3 only:   %s\n' "${I3_ONLY[@]}"
((${#SWAY_ONLY[@]})) && printf 'sway only: %s\n' "${SWAY_ONLY[@]}"

for (( i=0; i<${#I3_CONFIG[@]}; i++ )); do
    echo $( expr $i + 1 )/${#I3_CONFIG[@]} ${I3_CONFIG[i]} ${SWAY_CONFIG[i]}

    if ! command -v nvim; then
        vimdiff "${I3_CONFIG[i]}" "${SWAY_CONFIG[i]}"
    else
        nvim -d "${I3_CONFIG[i]}" "${SWAY_CONFIG[i]}"
    fi

    sleep 1
done
