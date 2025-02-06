#!/usr/bin/env bash

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Datetime    : 2024-12-13 14:06:51
# Description : Search PDF file contains specific word and open it
###########################################################

# Resources
# -- https://linuxcommandlibrary.com/man/pdftotext#:~:text=If%20text%2Dfile%20is%20not,text%20is%20sent%20to%20stdout.

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  pdf_keyword_search.sh [options]"
    echo ""
    echo "OPTIONS"
    echo "  --keywords=KEYWORD1,KEYWORD2, -w [REQUIRED] Keywords to search (separated by comma)"
    echo "  --dir=DIR                        Directory to search for PDF files"
    echo "                                   (DEFAULT: $HOME/Documents/PAPERS)"
    echo "  --max_num=MAX_NUM, -n            Maxium number of PDF files to find (DEFAULT: -1)"
    echo "  --viewer=VIEWER                  Specify PDF viewer to use (DEFAULT: zathura)"
    echo "  --all_at_once, -a                Show all matched files at once (DEFAULT: false)"
    echo "  --kill, -k                       Kill searching process"
    echo "  --help, -h                       Show this help message"
}

search_and_open () {
    # Input arguments
    keywords=$1
    input_dir=$2
    max_num=$3
    PDF_viewer=$4
    show_all_at_once=$5

    # Split keywords separated by comma (,)
    IFS=',' read -r -a keywords <<< "$keywords"

    # Loop through pdf files (including files contain space or other special characters)
    count = 0
    find ${input_dir} -iname '*.pdf' -print0 | while IFS= read -r -d '' file; do
        echo [INFO] Scanning ${file} ...

        # Ignore invalid file
        if [[ ! -f $file ]]; then
            continue
        fi

        # Convert pdf to text
        context=$(pdftotext -l 1  -nopgbrk -q -- "${file}" -)

        # Match keyword
        local all_matched=true
        for keyword in "${keywords[@]}"; do
            if  ! $(echo ${context} | grep -i -q "${keyword}"); then
                all_matched=false
                break
            fi
        done

        # If all keywords are matched
        if ${all_matched}; then
            echo [INFO] ${keywords[@]} are all found in ${file} ...
            echo [INFO] Opening ${SEARCH_TEXT} ...

            # Open file with sioyek
            i3-msg layout stacking
            if ${show_all_at_once}; then
                $PDF_viewer ${file} &
            else
                $PDF_viewer ${file}
            fi

            # Update count
            count=$(expr ${count} + 1)

            # Break if count reaches maximum
            if [[ ${max_num} -ge 1 ]] && [[ ${count} -ge ${max_num} ]]; then
                echo [INFO] ${count} results are found ...
                break
            fi
        fi

    done
}

# Main
main () {

    # Parse input arguments
    while [[ $# -gt 0 ]]; do

        case "$1" in
            --dir=*)
                INPUT_DIR="${1#*=}"
                shift
                ;;
            --keywords=*|-w=*)
                KEYWORDS="${1#*=}"
                shift
                ;;
            --max_num=*|-n=*)
                MAX_NUM="${1#*=}"
                shift
                ;;
            --viewer=*)
                PDF_VIEWER="${1#*=}"
                shift
                ;;
            --all_at_once|-a)
                SHOW_ALL_AT_ONCE=true
                shift
                ;;
            --kill|-k)
                kill $(pgrep bash -a | grep pdf_keyword_search | cut -d' ' -f1)
                exit
                ;;
            --help|-h)
                show_help_message
                exit
                ;;
            *)
                show_wrong_usage_message
                echo
                show_help_message
                exit
        esac

    done

    # Early stop
    if [[ -z ${KEYWORDS} ]]; then
        echo '[ERROR] No keyword is provided ... Quitting ...'
        echo
        show_help_message
        exit
    fi

    # Assign default value
    : ${INPUT_DIR:=$HOME/Documents/PAPERS}
    : ${MAX_NUM:=-1}
    : ${PDF_VIEWER:=zathura}
    : ${SHOW_ALL_AT_ONCE:=false}

    # Check if pdftotext is installed
    if [[ ! $(command -v pdftotext) ]]; then
        echo '[ERROR] Command pdftotext is not found ... Quitting ...'
        echo '[INFO] You should install poppler-utils to provide pdftotext function'
        echo '[INFO] In Ubuntu, try apt install poppler-utils'
        echo '[INFO] In Fedora, try dnf install poppler-utils'
        return
    fi
    # Start searching
    search_and_open ${KEYWORDS} ${INPUT_DIR} ${MAX_NUM} ${PDF_VIEWER} ${SHOW_ALL_AT_ONCE}
}

# Main
main $@
