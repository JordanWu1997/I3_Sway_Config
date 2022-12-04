#!/usr/bin/env bash

# Input variable and constant
CHANGE_ITEM=$1
NEW_DEFAULT_VALUE=$2

# Configuration files
I3_CONFIG_FILE="$HOME/.config/i3/config"
PICOM_DIR="$HOME/.config/picom"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"
CONKY_DIR="$HOME/.config/conky"
DUNST_DIR="$HOME/.config/dunst"

# Default value
DEFAULT_FONT=$(awk '$0~/default_font/' $I3_CONFIG_FILE | awk 'NR==1' | cut -d' ' -f3-)

# Column number of default value in $I3_CONFIG_FILE
COL_OUTER_GAP_WIDTH=$(awk '$0~/default_outer_gap/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_INNER_GAP_WIDTH=$(awk '$0~/default_inner_gap/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_BORDER_WIDTH=$(awk '$0~/default_border_width/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_TITLEBAR_STYLE=$(awk '$0~/default_titlebar_style/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_FLOATING_TITLEBAR_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_TITLEBAR_FONTSIZE=$(awk '$0~/default_titlebar_fontsize/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_I3BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_I3BAR_FONTSIZE=$(awk '$0~/default_i3bar_fontsize/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_I3BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_I3BAR_POS=$(awk '$0~/default_i3bar_position/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
COL_DUNST_POS=$(awk '$0~/origin/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
COL_DUNST_OFFSET=$(awk '$0~/offset/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
COL_DUNST_ALIGN=$(awk '$0~/alignment/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
COL_DUNST_FONT=$(awk '$0~/font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
COL_DUNST_ICON_POS=$(awk '$0~/icon_position/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
        echo "Usage:"
        echo "  i3_default_valuechanger [options] [new_value]"
        echo ""
        echo "OPTION: NEW_VALUE (TYPE or valiable options)"
        echo "  [border_width]: INTEGER"
        echo "  [outer_gap]: INTEGER"
        echo "  [inner_gap]: INTEGER"
        echo "  [titlebar_style]: pixel, normal"
        echo "  [floating_titlebar_style]: pixel, normal"
        echo "  [titlebar_fontsize]: INTEGER"
        echo "  [i3bar_height]: INTEGER"
        echo "  [i3bar_fontsize]: INTEGER"
        echo "  [i3bar_mode]: hide, dock"
        echo "  [i3bar_position]: top, bottom"
        echo "  [dunst_position]: top-left, top-center, top-right"
        echo "                    left-center, center, right-center"
        echo "                    bottom-left, bottom-center, bottom-right"
        echo "  [dunst_offset]: INTEGER"
        echo "  [dunst_alignment]: left, center, right"
        echo "  [dunst_fontsize]: INTEGER"
        echo "  [dunst_icon_position]: left, top, right, off"
        echo "  [picom]: blur, transparency"
        echo "  [flashfocus]: transparency, crystal, intermediate, blur, opaque"
        echo "  [conky_style]: full, light, minimal"
}

# Set new default value in i3 configuration file
case $CHANGE_ITEM in
    "outer_gap")
        sed -i "$COL_OUTER_GAP_WIDTH s/.*/set \$default_outer_gap $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "inner_gap")
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
    "i3bar_height")
        sed -i "$COL_I3BAR_HEIGHT s/.*/set \$default_i3bar_height $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_fontsize")
        sed -i "$COL_I3BAR_FONTSIZE s/.*/set \$default_i3bar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_mode")
        sed -i "$COL_I3BAR_MODE s/.*/set \$default_i3bar_mode $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_position")
        sed -i "$COL_I3BAR_POS s/.*/set \$default_i3bar_position $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
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
    "conky_style")
        rm "$CONKY_DIR/conky_config_bindkey"
        rm "$CONKY_DIR/conky_config_system"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_bindkey" "$CONKY_DIR/conky_config_bindkey"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_system" "$CONKY_DIR/conky_config_system"
        killall conky
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_bindkey'
        i3-msg 'exec --no-startup-id conky -c ~/.config/conky/conky_config_system'
        ;;
    "dunst_position")
        sed -i "$COL_DUNST_POS s/.*/    origin = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_walcolor.sh reload
        ;;
    "dunst_offset")
        sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${NEW_DEFAULT_VALUE}x${NEW_DEFAULT_VALUE}/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_walcolor.sh reload
        ;;
    "dunst_alignment")
        sed -i "$COL_DUNST_ALIGN s/.*/    alignment = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_walcolor.sh reload
        ;;
    "dunst_fontsize")
        sed -i "$COL_DUNST_FONT s/.*/    font = \"$DEFAULT_FONT $NEW_DEFAULT_VALUE\"/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_walcolor.sh reload
        ;;
    "dunst_icon_position")
        sed -i "$COL_DUNST_ICON_POS s/.*/    icon_position = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_walcolor.sh reload
        ;;
    *)
        show_wrong_usage_message
        echo
        show_help_message
        exit
        ;;
esac
