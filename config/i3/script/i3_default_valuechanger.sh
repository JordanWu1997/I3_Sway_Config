#!/usr/bin/env bash

# Input variable and constant
CHANGE_ITEM=$1

# Configuration files
I3_CONFIG_FILE="$HOME/.config/i3/config"
KITTY_CONFIG_FILE="$HOME/.config/kitty/kitty_common.conf"
PICOM_DIR="$HOME/.config/picom"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"
CONKY_DIR="$HOME/.config/conky"
DUNST_DIR="$HOME/.config/dunst"
ROFI_DIR="$HOME/.config/rofi"

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
        echo "OPTION: NEW_VALUE (TYPE or valiable options, or use 'input' to input manually)"
        echo "  [i3_default_font]: ANYTHING, just select font on pop-up rofi menu"
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
        echo "  [dunst_xoffset]: INTEGER"
        echo "  [dunst_yoffset]: INTEGER"
        echo "  [dunst_alignment]: left, center, right"
        echo "  [dunst_font]: ANYTHING, just select font on pop-up rofi menu"
        echo "  [dunst_fontsize]: INTEGER"
        echo "  [dunst_icon_position]: left, top, right, off"
        echo "  [picom]: blur, transparency"
        echo "  [flashfocus]: transparency, crystal, intermediate, blur, opaque"
        echo "  [conky_style]: full, light, minimal"
        echo "  [conky_startup]: enable, disable"
        echo "  [conky_system_position]: top_left, top_right"
        echo "  [conky_bindkey_position]: bottom_left, bottom_right"
        echo "  [kitty_font]: ANYTHING, just select font on pop-up rofi menu"
        echo "  [kitty_fontsize] INTEGER"
        echo "  [rofi_font]: ANYTHING, just select font on pop-up rofi menu"
        echo "  [rofi_fontsize] INTEGER"
}

# Input new default value
if [[ $2 == 'input' ]]; then
    NEW_DEFAULT_VALUE=$(rofi -dmenu -i -p "Set $1 to")
    # Avoid empty input
    if [ -z ${NEW_DEFAULT_VALUE} ]; then
        exit
    fi
else
    NEW_DEFAULT_VALUE=$2
fi

