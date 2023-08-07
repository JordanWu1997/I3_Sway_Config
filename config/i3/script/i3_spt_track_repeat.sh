#!/usr/bin/env bash

PLAYING=$(spt playback --format "%t")
REMAINING_SEC_THR_TO_REPEAT=5
SEC_SKIP_TO_SCAN_BEFORE_LAST_MIN=10
SEC_SKIP_TO_SCAN_IN_LAST_MIN=5

while true; do

    # Load playing information
    SPT_INFO=$(spt playback --format "%r %t")
    echo ${SPT_INFO}

    # Get remaining time (in min), skip some secs before the last minute
    REMAINING_MIN=$(echo ${SPT_INFO} | cut -d' ' -f2 | cut -d':' -f1 | cut -d'(' -f2)
    if [[ ${REMAINING_MIN} -lt 0 ]]; then
        sleep ${SEC_SKIP_TO_SCAN_BEFORE_LAST_MIN}
    else
        # Get remaining time (in sec), skip some secs before the last few seconds
        REMAINING_SEC=$(echo ${SPT_INFO} | cut -d' ' -f2 | cut -d':' -f2 | cut -d')' -f1)
        if [[ ${REMAINING_SEC} -gt ${SEC_SKIP_TO_SCAN_BEFORE_LAST_MIN} ]]; then
            sleep ${SEC_SKIP_TO_SCAN_IN_LAST_MIN}
        else
            if [[ ${REMAINING_SEC} -le ${REMAINING_SEC_THR_TO_REPEAT} ]]; then
                spt playback --previous
            else
                sleep 1
            fi
        fi
    fi

done
