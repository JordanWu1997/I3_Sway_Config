#!/usr/bin/env bash

# NetworkManager owns network, Wi-Fi, Ethernet, and VPN connection state.
ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
ICON="$HOME/.config/i3/share/64x64/wifi-connection.png"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -a Network -h string:x-dunst-stack-tag:network --icon="$ICON" 'Network' "$1"
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

# nmcli terse output escapes ':' and '\' with a backslash
unescape() {
    local text=${1//\\:/:}
    printf '%s' "${text//\\\\/\\}"
}

# Join a Wi-Fi network: scan, pick, ask for a password if needed.
# Saved networks are activated with their stored profile. For a new secured network,
# a profile is created without the password, which is then handed to nmcli through a
# file descriptor (passwd-file), so it never shows up in the process list.
wifi_connect() {
    local rescan=auto data in_use signal security ssid uuid type selected
    local password key_mgmt output state
    local -a rows ssids securities in_uses
    local -A saved=() seen=()

    if [[ $(nmcli radio wifi 2>/dev/null) != enabled ]]; then
        notify 'Wi-Fi is disabled. Enable it first (Network mode: 3)'
        return 1
    fi
    while IFS=: read -r uuid type; do
        [[ $type == 802-11-wireless ]] || continue
        ssid=$(unescape "$(nmcli -g 802-11-wireless.ssid connection show uuid "$uuid" 2>/dev/null)")
        [[ -n $ssid && -z ${saved[$ssid]:-} ]] && saved[$ssid]=$uuid
    done < <(nmcli -t -f UUID,TYPE connection show 2>/dev/null)

    while true; do
        notify 'Scanning Wi-Fi networks…'
        data=$(nmcli -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan "$rescan" 2>&1) || {
            notify "Wi-Fi scan failed: $data"
            return 1
        }
        rows=('↻ Rescan'); ssids=(''); securities=(''); in_uses=(''); seen=()
        while IFS=: read -r in_use signal security ssid; do
            ssid=$(unescape "$ssid")
            [[ -n $ssid && -z ${seen[$ssid]:-} ]] || continue
            seen[$ssid]=1
            [[ $security == '--' ]] && security=''
            local status=${security:-open}
            [[ -n ${saved[$ssid]:-} ]] && status+=' · saved'
            rows+=("$([[ $in_use == '*' ]] && printf '✓' || printf ' ') $(printf '%3s' "$signal")%  $ssid  ·  $status")
            ssids+=("$ssid"); securities+=("$security"); in_uses+=("$in_use")
        done < <(sort -t: -k2,2nr <<< "$data")
        (( ${#rows[@]} > 1 )) || { notify 'No Wi-Fi networks found'; return 1; }
        selected=$(printf '%s\n' "${rows[@]}" |
            rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p 'Wi-Fi network' \
                -mesg 'Enter: connect · ✓ connected · saved: password stored') || return 0
        [[ $selected =~ ^[0-9]+$ && $selected -lt ${#rows[@]} ]] || return 1
        (( selected == 0 )) && { rescan=yes; continue; }
        break
    done

    ssid=${ssids[selected]}
    security=${securities[selected]}
    if [[ ${in_uses[selected]} == '*' ]]; then
        notify "Already connected: $ssid"
        return 0
    fi

    # Saved network: use the stored profile (and its stored password)
    if [[ -n ${saved[$ssid]:-} ]]; then
        if output=$(nmcli --wait 30 connection up uuid "${saved[$ssid]}" 2>&1); then
            notify "Connected: $ssid"
        else
            notify "Could not connect to $ssid: $output"
            return 1
        fi
        return 0
    fi

    case "$security" in
        '') key_mgmt='' ;;
        *802.1X*)
            notify "$ssid uses enterprise (802.1X) login. Set it up in nm-connection-editor."
            return 1 ;;
        *WPA1*|*WPA2*) key_mgmt=wpa-psk ;;
        *WPA3*) key_mgmt=sae ;;
        *)
            notify "$ssid uses unsupported security ($security). Use nm-connection-editor."
            return 1 ;;
    esac

    if [[ -n $key_mgmt ]]; then
        password=$(rofi -dmenu -password -l 0 -config "$ROFI_CONFIG" \
            -p 'Password' -mesg "Wi-Fi: $ssid" < /dev/null) || return 0
        if (( ${#password} < 8 || ${#password} > 63 )); then
            notify "Wi-Fi passwords are 8 to 63 characters. $ssid was not added."
            return 1
        fi
        output=$(nmcli connection add type wifi con-name "$ssid" ssid "$ssid" \
            wifi-sec.key-mgmt "$key_mgmt" 2>&1)
    else
        output=$(nmcli connection add type wifi con-name "$ssid" ssid "$ssid" 2>&1)
    fi
    [[ $output =~ \(([[:xdigit:]-]{36})\) ]] || { notify "Could not add $ssid: $output"; return 1; }
    uuid=${BASH_REMATCH[1]}

    notify "Connecting to $ssid…"
    if [[ -n $key_mgmt ]]; then
        output=$(nmcli --wait 30 connection up uuid "$uuid" \
            passwd-file <(printf '802-11-wireless-security.psk:%s\n' "$password") 2>&1)
        state=$?
    else
        output=$(nmcli --wait 30 connection up uuid "$uuid" 2>&1)
        state=$?
    fi
    unset password
    if (( state == 0 )); then
        notify "Connected: $ssid"
    else
        # Do not keep a profile with a wrong password: the next attempt starts clean
        nmcli connection delete uuid "$uuid" >/dev/null 2>&1
        notify "Could not connect to $ssid (wrong password?): $output"
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
    wifi_connect) wifi_connect ;;
    enable_networking) switch_state networking on ;;
    disable_networking) switch_state networking off ;;
    enable_wifi) switch_state wifi on ;;
    disable_wifi) switch_state wifi off ;;
    *) printf 'Usage: %s {status|connection_up|connection_down|wifi_connect|enable_networking|disable_networking|enable_wifi|disable_wifi}\n' "$0" >&2; exit 2 ;;
esac
