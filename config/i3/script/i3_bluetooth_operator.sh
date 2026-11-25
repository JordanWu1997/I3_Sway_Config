#!/usr/bin/env bash

ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
ICON="$HOME/.config/i3/share/64x64/wifi-connection.png"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -a Bluetooth -h string:x-dunst-stack-tag:bluetooth --icon="$ICON" 'Bluetooth' "$1"
    fi
    return 0
}

show_error() {
    local message=$1
    if command -v rofi >/dev/null 2>&1 && [[ -n ${DISPLAY:-} ]]; then
        rofi -e "$message" -config "$ROFI_CONFIG" >/dev/null 2>&1 || notify "$message"
    else
        notify "$message"
    fi
}

controller_property() {
    local property=$1
    bluetoothctl show 2>/dev/null |
        sed -n "s/^[[:space:]]*$property: //p" | head -n 1
}

device_rows() {
    local devices line address name info paired connected listed=0 checked=0
    devices=$(bluetoothctl devices 2>&1) || {
        printf 'Bluetooth device query failed: %s\n' "$devices" >&2
        return 1
    }
    while IFS= read -r line; do
        [[ $line =~ ^Device[[:space:]]+([[:xdigit:]:]{17})[[:space:]]+(.+)$ ]] || continue
        address=${BASH_REMATCH[1]}
        name=${BASH_REMATCH[2]}
        ((listed++))
        info=$(bluetoothctl info "$address" 2>/dev/null) || continue
        ((checked++))
        [[ $info =~ (^|[[:space:]])Paired:[[:space:]]yes ]] && paired=yes || paired=no
        [[ $info =~ (^|[[:space:]])Connected:[[:space:]]yes ]] && connected=yes || connected=no
        printf '%s\t%s\t%s\t%s\n' "$address" "$name" "$paired" "$connected"
    done <<< "$devices"
    if (( listed > 0 && checked == 0 )); then
        printf 'Bluetooth device details are unavailable\n' >&2
        return 1
    fi
}

