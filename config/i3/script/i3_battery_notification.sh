#!/usr/bin/env bash
# vim: set fileencoding=utf-8

# --- Configuration ---
# Find your battery device name. It's usually BAT0 or BAT1.
BATTERY_DIR="${I3_BATTERY_DIR:-/sys/class/power_supply/BAT0}"
ERROR_ICON="$HOME/.config/i3/share/64x64/notification.png"

# Prefer BAT0, but support laptops whose battery is named BAT1. An override is
# useful for diagnostics and testing without reading the live sysfs tree.
if [[ ! -d $BATTERY_DIR && -z ${I3_BATTERY_DIR:-} ]]; then
    for candidate in /sys/class/power_supply/BAT*; do
        if [[ -d $candidate ]]; then
            BATTERY_DIR=$candidate
            break
        fi
    done
fi

if [[ ${1:-} == status ]]; then
    if [[ ! -d $BATTERY_DIR ]]; then
        printf 'Battery | not present\n'
        exit 0
    fi
    if [[ ! -r $BATTERY_DIR/status || ! -r $BATTERY_DIR/capacity ]]; then
        printf 'Battery | unreadable\n'
        exit 0
    fi
    IFS= read -r state < "$BATTERY_DIR/status"
    IFS= read -r capacity < "$BATTERY_DIR/capacity"
    [[ $capacity =~ ^[0-9]+$ ]] || { printf 'Battery | unreadable\n'; exit 0; }
    detail=
    if [[ $state == Discharging || $state == Charging ]]; then
        if [[ -r $BATTERY_DIR/energy_now && -r $BATTERY_DIR/power_now ]]; then
            IFS= read -r amount < "$BATTERY_DIR/energy_now"
            IFS= read -r rate < "$BATTERY_DIR/power_now"
            if [[ $state == Charging && -r $BATTERY_DIR/energy_full ]]; then
                IFS= read -r full < "$BATTERY_DIR/energy_full"
                amount=$((full - amount))
            elif [[ $state == Charging ]]; then
                amount=
            fi
        elif [[ -r $BATTERY_DIR/charge_now && -r $BATTERY_DIR/current_now ]]; then
            IFS= read -r amount < "$BATTERY_DIR/charge_now"
            IFS= read -r rate < "$BATTERY_DIR/current_now"
            if [[ $state == Charging && -r $BATTERY_DIR/charge_full ]]; then
                IFS= read -r full < "$BATTERY_DIR/charge_full"
                amount=$((full - amount))
            elif [[ $state == Charging ]]; then
                amount=
            fi
        fi
        if [[ ${amount:-} =~ ^[0-9]+$ && ${rate:-} =~ ^[0-9]+$ ]] && (( rate > 0 && amount >= 0 )); then
            minutes=$((amount * 60 / rate))
            if [[ $state == Charging ]]; then
                detail=$(printf ' · about %dh %02dm to full' "$((minutes / 60))" "$((minutes % 60))")
            else
                detail=$(printf ' · about %dh %02dm remaining' "$((minutes / 60))" "$((minutes % 60))")
            fi
        fi
    fi
    printf 'Battery | %s%% · %s%s\n' "$capacity" "$state" "$detail"
    exit 0
fi

# --- Error Handling & Setup ---
if [ ! -d "$BATTERY_DIR" ]; then
    notify-send -u critical "Battery Status Error" "Device directory $BATTERY_DIR not found. Check BAT0 or BAT1." --icon="$ERROR_ICON"
    exit 1
fi

STATUS=$(cat "$BATTERY_DIR/status" 2>/dev/null)
if [ "$STATUS" == "Unknown" ] || [ -z "$STATUS" ]; then
    notify-send -u critical "Battery Status Error" "Could not read battery status or battery not present." --icon="$ERROR_ICON"
    exit 1
fi

