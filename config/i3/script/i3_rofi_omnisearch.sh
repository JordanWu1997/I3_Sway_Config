#!/usr/bin/env bash
# vim: set fileencoding=utf-8

set -o pipefail

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Description : Rofi omnisearch / command palette
###########################################################

# Requirements:
#   rofi fd/fdfind ripgrep pdfgrep sqlite3 jq wmctrl xclip git neovim poppler-utils
#
# Optional:
#   notify-send xdg-open parcellite i3-msg

# Installation:
#   apt install fdfind ripgrep pdfgrep sqlite jq wmctrl xclip git neovim poppler-utils
#   apt install notify-send parcellite

# ============================================================
# Configuration
# ============================================================

ROFI_OPTION=(
    -config "$HOME/.config/rofi/config_omnisearch.rasi"
)
TERMINAL="${TERMINAL:-kitty}"
DOCUMENT_DIR="$HOME/Documents"
HISTORY="$HOME/.config/BraveSoftware/Brave-Browser/Default/History"
BOOKMARK="$HOME/.config/BraveSoftware/Brave-Browser/Default/Bookmarks"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-omnisearch"
LAST_DIR_FILE="$CACHE_DIR/last_dir"

mkdir -p "$CACHE_DIR"

# ============================================================
# Generic helpers
# ============================================================

rofi_menu() {
    local prompt="$1"
    shift

    rofi -dmenu \
        -p "$prompt" \
        -i \
        "${ROFI_OPTION[@]}" \
        "$@"
}

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -t 1500 "Rofi Omnisearch" "$1"
}

cancel_pdf_search() {
    local pid_file="$CACHE_DIR/pdfgrep-search.pid"
    local pid

    if [[ ! -s "$pid_file" ]]; then
        rm -f "$pid_file"
        notify "No PDF search is running"
        return 0
    fi

    pid=$(<"$pid_file")

    if [[ ! "$pid" =~ ^[0-9]+$ ]] ||
       ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$pid_file"
        notify "No PDF search is running"
        return 0
    fi

    # Stop children first (such as the currently running pdfgrep),
    # then stop the worker shell itself.
    if command -v pkill >/dev/null 2>&1; then
        pkill -TERM -P "$pid" 2>/dev/null || true
    fi

    kill -TERM "$pid" 2>/dev/null || true

    # Give the worker a brief chance to exit cleanly.
    for _ in {1..10}; do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.1
    done

    # Escalate only if it is still alive.
    if kill -0 "$pid" 2>/dev/null; then
        if command -v pkill >/dev/null 2>&1; then
            pkill -KILL -P "$pid" 2>/dev/null || true
        fi
        kill -KILL "$pid" 2>/dev/null || true
    fi

    rm -f "$pid_file"
    notify "PDF search cancelled"
}

copy_text() {
    local text="$1"

    if command -v xclip >/dev/null 2>&1; then
        printf '%s' "$text" | xclip -selection clipboard
        printf '%s' "$text" | xclip -selection primary
        notify "Copied to clipboard"
    else
        notify "xclip is not installed"
    fi
}

copy_lines() {
    local lines="$1"

    [[ -n "$lines" ]] || return 0
    copy_text "$lines"
}

# Convert a list of selected lines into a Bash array.
read_selected_lines() {
    local data="$1"
    local -n output="$2"

    output=()

    while IFS= read -r line; do
        [[ -n "$line" ]] && output+=("$line")
    done <<< "$data"
}

# ============================================================
# Universal action system
# ============================================================

action_menu() {
    local type="$1"

    case "$type" in
        file|document)
            printf '%s\n' \
                "Preview (Rofi)" \
                "Preview (Less)" \
                "Open" \
                "Edit in Neovim" \
                "Open in terminal" \
                "Open containing directory" \
                "Copy path"
            ;;
        grep)
            printf '%s\n' \
                "Preview file (Rofi)" \
                "Preview file (Less)" \
                "Open at match" \
                "Open file" \
                "Open containing directory" \
                "Copy file:line" \
                "Copy file path"
            ;;
        git)
            printf '%s\n' \
                "Edit in Neovim" \
                "Show Git diff" \
                "Open containing directory" \
                "Copy path"
            ;;
        pdf)
            printf '%s\n' \
                "Preview match" \
                "Preview file (Rofi)" \
                "Preview file (Less)" \
                "Open PDF" \
                "Open containing directory" \
                "Copy PDF path" \
                "Copy PDF:page"
            ;;
        url)
            printf '%s\n' \
                "Open" \
                "Copy URL"
            ;;
        ssh)
            printf '%s\n' \
                "Connect" \
                "Copy host"
            ;;
        *)
            return 1
            ;;
    esac
}

