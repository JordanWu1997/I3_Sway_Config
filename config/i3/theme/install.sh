#!/usr/bin/env bash

THEME_DIR="$HOME/.config/i3/theme"
TEMPLATE_DIR="${THEME_DIR}/templates"
PYWAL_COLORSCHEME="pywal/pywal/colorschemes/dark"
PYWAL_COLORSCHEME_DIR="${THEME_DIR}/${PYWAL_COLORSCHEME}"
NUM_COLOR=9
APPLY_NOW='no'

# Copy files in pywal from github
if [ ! -d "${TEMPLATE_DIR}" ]; then
    ${THEME_DIR}/copy_wal_templates.sh ${THEME_DIR} ${PYWAL_COLORSCHEME}
fi

# Generate color files from template color files and pywal colorscheme files
JSON_FILES=$(command ls "${PYWAL_COLORSCHEME_DIR}/")
for JSON_FILE in ${JSON_FILES[@]}; do
    echo "Generate color files: ${JSON_FILE} ..."
    TEMPLATE=$(basename ${JSON_FILE} .json)
    "${THEME_DIR}/generate_color_files_for_template.sh" \
        "${TEMPLATE_DIR}/${TEMPLATE}/${TEMPLATE}_colors" \
        "${THEME_DIR}/color_files" ${NUM_COLOR} ${APPLY_NOW}
done