choose_device() {
    local scope=$1 title=$2 data line address name paired connected selected error_file
    local -a rows=() addresses=() names=()
    error_file=$(mktemp) || return 1
    if ! data=$(device_rows 2>"$error_file"); then
        show_error "$(<"$error_file")"
        rm -f -- "$error_file"
        return 1
    fi
    rm -f -- "$error_file"
    while IFS=$'\t' read -r address name paired connected; do
        [[ -n $address ]] || continue
        if [[ $scope == connect ]]; then
            [[ $paired == yes && $connected == no ]] || continue
        else
            [[ $connected == yes ]] || continue
        fi
        rows+=("$name · $address")
        addresses+=("$address")
        names+=("$name")
    done <<< "$data"
    if (( ${#rows[@]} == 0 )); then
        if [[ $scope == connect ]]; then
            show_error 'No paired, disconnected Bluetooth devices. Pair a new one with [p] in Bluetooth mode.'
        else
            show_error 'No connected Bluetooth devices.'
        fi
        return 1
    fi
    selected=$(printf '%s\n' "${rows[@]}" |
        rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p "$title") || return 1
    [[ $selected =~ ^[0-9]+$ && $selected -lt ${#addresses[@]} ]] || return 1
    printf '%s\t%s\n' "${addresses[selected]}" "${names[selected]}"
}

is_connected() {
    bluetoothctl info "$1" 2>/dev/null | grep -q 'Connected: yes'
}

device_action() {
    local operation=$1 selection address name output
    case "$operation" in
        connect) selection=$(choose_device connect 'Connect paired device') || return 0 ;;
        disconnect) selection=$(choose_device disconnect 'Disconnect connected device') || return 0 ;;
        reconnect) selection=$(choose_device disconnect 'Reconnect connected device') || return 0 ;;
    esac
    IFS=$'\t' read -r address name <<< "$selection"
    if [[ $operation == reconnect ]]; then
        bluetoothctl disconnect "$address" >/dev/null 2>&1 || {
            notify "Could not disconnect $name"; return 1;
        }
        sleep 1
        operation=connect
    fi
    output=$(bluetoothctl "$operation" "$address" 2>&1)
    if [[ $operation == connect ]] && is_connected "$address"; then
        notify "Connected: $name"
    elif [[ $operation == disconnect ]] && ! is_connected "$address"; then
        notify "Disconnected: $name"
    else
        notify "Could not $operation $name: $output"
        return 1
    fi
}

# Pair a new device: scan, pick, pair, trust (auto-reconnect), connect.
# bluetoothctl in command mode registers no agent of its own, so PIN or passkey
# confirmations go to the default agent: blueman-applet's dialog.
pair_device() {
    local scan_pid data address name paired connected selected output
    local -a rows=() addresses=() names=()

    if [[ $(controller_property Powered) != yes ]]; then
        notify 'Bluetooth is off. Turn it on first (Bluetooth mode: 6)'
        return 1
    fi
    # Discovery lasts as long as this bluetoothctl runs; devices it found disappear
    # about 30 s after it stops, so keep it scanning until a device is picked.
    bluetoothctl --timeout 120 scan on >/dev/null 2>&1 &
    scan_pid=$!
    # Expand the PID now: scan_pid is local and gone when the EXIT trap runs
    trap "kill $scan_pid 2>/dev/null" EXIT
    notify 'Scanning for devices… Put the device in pairing mode'
    sleep 8

    data=$(device_rows 2>/dev/null)
    while IFS=$'\t' read -r address name paired connected; do
        [[ -n $address && $paired == no ]] || continue
        # Unnamed devices only show their address (AA-BB-…): rarely what you want
        [[ $name == "${address//:/-}" ]] && continue
        rows+=("$name · $address")
        addresses+=("$address")
        names+=("$name")
    done <<< "$data"
    if (( ${#rows[@]} == 0 )); then
        show_error 'No new devices found. Put the device in pairing mode and try again.'
        return 1
    fi
    selected=$(printf '%s\n' "${rows[@]}" |
        rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p 'Pair new device' \
            -mesg 'Still scanning: Esc and retry if the device is missing') || return 0
    [[ $selected =~ ^[0-9]+$ && $selected -lt ${#addresses[@]} ]] || return 1
    address=${addresses[selected]}
    name=${names[selected]}

    kill "$scan_pid" 2>/dev/null
    notify "Pairing with $name… Confirm the code if a dialog appears"
    if ! output=$(timeout 60 bluetoothctl pair "$address" 2>&1) ||
        ! bluetoothctl info "$address" 2>/dev/null | grep -q 'Paired: yes'; then
        notify "Could not pair $name: $(tail -n 1 <<< "$output")"
        return 1
    fi
    bluetoothctl trust "$address" >/dev/null 2>&1
    output=$(timeout 30 bluetoothctl connect "$address" 2>&1)
    if is_connected "$address"; then
        notify "Paired and connected: $name"
    else
        notify "Paired $name, but could not connect: $(tail -n 1 <<< "$output")"
        return 1
    fi
}

controller_action() {
    local property=$1 target=$2 command=$3 result actual
    result=$(bluetoothctl "$command" "$target" 2>&1) || {
        notify "Could not set $property: $result"; return 1;
    }
    actual=$(controller_property "$property")
    if [[ $actual == "$target" ]]; then
        notify "$property: $actual"
    else
        notify "Could not set $property: ${actual:-unavailable}"
        return 1
    fi
}

show_status() {
    local powered discoverable devices address name paired connected device_list_ok=1
    local -a names=()
    powered=$(controller_property Powered)
    if [[ -z $powered ]]; then
        printf 'Bluetooth | no controller or service unavailable\n'
        return 0
    fi
    discoverable=$(controller_property Discoverable)
    devices=$(device_rows 2>/dev/null) || device_list_ok=0
    while IFS=$'\t' read -r address name paired connected; do
        [[ $connected == yes ]] && names+=("$name")
    done <<< "$devices"
    if (( ! device_list_ok )); then
        printf 'Bluetooth | powered %s · discoverable %s · connected devices unavailable\n' \
            "$powered" "${discoverable:-unknown}"
    elif (( ${#names[@]} )); then
        printf 'Bluetooth | powered %s · discoverable %s · connected: %s\n' \
            "$powered" "${discoverable:-unknown}" "$(printf '%s, ' "${names[@]}" | sed 's/, $//')"
    else
        printf 'Bluetooth | powered %s · discoverable %s · no connected devices\n' \
            "$powered" "${discoverable:-unknown}"
    fi
}

case ${1:-} in
    status) show_status ;;
    connect_bluetooth_device) device_action connect ;;
    disconnect_bluetooth_device) device_action disconnect ;;
    reconnect_bluetooth_device) device_action reconnect ;;
    pair_bluetooth_device) pair_device ;;
    enable_bluetooth_discoverability) controller_action Discoverable yes discoverable ;;
    disable_bluetooth_discoverability) controller_action Discoverable no discoverable ;;
    enable_bluetooth) controller_action Powered yes power ;;
    disable_bluetooth) controller_action Powered no power ;;
    *) printf 'Usage: %s {status|connect_bluetooth_device|disconnect_bluetooth_device|reconnect_bluetooth_device|pair_bluetooth_device|enable_bluetooth_discoverability|disable_bluetooth_discoverability|enable_bluetooth|disable_bluetooth}\n' "$0" >&2; exit 2 ;;
esac