# Set new default value in i3 configuration file
case $CHANGE_ITEM in
    "i3_default_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'i3 Default Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n $FONT ]]; then
            COL=$(grep -n -m 1 -w '^set $default_font' $I3_CONFIG_FILE | cut -d: -f1)
            sed -i "$COL s/.*/set \$default_font $FONT/" $I3_CONFIG_FILE
        fi
        i3-msg reload
        ;;
    "kitty_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'Kitty Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n ${FONT} ]]; then
            COL=$(grep -n -m 1 -w '^font_family' $KITTY_CONFIG_FILE | cut -d: -f1)
            sed -i "$COL s/.*/font_family $FONT/" $KITTY_CONFIG_FILE
        fi
        ;;
    "kitty_fontsize")
        COL=$(grep -n -m 1 -w '^font_size' $KITTY_CONFIG_FILE | cut -d: -f1)
        echo $COL
        sed -i "$COL s/.*/font_size $NEW_DEFAULT_VALUE/" $KITTY_CONFIG_FILE
        ;;
    "rofi_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'Rofi Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n ${FONT} ]]; then
            for ROFI_FILE in $ROFI_DIR/*.rasi; do
                COL=$(grep -n -m 1 -w ' font: ' $ROFI_FILE | cut -d: -f1)
                # Get fontsize
                FONTSIZE=$(grep -m 1 -w ' font' $ROFI_FILE | cut -d: -f2- | cut -d\; -f1 |cut -d \" -f2 | rev | cut -d' ' -f1 | rev)
                sed -i "$COL s/.*/    font: \"$NEW_DEFAULT_VALUE $FONTSIZE\";/" $ROFI_FILE
            done
        fi
        ;;
    "rofi_fontsize")
        for ROFI_FILE in $ROFI_DIR/*.rasi; do
            COL=$(grep -n -m 1 -w ' font: ' $ROFI_FILE | cut -d: -f1)
            # Get font
            FONT=$(grep -m 1 -w ' font' $ROFI_FILE | cut -d: -f2- | cut -d\; -f1 |cut -d \" -f2 | rev | cut -d' ' -f2- | rev)
            sed -i "$COL s/.*/    font: \"$FONT $NEW_DEFAULT_VALUE\";/" $ROFI_FILE
        done
        ;;
    "outer_gap")
        COL_OUTER_GAP_WIDTH=$(awk '$0~/default_outer_gap/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_OUTER_GAP_WIDTH s/.*/set \$default_outer_gap $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "inner_gap")
        COL_INNER_GAP_WIDTH=$(awk '$0~/default_inner_gap/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_INNER_GAP_WIDTH s/.*/set \$default_inner_gap $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "border_width")
        COL_BORDER_WIDTH=$(awk '$0~/default_border_width/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_BORDER_WIDTH s/.*/set \$default_border_width $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "titlebar_style")
        COL_TITLEBAR_STYLE=$(awk '$0~/default_titlebar_style/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_TITLEBAR_STYLE s/.*/set \$default_titlebar_style $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "floating_titlebar_style")
        COL_FLOATING_TITLEBAR_STYLE=$(awk '$0~/default_floating_titlebar_style/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_FLOATING_TITLEBAR_STYLE s/.*/set \$default_floating_titlebar_style $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "titlebar_fontsize")
        COL_TITLEBAR_FONTSIZE=$(awk '$0~/default_titlebar_fontsize/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_TITLEBAR_FONTSIZE s/.*/set \$default_titlebar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_height")
        COL_I3BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_I3BAR_HEIGHT s/.*/set \$default_i3bar_height $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_fontsize")
        COL_I3BAR_FONTSIZE=$(awk '$0~/default_i3bar_fontsize/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_I3BAR_FONTSIZE s/.*/set \$default_i3bar_fontsize $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_mode")
        COL_I3BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_I3BAR_MODE s/.*/set \$default_i3bar_mode $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "i3bar_position")
        COL_I3BAR_POS=$(awk '$0~/default_i3bar_position/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
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
    "conky_startup")
        COL_CONKY_STARTUP=$(awk '$0~/default_conky_startup/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_CONKY_STARTUP s/.*/set \$default_conky_startup $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "conky_system_position")
        COL_CONKY_SYSTEM_POS=$(awk '$0~/default_conky_system_alignment/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_CONKY_SYSTEM_POS s/.*/set \$default_conky_system_alignment $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "conky_bindkey_position")
        COL_CONKY_BINDKEY_POS=$(awk '$0~/default_conky_bindkey_alignment/ {print NR}' $I3_CONFIG_FILE | awk 'NR==1')
        sed -i "$COL_CONKY_BINDKEY_POS s/.*/set \$default_conky_bindkey_alignment $NEW_DEFAULT_VALUE/" $I3_CONFIG_FILE
        i3-msg reload
        ;;
    "dunst_position")
        COL_DUNST_POS=$(awk '$0~/ origin/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_POS s/.*/    origin = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    "dunst_xoffset")
        COL_DUNST_OFFSET=$(awk '$0~/ offset/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        DEFAULT_DUNST_XOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f1)
        DEFAULT_DUNST_YOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f2)
        sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${NEW_DEFAULT_VALUE}x${DEFAULT_DUNST_YOFFSET}/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    "dunst_yoffset")
        COL_DUNST_OFFSET=$(awk '$0~/ offset/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        DEFAULT_DUNST_XOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f1)
        DEFAULT_DUNST_YOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f2)
        sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${DEFAULT_DUNST_XOFFSET}x${NEW_DEFAULT_VALUE}/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    "dunst_alignment")
        COL_DUNST_ALIGN=$(awk '$0~/ alignment = / {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_ALIGN s/.*/    alignment = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    "dunst_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'Dunst Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n ${FONT} ]]; then
            COL_DUNST_FONT=$(awk '$0~/ font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
            FONTSIZE=$(grep -m 1 -w ' font =' $DUNST_DIR/dunstrc | cut -d: -f2- | cut -d \" -f2 | rev | cut -d' ' -f1 | rev)
            sed -i "$COL_DUNST_FONT s/.*/    font = \"$NEW_DEFAULT_VALUE $FONTSIZE\"/" $DUNST_DIR/dunstrc
            $I3_SCRIPT/i3_dunst_operator.sh reload
        fi
        ;;
    "dunst_fontsize")
        COL_DUNST_FONT=$(awk '$0~/ font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        FONT=$(grep -m 1 -w ' font =' $DUNST_DIR/dunstrc | cut -d: -f2- | cut -d \" -f2 | rev | cut -d' ' -f2- | rev)
        sed -i "$COL_DUNST_FONT s/.*/    font = \"$FONT $NEW_DEFAULT_VALUE\"/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    "dunst_icon_position")
        COL_DUNST_ICON_POS=$(awk '$0~/ icon_position/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_ICON_POS s/.*/    icon_position = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        $I3_SCRIPT/i3_dunst_operator.sh reload
        ;;
    *)
        show_wrong_usage_message
        echo
        show_help_message
        exit
        ;;
esac

# Send notification
ICON="$HOME/.config/i3/share/64x64/list.png"
notify-send -u low "i3 Default Value Changer" "Default $1 is set to $NEW_DEFAULT_VALUE" --icon="${ICON}"
