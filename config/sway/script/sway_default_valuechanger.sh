#!/usr/bin/env bash
# Ported from i3_default_valuechanger.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config                     -> ~/.config/sway/config
#   ~/.config/i3/config.d/i3_startup.config -> ~/.config/sway/config.d/sway_startup.config
#   i3-msg reload                           -> swaymsg reload
#   i3-msg exec --no-startup-id ...         -> swaymsg exec ...
#   i3_flashfocus_operator.sh / i3_toolkit_operator.sh startup lines
#                                           -> sway_flashfocus_operator.sh / sway_toolkit_operator.sh
#   i3_dunst_operator.sh reload             -> sway_dunst_operator.sh reload
#   picom: the ~/.config/picom/picom.conf link is still switched (sway_opacity_operator.sh
#          reads it to pick its default mode); `swaymsg reload` re-runs its exec_always.
# `set $default_* <value>` lines are located by exact variable name instead of the
# first line merely containing the name. Edits of kitty/rofi/dunst/conky/flashfocus
# configs are unchanged from the i3 version.

SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"

# Input variable and constant
CHANGE_ITEM=$1

# Configuration files
SWAY_CONFIG_FILE="$HOME/.config/sway/config"
SWAY_STARTUP_CONFIG_FILE="$HOME/.config/sway/config.d/sway_startup.config"
KITTY_CONFIG_FILE="$HOME/.config/kitty/kitty_common.conf"
PICOM_DIR="$HOME/.config/picom"
FLASHFOCUS_DIR="$HOME/.config/flashfocus"
CONKY_DIR="$HOME/.config/conky"
DUNST_DIR="$HOME/.config/dunst"
ROFI_DIR="$HOME/.config/rofi"

# Dunst operator (prefer the sway port)
if [[ -x "$SWAY_SCRIPT/sway_dunst_operator.sh" ]]; then
    DUNST_OPERATOR="$SWAY_SCRIPT/sway_dunst_operator.sh"
else
    DUNST_OPERATOR="$I3_SCRIPT/i3_dunst_operator.sh"
fi

# Replace the first `set $<name> ...` line of the sway config with `set $<name> <value>`
set_sway_variable () {
    local name=$1 value=$2 tmp
    if ! awk -v name="$name" '$1 == "set" && $2 == "$" name {found = 1; exit} END {exit !found}' "$SWAY_CONFIG_FILE"; then
        notify-send -u critical "Sway Default Value Changer" "No 'set \$$name' line in $SWAY_CONFIG_FILE"
        return 1
    fi
    tmp=$(mktemp) || return 1
    awk -v name="$name" -v value="$value" '
        !done && $1 == "set" && $2 == "$" name { print "set $" name " " value; done = 1; next }
        { print }
    ' "$SWAY_CONFIG_FILE" > "$tmp" && cat "$tmp" > "$SWAY_CONFIG_FILE"
    rm -f -- "$tmp"
}

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
        echo "Usage:"
        echo "  sway_default_valuechanger.sh [options] [new_value]"
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
        echo "  [flashfocus_startup]: enable flashfocus at startup or not"
        echo "  [caffeine_startup]: enable caffeine at startup or not"
        echo "  [conky_style]: full, light, minimal"
        echo "  [conky_startup]: enable, disable"
        echo "  [conky_system_position]: top_left, top_right"
        echo "  [conky_bindkey_position]: bottom_left, bottom_right"
        echo "  [kitty_font]: ANYTHING, just select font on pop-up rofi menu"
        echo "  [kitty_fontsize] INTEGER"
        echo "  [rofi_font]: ANYTHING, just select font on pop-up rofi menu"
        echo "  [rofi_fontsize] INTEGER"
        echo "  [all_font]: ANYTHIN, just select font on pop-up rofi menu"
}

# Input new default value
if [[ $2 == 'input' ]]; then
    NEW_DEFAULT_VALUE=$(rofi -dmenu -i -p "Set $1 to")
    # Avoid empty input
    if [ -z "${NEW_DEFAULT_VALUE}" ]; then
        exit
    fi
else
    NEW_DEFAULT_VALUE=$2
fi