select_action() {
    local type="$1"
    local action

    action=$(action_menu "$type" | rofi_menu "Action")
    [[ -n "$action" ]] || return 1

    printf '%s\n' "$action"
}

run_file_action() {
    local action="$1"
    shift
    local files=("$@")

    (( ${#files[@]} > 0 )) || return 0

    case "$action" in
        "Preview (Rofi)")
            local file
            for file in "${files[@]}"; do
                if [[ "${file,,}" == *.pdf ]]; then
                    pdftotext "$file" - | rofi_menu "PDF Content"
                else
                    cat "$file" | rofi_menu "File Content"
                fi
            done
            ;;
        "Preview (Less)")
            local file
            for file in "${files[@]}"; do
                if [[ "${file,,}" == *.pdf ]]; then
                    "$TERMINAL" -e bash -c 'pdftotext "$1" - | less' _ "$file"
                else
                    "$TERMINAL" -e less "$file"
                fi
            done
            ;;
        "Open")
            xdg-open "${files[@]}"
            ;;
        "Edit in Neovim")
            "$TERMINAL" -e nvim "${files[@]}"
            ;;
        "Open in terminal")
            local file
            for file in "${files[@]}"; do
                "$TERMINAL" --directory "$(dirname "$file")" &
            done
            ;;
        "Open containing directory")
            local dir
            for dir in "${files[@]}"; do
                xdg-open "$(dirname "$dir")"
            done
            ;;
        "Copy path")
            printf '%s\n' "${files[@]}" | copy_lines "$(cat)"
            ;;
    esac
}

run_grep_action() {
    local action="$1"
    shift
    local files=()
    local lines=()
    local locations=()
    local item file line

    for item in "$@"; do
        IFS=$'\t' read -r file line <<< "$item"
        [[ -n "$file" ]] || continue
        files+=("$file")
        lines+=("$line")
        locations+=("$file:$line")
    done

    (( ${#files[@]} > 0 )) || return 0

    case "$action" in
        "Preview file (Rofi)")
            local f
            for f in "${files[@]}"; do
                if [[ "${f,,}" == *.pdf ]]; then
                    pdftotext "$f" - | rofi_menu "PDF Content"
                else
                    cat "$f" | rofi_menu "File Content"
                fi
            done
            ;;
        "Preview file (Less)")
            local f
            for f in "${files[@]}"; do
                if [[ "${f,,}" == *.pdf ]]; then
                    "$TERMINAL" -e bash -c 'pdftotext "$1" - | less' _ "$f"
                else
                    "$TERMINAL" -e less "$f"
                fi
            done
            ;;
        "Open at match")
            local nvim_args=()
            local i
            for i in "${!files[@]}"; do
                nvim_args+=("+${lines[$i]}" "${files[$i]}")
            done
            "$TERMINAL" -e nvim "${nvim_args[@]}"
            ;;
        "Open file")
            "$TERMINAL" -e nvim "${files[@]}"
            ;;
        "Open containing directory")
            local dir
            for dir in "${files[@]}"; do
                xdg-open "$(dirname "$dir")"
            done
            ;;
        "Copy file:line")
            printf '%s\n' "${locations[@]}" | copy_lines "$(cat)"
            ;;
        "Copy file path")
            printf '%s\n' "${files[@]}" | copy_lines "$(cat)"
            ;;
    esac
}

run_git_action() {
    local action="$1"
    local root="$2"
    shift 2
    local files=("$@")

    (( ${#files[@]} > 0 )) || return 0

    case "$action" in
        "Edit in Neovim")
            "$TERMINAL" -e nvim "${files[@]}"
            ;;
        "Show Git diff")
            "$TERMINAL" -e bash -lc \
                'git -C "$1" diff -- "${@:2}"; printf "\nPress Enter to close..."; read -r' \
                bash "$root" "${files[@]}"
            ;;
        "Open containing directory")
            local file
            for file in "${files[@]}"; do
                xdg-open "$(dirname "$file")"
            done
            ;;
        "Copy path")
            printf '%s\n' "${files[@]}" | copy_lines "$(cat)"
            ;;
    esac
}

run_pdf_preview() {
    local match="$1"
    local file page content

    [[ "$match" =~ ^(.*):([0-9]+):(.*)$ ]] || {
        notify "Unable to preview selected PDF result"
        return 1
    }

    file="${BASH_REMATCH[1]}"
    page="${BASH_REMATCH[2]}"
    content="${BASH_REMATCH[3]}"

    rofi \
        -e "$(printf 'PDF: %s\nPage: %s\n\n%s' \
            "$file" "$page" "$content")" \
        "${ROFI_OPTION[@]}"
}

