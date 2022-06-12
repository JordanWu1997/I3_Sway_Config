#!/usr/bin/env bash

workspace_next_cycle () {
    if (( $1 == 40 )); then
        NEW=1
    else
        NEW=$(( $1 + 1 ))
    fi
}

workspace_prev_cycle () {
    if ((  $1 == 1 )); then
        NEW=40
    else
        NEW=$(( $1 - 1 ))
    fi
}

name_new_workspace_with_index () {
    if (( $1 >= 1 )) && (( $1 <= 10 )); then
        NEW=${1}:A$(( $1 - 0))
    elif (( $1 >= 11 )) && (( $1 <= 20 )); then
        NEW=${1}:B$(( $1 - 10 ))
    elif (( $1 >= 21 )) && (( $1 <= 30 )); then
        NEW=${1}:C$(( $1 - 20 ))
    elif (( $1 >= 31 )) && (( $1 <= 40 )); then
        NEW=${1}:D$(( $1 - 30 ))
    fi
}

case $1 in
    "swap")
        # Calculate workspace number for different monitor
        case $2 in
            "A")
                ORIGIN=0
                ;;
            "B")
                ORIGIN=10
                ;;
            "C")
                ORIGIN=20
                ;;
            "D")
                ORIGIN=30
                ;;
            *)
                echo "Wrong Input Workspace Header (Available: A/B/C/D)"
        esac
        # Generate workspace name to swap
        WN=$(( $ORIGIN+$3 ))
        WPNM="$WN:$2$3"
        echo $WPNM
        # Swap workspace with i3-workspace-swap
        # -- Installation: pip install i3-workspace-swap
        i3-workspace-swap -d "$WPNM"
        ;;
    "swap_next")
        # Load current workspace
        CURRENT=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
            tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)
        # Swap with next workspace
        workspace_next_cycle $CURRENT
        name_new_workspace_with_index $NEW
        i3-workspace-swap -d "$NEW"
        ;;
    "swap_prev")
        # Load current workspace
        CURRENT=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
            tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)
        # Swap with previous workspace
        workspace_prev_cycle $CURRENT
        name_new_workspace_with_index $NEW
        i3-workspace-swap -d "$NEW"
        ;;
    "save_all")
        # Loop all defined workspaces
        for prefix in A B C D; do
            for index in {1..10}; do
                i3-resurrect save -w ${index}:${prefix}${index}
            done
        done
        ;;
    "restore_all")
        # Loop all defined workspaces
        for prefix in A B C D; do
            for index in {1..10}; do
                i3-resurrect restore -w ${index}:${prefix}${index}
            done
        done
        ;;
    *)
        echo $0
        ;;
esac
