#!/usr/bin/env bash

WINDOW_CONFIG="$HOME/.config/i3/configs/i3_window.config"

COL_WIN1=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 2)
COL_WIN2=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 3)
COL_WIN3=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 4)
COL_WIN4=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 5)
COL_WIN5=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 6)
COL_WIN6=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 7)

case $1 in
    "default")
        # Set window decoration
        sed -i "$COL_WIN1 s/.*/client.focused          \#4c7899 \#285577 \#ffffff \#2e9ef4 \#285577/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN2 s/.*/client.focused_inactive \#333333 \#5f676a \#ffffff \#484e50 \#5f676a/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN3 s/.*/client.unfocused        \#333333 \#222222 \#888888 \#292d2e \#222222/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN4 s/.*/client.urgent           \#2f343a \#900000 \#ffffff \#900000 \#900000/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN5 s/.*/client.placeholder      \#000000 \#0c0c0c \#ffffff \#000000 \#0c0c0c/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN6 s/.*/client.background               \#ffffff/" "$WINDOW_CONFIG"
        ;;
    "monochromic")
        # Set window decoration
        sed -i "$COL_WIN1 s/.*/client.focused          \$c5     \$c5     \$c15    \$c13    \$c5/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN2 s/.*/client.focused_inactive \$c1     \$c1     \$c7     \$c9     \$c1/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN3 s/.*/client.unfocused        \$c1     \$c1     \$c7     \$c1     \$c1/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN4 s/.*/client.urgent           \$c0     \$c15    \$c0     \$c15    \$c15/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN5 s/.*/client.placeholder      \$c1     \$c1     \$c15    \$c9     \$c1/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN6 s/.*/client.background               \$transp/" "$WINDOW_CONFIG"
        ;;
    "dirchromatic")
        # Set window decoration
        sed -i "$COL_WIN1 s/.*/client.focused          \$c13    \$c5     \$c15    \$c11    \$c13/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN2 s/.*/client.focused_inactive \$c9     \$c1     \$c7     \$c10    \$c9/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN3 s/.*/client.unfocused        \$c1     \$c1     \$c7     \$c12    \$c1/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN4 s/.*/client.urgent           \$c0     \$c15    \$c0     \$c15    \$c0/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN5 s/.*/client.placeholder      \$c1     \$c1     \$c15    \$c14    \$c1/" "$WINDOW_CONFIG"
        sed -i "$COL_WIN6 s/.*/client.background               \$transp/" "$WINDOW_CONFIG"
        ;;
esac

i3-msg reload