run_pdf_action() {
    local action="$1"
    shift

    local pdfs=()
    local locations=()
    local item file page

    for item in "$@"; do
        IFS=$'\t' read -r file page <<< "$item"
        [[ -n "$file" ]] || continue
        pdfs+=("$file")
        locations+=("$file:$page")
    done

    (( ${#pdfs[@]} > 0 )) || return 0

    case "$action" in
        "Preview file (Rofi)")
            local f
            for f in "${pdfs[@]}"; do
                pdftotext "$f" - | rofi_menu "PDF Content"
            done
            ;;
        "Preview file (Less)")
            local f
            for f in "${pdfs[@]}"; do
                "$TERMINAL" -e bash -c 'pdftotext "$1" - | less' _ "$f"
            done
            ;;
        "Open PDF")
            xdg-open "${pdfs[@]}"
            ;;
        "Open containing directory")
            local dir
            declare -A seen_dirs=()

            for file in "${pdfs[@]}"; do
                dir="$(dirname "$file")"
                [[ -n "${seen_dirs[$dir]}" ]] && continue
                seen_dirs[$dir]=1
                xdg-open "$dir"
            done
            ;;
        "Copy PDF path")
            copy_lines "$(printf '%s\n' "${pdfs[@]}")"
            ;;
        "Copy PDF:page")
            copy_lines "$(printf '%s\n' "${locations[@]}")"
            ;;
    esac
}

