#!/bin/bash

# Set threshold (75% by default)
THRESHOLD=${1:-75}

# Function to get memory usage percentage
get_memory_usage() {
    # Get memory information using free command
    local memory_info=$(free | grep Mem)
    local total=$(echo $memory_info | awk '{print $2}')
    local used=$(echo $memory_info | awk '{print $3}')

    # Calculate percentage
    local percentage=$(( ($used * 100) / $total ))
    echo $percentage
}

# Function to send notification
send_notification() {
    local usage=$1
    notify-send "High Memory Usage Alert" "Memory usage is at ${usage}%" -u critical -i dialog-warning
}

# Main loop
while true; do
    usage=$(get_memory_usage)

    # Check if usage exceeds threshold
    if [ $usage -gt $THRESHOLD ]; then
        send_notification $usage
        # Wait 5 minutes before checking again to avoid spam
        sleep 300
    else
        # Check every 15 seconds
        sleep 15
    fi
done
