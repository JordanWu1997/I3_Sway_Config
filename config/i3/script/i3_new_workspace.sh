#!/usr/bin/env bash

# Load current workspace
CURRENT=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
    tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)

# Assign new workspace increasely
case $2 in
    "inc")
        if (( $CURRENT >= 1  )) && (( $CURRENT <= 10 )) ; then
            if (( $(($CURRENT + 1)) == 11 )); then
                NEW="11:B1"
            else
                NEW="$(( $CURRENT + 1 )):A$(( $CURRENT + 1 - 0  ))"
            fi
        elif (( $CURRENT >= 11 )) && (( $CURRENT <= 20 )) ; then
            if (( $(($CURRENT + 1)) == 21 )); then
                NEW="21:C1"
            else
                NEW="$(( $CURRENT + 1 )):B$(( $CURRENT + 1 - 10  ))"
            fi
        elif (( $CURRENT >= 21 )) && (( $CURRENT <= 30 )) ; then
            if (( $(($CURRENT + 1)) == 31 )); then
                NEW="31:D1"
            else
                NEW="$(( $CURRENT + 1 )):C$(( $CURRENT + 1 - 20  ))"
            fi
        elif (( $CURRENT >= 31 )) && (( $CURRENT <= 40 )) ; then
            if (( $(($CURRENT + 1)) == 41 )); then
                NEW="1:A1"
            else
                NEW="$(( $CURRENT + 1 )):D$(( $CURRENT + 1 - 30  ))"
            fi
        fi
        ;;
    # Assign new workspace decreasely
    "dec")
        if (( $CURRENT >= 1  )) && (( $CURRENT <= 10 )) ; then
            if (( $(($CURRENT - 1)) == 0 )); then
                NEW="40:D10"
            else
                NEW="$(( $CURRENT - 1 )):A$(( $CURRENT - 1 - 0  ))"
            fi
        elif (( $CURRENT >= 11 )) && (( $CURRENT <= 20 )) ; then
            if (( $(($CURRENT - 1)) == 10 )); then
                NEW="10:A10"
            else
                NEW="$(( $CURRENT - 1 )):B$(( $CURRENT - 1 - 10  ))"
            fi
        elif (( $CURRENT >= 21 )) && (( $CURRENT <= 30 )) ; then
            if (( $(($CURRENT - 1)) == 20 )); then
                NEW="20:B10"
            else
                NEW="$(( $CURRENT - 1 )):C$(( $CURRENT - 1 - 20  ))"
            fi
        elif (( $CURRENT >= 31 )) && (( $CURRENT <= 40 )) ; then
            if (( $(($CURRENT - 1)) == 30 )); then
                NEW="30:C10"
            else
                NEW="$(( $CURRENT - 1 )):D$(( $CURRENT - 1 - 30  ))"
            fi

        fi
        ;;
esac

# Workspace action
case $1 in
    # Move to new workspace
    "move")
        i3-msg workspace $NEW
        ;;
    # Move container to new workspace
    "move_container")
        i3-msg move container to workspace $NEW
        i3-msg workspace $NEW
        ;;
esac
