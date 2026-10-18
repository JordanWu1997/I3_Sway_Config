#!/usr/bin/env bash

# NetworkManager owns network, Wi-Fi, Ethernet, and VPN connection state.
ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
ICON="$HOME/.config/i3/share/64x64/wifi-connection.png"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -a Network --icon="$ICON" 'Network' "$1"
    fi
    return 0
}

connection_type_label() {
    case "$1" in
        802-3-ethernet|ethernet) printf 'Ethernet' ;;
        802-11-wireless|wifi) printf 'Wi-Fi' ;;
        vpn|wireguard) printf 'VPN' ;;
        *) printf '%s' "$1" ;;
    esac
}

choose_connection() {
    local scope=$1 title=$2 data uuid type name selected
    local -a rows=() uuids=() names=()
    if [[ $scope == active ]]; then
        data=$(nmcli -t -f UUID,TYPE,NAME connection show --active) || return 1
    else
        data=$(nmcli -t -f UUID,TYPE,NAME connection show) || return 1
    fi
    while IFS=: read -r uuid type name; do
        [[ $uuid =~ ^[[:xdigit:]-]{36}$ ]] || continue
        name=${name//\\:/:}
        rows+=("[$(connection_type_label "$type")] $name")
        uuids+=("$uuid")
        names+=("$name")
    done <<< "$data"
    if (( ${#rows[@]} == 0 )); then
        notify 'No matching saved connections'
        return 1
    fi
    selected=$(printf '%s\n' "${rows[@]}" |
        rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p "$title") || return 1
    [[ $selected =~ ^[0-9]+$ && $selected -lt ${#uuids[@]} ]] || return 1
    printf '%s\t%s\n' "${uuids[selected]}" "${names[selected]}"
}

connection_action() {
    local operation=$1 selection uuid name output
    if [[ $operation == up ]]; then
        selection=$(choose_connection all 'Activate saved connection') || return 0
    else
        selection=$(choose_connection active 'Disconnect active connection') || return 0
    fi
    IFS=$'\t' read -r uuid name <<< "$selection"
    if output=$(nmcli connection "$operation" uuid "$uuid" 2>&1); then
        if [[ $operation == up ]]; then
            notify "Connected: $name"
        else
            notify "Disconnected: $name"
        fi
    else
        notify "Could not change $name: $output"
        return 1
    fi
}

switch_state() {
    local kind=$1 target=$2 result actual
    case "$kind" in
        networking) result=$(nmcli networking "$target" 2>&1) || { notify "Networking: $result"; return 1; }
                    actual=$(nmcli networking) ;;
        wifi) result=$(nmcli radio wifi "$target" 2>&1) || { notify "Wi-Fi: $result"; return 1; }
              actual=$(nmcli radio wifi) ;;
    esac
    if [[ $actual == enabled && $target == on || $actual == disabled && $target == off ]]; then
        notify "${kind^} $actual"
    else
        notify "${kind^} is ${actual:-unavailable}"
        return 1
    fi
}

show_status() {
    local master wifi data device_types uuid type name
    local -a ethernet=() wireless=() vpn=() other=()
    master=$(nmcli networking 2>/dev/null) || { printf 'Network | NetworkManager unavailable\n'; return 0; }
    wifi=$(nmcli radio wifi 2>/dev/null) || wifi=unavailable
    if ! data=$(nmcli -t -f UUID,TYPE,NAME connection show --active 2>/dev/null); then
        printf 'Network | %s · active connections unavailable\n' "$master"
        printf 'Wi-Fi | %s · connection state unavailable\n' "$wifi"
        return 0
    fi
    device_types=$(nmcli -t -f TYPE device status 2>/dev/null) || device_types=
    while IFS=: read -r uuid type name; do
        [[ $uuid =~ ^[[:xdigit:]-]{36}$ ]] || continue
        name=${name//\\:/:}
        case "$type" in
            802-3-ethernet|ethernet) ethernet+=("$name") ;;
            802-11-wireless|wifi) wireless+=("$name") ;;
            vpn|wireguard) vpn+=("$name") ;;
            *) other+=("$name") ;;
        esac
    done <<< "$data"
    printf 'Network | %s\n' "$master"
    if (( ${#ethernet[@]} )); then
        printf 'Ethernet | connected: %s\n' "$(printf '%s, ' "${ethernet[@]}" | sed 's/, $//')"
    else
        printf 'Ethernet | disconnected\n'
    fi
    if [[ -z $device_types ]]; then
        printf 'Wi-Fi | %s · adapter state unavailable\n' "$wifi"
    elif ! grep -qx wifi <<< "$device_types"; then
        printf 'Wi-Fi | no adapter\n'
    elif (( ${#wireless[@]} )); then
        printf 'Wi-Fi | %s · connected: %s\n' "$wifi" "$(printf '%s, ' "${wireless[@]}" | sed 's/, $//')"
    else
        printf 'Wi-Fi | %s · disconnected\n' "$wifi"
    fi
    if (( ${#vpn[@]} )); then
        printf 'VPN | connected: %s\n' "$(printf '%s, ' "${vpn[@]}" | sed 's/, $//')"
    else
        printf 'VPN | disconnected\n'
    fi
    (( ${#other[@]} )) && printf 'Other links | %s\n' "$(printf '%s, ' "${other[@]}" | sed 's/, $//')"
    return 0
}

case ${1:-} in
    status) show_status ;;
    connection_up) connection_action up ;;
    connection_down) connection_action down ;;
    enable_networking) switch_state networking on ;;
    disable_networking) switch_state networking off ;;
    enable_wifi) switch_state wifi on ;;
    disable_wifi) switch_state wifi off ;;
    *) printf 'Usage: %s {status|connection_up|connection_down|enable_networking|disable_networking|enable_wifi|disable_wifi}\n' "$0" >&2; exit 2 ;;
esac
