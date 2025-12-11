#!/usr/bin/env bash
# vim: set fileencoding=utf-8

# --- Configuration ---
# Find your battery device name. It's usually BAT0 or BAT1.
BATTERY_DIR="/sys/class/power_supply/BAT0"

# --- Error Handling & Setup ---
if [ ! -d "$BATTERY_DIR" ]; then
    notify-send -u critical "Battery Status Error" "Device directory $BATTERY_DIR not found. Check BAT0 or BAT1."
    exit 1
fi

STATUS=$(cat "$BATTERY_DIR/status" 2>/dev/null)
if [ "$STATUS" == "Unknown" ] || [ -z "$STATUS" ]; then
    notify-send -u critical "Battery Status Error" "Could not read battery status or battery not present."
    exit 1
fi

# --- Variables for Notification Content ---
NOTIFICATION_TITLE="Battery Info"
NOTIFICATION_BODY="Status: $STATUS\n"
ICON="battery-good" # Default icon

# --- 1. Get Power Consumption (Watts) ---
POWER_NOW_UW=$(cat "$BATTERY_DIR/power_now" 2>/dev/null)

if [ -z "$POWER_NOW_UW" ] || [ "$POWER_NOW_UW" -eq 0 ]; then
    POWER_WATTS="N/A"
else
    # Convert microwatts to Watts (divide by 1,000,000)
    POWER_WATTS=$(echo "scale=1; $POWER_NOW_UW / 1000000" | bc 2>/dev/null)
    NOTIFICATION_BODY+="Consumption: ${POWER_WATTS}W\n"
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
