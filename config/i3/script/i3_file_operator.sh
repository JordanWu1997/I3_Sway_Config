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
    echo "  [search_PDF]: Search PDF in $HOME/Documents/PAPERS and show results"
    echo "  [search_PDF_open_at_once]: Search PDF in $HOME/Documents/PAPERS and open all at once"
    echo "  [search_PDF_in_dir]: Search PDF in a chosen directory and show results"
    echo "  [search_PDF_in_dir_open_at_once]: Search PDF in input directory and open all at once"
    echo "  [stop_searching]: Stop searching (kill the process)"
}

# File operation
file_operation () {
    local omnisearch
    omnisearch="$(dirname -- "${BASH_SOURCE[0]}")/i3_rofi_omnisearch.sh"
    case $1 in
        'open_PDF')
            exec "$omnisearch" --pdf-open
            ;;
        'search_PDF')
            exec "$omnisearch" --pdf-search-default
            ;;
        'search_PDF_open_at_once')
            exec "$omnisearch" --pdf-search-all
            ;;
        'search_PDF_in_dir')
            exec "$omnisearch" --pdf-search-dir
            ;;
        'search_PDF_in_dir_open_at_once')
            exec "$omnisearch" --pdf-search-dir-all
            ;;
        'stop_searching')
            exec "$omnisearch" --pdf-cancel
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
file_operation "$1"