# Set new default value in sway configuration file
case $CHANGE_ITEM in
    "i3_default_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'i3 Default Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n $FONT ]]; then
            set_sway_variable default_font "$FONT"
        fi
        swaymsg reload
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
        set_sway_variable default_outer_gap "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "inner_gap")
        set_sway_variable default_inner_gap "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "border_width")
        set_sway_variable default_border_width "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "titlebar_style")
        set_sway_variable default_titlebar_style "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "floating_titlebar_style")
        set_sway_variable default_floating_titlebar_style "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "titlebar_fontsize")
        set_sway_variable default_titlebar_fontsize "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "i3bar_height")
        set_sway_variable default_i3bar_height "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "i3bar_fontsize")
        set_sway_variable default_i3bar_fontsize "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "i3bar_mode")
        set_sway_variable default_i3bar_mode "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "i3bar_position")
        set_sway_variable default_i3bar_position "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "picom")
        # -f replaces the link in one step (also works when it is missing)
        # sway has no picom: the link only records the default mode
        # (transparency|blur) read by sway_opacity_operator.sh.
        ln -sfn "$PICOM_DIR/picom_$NEW_DEFAULT_VALUE.conf" "$PICOM_DIR/picom.conf"
        swaymsg reload
        ;;
    "flashfocus")
        # -f replaces the link in one step (also works when it is missing)
        ln -sfn "$FLASHFOCUS_DIR/flashfocus_$NEW_DEFAULT_VALUE.yml" "$FLASHFOCUS_DIR/flashfocus.yml"
        swaymsg exec "$SWAY_SCRIPT/sway_flashfocus_operator.sh restart"
        ;;
    "flashfocus_startup")
        echo $NEW_DEFAULT_VALUE
        if [[ $NEW_DEFAULT_VALUE == "enable" ]]; then
            sed -i 's/^#\(exec .*sway_flashfocus_operator\.sh start\)/\1/' "$SWAY_STARTUP_CONFIG_FILE"
        elif [[ $NEW_DEFAULT_VALUE == "disable" ]]; then
            sed -i 's/^exec .*sway_flashfocus_operator\.sh start/#&/' "$SWAY_STARTUP_CONFIG_FILE"
        else
            echo Unknown option for flashfocus_startup
        fi
        ;;
    "caffeine_startup")
        echo "$NEW_DEFAULT_VALUE"
        if [[ $NEW_DEFAULT_VALUE == "enable" ]]; then
            # Uncomment (if commented) and set argument to enable_caffeine
            sed -i 's/^\(#\?\)\(exec .*sway_toolkit_operator\.sh \)\(enable\|disable\)_caffeine.*/\2enable_caffeine/' "$SWAY_STARTUP_CONFIG_FILE"
        elif [[ $NEW_DEFAULT_VALUE == "disable" ]]; then
            # Uncomment (if commented) and set argument to disable_caffeine
            sed -i 's/^\(#\?\)\(exec .*sway_toolkit_operator\.sh \)\(enable\|disable\)_caffeine.*/\2disable_caffeine/' "$SWAY_STARTUP_CONFIG_FILE"
        else
            echo "Unknown option for caffeine_startup: $NEW_DEFAULT_VALUE"
        fi
        ;;
    "conky_style")
        rm "$CONKY_DIR/conky_config_bindkey"
        rm "$CONKY_DIR/conky_config_system"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_bindkey" "$CONKY_DIR/conky_config_bindkey"
        ln -s "$CONKY_DIR/$NEW_DEFAULT_VALUE/conky_config_system" "$CONKY_DIR/conky_config_system"
        killall conky
        # Relaunch through the wrapper: it builds the Wayland copy (out_to_wayland) of each config
        "$SWAY_SCRIPT/sway_conky_monitor_display.sh" bindkey_on
        "$SWAY_SCRIPT/sway_conky_monitor_display.sh" system_on
        ;;
    "conky_startup")
        set_sway_variable default_conky_startup "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "conky_system_position")
        set_sway_variable default_conky_system_alignment "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "conky_bindkey_position")
        set_sway_variable default_conky_bindkey_alignment "$NEW_DEFAULT_VALUE" &&
            swaymsg reload
        ;;
    "dunst_position")
        COL_DUNST_POS=$(awk '$0~/ origin/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_POS s/.*/    origin = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "dunst_xoffset")
        COL_DUNST_OFFSET=$(awk '$0~/ offset/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        DEFAULT_DUNST_XOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f1)
        DEFAULT_DUNST_YOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f2)
        sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${NEW_DEFAULT_VALUE}x${DEFAULT_DUNST_YOFFSET}/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "dunst_yoffset")
        COL_DUNST_OFFSET=$(awk '$0~/ offset/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        DEFAULT_DUNST_XOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f1)
        DEFAULT_DUNST_YOFFSET=$(awk '$0~/offset =/{print $3}' $DUNST_DIR/dunstrc | cut -dx -f2)
        sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${DEFAULT_DUNST_XOFFSET}x${NEW_DEFAULT_VALUE}/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "dunst_alignment")
        COL_DUNST_ALIGN=$(awk '$0~/ alignment = / {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_ALIGN s/.*/    alignment = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "dunst_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | rofi -dmenu -i -p 'Dunst Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n ${FONT} ]]; then
            COL_DUNST_FONT=$(awk '$0~/ font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
            FONTSIZE=$(grep -m 1 -w ' font =' $DUNST_DIR/dunstrc | cut -d: -f2- | cut -d \" -f2 | rev | cut -d' ' -f1 | rev)
            sed -i "$COL_DUNST_FONT s/.*/    font = \"$NEW_DEFAULT_VALUE $FONTSIZE\"/" $DUNST_DIR/dunstrc
            "$DUNST_OPERATOR" reload
        fi
        ;;
    "dunst_fontsize")
        COL_DUNST_FONT=$(awk '$0~/ font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        FONT=$(grep -m 1 -w ' font =' $DUNST_DIR/dunstrc | cut -d: -f2- | cut -d \" -f2 | rev | cut -d' ' -f2- | rev)
        sed -i "$COL_DUNST_FONT s/.*/    font = \"$FONT $NEW_DEFAULT_VALUE\"/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "dunst_icon_position")
        COL_DUNST_ICON_POS=$(awk '$0~/ icon_position/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
        sed -i "$COL_DUNST_ICON_POS s/.*/    icon_position = $NEW_DEFAULT_VALUE/" $DUNST_DIR/dunstrc
        "$DUNST_OPERATOR" reload
        ;;
    "all_font")
        FONT=$(fc-list | cut -d':' -f2 | cut -d',' -f1 | sort -u | cut -c 2- | rofi -dmenu -i -p 'i3 Default Font')
        NEW_DEFAULT_VALUE=$FONT
        if [[ -n $FONT ]]; then
            # Sway
            set_sway_variable default_font "$FONT"
            swaymsg reload
            # Kitty
            COL=$(grep -n -m 1 -w '^font_family' $KITTY_CONFIG_FILE | cut -d: -f1)
            sed -i "$COL s/.*/font_family $FONT/" $KITTY_CONFIG_FILE
            # Dunst
            COL_DUNST_FONT=$(awk '$0~/ font/ {print NR}' $DUNST_DIR/dunstrc | awk 'NR==1')
            FONTSIZE=$(grep -m 1 -w ' font =' $DUNST_DIR/dunstrc | cut -d: -f2- | cut -d \" -f2 | rev | cut -d' ' -f1 | rev)
            sed -i "$COL_DUNST_FONT s/.*/    font = \"$NEW_DEFAULT_VALUE $FONTSIZE\"/" $DUNST_DIR/dunstrc
            "$DUNST_OPERATOR" reload
            # Rofi
            for ROFI_FILE in $ROFI_DIR/*.rasi; do
                COL=$(grep -n -m 1 -w ' font: ' $ROFI_FILE | cut -d: -f1)
                # Get fontsize
                FONTSIZE=$(grep -m 1 -w ' font' $ROFI_FILE | cut -d: -f2- | cut -d\; -f1 |cut -d \" -f2 | rev | cut -d' ' -f1 | rev)
                sed -i "$COL s/.*/    font: \"$NEW_DEFAULT_VALUE $FONTSIZE\";/" $ROFI_FILE
            done
        fi
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
notify-send -u low "Sway Default Value Changer" "Default $1 is set to $NEW_DEFAULT_VALUE" --icon="${ICON}"
