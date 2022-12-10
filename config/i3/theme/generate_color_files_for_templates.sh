#!/usr/bin/env bash

PYWAL_DIR="$HOME/Desktop/pywal-3.3.0/pywal/colorschemes/dark"

JSON_FILES=$(ls ${PYWAL_DIR})
for JSON_FILE in ${JSON_FILES[@]}; do
    echo $TEMPLATE
    TEMPLATE=$(basename $JSON_FILE .json)
    ./generate_color_files_for_template.sh ./templates/${TEMPLATE}/${TEMPLATE}_colors ./color_files 9 no
done
