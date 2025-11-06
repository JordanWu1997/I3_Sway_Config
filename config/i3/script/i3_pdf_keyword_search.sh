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
    echo "  --keywords=KEYWORD1,KEYWORD2, -w Keywords to search (separated by comma)"
    echo "  --dir=DIR, -d                    Directory to search for PDF files"
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

    # Set the PDF viewer name for the kill command logic
    # This might need adjustment if the process name differs from $PDF_VIEWER
    local viewer_pname=$(basename "$PDF_viewer")

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

            # Update count
            count=$(expr ${count} + 1)

            # Switch layout for titlebar
            i3-msg layout stacking

            # Skip the interactive prompt if showing all at once
            if ${show_all_at_once}; then
                echo "[INFO] Opening ${SEARCH_TEXT} ..."
                echo "[INFO] Showing all at once, skipping interactive prompt."
                $PDF_viewer ${file} &
                continue
            fi

            # Open file. Using '&' for background opening for all_at_once or if
            echo [INFO] "Opening ${SEARCH_TEXT} ..."
            $PDF_viewer "${file}" &
            local pdf_pid=$! # Capture the PID of the viewer process

            # The --action flag takes an 'id,label'. The command outputs the chosen 'id'.
            local choice
            choice=$(dunstify \
                --action="keep,Keep Open" \
                --action="close,Close File" \
                --action="end,End Search" \
                --icon="info" \
                --timeout=0 \
                "PDF Found (${count}/${max_num})" \
                "Keywords: ${keywords[@]} found in $(basename "${file}")"
            )

            # Actions
            case "$choice" in
                "keep")
                    echo "[INFO] Keeping file open and continuing search."
                    ;;
                "close")
                    echo "[INFO] Closing file and continuing search."
                    # Kill the specific viewer process for this file
                    kill -TERM $pdf_pid 2>/dev/null
                    ;;
                "end")
                    echo "[INFO] Ending search process."
                    # Kill the specific viewer process for this file and break
                    kill -TERM $pdf_pid 2>/dev/null
                    break # Break out of the while loop
                    ;;
                *)
                    # Default case if the notification times out or is closed without action
                    echo "[INFO] Notification closed without action. Continuing search."
                    ;;
            esac

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
            --dir=*|-d=*)
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

    # Assign default value
    : ${INPUT_DIR:=$HOME/Documents/PAPERS}
    : ${MAX_NUM:=-1}
    : ${PDF_VIEWER:=sioyek}
    : ${SHOW_ALL_AT_ONCE:=false}

    # Switch to interactively mode if there are no provided keywords
    if [[ -z ${KEYWORDS} ]]; then
        echo '[INFO] No keyword is provided ... Switch to interactive mode'
        KEYWORDS=$(rofi -dmenu -p Keyword | tr ' ' ',')
    fi

    # Early Stop
    if [[ -z ${KEYWORDS} ]]; then
        echo '[ERROR] No keyword is provided ... Quitting'
        show_help_message
        exit
    fi

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
