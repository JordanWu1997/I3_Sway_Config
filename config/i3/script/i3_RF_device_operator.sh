#!/bin/bash

ICON="$HOME/.config/i3/share/wifi-connection.png"

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_RF_device_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [enable]: enable selected RF device"
    echo "  [disable]: disable selected RF device"
}

# Operation
RF_device_operation () {
    case $1 in
        'enable')
            RF_DEVICE=$(rfkill list | grep -v "blocked" | rofi -dmenu -p "Enable RF Device:")
            RF_ID=$(echo ${RF_DEVICE} | cut -d: -f1)
            RF_NAME=$(echo ${RF_DEVICE} | cut -d: -f2)
            RF_TYPE=$(echo ${RF_DEVICE} | cut -d: -f3)
            rfkill unblock ${RF_ID}
            notify-send -u low "${RF_TYPE} Device" "${RF_NAME} is enabled" --icon=${ICON}
            ;;
        'disable')
            RF_DEVICE=$(rfkill list | grep -v "blocked" | rofi -dmenu -p "Disable RF Device:")
            RF_ID=$(echo ${RF_DEVICE} | cut -d: -f1)
            RF_NAME=$(echo ${RF_DEVICE} | cut -d: -f2)
            RF_TYPE=$(echo ${RF_DEVICE} | cut -d: -f3)
            rfkill block ${RF_ID}
            notify-send -u low -a "${RF_TYPE} Device" "${RF_NAME} is disabled" --icon=${ICON}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
RF_device_operation $1
