#!/usr/bin/env bash
#
THEME_DIR=$1 #"$HOME/.config/i3/theme"
PYWAL_COLORSCHEME=$2 #"pywal/pywal/colorschemes/dark"

# Clone pywal from github
PYWAL_GIT="https://github.com/dylanaraps/pywal.git"
if [[ ! -d "${THEME_DIR}/pywal" ]]; then
    cd ${THEME_DIR}; git clone ${PYWAL_GIT}; cd -
fi

# Copy json files of pywal
TEMPLATE_DIR="${THEME_DIR}/templates"
JSON_FILES=$(ls ${THEME_DIR}/${PYWAL_COLORSCHEME})
for JSON_FILE in ${JSON_FILES[@]}; do
    TEMPLATE=$(basename $JSON_FILE .json)
    echo $TEMPLATE, $JSON_FILE
    # Read color from json file
    for i in {0..15}; do
        COLOR=$(cat ${THEME_DIR}/${PYWAL_COLORSCHEME}/${JSON_FILE} | jq '.colors' | jq ".color${i}")
        COLORS[$i]=${COLOR}
    done
    # Create output directory
    OUTPUT_DIR="${TEMPLATE_DIR}/${TEMPLATE}"
    OUTPUT_FILE=${OUTPUT_DIR}/${TEMPLATE}_colors
    [ ! -d ${OUTPUT_DIR} ] && mkdir -p ${OUTPUT_DIR}
    [ -f ${OUTPUT_FILE} ] && rm ${OUTPUT_FILE}
    # Write color to text color file
    for COLOR in ${COLORS[@]}; do
        echo ${COLOR} >> ${OUTPUT_FILE}
    done
done