run_url_action() {
    local action="$1"
    shift
    local urls=("$@")

    (( ${#urls[@]} > 0 )) || return 0

    case "$action" in
        "Open")
            local url
            for url in "${urls[@]}"; do
                xdg-open "$url"
            done
            ;;
        "Copy URL")
            printf '%s\n' "${urls[@]}" | copy_lines "$(cat)"
            ;;
    esac
}

run_ssh_action() {
    local action="$1"
    shift
    local hosts=("$@")

    (( ${#hosts[@]} > 0 )) || return 0

    case "$action" in
        "Connect")
            local host
            for host in "${hosts[@]}"; do
                "$TERMINAL" -e ssh "$host" &
            done
            ;;
        "Copy host")
            printf '%s\n' "${hosts[@]}" | copy_lines "$(cat)"
            ;;
    esac
}

# ============================================================
# Directory helpers
# ============================================================

select_directory() {
    local choice
    local last_dir=""

    [[ -f "$LAST_DIR_FILE" ]] &&
        last_dir=$(<"$LAST_DIR_FILE")

    choice=$(
        {
            [[ -n "$last_dir" && -d "$last_dir" ]] &&
                printf '🕒 Last used │ %s\n' "$last_dir"

            printf '🏠 Home │ %s\n' "$HOME"

            [[ -d "$HOME/Documents" ]] &&
                printf '📝 Documents │ %s\n' "$HOME/Documents"

            [[ -d "$HOME/Downloads" ]] &&
                printf '⬇️ Downloads │ %s\n' "$HOME/Downloads"

            [[ -d "$HOME/Projects" ]] &&
                printf '💻 Projects │ %s\n' "$HOME/Projects"

            printf '⌨️ Custom path\n'
        } |
        rofi_menu "Search directory"
    )

    [[ -n "$choice" ]] || return 1

    if [[ "$choice" == "⌨️ Custom path" ]]; then
        choice=$(rofi_menu "Custom directory (empty for ~)") || return 1
        choice=${choice:-~}
        choice="${choice/#\~/$HOME}"
    else
        choice="${choice##* │ }"
    fi

    [[ -d "$choice" ]] || {
        notify "Directory does not exist: $choice"
        return 1
    }

    printf '%s' "$choice" > "$LAST_DIR_FILE"
    printf '%s\n' "$choice"
}

# ============================================================
# Display helpers
# ============================================================

shorten_paths() {
    awk -v home="$HOME" '{
        orig = $0
        display = $0
        sub(home, "~", display)

        n = split(display, parts, "/")
        short = parts[1]

        for (i = 2; i < n; i++)
            if (parts[i] != "")
                short = short "/" substr(parts[i], 1, 1)

        if (n > 1)
            short = short "/" parts[n]

        print short " │ " orig
    }'
}

build_grep_rows() {
    awk -F '\t' -v home="$HOME" '
    {
        file = $1
        line = $2
        content = $3

        # Truncate long lines (like base64) to prevent Rofi freezes
        if (length(content) > 500) {
            content = substr(content, 1, 500) "..."
        }

        display = file
        sub(home, "~", display)

        n = split(display, parts, "/")
        short = parts[1]

        for (i = 2; i < n; i++)
            if (parts[i] != "")
                short = short "/" substr(parts[i], 1, 1)

        if (n > 1)
            short = short "/" parts[n]

        print short ":" line ": " content
    }'
}

# ============================================================
# Main mode selector
# ============================================================

#"📦 Git Modified" \
MODE=$(
    printf '%s\n' \
        "🔍 Grep" \
        "📁 Files" \
        "📝 Documents" \
        "📕 PDF Content" \
        "🛑 Cancel PDF Search" \
        "🕒 Recent" \
        "🌐 History" \
        "🔖 Bookmarks" \
        "📋 Clipboard" \
        "🪟 Windows" \
        "🏷️ Marks" \
        "🖥️ SSH" \
        "⌨️ Keybindings" \
        "💀 Kill" |
    rofi_menu "Search" -auto-select
)

[[ -n "$MODE" ]] || exit 0

# ============================================================
# Modes
# ============================================================

case "$MODE" in

    *Files*)
        TARGET_DIR=$(select_directory) || exit 0

        notify "Searching files in $TARGET_DIR..."
        RESULTS=$(fdfind --type f "" "$TARGET_DIR" | shorten_paths)

        [[ -n "$RESULTS" ]] || { notify "No files found in $TARGET_DIR"; exit 0; }

        LAST_SELECTION=""
        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$RESULTS" | rofi_menu "Files" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done
        ;;

    *Grep*)
        QUERY=$(rofi_menu "Grep for")
        [[ -n "$QUERY" ]] || exit 0

        TARGET_DIR=$(select_directory) || exit 0

        notify "Searching for '$QUERY' in $TARGET_DIR..."

        GREP_RESULTS=$(mktemp)
        trap 'rm -f "$GREP_RESULTS"' EXIT

        # Added --max-columns=500 to prevent ripgrep from returning massive base64 blocks
        rg \
            --line-number \
            --no-heading \
            --color=never \
            --field-match-separator $'\t' \
            --smart-case \
            --max-filesize 10M \
            --no-binary \
            --max-columns=500 \
            "$QUERY" \
            "$TARGET_DIR" > "$GREP_RESULTS"

        [[ -s "$GREP_RESULTS" ]] || {
            notify "No matches found"
            exit 0
        }

        DISPLAY_ROWS=$(build_grep_rows < "$GREP_RESULTS")
        LAST_SELECTION=""

        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$DISPLAY_ROWS" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action grep) || continue

            GREP_ITEMS=()
            while IFS= read -r row_text; do
                [[ -z "$row_text" ]] && continue

                # Identify original index to extract raw match data
                INDEX=$(printf '%s\n' "$DISPLAY_ROWS" | grep -nF -m 1 "$row_text" | cut -d: -f1)
                [[ -n "$INDEX" ]] || continue

                MATCH=$(sed -n "${INDEX}p" "$GREP_RESULTS")
                FILE="${MATCH%%$'\t'*}"
                REST="${MATCH#*$'\t'}"
                LINE="${REST%%$'\t'*}"

                [[ -n "$FILE" && -n "$LINE" ]] && GREP_ITEMS+=("$FILE"$'\t'"$LINE")
            done <<< "$SELECTED"

            run_grep_action "$ACTION" "${GREP_ITEMS[@]}"
        done
        ;;

    *Documents*)
        notify "Searching for Markdown documents..."
        RESULTS=$(fdfind --type f --extension md . "$DOCUMENT_DIR" | shorten_paths)

        [[ -n "$RESULTS" ]] || { notify "No documents found"; exit 0; }

        LAST_SELECTION=""
        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$RESULTS" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done
        ;;

    *Cancel\ PDF\ Search*)
        cancel_pdf_search
        ;;

    *PDF\ Content*)
        DEBUG_LOG="$CACHE_DIR/pdfgrep-debug.log"
        PDF_PID_FILE="$CACHE_DIR/pdfgrep-search.pid"

        # Remove a stale PID file left by an interrupted previous run.
        if [[ -s "$PDF_PID_FILE" ]]; then
            OLD_PDF_PID=$(<"$PDF_PID_FILE")
            if [[ ! "$OLD_PDF_PID" =~ ^[0-9]+$ ]] ||
               ! kill -0 "$OLD_PDF_PID" 2>/dev/null; then
                rm -f "$PDF_PID_FILE"
            fi
        fi

        log_pdf_debug() {
            printf '[%(%F %T)T] %s\n' -1 "$*" >> "$DEBUG_LOG"
        }

        : > "$DEBUG_LOG"
        log_pdf_debug "===== PDF search started ====="

        command -v pdfgrep >/dev/null 2>&1 || {
            notify "pdfgrep is not installed"
            log_pdf_debug "ERROR: pdfgrep not found"
            exit 0
        }

        QUERY=$(rofi_menu "Search PDF content")
        [[ -n "$QUERY" ]] || exit 0

        read -r -a KEYWORDS <<< "$QUERY"
        (( ${#KEYWORDS[@]} > 0 )) || exit 0

        TARGET_DIR=$(select_directory) || exit 0

        notify "Preparing PDF search in $TARGET_DIR..."

        PDF_WORK_DIR=$(mktemp -d)
        PDF_RESULTS="$PDF_WORK_DIR/results"
        PDF_MATCHING_FILES="$PDF_WORK_DIR/matching-files"
        PDF_PROGRESS_FILE="$PDF_WORK_DIR/progress"
        PDF_CANCEL_FILE="$PDF_WORK_DIR/cancel"

        cleanup_pdf_search() {
            rm -f "$PDF_PID_FILE"
            rm -rf "$PDF_WORK_DIR"
        }

        PDF_COUNT=$(
            fdfind \
                --type f \
                --extension pdf \
                . "$TARGET_DIR" \
                2>> "$DEBUG_LOG" |
            wc -l
        )

        log_pdf_debug "Query: $QUERY"
        log_pdf_debug "Keywords: ${KEYWORDS[*]}"
        log_pdf_debug "Directory: $TARGET_DIR"
        log_pdf_debug "PDF files found: $PDF_COUNT"

        if (( PDF_COUNT == 0 )); then
            cleanup_pdf_search
            notify "No PDF files found"
            exit 0
        fi

        notify "Found $PDF_COUNT PDF file(s), starting search..."

        (
            CURRENT=0
            : > "$PDF_MATCHING_FILES"
            : > "$PDF_RESULTS"

            fdfind \
                --type f \
                --extension pdf \
                -0 \
                . "$TARGET_DIR" \
                2>> "$DEBUG_LOG" |
            while IFS= read -r -d '' PDF_FILE; do
                [[ -e "$PDF_CANCEL_FILE" ]] && exit 130

                CURRENT=$((CURRENT + 1))
                printf '%s/%s|%s\n' \
                    "$CURRENT" \
                    "$PDF_COUNT" \
                    "$PDF_FILE" \
                    > "$PDF_PROGRESS_FILE"

                MATCHES_ALL=1

                for KEYWORD in "${KEYWORDS[@]}"; do
                    if ! pdfgrep \
                        --ignore-case \
                        -- "$KEYWORD" "$PDF_FILE" \
                        >/dev/null 2>> "$DEBUG_LOG"; then
                        MATCHES_ALL=0
                        break
                    fi

                    [[ -e "$PDF_CANCEL_FILE" ]] && exit 130
                done

                (( MATCHES_ALL == 1 )) &&
                    printf '%s\n' "$PDF_FILE" >> "$PDF_MATCHING_FILES"
            done

            [[ -e "$PDF_CANCEL_FILE" ]] && exit 130

            MATCHING_PDF_COUNT=$(wc -l < "$PDF_MATCHING_FILES")
            printf 'results|%s\n' "$MATCHING_PDF_COUNT" > "$PDF_PROGRESS_FILE"

            (( MATCHING_PDF_COUNT > 0 )) || exit 0

            while IFS= read -r PDF_FILE; do
                [[ -n "$PDF_FILE" ]] || continue
                [[ -e "$PDF_CANCEL_FILE" ]] && exit 130

                for KEYWORD in "${KEYWORDS[@]}"; do
                    pdfgrep \
                        --ignore-case \
                        --page-number \
                        --with-filename \
                        -- "$KEYWORD" "$PDF_FILE" \
                        2>> "$DEBUG_LOG"
                done
            done < "$PDF_MATCHING_FILES" |
                sort -u > "$PDF_RESULTS"

            [[ -e "$PDF_CANCEL_FILE" ]] && exit 130

            printf 'done\n' > "$PDF_PROGRESS_FILE"
        ) &

        PDF_WORKER_PID=$!
        printf '%s\n' "$PDF_WORKER_PID" > "$PDF_PID_FILE"

        (
            while kill -0 "$PDF_WORKER_PID" 2>/dev/null; do
                sleep 0.5
                PROGRESS="$(cat "$PDF_PROGRESS_FILE" 2>/dev/null)"

                case "$PROGRESS" in
                    [0-9]*/*\|*)
                        CURRENT="${PROGRESS%%/*}"
                        REST="${PROGRESS#*/}"
                        TOTAL="${REST%%|*}"
                        PERCENT=$((CURRENT * 100 / TOTAL))

                        if (( PERCENT % 10 == 0 )); then
                            notify "PDF search: $CURRENT / $TOTAL ($PERCENT%)"
                        fi
                        ;;
                esac
            done
        ) &
        PDF_PROGRESS_MONITOR_PID=$!

        wait "$PDF_WORKER_PID"
        PDF_STATUS=$?

        kill "$PDF_PROGRESS_MONITOR_PID" 2>/dev/null
        wait "$PDF_PROGRESS_MONITOR_PID" 2>/dev/null

        if (( PDF_STATUS == 130 )); then
            cleanup_pdf_search
            notify "PDF search cancelled"
            exit 0
        fi

        if (( PDF_STATUS > 1 )); then
            cleanup_pdf_search
            notify "PDF search failed — check debug log"
            exit 0
        fi

        MATCHING_PDF_COUNT=$(wc -l < "$PDF_MATCHING_FILES")
        MATCH_COUNT=$(wc -l < "$PDF_RESULTS")

        log_pdf_debug "PDFs containing all keywords: $MATCHING_PDF_COUNT"
        log_pdf_debug "Matching result lines: $MATCH_COUNT"

        if (( MATCHING_PDF_COUNT == 0 )); then
            cleanup_pdf_search
            notify "No PDF contains all ${#KEYWORDS[@]} keyword(s)"
            exit 0
        fi

        if (( MATCH_COUNT == 0 )); then
            cleanup_pdf_search
            notify "Matching PDFs found, but no result snippets were generated"
            exit 0
        fi

        notify \
            "$MATCHING_PDF_COUNT PDF(s), $MATCH_COUNT match(es) found"

        PDF_DISPLAY=$(
            awk -v home="$HOME" '
            {
                line = $0

                content = line
                sub(/^.*:[0-9]+:/, "", content)

                # Truncate to prevent Rofi freezes on massive strings
                if (length(content) > 500) {
                    content = substr(content, 1, 500) "..."
                }

                prefix = line
                sub(/:[^:]*$/, "", prefix)

                page = prefix
                sub(/^.*:/, "", page)

                file = prefix
                sub(/:[0-9]+$/, "", file)

                if (file == "" || page == "")
                    next

                display = file
                sub(home, "~", display)

                n = split(display, path_parts, "/")
                short = path_parts[1]

                for (i = 2; i < n; i++) {
                    if (path_parts[i] != "")
                        short = short "/" substr(path_parts[i], 1, 1)
                }

                if (n > 1)
                    short = short "/" path_parts[n]

                print short ":p" page ": " content
            }
            ' "$PDF_RESULTS"
        )

        DISPLAY_COUNT=$(printf '%s\n' "$PDF_DISPLAY" | grep -c .)

        if (( DISPLAY_COUNT == 0 )); then
            cleanup_pdf_search
            notify "PDF matches found, but display parsing failed"
            exit 0
        fi

        LAST_SELECTION=""
        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$PDF_DISPLAY" | rofi_menu "PDF Content ($MATCHING_PDF_COUNT PDFs)" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action pdf) || continue

            if [[ "$ACTION" == "Preview match" ]]; then
                INDEX=$(printf '%s\n' "$PDF_DISPLAY" | grep -nF -m 1 "$LAST_SELECTION" | cut -d: -f1)
                if [[ -n "$INDEX" ]]; then
                    FIRST_MATCH=$(sed -n "${INDEX}p" "$PDF_RESULTS")
                    run_pdf_preview "$FIRST_MATCH"
                else
                    notify "Unable to determine preview selection"
                fi
                continue
            fi

            PDF_ITEMS=()
            while IFS= read -r row_text; do
                [[ -z "$row_text" ]] && continue

                INDEX=$(printf '%s\n' "$PDF_DISPLAY" | grep -nF -m 1 "$row_text" | cut -d: -f1)
                [[ -n "$INDEX" ]] || continue

                MATCH=$(sed -n "${INDEX}p" "$PDF_RESULTS")
                if [[ "$MATCH" =~ ^(.*):([0-9]+):(.*)$ ]]; then
                    FILE="${BASH_REMATCH[1]}"
                    PAGE="${BASH_REMATCH[2]}"
                    [[ -n "$FILE" && -n "$PAGE" ]] && PDF_ITEMS+=("$FILE"$'\t'"$PAGE")
                else
                    log_pdf_debug "Failed to parse selected result: $MATCH"
                fi
            done <<< "$SELECTED"

            if (( ${#PDF_ITEMS[@]} == 0 )); then
                notify "Failed to parse selected PDF results"
                continue
            fi

            run_pdf_action "$ACTION" "${PDF_ITEMS[@]}"
        done

        cleanup_pdf_search
        ;;

    *Recent*)
        notify "Loading recent files..."
        SELECTED=$(
            nvim --headless \
                +'lua for _, f in ipairs(vim.v.oldfiles) do if vim.fn.filereadable(f) == 1 then print(f) end end' \
                +qa 2>/dev/null |
            awk 'NF && !seen[$0]++' |
            shorten_paths |
            rofi_menu "Recent files" -multi-select
        )

        [[ -n "$SELECTED" ]] || exit 0

        ACTION=$(select_action file) || exit 0

        FILES=()
        while IFS= read -r row; do
            FILE="${row##* │ }"
            [[ -n "$FILE" ]] && FILES+=("$FILE")
        done <<< "$SELECTED"

        run_file_action "$ACTION" "${FILES[@]}"
        ;;

    *Git\ Modified*)
        TARGET_DIR=$(select_directory) || exit 0

        git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
            notify "Not a Git repository"
            exit 0
        }

        notify "Scanning Git repository..."

        GIT_ROOT=$(git -C "$TARGET_DIR" rev-parse --show-toplevel)

        SELECTED=$(
            git -C "$GIT_ROOT" status --short |
            awk '{print substr($0, 4)}' |
            rofi_menu "Git modified files" -multi-select
        )

        [[ -n "$SELECTED" ]] || exit 0

        ACTION=$(select_action git) || exit 0

        FILES=()
        while IFS= read -r file; do
            [[ -n "$file" ]] && FILES+=("$GIT_ROOT/$file")
        done <<< "$SELECTED"

        run_git_action "$ACTION" "$GIT_ROOT" "${FILES[@]}"
        ;;

    *History*)
        [[ -f "$HISTORY" ]] || {
            notify "Brave history database not found"
            exit 0
        }

        notify "Loading browser history..."

        HISTORY_COPY=$(mktemp)
        trap 'rm -f "$HISTORY_COPY"' EXIT
        cp "$HISTORY" "$HISTORY_COPY"

        HISTORY_DATA=$(
            sqlite3 -separator $'\t' "$HISTORY_COPY" \
                "SELECT url, COALESCE(REPLACE(REPLACE(title, char(10), ' '), char(13), ' '), url)
                 FROM urls
                 ORDER BY last_visit_time DESC
                 LIMIT 1000" |
            awk -F'\t' '!seen[$2]++'
        )

        [[ -n "$HISTORY_DATA" ]] || exit 0

        LAST_SELECTION=""
        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$HISTORY_DATA" | cut -f2 | rofi_menu "History" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r title; do
                [[ -z "$title" ]] && continue
                URL=$(printf '%s\n' "$HISTORY_DATA" | awk -F'\t' -v t="$title" '$2 == t {print $1; exit}')
                [[ -n "$URL" ]] && URLS+=("$URL")
            done <<< "$SELECTED"

            run_url_action "$ACTION" "${URLS[@]}"
        done
        ;;

    *Bookmarks*)
        [[ -f "$BOOKMARK" ]] || {
            notify "Brave bookmarks file not found"
            exit 0
        }

        notify "Loading bookmarks..."

        BMARK_DATA=$(
            jq -r '
                .. | objects | select(.url != null) |
                "\(.url)\t\((.name // "Untitled") | gsub("\n"; " "))"
            ' "$BOOKMARK" |
            awk -F'\t' '!seen[$2]++'
        )

        [[ -n "$BMARK_DATA" ]] || exit 0

        LAST_SELECTION=""
        while true; do
            ROFI_ARGS=("-multi-select")
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")

            SELECTED=$(printf '%s\n' "$BMARK_DATA" | cut -f2 | rofi_menu "Bookmarks" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || break

            LAST_SELECTION="${SELECTED%%$'\n'*}"
            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r title; do
                [[ -z "$title" ]] && continue
                URL=$(printf '%s\n' "$BMARK_DATA" | awk -F'\t' -v t="$title" '$2 == t {print $1; exit}')
                [[ -n "$URL" ]] && URLS+=("$URL")
            done <<< "$SELECTED"

            run_url_action "$ACTION" "${URLS[@]}"
        done
        ;;

    *Clipboard*)
        python3 - <<'PY'
