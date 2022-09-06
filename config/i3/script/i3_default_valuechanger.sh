#!/usr/bin/env bash

# Input variable and constant
CHANGE_ITEM=$1
NEW_DEFAULT_VALUE=$2
I3_CONFIG_FILE="$HOME/.config/i3/config"
PICOM_DIR="$HOME/.config/picom"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"
CONKY_DIR="$HOME/.config/conky"

# Default gap, border width column number in i3 configuration
COL_OUTER_GAP_WIDTH=$(awk '$0~/default_outer_gap/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_INNER_GAP_WIDTH=$(awk '$0~/default_inner_gap/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_BORDER_WIDTH=$(awk '$0~/default_border_width/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_TITLEBAR_STYLE=$(awk '$0~/default_titlebar_style/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_FLOATING_TITLEBAR_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_TITLEBAR_FONTSIZE=$(awk '$0~/default_titlebar_fontsize/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')
COL_I3BAR_FONTSIZE=$(awk '$0~/default_i3bar_fontsize/ {print NR}' $HOME/.config/i3/config | awk 'NR==1')

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
        sed -i "$COL_BORDER_WIDTH s/.*/set \$default_border_width $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "titlebar_style")
        sed -i "$COL_TITLEBAR_STYLE s/.*/set \$default_titlebar_style $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "floating_titlebar_style")
        sed -i "$COL_FLOATING_TITLEBAR_STYLE s/.*/set \$default_floating_titlebar_style $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "titlebar_fontsize")
        sed -i "$COL_TITLEBAR_FONTSIZE s/.*/set \$default_titlebar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_fontsize")
        sed -i "$COL_I3BAR_FONTSIZE s/.*/set \$default_i3bar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "picom")
        rm "$HOME/.config/picom/picom.conf"
        ln -s "$PICOM_DIR/picom_$NEW_DEFAULT_VALUE.conf" "$PICOM_DIR/picom.conf"
        i3-msg reload
        ;;
    "flashfocus")
        rm "$HOME/.config/flashfocus/flashfocus.yml"
        ln -s "$FLASHFOCUS_DIR/flashfocus_$NEW_DEFAULT_VALUE.yml" "$FLASHFOCUS_DIR/flashfocus.yml"
        killall flashfocus
        i3-msg exec flashfocus
        ;;
    "conky")
        rm "$CONKY_DIR/conky_config_bindkey"
        rm "$CONKY_DIR/conky_config_system"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_bindkey" "$CONKY_DIR/conky_config_bindkey"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_system" "$CONKY_DIR/conky_config_system"
        killall conky
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        ;;
    *)
        echo ""
        echo "Wrong input [Available option: outer_gap/inner_gap/border_width/titlebar_style/floating_titlebar_style/titlebar_fontsize/i3bar_fontsize/picom/flashfocus/conky]"
        echo ""
        ;;
esac
