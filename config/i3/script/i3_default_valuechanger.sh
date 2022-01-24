#!/usr/bin/env bash

# Input variable and constant
CHANGE_ITEM=$1
NEW_DEFAULT_VALUE=$2
I3_CONFIG_FILE="$HOME/.config/i3/config"
PICOM_DIR="$HOME/.config/picom"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"

# Default gap, border width column number in i3 configuration
COL_OUTER_GAP_WIDTH=$(awk '$0~/default_outer_gap/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_INNER_GAP_WIDTH=$(awk '$0~/default_inner_gap/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_BORDER_WIDTH=$(awk '$0~/default_border_width/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_TITLEBAR_FONTSIZE=$(awk '$0~/default_titlebar_fontsize/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')

# Set new default value in i3 configuration file
case $CHANGE_ITEM in
    "outer_gap")
        echo $NEW_DEFAULT_VALUE
        echo $COL_OUTER_GAP_WIDTH
        sed -i "$COL_OUTER_GAP_WIDTH s/.*/set \$default_outer_gap $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "inner_gap")
        echo $NEW_DEFAULT_VALUE
        echo $COL_INNER_GAP_WIDTH
        sed -i "$COL_INNER_GAP_WIDTH s/.*/set \$default_inner_gap $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "border_width")
        if [ $NEW_DEFAULT_VALUE == "normal" ]; then
            sed -i "$COL_BORDER_WIDTH s/.*/set \$default_border_width normal/" $I3_CONFIG_FILE
        else
            sed -i "$COL_BORDER_WIDTH s/.*/set \$default_border_width pixel $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        fi
        i3-msg reload
        ;;
    "titlebar_fontsize")
        sed -i "$COL_TITLEBAR_FONTSIZE s/.*/set \$default_titlebar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "picom")
        rm "$HOME/.config/picom/picom.conf"
        ln -s "$HOME/.config/picom/picom_$NEW_DEFAULT_VALUE.conf" "$HOME/.config/picom/picom.conf"
        i3-msg reload
        ;;
    "flashfocus")
        rm "$HOME/.config/flashfocus/flashfocus.yml"
        ln -s "$HOME/.config/flashfocus/flashfocus_$NEW_DEFAULT_VALUE.yml" "$HOME/.config/flashfocus/flashfocus.yml"
        killall flashfocus
        i3-msg exec flashfocus
        ;;
    *)
        echo ""
        echo "Wrong input [Available option: outer_gap/inner_gap/border_width/titlebar_fontsize/picom/flashfocus]"
        echo ""
        ;;
esac