import os
import struct
import subprocess
import sys

history_file = os.path.expanduser("~/.local/share/parcellite/history")
signature = b"1.0ParcelliteHistoryFile"
header_size = 32
record_header_size = 28

def notify(message):
    subprocess.run(["notify-send", "Rofi Omnisearch", message],
                   stdout=subprocess.DEVNULL,
                   stderr=subprocess.DEVNULL)

try:
    with open(history_file, "rb") as f:
        data = f.read()
except FileNotFoundError:
    notify("Parcellite history file not found")
    sys.exit(1)

if not data.startswith(signature):
    notify("Unknown Parcellite history format")
    sys.exit(1)

entries = []
offset = header_size

while offset + record_header_size <= len(data):
    record_size = struct.unpack_from("<I", data, offset)[0]

    if record_size < record_header_size:
        break

    record_end = offset + record_size
    if record_end > len(data):
        break

    raw_text = data[offset + record_header_size:record_end].rstrip(b"\x00")

    try:
        text = raw_text.decode("utf-8")
    except UnicodeDecodeError:
        text = raw_text.decode("utf-8", errors="replace")

    if text:
        entries.append(text)

    offset = record_end

if not entries:
    notify("No clipboard history found")
    sys.exit(0)

display_entries = []

for i, text in enumerate(entries):
    display = (
        text
        .replace("\r\n", "\n")
        .replace("\r", "\n")
        .replace("\n", " ↵ ")
    )

    if len(display) > 400:
        display = display[:400] + " …"

    display_entries.append(f"{i}\t{display}")

