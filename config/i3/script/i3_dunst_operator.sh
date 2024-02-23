#!/usr/bin/env bash

DUNST_CONFIG="$HOME/.config/dunst/dunstrc"
I3_CONFIG="$HOME/.config/i3/config"
ICON="$HOME/.config/i3/share/notification.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_dunst_walcolor.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  [load_wal_color]: Load wal color to dunst"
    echo "  [load_i3_border_width]: Load border width to dunst"
    echo "  [load_offset]: Load x, y offset to dunst"
    echo "  [reload]: Reload dunst"
    echo "  [reload_all]: Load wal color and border width to dunst and reload dunst"
    echo "  [enable_dunst_logger]: Enable dunst logger"
    echo "  [disable_dunst_logger]: Disable dunst logger"
    echo "  [show_dunst_logger_status]: Show dunst logger status"
    echo "  [show_dunst_logger_history]: Show dunst logger history"
}

load_wal_border_width () {
    BORDER_WIDTH=$(awk '$0~/default_border_width/ {print $3}' $I3_CONFIG)
    FRAME_BORDER_WIDTH_COL=$(awk '$0~/frame_width =/ {print NR}' $DUNST_CONFIG)
    SEPARATOR_BORDER_WIDTH_COL=$(awk '$0~/separator_height =/ {print NR}' $DUNST_CONFIG)
    # Separator border width
    sed -i "$SEPARATOR_BORDER_WIDTH_COL s/.*/    separator_height \= $BORDER_WIDTH/" "$DUNST_CONFIG"
    # Frame border width
    sed -i "$FRAME_BORDER_WIDTH_COL s/.*/    frame_width \= $BORDER_WIDTH/" "$DUNST_CONFIG"
}

load_wal_color () {
    WAL_COLOR="$HOME/.cache/wal/colors"
    WAL_COLOR3="$(awk 'NR==4' $WAL_COLOR)"
    WAL_COLOR12="$(awk 'NR==13' $WAL_COLOR)"
    WAL_COLOR15="$(awk 'NR==16' $WAL_COLOR)"
    BG_COLOR_COL=$(awk '$0~/background/ {print NR}' $DUNST_CONFIG)
    FG_COLOR_COL=$(awk '$0~/foreground/ {print NR}' $DUNST_CONFIG)
    FRAME_COLOR_COL=$(awk '$0~/frame_color/ {print NR}' $DUNST_CONFIG)
    # Background: wal color3 (Yellow)
    for col in $BG_COLOR_COL; do
        sed -i "$col s/.*/    background \= \"$WAL_COLOR3\"/" "$DUNST_CONFIG"
    done
    # Foreground: wal color15 (White)
    for col in $FG_COLOR_COL; do
        sed -i "$col s/.*/    foreground \= \"$WAL_COLOR15\"/" "$DUNST_CONFIG"
    done
    # Frame: wal color12 (Magenta)
    for col in $FRAME_COLOR_COL; do
        sed -i "$col s/.*/    frame_color \= \"$WAL_COLOR12\"/" "$DUNST_CONFIG"
    done
}

