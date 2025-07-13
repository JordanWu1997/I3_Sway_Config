#!/usr/bin/env bash

# NOTE
# -- Source code
#   -- https://www.reddit.com/r/i3wm/comments/jct4ti/i3wm_gaps_cant_switch_ibus_method/
# -- In libpinyin, use [Ctrl]+[Shift]+[f] to switch between SC and TC
#   -- https://blog.csdn.net/shenyuan12/article/details/109485174

ICON="$HOME/.config/i3/share/64x64/language.png"
CURRENT_ENGINE=$(ibus engine)
#ENGINES=("xkb:us::eng" "chewing" "libpinyin")
ENGINES=("xkb:us::eng" "chewing")

# Check if an engine is installed
is_engine_installed () {
    ibus list-engine | grep -q "$1"
}

# Get current engine index
CURRENT_ENGINE_INDEX=-1
for i in "${!ENGINES[@]}"; do
    if [ "${ENGINES[$i]}" == "${CURRENT_ENGINE}" ]; then
        CURRENT_ENGINE_INDEX=$i
        break
    fi
done

# Find the next available engine
NEXT_ENGINE_INDEX=$((CURRENT_ENGINE_INDEX + 1))
while true; do
    # When cycle to the last element
    if [ "${NEXT_ENGINE_INDEX}" -ge "${#ENGINES[@]}" ]; then
        NEXT_ENGINE_INDEX=0
    fi
    # Check if the engine is installed
    NEXT_ENGINE="${ENGINES[${NEXT_ENGINE_INDEX}]}"
    if is_engine_installed "${NEXT_ENGINE}"; then
        break
    fi
    NEXT_ENGINE_INDEX=$((NEXT_ENGINE_INDEX + 1))
done

# Cycle to next engine
notify-send -u low "IBus Input Method" "Switch to ${NEXT_ENGINE}" --icon="${ICON}"
ibus engine "${NEXT_ENGINE}"