result = subprocess.run(
    [
        "rofi",
        "-dmenu",
        "-i",
        "-config",
        os.path.expanduser("~/.config/rofi/config_omnisearch.rasi"),
        "-p",
        "Clipboard",
        "-format",
        "s",
    ],
    input="\n".join(display_entries),
    text=True,
    stdout=subprocess.PIPE,
)

selected = result.stdout.rstrip("\n")
if not selected:
    sys.exit(0)

try:
    index = int(selected.split("\t", 1)[0])
except (ValueError, IndexError):
    sys.exit(0)

clipboard_text = entries[index]
clipboard_bytes = clipboard_text.encode("utf-8")

for selection in ("clipboard", "primary"):
    subprocess.run(
        ["xclip", "-selection", selection],
        input=clipboard_bytes,
    )
PY
        ;;

    *Windows*)
        wmctrl -l |
            rofi_menu "Windows" -auto-select |
            awk '{print $1}' |
            xargs -r -I{} wmctrl -i -a {}
        ;;

    *Marks*)
        i3-msg -t get_tree |
            jq -r '
                recurse(.nodes[], .floating_nodes[]?)
                | select(.marks != null and (.marks | length > 0))
                | . as $node
                | .marks[]
                | [.,
                   ($node.name // $node.window_properties.title // "(untitled)")
                  ]
                | @tsv
            ' |
            rofi_menu "Jump to mark" -auto-select -format s |
            cut -f1 |
            xargs -r -I{} i3-msg '[con_mark="{}"] focus'
        ;;

    *Keybindings*)
        # i3 keybindings hinter
        # -- https://www.reddit.com/r/i3wm/comments/e1x9n6/keybindings_menu_not_dmenurofi/
        i3 $(
            cat ~/.config/i3/config.d/* |
            grep '^bindsym' |
            grep -v '^\s*#' |
            sed 's/bindsym / /' |
            rofi_menu "i3 Keybinds" |
            sed 's/^\s*//' |
            cut -d' ' -f2-
        )
        ;;

    *SSH*)
        SELECTED=$(
            grep -E '^Host ' ~/.ssh/config 2>/dev/null |
            awk '{print $2}' |
            grep -v '[*?!]' |
            rofi_menu "SSH to" -multi-select
        )

        [[ -n "$SELECTED" ]] || exit 0

        ACTION=$(select_action ssh) || exit 0

        HOSTS=()
        while IFS= read -r host; do
            [[ -n "$host" ]] && HOSTS+=("$host")
        done <<< "$SELECTED"

        run_ssh_action "$ACTION" "${HOSTS[@]}"
        ;;

    *Kill*)
        SELECTED_PIDS=$(
            ps axww --no-headers -o pid,cmd |
            rofi_menu "Kill process" -multi-select |
            awk '{print $1}'
        )

        [[ -n "$SELECTED_PIDS" ]] || exit 0

        COUNT=$(printf '%s\n' "$SELECTED_PIDS" | grep -c .)

        SIGNAL=$(
            printf '%s\n' \
                "SIGTERM" \
                "Cancel" \
                "SIGKILL" |
            rofi_menu "Kill $COUNT process(es)" -auto-select
        )

        case "$SIGNAL" in
            SIGTERM)
                printf '%s\n' "$SELECTED_PIDS" | xargs -r kill -TERM
                ;;
            SIGKILL)
                printf '%s\n' "$SELECTED_PIDS" | xargs -r kill -KILL
                ;;
        esac
        ;;
esac
