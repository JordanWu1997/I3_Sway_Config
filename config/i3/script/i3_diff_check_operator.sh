#!/bin/bash

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_diff_check_operator.sh [OPTIONS] ([INPUT_DIR)])"
    echo ""
    echo "OPTIONS"
    echo "  [latest_git]: compare difference between files in git HEAD^ and local files"
    echo "  [input_dir]: compare difference between files in INPUT_DIR and local files. NOTE: INPUT_DIR must be provided."
    echo
}

check_diff () {
    case $1 in
        'latest_git')
            # Diff
            DIFF=$(git diff HEAD^ --name-only)
            for diff in ${DIFF[@]}; do
                if [[ -n $(diff ${diff} $HOME/.${diff}) ]]; then
                    nvim -d  ${diff} $HOME/.${diff}
                fi
            done
            ;;
        'input_dir')
            # Input root dir
            INPUT_ROOT_DIR=$2
            # Local root dir
            LOCAL_ROOT_DIR="$HOME"

            # Main config file
            echo ""
            echo "================================================================================"
            echo "CHECKING MAIN CONFIG FILE IN ${INPUT_I3_CONFIG_DIR}" ...
            echo "================================================================================"
            echo ""
            echo "MAIN CONFIG FILE"
            echo "  INPUT: ${INPUT_ROOT_DIR}/config/i3/config"
            echo "  LOCAL: ${LOCAL_ROOT_DIR}/.config/i3/config"
            sleep 1
            if [[ -n $(diff ${INPUT_ROOT_DIR}/config/i3/config ${LOCAL_ROOT_DIR}/.config/i3/config) ]]; then
                INPUT_FILE=${INPUT_ROOT_DIR}/config/i3/config
                LOCAL_FILE=${LOCAL_ROOT_DIR}/.config/i3/config
                nvim -d ${INPUT_FILE} ${LOCAL_FILE}
            fi

            # Configs, Scripts and etc.
            INPUT_I3_CONFIG_DIRS=("config/i3/config.d" "config/i3/script")
            LOCAL_I3_CONFIG_DIRS=(".config/i3/config.d" ".config/i3/script")
            for (( i=0; i<${#INPUT_I3_CONFIG_DIRS[@]}; i++ )); do
                INPUT_I3_CONFIG_DIR=${INPUT_I3_CONFIG_DIRS[$i]}
                LOCAL_I3_CONFIG_DIR=${LOCAL_I3_CONFIG_DIRS[$i]}

                # Print
                echo ""
                echo "================================================================================"
                echo "CHECKING FILE IN ${INPUT_I3_CONFIG_DIR}" ...
                echo "================================================================================"
                echo ""
                sleep 1

                # Input
                INPUT_FILES=()
                for config in $(ls ${INPUT_ROOT_DIR}/${INPUT_I3_CONFIG_DIR}/*); do
                    INPUT_FILES+=($(basename $config))
                done
                # Local
                LOCAL_FILES=()
                for config in $(ls ${LOCAL_ROOT_DIR}/${LOCAL_I3_CONFIG_DIR}/*); do
                    LOCAL_FILES+=($(basename $config))
                done
                # Common (Input ^ Local) files
                readarray -t COMMON <<<$(echo ${INPUT_FILES[@]} ${LOCAL_FILES[@]} | tr ' ' '\n' | sort | uniq -D | uniq)
                for (( j=0; j<${#COMMON[@]}; j++ )); do
                    INPUT_FILE=${INPUT_ROOT_DIR}/${INPUT_I3_CONFIG_DIR}/${COMMON[$j]}
                    LOCAL_FILE=${LOCAL_ROOT_DIR}/${LOCAL_I3_CONFIG_DIR}/${COMMON[$j]}
                    echo "COMM (INPUT ^ LOCAL) [$( expr $j + 1 )/${#COMMON[@]}]"
                    echo "  INPUT: ${INPUT_FILE} "
                    echo "  LOCAL: ${LOCAL_FILE}"
                    if [[ -f ${INPUT_FILE} ]] || [[ -f ${LOCAL_FILE} ]]; then
                        if [[ -n $(diff ${INPUT_FILE} ${LOCAL_FILE}) ]]; then
                            sleep 1
                            nvim -d ${INPUT_FILE} ${LOCAL_FILE}
                        fi
                    sleep 0.1
                    fi
                done
                # Diff (NOT Input ^ Local) files
                readarray -t DIFF <<<$(echo ${LOCAL_FILES[@]} ${INPUT_FILES[@]} | tr ' ' '\n' | sort | uniq -u)
                for (( j=0; j<${#DIFF[@]}; j++ )); do
                    INPUT_FILE=${INPUT_ROOT_DIR}/${INPUT_I3_CONFIG_DIR}/${DIFF[$j]}
                    LOCAL_FILE=${LOCAL_ROOT_DIR}/${LOCAL_I3_CONFIG_DIR}/${DIFF[$j]}
                    echo "DIFF (NOT INPUT ^ LOCAL) [$( expr $j + 1 )/${#DIFF[@]}]"
                    echo "  INPUT: ${INPUT_FILE} "
                    echo "  LOCAL: ${LOCAL_FILE}"
                    sleep 1
                    if [[ -f ${INPUT_FILE} ]] || [[ -f ${LOCAL_FILE} ]]; then
                        nvim -d ${INPUT_FILE} ${LOCAL_FILE}
                    fi
                done
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
