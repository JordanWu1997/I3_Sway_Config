#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_kdeconnect_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable_pointer]: enable pointer daemon"
    echo "  [disable_pointer]: disable pointer daemon"
    echo "  [reload_pointer]: reload pointer daemon"
    echo "  [pointer_invert_on]: invert pointer color"
    echo "  [pointer_invert_off]: restore pointer color"
}

kdeconnect_operation () {
    ICON="$HOME/.config/i3/share/64x64/cursor.png"
    case $1 in
        "enable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is enabled" --icon=${ICON}
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        "disable_pointer")
            notify-send -u "low" "i3 kdeconnect" "Pointer daemon is disabled" --icon=${ICON}
            ps -aux | grep "python3 ${I3_SCRIPT}/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            ;;
        "reload_pointer")
            notify-send -u "low" "i3 kdeconnect" "Reload pointer daemon" --icon=${ICON}
            ps -aux | grep "python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py" | \
                awk 'NR==1 {print $2}' | xargs -I {} kill {}
            python3 $I3_SCRIPT/i3_kdeconnect_pointer_daemon.py
            ;;
        "pointer_invert_on")
            CONFIGS=( \
                "$HOME/.config/picom/picom.conf" \
                "$HOME/.config/picom/picom_transparency.conf" \
                "$HOME/.config/picom/picom_blur.conf" \
            )
            for CONFIG in ${CONFIGS[@]}; do
                COL_INVERT=$(awk '$0~/invert-color-include/ {print NR}' ${CONFIG} | awk 'NR==1')
                sed -i "$(( ${COL_INVERT} + 1 )) s/.*/  \"class_g \= \'kdeconnect.daemon\'\"/" "${CONFIG}"
            done
            ;;
        "pointer_invert_off")
            #CONFIG="$HOME/.config/picom/picom.conf"
            CONFIGS=( \
                "$HOME/.config/picom/picom.conf" \
                "$HOME/.config/picom/picom_transparency.conf" \
                "$HOME/.config/picom/picom_blur.conf" \
            )
            for CONFIG in ${CONFIGS[@]}; do
                COL_INVERT=$(awk '$0~/invert-color-include/ {print NR}' ${CONFIG} | awk 'NR==1')
                sed -i "$(( ${COL_INVERT} + 1 )) s/.*/  \#\"class_g \= \'kdeconnect.daemon\'\"/" "${CONFIG}"
            done
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
kdeconnect_operation $1