# --- Variables for Notification Content ---
NOTIFICATION_TITLE="Battery Info"
CAPACITY=$(cat "$BATTERY_DIR/capacity" 2>/dev/null)
NOTIFICATION_BODY="Charge: ${CAPACITY:-unknown}%\nStatus: $STATUS\n"
ICON="battery-good" # Default icon

# --- 1. Get Power Consumption (Watts) ---
POWER_NOW_UW=$(cat "$BATTERY_DIR/power_now" 2>/dev/null)

if [ -z "$POWER_NOW_UW" ] || [ "$POWER_NOW_UW" -eq 0 ]; then
    POWER_WATTS="N/A"
else
    # Convert microwatts to Watts (divide by 1,000,000)
    POWER_WATTS=$(echo "scale=1; $POWER_NOW_UW / 1000000" | bc 2>/dev/null)
    if [ "$STATUS" == "Discharging" ]; then
        NOTIFICATION_BODY+="Discharge Power: ${POWER_WATTS}W\n"
    elif [ "$STATUS" == "Charging" ]; then
        NOTIFICATION_BODY+="Charge Power: ${POWER_WATTS}W\n"
    else
        NOTIFICATION_BODY+="N/A: ${POWER_WATTS}W\n"
    fi
fi

# --- 2. Calculate Time Remaining/To Full ---
if [ "$STATUS" == "Discharging" ]; then
    ENERGY_NOW_UWH=$(cat "$BATTERY_DIR/energy_now" 2>/dev/null)

    if [ "$POWER_NOW_UW" -gt 0 ] && [ -n "$ENERGY_NOW_UWH" ]; then
        # Time (in hours) = Energy (µWh) / Power (µW)
        TIME_HOURS=$(echo "scale=4; $ENERGY_NOW_UWH / $POWER_NOW_UW" | bc 2>/dev/null)

        HOURS=$(echo "$TIME_HOURS / 1" | bc 2>/dev/null)
        MINUTES_RAW=$(echo "scale=0; ($TIME_HOURS - $HOURS) * 60" | bc 2>/dev/null)
        MINUTES=$(printf "%02d" $MINUTES_RAW)

        NOTIFICATION_BODY+="Remaining: ${HOURS}h ${MINUTES}m"
    fi

elif [ "$STATUS" == "Charging" ]; then
    ENERGY_NOW_UWH=$(cat "$BATTERY_DIR/energy_now" 2>/dev/null)
    ENERGY_FULL_UWH=$(cat "$BATTERY_DIR/energy_full" 2>/dev/null)

    # Use absolute value of power consumption for charging rate
    if [ "$POWER_NOW_UW" -gt 0 ] && [ -n "$ENERGY_NOW_UWH" ] && [ -n "$ENERGY_FULL_UWH" ]; then
        ENERGY_TO_FULL=$(echo "$ENERGY_FULL_UWH - $ENERGY_NOW_UWH" | bc 2>/dev/null)

        # Time to full (in hours) = Energy to full / Charging Power Rate
        POWER_RATE=$(echo "$POWER_NOW_UW" | bc 2>/dev/null)
        TIME_HOURS_TO_FULL=$(echo "scale=4; $ENERGY_TO_FULL / $POWER_RATE" | bc 2>/dev/null)

        HOURS=$(echo "$TIME_HOURS_TO_FULL / 1" | bc 2>/dev/null)
        MINUTES_RAW=$(echo "scale=0; ($TIME_HOURS_TO_FULL - $HOURS) * 60" | bc 2>/dev/null)
        MINUTES=$(printf "%02d" $MINUTES_RAW)

        NOTIFICATION_BODY+="Time to Full: ${HOURS}h ${MINUTES}m"
    fi
else
    # Status is Full or Unknown (and not handled above)
    NOTIFICATION_BODY+="No time calculation needed."
fi

# --- Send Notification ---
notify-send -i "$ICON" -u low -a "$NOTIFICATION_TITLE" " " "$NOTIFICATION_BODY"
