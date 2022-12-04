#!/usr/bin/env bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_picom_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [default]: start picom with default picom configuration"
    echo "  [blur]: start picom with blur configuration"
    echo "  [transparency]: start picom with transparency configuration"
}

picom_operation () {
    case $1 in
        "default")
            killall picom
            i3-msg exec "picom"
            ;;
        "blur")
            killall picom
            i3-msg exec "picom --config $HOME/.config/picom/picom_blur.conf"
            ;;
        "transparency")
            killall picom
            i3-msg exec "picom --config $HOME/.config/picom/picom_transparency.conf"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
picom_operation $1
