#!/bin/bash

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
    echo "  [enable_RF_device]: enable selected RF device"
    echo "  [disable_RF_device]: disable selected RF device"
    echo "  [connect_bluetooth_device]: connect to bluetooth device"
    echo "  [disconnect_bluetooth_device]: disconnect from bluetooth device"
    echo "  [reconnect_bluetooth_device]: reconnect to bluetooth device"
    echo "  [enable_bluetooth_discoverability]: enable bluetooth discoverability"
    echo "  [disable_bluetooth_discoverability]: disable bluetooth discoverability"
}

# Operation
RF_device_operation () {
    ICON="$HOME/.config/i3/share/64x64/wifi-connection.png"
    case $1 in
        'enable_RF_device')
            RF_DEVICE=$(rfkill list | grep -v "blocked" | rofi -dmenu -i -p "Enable RF Device")
            RF_ID=$(echo ${RF_DEVICE} | cut -d: -f1)
            RF_NAME=$(echo ${RF_DEVICE} | cut -d: -f2)
            RF_TYPE=$(echo ${RF_DEVICE} | cut -d: -f3)
            if [[ -n ${RF_ID} ]]; then
                rfkill unblock ${RF_ID}
                notify-send -u low "${RF_TYPE} Device" "${RF_NAME} is enabled" --icon=${ICON}
            fi
            ;;
        'disable_RF_device')
            RF_DEVICE=$(rfkill list | grep -v "blocked" | rofi -dmenu -i -p "Disable RF Device")
            RF_ID=$(echo ${RF_DEVICE} | cut -d: -f1)
            RF_NAME=$(echo ${RF_DEVICE} | cut -d: -f2)
            RF_TYPE=$(echo ${RF_DEVICE} | cut -d: -f3)
            if [[ -n ${RF_ID} ]]; then
                rfkill block ${RF_ID}
                notify-send -u low -a "${RF_TYPE} Device" "${RF_NAME} is disabled" --icon=${ICON}
            fi
            ;;
        'connect_bluetooth_device')
            BT_DEVICE=$(bluetoothctl devices | rofi -dmenu -i -p "Connect to Bluetooth Device")
            BT_ADDR=$(echo ${BT_DEVICE} | cut -d' ' -f2)
            BT_NAME=$(echo ${BT_DEVICE} | cut -d' ' -f3-)
            if [[ -n ${BT_ADDR} ]]; then
                notify-send -u low -a "Bluetooth" "Connecting to ${BT_NAME}" --icon=${ICON}
                bluetoothctl connect ${BT_ADDR}
            fi
            ;;
        'disconnect_bluetooth_device')
            BT_DEVICE=$(bluetoothctl devices | rofi -dmenu -i -p "Disconnect from Bluetooth Device")
            BT_ADDR=$(echo ${BT_DEVICE} | cut -d' ' -f2)
            BT_NAME=$(echo ${BT_DEVICE} | cut -d' ' -f3-)
            if [[ -n ${BT_ADDR} ]]; then
                notify-send -u low -a "Bluetooth" "Disconnecting from ${BT_NAME}" --icon=${ICON}
                bluetoothctl disconnect ${BT_ADDR}
            fi
            ;;
        'reconnect_bluetooth_device')
            BT_DEVICE=$(bluetoothctl devices | rofi -dmenu -i -p "Reconnect to Bluetooth Device")
            BT_ADDR=$(echo ${BT_DEVICE} | cut -d' ' -f2)
            BT_NAME=$(echo ${BT_DEVICE} | cut -d' ' -f3-)
            if [[ -n ${BT_ADDR} ]]; then
                notify-send -u low -a "Bluetooth" "Disconnecting to ${BT_NAME} (try to reconnect after 3 secs)" --icon=${ICON}
                bluetoothctl disconnect ${BT_ADDR}
                sleep 1.5
                notify-send -u low -a "Bluetooth" "Reconnecting to ${BT_NAME}" --icon=${ICON}
                bluetoothctl connect ${BT_ADDR}
            fi
            ;;
        'enable_bluetooth_discoverability')
            notify-send -u low -a "Bluetooth" "Discoverable ON" --icon=${ICON}
            bluetoothctl discoverable on
            ;;
        'disable_bluetooth_discoverability')
            notify-send -u low -a "Bluetooth" "Discoverable OFF" --icon=${ICON}
            bluetoothctl discoverable off
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
