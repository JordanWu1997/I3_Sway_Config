#!/usr/bin/env bash

# Load current workspace
current=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
    tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)

# Assign new workspace increasely
if [ $2 == "inc" ]; then
    if (( $current >= 1  )) && (( $current <= 10 )) ; then
        if (( $(($current + 1)) == 11 )); then
            new="11:B1"
        else
            new="$(( $current + 1 )):A$(( $current + 1 - 0  ))"
        fi
    elif (( $current >= 11 )) && (( $current <= 20 )) ; then
        if (( $(($current + 1)) == 21 )); then
            new="21:C1"
        else
            new="$(( $current + 1 )):B$(( $current + 1 - 10  ))"
        fi
    elif (( $current >= 21 )) && (( $current <= 30 )) ; then
        if (( $(($current + 1)) == 31 )); then
            new="31:D1"
        else
            new="$(( $current + 1 )):C$(( $current + 1 - 20  ))"
        fi
    elif (( $current >= 31 )) && (( $current <= 40 )) ; then
        if (( $(($current + 1)) == 41 )); then
            new="1:A1"
        else
            new="$(( $current + 1 )):C$(( $current + 1 - 30  ))"
        fi
    fi
# Assign new workspace decreasely
elif [ $2 == "dec" ]; then
    if (( $current >= 1  )) && (( $current <= 10 )) ; then
        if (( $(($current - 1)) == 0 )); then
            new="40:D10"
        else
            new="$(( $current - 1 )):A$(( $current - 1 - 0  ))"
        fi
    elif (( $current >= 11 )) && (( $current <= 20 )) ; then
        if (( $(($current - 1)) == 10 )); then
            new="10:A10"
        else
            new="$(( $current - 1 )):B$(( $current - 1 - 10  ))"
        fi
    elif (( $current >= 21 )) && (( $current <= 30 )) ; then
        if (( $(($current - 1)) == 20 )); then
            new="20:B10"
        else
            new="$(( $current - 1 )):C$(( $current - 1 - 20  ))"
        fi
    elif (( $current >= 31 )) && (( $current <= 40 )) ; then
        if (( $(($current - 1)) == 30 )); then
            new="30:C10"
        else
            new="$(( $current - 1 )):D$(( $current - 1 - 30  ))"
        fi

    fi
fi

# Move to new workspace
if [ $1 == "move" ]; then
    i3-msg workspace $new
# Move container to new workspace
elif [ $1 == "move_container" ]; then
    i3-msg move container to workspace $new; i3-msg workspace $new
fi
