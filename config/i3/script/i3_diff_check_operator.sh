#!/bin/bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_diff_check_operator.sh [operations] ([GIT_REPO_PATH)])"
    echo ""
    echo "OPERATIONS"
    echo "  [latest_diff]: compare difference between git HEAD^ and local"
    echo "  [local_diff]: compare difference between local git and local i3 config"
    echo
    echo "GIT_REPO_PATH"
    echo "  local git directory location e.g. default: $HOME/Desktop/I3_Sway_Config"
}

check_diff () {
    case $1 in
        'latest_diff')
            # Diff
            DIFF=$(git diff HEAD^ --name-only)
            for diff in ${DIFF[@]}; do
                if [[ -n $(diff ${diff} $HOME/.${diff}) ]]; then
                    nvim -d  ${diff} $HOME/.${diff}
                fi
            done
            ;;
        'local_diff')
            # Git
            GIT_DIR="${2:-$HOME/Desktop/I3_Sway_Config}"
            GIT_CONFIG=("$GIT_DIR/config/i3/config")
            for config in $(ls $GIT_DIR/config/i3/config.d/*); do
                GIT_CONFIG+=($config)
            done
            # Local
            LOC_DIR="$HOME/.config/i3"
            LOC_CONFIG=("$LOC_DIR/config")
            for config in $(ls $LOC_DIR/config.d/*); do
                LOC_CONFIG+=($config)
            done
            # Diff
            for (( i=0; i<${#GIT_CONFIG[@]}; i++ )); do
                echo $( expr $i + 1 )/${#GIT_CONFIG[@]} ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}
                if [[ -n $(diff ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}) ]]; then
                    nvim -d ${GIT_CONFIG[i]} ${LOC_CONFIG[i]}
                fi
            done
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
check_diff $@
