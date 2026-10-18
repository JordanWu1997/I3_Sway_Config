#!/usr/bin/env bash

# Advanced radio block diagnostics and recovery. Normal Wi-Fi/Bluetooth
# controls belong to NetworkManager and BlueZ respectively.
ROFI_CONFIG="$HOME/.config/rofi/config_singlecol.rasi"
ICON="$HOME/.config/i3/share/64x64/wifi-connection.png"

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low -a Radio --icon="$ICON" 'Radio devices' "$1"
    fi
    return 0
}

radio_rows() {
    rfkill --noheadings --output ID,TYPE,SOFT,HARD 2>/dev/null
}

show_status() {
    local rows id type soft hard found=0
    rows=$(radio_rows) || { printf 'Radio blocks | unavailable\n'; return 0; }
    while read -r id type soft hard; do
        [[ $id =~ ^[0-9]+$ ]] || continue
        printf 'Radio %s #%s | software %s · hardware %s\n' "$type" "$id" "$soft" "$hard"
        found=1
    done <<< "$rows"
    (( found )) || printf 'Radio blocks | no radio devices\n'
    return 0
}

select_radio() {
    local operation=$1 rows id type soft hard selected
    local -a choices=() ids=() labels=()
    rows=$(radio_rows) || { notify 'Could not read radio devices'; return 1; }
    while read -r id type soft hard; do
        [[ $id =~ ^[0-9]+$ ]] || continue
        if [[ $operation == unblock ]]; then
            [[ $soft == blocked ]] || continue
        else
            [[ $soft == unblocked ]] || continue
        fi
        choices+=("$type #$id · software $soft · hardware $hard")
        ids+=("$id")
        labels+=("$type #$id")
    done <<< "$rows"
    if (( ${#choices[@]} == 0 )); then
        notify "No radio device eligible to $operation (check hardware block status)"
        return 1
    fi
    selected=$(printf '%s\n' "${choices[@]}" |
        rofi -dmenu -i -no-custom -format i -config "$ROFI_CONFIG" -p "$operation radio block") || return 1
    [[ $selected =~ ^[0-9]+$ && $selected -lt ${#ids[@]} ]] || return 1
    printf '%s\t%s\n' "${ids[selected]}" "${labels[selected]}"
}

change_radio() {
    local operation=$1 choice id label result state
    choice=$(select_radio "$operation") || return 0
    IFS=$'\t' read -r id label <<< "$choice"
    result=$(rfkill "$operation" "$id" 2>&1) || {
        notify "Could not $operation $label: $result"
        return 1
    }
    state=$(radio_rows | awk -v id="$id" '$1 == id {print $3; exit}')
    if [[ $operation == unblock && $state == unblocked ||
          $operation == block && $state == blocked ]]; then
        if [[ $operation == unblock ]]; then
            notify "$label software $state (hardware block, if any, still applies)"
        else
            notify "$label software $state"
        fi
    else
        notify "$label state is ${state:-unavailable}"
        return 1
    fi
}

case ${1:-} in
    status) show_status ;;
    enable_RF_device) change_radio unblock ;;
    disable_RF_device) change_radio block ;;
    *) printf 'Usage: %s {status|enable_RF_device|disable_RF_device}\n' "$0" >&2; exit 2 ;;
esac
