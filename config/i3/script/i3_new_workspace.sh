#!/usr/bin/env bash

# Workspace name list
WS_NAME_LIST="$HOME/.config/i3/share/i3_workspace_name_list.txt"

# Set workspace list to workspace array
readarray WS_ARRAY < ${WS_NAME_LIST}

# Maximal number of workspaces
MAX_NUM_WS=${#WS_ARRAY[@]}

# Load current workspace
CURRENT_WS_NUM=$(i3-msg -t get_workspaces | tr \} '\n' | grep '"focused":true' | \
    tr , '\n' | grep "name"| cut -d ':' -f 2 | cut -c 2-)

# Load all workspace
ALL_WS=$(i3-msg -t get_workspaces | tr \} '\n' | grep "num" \
    | cut -d ':' -f 3 | cut -d ',' -f 1 | sort -n)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_new_workspace.sh [actions] [to_workspace]"
    echo
    echo "ACTIONS"
    echo "  [move_focus]: move focus"
    echo "  [move_container]: move currently focused container"
    echo
    echo "TO_WORKSPACE"
    echo "  [next]: next workspace"
    echo "  [prev]: previous workspace"
    echo "  [next_free_only]: next workspace that does not have containers"
    echo "  [prev_free_only]: previous workspace that does not have containers"
}

workspace_next_WS_NUM () {
    if (( $1 == ${MAX_NUM_WS} )); then
        NEXT_WS_NUM=1
    else
        NEXT_WS_NUM=$(( $1 + 1 ))
    fi
}

workspace_prev_WS_NUM () {
    if (( $1 == 1 )); then
        PREV_WS_NUM=${MAX_NUM_WS}
    else
        PREV_WS_NUM=$(( $1 - 1 ))
    fi
}

workspace_next_free_only_WS_NUM () {
    NEXT_FREE_WS_NUM=$1
    while true; do
        if [[ ${ALL_WS[*]} =~ (^|[[:space:]])"$NEXT_FREE_WS_NUM"($|[[:space:]]) ]]; then
            if (( $NEXT_FREE_WS_NUM == ${MAX_NUM_WS} )); then
                NEXT_FREE_WS_NUM=1
            else
                NEXT_FREE_WS_NUM=$(( $NEXT_FREE_WS_NUM + 1 ))
            fi
        else
            break
        fi
    done
}

workspace_prev_free_only_WS_NUM () {
    PREV_FREE_WS_NUM=$1
    while true; do
        if [[ ${ALL_WS[*]} =~ (^|[[:space:]])"$PREV_FREE_WS_NUM"($|[[:space:]]) ]]; then
            if (( $PREV_FREE_WS_NUM == 1 )); then
                PREV_FREE_WS_NUM=${MAX_NUM_WS}
            else
                PREV_FREE_WS_NUM=$(( $PREV_FREE_WS_NUM - 1 ))
            fi
        else
            break
        fi
    done
}

assign_new_workspace () {
    # Assign new workspace
    case $1 in
        # Assign next workspace as new workspace
        "next")
            workspace_next_WS_NUM ${CURRENT_WS_NUM}
            WS_NAME="${WS_ARRAY[$(( ${NEXT_WS_NUM} - 1 ))]}"
            ;;
        # Assign previous workspace as new workspace
        "prev")
            workspace_prev_WS_NUM ${CURRENT_WS_NUM}
            WS_NAME="${WS_ARRAY[$(( ${PREV_WS_NUM} - 1 ))]}"
            ;;
        # Assign next workspace (free only) as new workspace
        "next_free_only")
            workspace_next_free_only_WS_NUM ${CURRENT_WS_NUM}
            WS_NAME="${WS_ARRAY[$(( ${NEXT_FREE_WS_NUM} - 1 ))]}"
            ;;
        # Assign previous workspace (free only) as new workspace
        "prev_free_only")
            workspace_prev_free_only_WS_NUM ${CURRENT_WS_NUM}
            WS_NAME="${WS_ARRAY[$(( ${PREV_FREE_WS_NUM} - 1 ))]}"
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

workspace_action () {
    # Workspace action
    case $1 in
        # Move to new workspace
        "move_focus")
            i3-msg workspace ${WS_NAME}
            ;;
        # Move container to new workspace
        "move_container")
            i3-msg move container to workspace ${WS_NAME}
            i3-msg workspace ${WS_NAME}
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
assign_new_workspace $2
workspace_action $1