load_offset_and_text_alignment () {
    DEFAULT_BAR_MODE=$(awk '$0~/default_i3bar_mode/ {print $3}' $I3_CONFIG | awk 'NR==1')
    DEFAULT_BAR_HEIGHT=$(awk '$0~/default_i3bar_height/ {print $3}' $I3_CONFIG | awk 'NR==1')
    DEFAULT_BAR_POS=$(awk '$0~/default_i3bar_position/ {print $3}' $I3_CONFIG | awk 'NR==1')
    DEFAULT_INNER_GAP=$(awk '$0~/default_inner_gap/ {print $3}' $I3_CONFIG | awk 'NR==1')
    DEFAULT_OUTER_GAP=$(awk '$0~/default_outer_gap/ {print $3}' $I3_CONFIG | awk 'NR==1')
    DEFAULT_DUNST_OFFSET=$(expr ${DEFAULT_INNER_GAP} + ${DEFAULT_OUTER_GAP} + 15)
    DUNST_POS=$(awk '$0~/origin/' $DUNST_CONFIG | cut -d= -f 2 | cut -c 2-)
    DUNST_POS_Y=$(echo $DUNST_POS | cut -d- -f1)
    DUNST_POS_X=$(echo $DUNST_POS | cut -d- -f2)
    # Dunst text alignment
    case ${DUNST_POS} in
        *-left)
            DUNST_ALIGN='left'
            ;;
        *-center)
            DUNST_ALIGN='center'
            ;;
        *-right)
            DUNST_ALIGN='right'
            ;;
        *)
            DUNST_ALIGN='left'
    esac
    # Dunst offset
    case ${DEFAULT_BAR_MODE}/${DEFAULT_BAR_POS}/${DUNST_POS} in
        dock/top/top-*|dock/bottom/bottom-*)
            DUNST_OFFSET_Y=$(expr ${DEFAULT_DUNST_OFFSET} + ${DEFAULT_BAR_HEIGHT})
            DUNST_OFFSET_X=${DEFAULT_DUNST_OFFSET}
            ;;
        *)
            DUNST_OFFSET_Y=${DEFAULT_DUNST_OFFSET}
            DUNST_OFFSET_X=${DEFAULT_DUNST_OFFSET}
    esac
    #
    COL_DUNST_OFFSET=$(awk '$0~/offset/ {print NR}' $DUNST_CONFIG | awk 'NR==1')
    COL_DUNST_ALIGN=$(awk '$0~/ alignment = / {print NR}' $DUNST_CONFIG | awk 'NR==1')
    sed -i "$COL_DUNST_OFFSET s/.*/    offset = ${DUNST_OFFSET_X}x${DUNST_OFFSET_Y}/" $DUNST_CONFIG
    sed -i "$COL_DUNST_ALIGN s/.*/    alignment = ${DUNST_ALIGN}/" $DUNST_CONFIG
}

reload_dunst () {
    # Reload dunst
    pidof dunst && killall dunst
    dunst > /dev/null 2>&1 &
    sleep 1
    notify-send -u low "Dunst" "Dunst is up and running" --icon=${ICON}
}

enable_dunst_logger () {
    i3-msg exec $I3_SCRIPT/i3_notify_logger.sh $HOME/.config/dunst/log.txt
}

disable_dunst_logger () {
    ps -aux | \
        grep "[bash] $HOME/.config/i3/script/i3_notify_logger.sh" | \
        awk '{print $2}' | \
        xargs -I {} kill {}
}

show_dunst_logger_status () {
    if ps -aux | grep "[bash] $HOME/.config/i3/script/i3_notify_logger.sh"; then
        notify-send "Dunst" "Dunst logger is running" --icon=${ICON}
    else
        notify-send "Dunst" "Dunst logger is NOT running" --icon=${ICON}
    fi
}

show_dunst_logger_history () {
    tac ~/.config/dunst/log.txt | \
        sed 's/^string /\n/' | \
        sed 's/,string/,/g' | \
        sed 's/", /"\n/g' | \
        sed 's/^---/\n---/' | \
        rofi -dmenu -config $HOME/.config/rofi/config_doublecol.rasi -p "Notification History" | \
        xargs -I {} notify-send -u low logger-history {} --icon=${ICON}
}

dunst_operation () {
    case $1 in
        "load_wal_color")
            load_wal_color
            ;;
        "load_i3_border_width")
            load_wal_border_width
            ;;
        "load_offset_and_text_alignment")
            load_offset_and_text_alignment
            ;;
        "reload")
            reload_dunst
            ;;
        "reload_all")
            load_wal_color
            load_wal_border_width
            load_offset_and_text_alignment
            reload_dunst
            ;;
        "enable_dunst_logger")
            disable_dunst_logger
            enable_dunst_logger
            ;;
        "disable_dunst_logger")
            disable_dunst_logger
            ;;
        "show_dunst_logger_status")
            show_dunst_logger_status
            ;;
        "show_dunst_logger_history")
            show_dunst_logger_history
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
dunst_operation $1
