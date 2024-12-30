#!/usr/bin/env bash

STARTUP_CONFIG="$HOME/.config/i3/config.d/i3_startup.config"
WINDOW_CONFIG="$HOME/.config/i3/config.d/i3_window.config"
BINDKEY_CONFIG="$HOME/.config/i3/config.d/i3_bindkey.config"
CUSTOM_CONFIG="$HOME/.config/i3/config.d/i3_custom.config"
MODE_CONFIG="$HOME/.config/i3/config.d/i3_mode.config"
COL_UNCLUTTER=$(awk '$0~/exec --no-startup-id unclutter/ {print NR}' ${STARTUP_CONFIG})
COL_FOCUS=$(awk '$0~/focus_follows_mouse/ {print NR}' ${WINDOW_CONFIG})
COL_WARP=$(awk '$0~/mouse_warping/ {print NR}' ${WINDOW_CONFIG})
UNCLUTTER_OPTION="--start-hidden"
TIMEOUT=3 # Unit: second
ICON="$HOME/.config/i3/share/64x64/cursor.png"

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  i3_cursor_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_unclutter]: enable unclutter (cursor auto-hiding)"
    echo "  [disable_unclutter]: disable unclutter"
    echo "  [set_unclutter_as_default]: enable unclutter as default"
    echo "  [set_no_unclutter_as_default]: disable unclutter as default"
    echo "  [enable_focus_follows_mouse]: set i3wm focus_follows_mouse to yes"
    echo "  [disable_focus_follows_mouse]: set i3wm focus_follows_mouse to no"
    echo "  [move_cursor_inside_window]: move cursor to inside focus window"
}

move_cursor_inside_window () {
    # Source Code: https://github.com/i3/i3/issues/2971
    WINDOW=$(xdotool getwindowfocus)
    # This brings in variables WIDTH and HEIGHT
    eval `xdotool getwindowgeometry --shell $WINDOW`
    CENTER_X=`expr $WIDTH / 2`
    CENTER_Y=`expr $HEIGHT / 2`
    BLOCK_W=`expr $WIDTH / 3`
    BLOCK_H=`expr $HEIGHT / 3`
    case $1 in
        "1")
            TX=`expr $CENTER_X - $BLOCK_W`
            TY=`expr $CENTER_Y - $BLOCK_H`
            ;;
        "2")
            TX=$CENTER_X
            TY=`expr $CENTER_Y - $BLOCK_H`
            ;;
        "3")
            TX=`expr $CENTER_X + $BLOCK_W`
            TY=`expr $CENTER_Y - $BLOCK_H`
            ;;
        "4")
            TX=`expr $CENTER_X - $BLOCK_W`
            TY=$CENTER_Y
            ;;
        "5"|"")
            TX=$CENTER_X
            TY=$CENTER_Y
            ;;
        "6")
            TX=`expr $CENTER_X + $BLOCK_W`
            TY=$CENTER_Y
            ;;
        "7")
            TX=`expr $CENTER_X - $BLOCK_W`
            TY=`expr $CENTER_Y + $BLOCK_H`
            ;;
        "8")
            TX=$CENTER_X
            TY=`expr $CENTER_Y + $BLOCK_H`
            ;;
        "9")
            TX=`expr $CENTER_X + $BLOCK_W`
            TY=`expr $CENTER_Y + $BLOCK_H`
            ;;
        *)
            return
    esac
    xdotool mousemove -window $WINDOW $TX $TY
}

cursor_operation () {
    case $1 in
        "enable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (unclutter) is enabled" --icon=${ICON}
            unclutter --timeout ${TIMEOUT} ${UNCLUTTER_OPTION}
            ;;
        "disable_unclutter")
            notify-send -u low "Mouse Mode" "Cursor auto-hiding (unclutter) is disabled" --icon=${ICON}
            killall unclutter
            ;;
        "set_unclutter_as_default")
            sed -i "${COL_UNCLUTTER} s/.*/exec \-\-no\-startup\-id unclutter \-\-timeout ${TIMEOUT} ${UNCLUTTER_OPTION}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Mouse Mode" "Set cursor auto-hiding (unclutter) as default" --icon=${ICON}
            ;;
        "set_no_unclutter_as_default")
            sed -i "${COL_UNCLUTTER} s/.*/\#exec \-\-no\-startup\-id unclutter \-\-timeout ${TIMEOUT} ${UNCLUTTER_OPTION}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Mouse Mode" "Set no cursor auto-hiding (unclutter) as default" --icon=${ICON}
            ;;
        "enable_focus_follows_mouse")
            sed -i "${COL_FOCUS} s/.*/focus_follows_mouse yes/" ${WINDOW_CONFIG}
            sed -i "${COL_WARP} s/.*/mouse_warping output/" ${WINDOW_CONFIG}
            for CONFIG in "${BINDKEY_CONFIG}" "${CUSTOM_CONFIG}" "${MODE_CONFIG}"; do
                sed -i "s/Mod4+h focus left$/Mod4+h focus left, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window/" ${CONFIG}
                sed -i "s/Mod4+j focus down$/Mod4+j focus down, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window/" ${CONFIG}
                sed -i "s/Mod4+k focus up$/Mod4+k focus up, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window/" ${CONFIG}
                sed -i "s/Mod4+l focus right$/Mod4+l focus right, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window/" ${CONFIG}
            done
            i3-msg reload
            ;;
        "disable_focus_follows_mouse")
            sed -i "${COL_FOCUS} s/.*/focus_follows_mouse no/" ${WINDOW_CONFIG}
            sed -i "${COL_WARP} s/.*/mouse_warping none/" ${WINDOW_CONFIG}
            for CONFIG in "${BINDKEY_CONFIG}" "${CUSTOM_CONFIG}" "${MODE_CONFIG}"; do
                sed -i "s/Mod4+h focus left, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window$/Mod4+h focus left/" ${CONFIG}
                sed -i "s/Mod4+j focus down, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window$/Mod4+j focus down/" ${CONFIG}
                sed -i "s/Mod4+k focus up, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window$/Mod4+k focus up/" ${CONFIG}
                sed -i "s/Mod4+l focus right, exec \$I3_SCRIPT\/i3_cursor_operator.sh move_cursor_inside_window$/Mod4+l focus right/" ${CONFIG}
            done
            i3-msg reload
            ;;
        "move_cursor_inside_window")
            move_cursor_inside_window $2
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
cursor_operation "$@"
