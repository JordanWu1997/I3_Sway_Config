#!/bin/bash

check_diff () {
    # Diff
    if [[ $(command -v nvim) ]]; then
        diff='nvim -d'
    else
        diff='vimdiff'
    fi
    # Loop
    for file in $(ls $1); do
        remote_file="$1/${file}"
        local_file="$2/${file}"
        if [[ -e ${local_file} ]]; then
            echo "${remote_file} <-> ${local_file}"
            ${diff} ${remote_file} ${local_file}
            sleep 1
        fi
    done
}

# Configs
REMOTE_DIR="$HOME/Desktop/Jordan/I3_Sway_Config/config/i3"
LOCAL_DIR="$HOME/.config/i3"
if [[ $(command -v nvim) ]]; then
    diff='nvim -d'
else
    diff='vimdiff'
fi
${diff} ${REMOTE_DIR}/config ${LOCAL_DIR}/config
check_diff ${REMOTE_DIR}/config.d ${LOCAL_DIR}/config.d

# Scripts
REMOTE_DIR="$HOME/Desktop/Jordan/I3_Sway_Config/config/i3/script"
LOCAL_DIR="$HOME/.config/i3/script"
check_diff ${REMOTE_DIR} ${LOCAL_DIR}
