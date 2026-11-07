#!/usr/bin/env bash
# Ported from i3_autotiling_operator.sh for sway.
# Replaced i3-isms:
#   ~/.config/i3/config.d/i3_startup.config -> ~/.config/sway/config.d/sway_startup.config
#   startup line `exec_always --no-startup-id autotiling [--limit 2]`
#       -> `exec_always pgrep -u "$USER" -x autotiling >/dev/null || $SWAY_SCRIPT/sway_run.sh autotiling [--limit 2]`
# autotiling itself supports sway (i3ipc via SWAYSOCK), so runtime operations are unchanged.
# The default-setting operations rewrite the first (optionally commented) line
# matching ^#?exec_always .*autotiling and refuse to run if there is none
# (the i3 version rewrote every line of the file in that case).

STARTUP_CONFIG="$HOME/.config/sway/config.d/sway_startup.config"
COL_AUTOTILING=$(awk '/^#?exec_always .*autotiling/ {print NR; exit}' "${STARTUP_CONFIG}")
AUTOTILING_LINE='exec_always pgrep -u "$USER" -x autotiling >\/dev\/null || $SWAY_SCRIPT\/sway_run.sh autotiling'
ICON="$HOME/.config/i3/share/64x64/window.png"

show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

show_help_message () {
    echo "Usage:"
    echo "  sway_autotiling_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [disable_autotiling]: disable autotiling (dwindling / master-stack)"
    echo "  [enable_dwindling]: enable dwindling layout"
    echo "  [enable_master_stack]: enable master-stack layout (require autotiling > 1.8)"
    echo "  [set_dwindling_as_default]: set dwindling layout as default"
    echo "  [set_master_stack_as_default]: set master-stack layout as default"
    echo "  [set_no_autotiling_as_default]: do not set autotiling layout as default"
}

require_startup_line () {
    if [[ ! $COL_AUTOTILING =~ ^[0-9]+$ ]]; then
        notify-send -u critical "Sway Autotiling" "No autotiling exec_always line in ${STARTUP_CONFIG}" --icon="${ICON}"
        exit 1
    fi
}

autotiling_operation () {
    case $1 in
        "disable_autotiling")
            notify-send -u "low" "Sway Autotiling" "Sway Autotiling is disabled" --icon="${ICON}"
            killall autotiling
            ;;
        "enable_dwindling")
            killall autotiling
            notify-send -u "low" "Sway Autotiling" "Sway dwindling layout is enabled" --icon="${ICON}"
            "$(dirname "$0")/sway_run.sh" autotiling
            ;;
        "enable_master_stack")
            killall autotiling
            notify-send -u "low" "Sway Autotiling" "Sway master-stack layout is enabled" --icon="${ICON}"
            "$(dirname "$0")/sway_run.sh" autotiling --limit 2
            ;;
        "set_dwindling_as_default")
            require_startup_line
            sed -i "$COL_AUTOTILING s/.*/${AUTOTILING_LINE}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Sway Autotiling" "Set dwindling layout as default" --icon="${ICON}"
            ;;
        "set_master_stack_as_default")
            require_startup_line
            sed -i "$COL_AUTOTILING s/.*/${AUTOTILING_LINE} --limit 2/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Sway Autotiling" "Set master-stack layout as default" --icon="${ICON}"
            ;;
        "set_no_autotiling_as_default")
            require_startup_line
            sed -i "$COL_AUTOTILING s/.*/#${AUTOTILING_LINE}/" "${STARTUP_CONFIG}"
            notify-send -u "low" "Sway Autotiling" "Set no auto-tiling layout as default" --icon="${ICON}"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
autotiling_operation "$1"
