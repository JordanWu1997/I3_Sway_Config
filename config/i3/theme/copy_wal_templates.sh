#!/usr/bin/env bash

PYWAL_DIR="$HOME/Desktop/pywal-3.3.0/pywal/colorschemes/dark"
echo Pywal Colorscheme Sources: $PYWAL_DIR

JSON_FILES=$(ls ${PYWAL_DIR})
for JSON_FILE in ${JSON_FILES[@]}; do
    TEMPLATE=$(basename $JSON_FILE .json)
    echo $TEMPLATE, $JSON_FILE
    # Read color from json file
    for i in {0..15}; do
        COLOR=$(cat ${PYWAL_DIR}/${JSON_FILE} | jq '.colors' | jq ".color${i}")
        COLORS[$i]=${COLOR}
    done
    # Create output directory
    OUTPUT_DIR="./templates/${TEMPLATE}"
    OUTPUT_FILE=${OUTPUT_DIR}/${TEMPLATE}_colors
    [ ! -d ${OUTPUT_DIR} ] && mkdir ${OUTPUT_DIR}
    [ -f ${OUTPUT_FILE} ] && rm ${OUTPUT_FILE}
    # Write color to text color file
    for COLOR in ${COLORS[@]}; do
        echo ${COLOR} >> ${OUTPUT_FILE}
    done
done
