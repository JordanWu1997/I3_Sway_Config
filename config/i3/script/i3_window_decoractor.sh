#!/usr/bin/env bash

WINDOW_CONFIG="$HOME/.config/i3/configs/i3_window.config"
COL_WIN1=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 2)
COL_WIN2=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 3)
COL_WIN3=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 4)
COL_WIN4=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 5)
COL_WIN5=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 6)
COL_WIN6=$(expr $(awk '$0~/Color Palette/{print NR}' $WINDOW_CONFIG) + 7)

window_decoraction () {
    case $1 in
        "default")
            # Set window decoration
            sed -i "$COL_WIN1 s/.*/client.focused          \#4C7899 \#285577 \#FFFFFF \#2E9EF4 \#285577/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN2 s/.*/client.focused_inactive \#333333 \#5F676A \#FFFFFF \#484E50 \#5F676A/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN3 s/.*/client.unfocused        \#333333 \#222222 \#888888 \#292D2E \#222222/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN4 s/.*/client.urgent           \#2F343A \#900000 \#FFFFFF \#900000 \#900000/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN5 s/.*/client.placeholder      \#000000 \#0C0C0C \#FFFFFF \#000000 \#0C0C0C/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN6 s/.*/client.background               \#ffffff/" "$WINDOW_CONFIG"
            ;;
        "dracula")
            # Dracula theme [https://draculatheme.com/]
            sed -i "$COL_WIN1 s/.*/client.focused          \#6272A4 \#6272A4 \#F8F8F2 \#6272A4 \#6272A4/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN2 s/.*/client.focused_inactive \#44475A \#44475A \#F8F8F2 \#44475A \#44475A/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN3 s/.*/client.unfocused        \#282A36 \#282A36 \#BFBFBF \#282A36 \#282A36/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN4 s/.*/client.urgent           \#44475A \#FF5555 \#F8F8F2 \#FF5555 \#FF5555/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN5 s/.*/client.placeholder      \#282A36 \#282A36 \#F8F8F2 \#282A36 \#282A36/" "$WINDOW_CONFIG"
            sed -i "$COL_WIN6 s/.*/client.background               \#F8F8F2/" "$WINDOW_CONFIG"
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
}

# Main
window_decoraction $1
i3-msg reload
