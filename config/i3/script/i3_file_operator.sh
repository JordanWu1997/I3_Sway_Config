#!/usr/bin/env bash

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Datetime    : 2025-02-08 09:33:52
# Description :
###########################################################

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_file_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [open_PDF]: Open PDF with sioyek"
    echo "  [search_PDF]: Search PDF in $HOME/Documents/PAPERS and open one by one"
    echo "  [search_PDF_open_at_once]: Search PDF in $HOME/Documents/PAPERS and open all at once"
    echo "  [search_PDF_in_dir]: Search PDF in input directory and open one by one"
    echo "  [search_PDF_in_dir_open_at_once]: Search PDF in input directory and open all at once"
    echo "  [stop_searching]: Stop searching (kill the process)"
}

# File operation
file_operation () {
    ICON="$HOME/.config/i3/share/64x64/abc.png"
    case $1 in
        'open_PDF')
            FILE=$(xclip -o | rofi -dmenu -i -p 'Open PDF')
            sioyek ${FILE}
            ;;
        'search_PDF')
            $I3_SCRIPT/i3_pdf_keyword_search.sh
            ;;
        'search_PDF_open_at_once')
            $I3_SCRIPT/i3_pdf_keyword_search.sh --all_at_once
            ;;
        'search_PDF_in_dir')
            INPUT_DIR=$(xclip -o | rofi -dmenu -i -p 'Search in Directory')
            : ${INPUT_DIR:=$HOME/Documents/PAPERS}
            $I3_SCRIPT/i3_pdf_keyword_search.sh --dir=${INPUT_DIR}
            ;;
        'search_PDF_in_dir_open_at_once')
            INPUT_DIR=$(xclip -o | rofi -dmenu -i -p 'Search in Diectoryr')
            : ${INPUT_DIR:=$HOME/Documents/PAPERS}
            $I3_SCRIPT/i3_pdf_keyword_search.sh --dir=${INPUT_DIR} --all_at_once
            ;;
        'stop_searching')
            notify-send -u "low" "i3 File" "Stop searching process" --icon="${ICON}"
            $I3_SCRIPT/i3_pdf_keyword_search.sh --kill
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
file_operation $1
