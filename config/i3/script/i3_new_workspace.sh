#!/usr/bin/env bash

# Load current workspace
CURRENT=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
    tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)

# Load all workspace
ALL_WS=$(i3-msg -t get_workspaces | tr \} '\n' | grep "num" \
    | cut -d ':' -f 3 | cut -d ',' -f 1 | sort -n)

cycle_workspace_next () {
    if (( $1 == 40 )); then
        NEW=1
    else
        NEW=$(( $1 + 1 ))
    fi
}

cycle_workspace_prev () {
    if ((  $1 == 1 )); then
        NEW=40
    else
        NEW=$(( $1 - 1 ))
    fi
}

cycle_workspace_next_free_only () {
    NEW=$1
    echo $CURRENT
    echo $ALL_WS
    while true; do
        if [[ ${ALL_WS[*]} =~ (^|[[:space:]])"$NEW"($|[[:space:]]) ]]; then
            echo $NEW
            if (( $NEW == 40 )); then
                NEW=1
            else
                NEW=$(( $NEW + 1 ))
            fi
        else
            break
        fi
    done
}

cycle_workspace_prev_free_only () {
    NEW=$1
    while true; do
        echo $NEW
        if [[ ${ALL_WS[*]} =~ (^|[[:space:]])"$NEW"($|[[:space:]]) ]]; then
            if (( $NEW == 1 )); then
                NEW=40
            else
                NEW=$(( $NEW - 1 ))
            fi
        else
            break
        fi
    done
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

assign_new_workspace () {
    # Assign new workspace
    case $1 in
        # Assign next workspace as new workspace
        "next")
            cycle_workspace_next $CURRENT
            name_new_workspace_with_index $NEW
            ;;
        # Assign previous workspace as new workspace
        "prev")
            echo $CURRENT
            cycle_workspace_prev $CURRENT
            echo $NEW
            name_new_workspace_with_index $NEW
            ;;
        # Assign next workspace (free only) as new workspace
        "next_free_only")
            cycle_workspace_next_free_only $CURRENT
            name_new_workspace_with_index $NEW
            ;;
        # Assign previous workspace (free only) as new workspace
        "prev_free_only")
            cycle_workspace_prev_free_only $CURRENT
            name_new_workspace_with_index $NEW
            ;;
        *)
            echo $2
            ;;
    esac
}

workspace_action () {
    # Workspace action
    case $1 in
        # Move to new workspace
        "move_focus")
            i3-msg workspace $NEW
            ;;
        # Move container to new workspace
        "move_container")
            i3-msg move container to workspace $NEW
            i3-msg workspace $NEW
            ;;
        *)
            echo $1
            ;;
    esac
}

# Main
assign_new_workspace $2
workspace_action $1
