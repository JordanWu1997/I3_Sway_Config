#!/usr/bin/env bash

THEME_TEMPLATE_DIR="$HOME/.config/i3/theme/templates"
WAL_DIR="$HOME/.cache/wal"
FILE_NAME_LIST=( \
    colors \
    colors.sh \
    colors.Xresources \
    colors.json \
    colors-kitty.conf \
    colors-rofi-dark.rasi \
)

show_available_theme_templates () {
    echo Available Templates:
    for THEME in $(command ls -D ${THEME_TEMPLATE_DIR}/); do
        echo "  $THEME"
    done
}

verify_input_template () {
    if [[ ! $(command ls -D ${THEME_TEMPLATE_DIR/}) =~ $1 ]]; then
        show_available_theme_templates
        false
    else
        true
    fi
}

replace_all_wal_color_files () {
    # Replace Files
    for file in ${FILE_NAME_LIST[@]}; do
        echo "${THEME_TEMPLATE_DIR}/$1/${file}"
        command cp "${THEME_TEMPLATE_DIR}/$1/${file}" ${WAL_DIR}/
    done
}

reload_after_replacement () {
    # Reload Xresources
    xrdb -load ~/.Xresources
    # Reload i3
    i3-msg reload
}

# Main
if [ -z $1 ]; then
    THEME=$(command ls -D ${THEME_TEMPLATE_DIR}/ | rofi -dmenu -i -p "Theme Templates")
    replace_all_wal_color_files ${THEME}
    reload_after_replacement
    notify-send -u low "Template Theme" "Theme ${THEME} is applied"
else
    if verify_input_template $1; then
        replace_all_wal_color_files $1
        reload_after_replacement
        notify-send -u low "Template Theme" "Theme $1 is applied"
    fi
fi
