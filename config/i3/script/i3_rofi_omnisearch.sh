#!/usr/bin/env bash
# vim: set fileencoding=utf-8

set -o pipefail

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Description : Rofi omnisearch / command palette
###########################################################

# Requirements:
#   rofi(>=1.7.0) fd/fdfind ripgrep pdfgrep sqlite3 jq wmctrl xclip git neovim poppler-utils
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
RECENT_FILES_CACHE="$CACHE_DIR/recent_files"
PID_FILE="$CACHE_DIR/omnisearch.pids"

mkdir -p "$CACHE_DIR"

# ============================================================
# Global Process Tracking
# ============================================================

# Clean up stale PIDs from previous runs, keep active ones
if [[ -f "$PID_FILE" ]]; then
    ACTIVE_PIDS=$(while IFS= read -r p; do kill -0 "$p" 2>/dev/null && echo "$p"; done < "$PID_FILE")
    [[ -n "$ACTIVE_PIDS" ]] && echo "$ACTIVE_PIDS" > "$PID_FILE" || > "$PID_FILE"
fi

# Register current script instance
echo "$$" >> "$PID_FILE"

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
        notify-send -t 1000 "Rofi Omnisearch" "$1"
}

global_cancel() {
    local count=0
    local pdf_pid_file="$CACHE_DIR/pdfgrep-search.pid"

    # 1. Kill PDF worker if running
    if [[ -s "$pdf_pid_file" ]]; then
        local pdf_pid=$(<"$pdf_pid_file")
        if [[ "$pdf_pid" =~ ^[0-9]+$ ]] && kill -0 "$pdf_pid" 2>/dev/null; then
            pkill -TERM -P "$pdf_pid" 2>/dev/null || true
            kill -TERM "$pdf_pid" 2>/dev/null || true
            ((count++))
        fi
        rm -f "$pdf_pid_file"
    fi

    # 2. Kill other running instances of this script and their children (rg, fd, etc.)
    if [[ -f "$PID_FILE" ]]; then
        while IFS= read -r pid; do
            # Ensure we don't kill the current instance ($$)
            if [[ "$pid" != "$$" && "$pid" =~ ^[0-9]+$ ]] && kill -0 "$pid" 2>/dev/null; then
                pkill -TERM -P "$pid" 2>/dev/null || true
                kill -9 "$pid" 2>/dev/null || true
                ((count++))
            fi
        done < "$PID_FILE"

        # Clear file and re-register ourselves
        > "$PID_FILE"
        echo "$$" >> "$PID_FILE"
    fi

    if (( count > 0 )); then
        notify "Cancelled all active background searches."
    else
        notify "No active searches to cancel."
    fi
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

record_recent_files() {
    local files=("$@")
    (( ${#files[@]} > 0 )) || return 0

    touch "$RECENT_FILES_CACHE"
    local tmp
    tmp=$(mktemp)

    # Push newly selected files to the top
    for f in "${files[@]}"; do
        realpath "$f" 2>/dev/null || echo "$f"
    done > "$tmp"

    # Append existing history
    cat "$RECENT_FILES_CACHE" >> "$tmp" 2>/dev/null || true

    # Keep only unique lines (preserving the most recent order) and limit to 100
    awk '!seen[$0]++' "$tmp" | head -n 100 > "$RECENT_FILES_CACHE"
    rm -f "$tmp"
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

    record_recent_files "${files[@]}"

    case "$action" in
        "Preview (Rofi)")
            local file
            for file in "${files[@]}"; do
                # Limit Rofi content preview to 1000 lines to prevent X11 freeze
                if [[ "${file,,}" == *.pdf ]]; then
                    pdftotext "$file" - | head -n 1000 | rofi_menu "PDF View"
                else
                    head -n 1000 "$file" | rofi_menu "File Content"
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

    record_recent_files "${files[@]}"

    case "$action" in
        "Preview file (Rofi)")
            local f
            for f in "${files[@]}"; do
                if [[ "${f,,}" == *.pdf ]]; then
                    pdftotext "$f" - | head -n 1000 | rofi_menu "PDF View"
                else
                    head -n 1000 "$f" | rofi_menu "File Content"
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

    record_recent_files "${pdfs[@]}"

    case "$action" in
        "Preview file (Rofi)")
            local f
            for f in "${pdfs[@]}"; do
                pdftotext "$f" - | head -n 1000 | rofi_menu "PDF View"
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
        } |
        rofi_menu "Search directory or enter path"
    )

    # Extract path if selected from formatted list, otherwise treat input directly as path
    if [[ "$choice" == *" │ "* ]]; then
        choice="${choice##* │ }"
    fi

    # Expand tilde (handles both manual typing and empty default)
    choice="${choice/#\~/$HOME}"

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

        # Vital for live-streaming Rofi updates
        fflush()
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

        # Vital for live-streaming Rofi updates
        fflush()
    }'
}

# ============================================================
# Main mode selector
# ============================================================

MODE=$(
    printf '%s\n' \
        "🚀 Apps" \
        "🧮 Calculator" \
        "🔍 Grep" \
        "📁 Files" \
        "📝 Documents" \
        "🔍 PDF Fetch" \
        "📖 PDF View" \
        "🕒 Recent Files" \
        "🌐 History" \
        "🔖 Bookmarks" \
        "📋 Clipboard" \
        "🪟 Windows" \
        "🏷️ Marks" \
        "🖥️ SSH" \
        "⌨️ Keybindings" \
        "💀 Kill" \
        "🛑 Cancel" |
    rofi_menu "Search" -auto-select
)

[[ -n "$MODE" ]] || { notify "Omnisearch closed"; exit 0; }

# ============================================================
# Modes
# ============================================================

case "$MODE" in

    *Apps*)
        # Invokes Rofi's native application launcher directly
        rofi -show drun "${ROFI_OPTION[@]}"
        ;;

    *Calculator*)
        EXPR=""
        while true; do
            EXPR=$(echo "" | rofi_menu "Calculate (Enter to evaluate)" -filter "$EXPR")

            # Exit if user presses Escape or submits an empty string
            [[ $? -ne 0 || -z "$EXPR" ]] && { notify "Calculator closed"; break; }

            # Safely evaluate using Python's math module
            RESULT=$(python3 -c "
from math import *
try:
    expr = '''$EXPR'''
    # Basic security check to prevent os.system execution
    if '__' in expr or 'import' in expr or 'os' in expr or 'sys' in expr:
        print('Security Exception')
    else:
        print(eval(expr))
except Exception as e:
    print('Error: Invalid Expression')
" 2>/dev/null)

            # Display the result
            ACTION=$(printf "📋 Copy to clipboard\n🔙 Edit expression" | rofi_menu "= $RESULT")

            # Exit if user presses Escape on the result screen
            [[ $? -ne 0 ]] && { notify "Calculator closed"; break; }

            if [[ "$ACTION" == *Copy* ]]; then
                copy_lines "$RESULT"
                break
            fi
            # If Edit is chosen, the loop natively continues and $EXPR is pre-filled via -filter
        done
        ;;

    # Must be placed before *File*
    *Recent\ Files*)
        [[ -f "$RECENT_FILES_CACHE" ]] || touch "$RECENT_FILES_CACHE"

        # Verify files still exist before displaying them
        VALID_RECENTS=$(while IFS= read -r f; do [[ -f "$f" ]] && echo "$f"; done < "$RECENT_FILES_CACHE")

        if [[ -z "$VALID_RECENTS" ]]; then
            notify "No recent files found in history."
            exit 0
        fi

        # Generate the list OUTSIDE the loop so it remains stable during this session.
        # This guarantees the cursor stays exactly where it was and doesn't jump to row 0.
        RECENT_DISPLAY=$(printf '%s\n' "$VALID_RECENTS" | shorten_paths)

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Pass the raw unescaped string so modern Rofi can match it literally
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(printf '%s\n' "$RECENT_DISPLAY" | rofi_menu "Recent files" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            # Clean formatting and carriage returns to ensure perfect Rofi matching
            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$CLEAN_SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done
        ;;

    *Files*)
        TARGET_DIR=$(select_directory) || { notify "Exited $MODE"; exit 0; }

        notify "🔍 Starting file search in $TARGET_DIR..."

        RESULTS_FILE=$(mktemp)
        trap 'rm -f "$RESULTS_FILE"' EXIT

        # Push to background and stream immediately
        ( fdfind --type f "" "$TARGET_DIR" | shorten_paths > "$RESULTS_FILE" ) &
        SEARCH_PID=$!
        echo "$SEARCH_PID" >> "$PID_FILE"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            # Use a real tab character ($'\t') to separate the typed filter from the result
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Escape regex characters before passing to -select
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            # Stream dynamically if search is still running, otherwise read cache
            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | head -n 5000 | rofi_menu "Files" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(head -n 5000 "$RESULTS_FILE" | rofi_menu "Files" "${ROFI_ARGS[@]}")
            fi

            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            # Safely halt the background search as soon as the user selects a file
            kill "$SEARCH_PID" 2>/dev/null

            # Safely split the tab-separated filter from the result list
            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$CLEAN_SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done

        kill "$SEARCH_PID" 2>/dev/null
        ;;

    *Grep*)
        QUERY=$(rofi_menu "Grep for")
        [[ -n "$QUERY" ]] || { notify "Exited $MODE"; exit 0; }

        TARGET_DIR=$(select_directory) || exit 0

        notify "🔍 Grepping for '$QUERY' in $TARGET_DIR..."

        GREP_RAW=$(mktemp)
        GREP_DISPLAY=$(mktemp)
        trap 'rm -f "$GREP_RAW" "$GREP_DISPLAY"' EXIT

        # Use --line-buffered to force ripgrep to stream lines instantly
        (
            rg \
                --line-buffered \
                --line-number \
                --no-heading \
                --color=never \
                --max-columns=500 \
                --field-match-separator $'\t' \
                --smart-case \
                --max-filesize 10M \
                --no-binary \
                "$QUERY" \
                "$TARGET_DIR" | \
            tee "$GREP_RAW" | build_grep_rows > "$GREP_DISPLAY"
        ) &
        SEARCH_PID=$!
        echo "$SEARCH_PID" >> "$PID_FILE"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Escape regex characters before passing to -select to prevent Rofi crashes
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$GREP_DISPLAY" | head -n 5000 | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(head -n 5000 "$GREP_DISPLAY" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            fi

            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            # Safely halt the background search as soon as the user selects a file
            kill "$SEARCH_PID" 2>/dev/null

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action grep) || continue

            GREP_ITEMS=()
            while IFS= read -r row_text; do
                [[ -z "$row_text" ]] && continue

                # Added -e to handle matched lines that legitimately start with a hyphen
                INDEX=$(cat "$GREP_DISPLAY" | grep -nF -m 1 -e "$row_text" | cut -d: -f1)
                [[ -n "$INDEX" ]] || continue

                MATCH=$(sed -n "${INDEX}p" "$GREP_RAW")
                FILE="${MATCH%%$'\t'*}"
                REST="${MATCH#*$'\t'}"
                LINE="${REST%%$'\t'*}"

                [[ -n "$FILE" && -n "$LINE" ]] && GREP_ITEMS+=("$FILE"$'\t'"$LINE")
            done <<< "$CLEAN_SELECTED"

            run_grep_action "$ACTION" "${GREP_ITEMS[@]}"
        done

        kill "$SEARCH_PID" 2>/dev/null
        ;;

    *Documents*)
        RESULTS_FILE=$(mktemp)
        trap 'rm -f "$RESULTS_FILE"' EXIT

        ( fdfind --type f --extension md . "$DOCUMENT_DIR" | shorten_paths > "$RESULTS_FILE" ) &
        SEARCH_PID=$!
        echo "$SEARCH_PID" >> "$PID_FILE"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Escape regex characters
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | head -n 5000 | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(head -n 5000 "$RESULTS_FILE" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            fi

            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }
            kill "$SEARCH_PID" 2>/dev/null

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$CLEAN_SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done

        kill "$SEARCH_PID" 2>/dev/null
        ;;

    *Cancel*)
        global_cancel
        ;;

    *PDF\ Fetch*)
        command -v pdfgrep >/dev/null 2>&1 || {
            notify "pdfgrep is not installed"
            exit 0
        }

        QUERY=$(rofi_menu "Enter query to fetch")
        [[ -n "$QUERY" ]] || exit 0

        read -r -a KEYWORDS <<< "$QUERY"
        (( ${#KEYWORDS[@]} > 0 )) || exit 0

        TARGET_DIR=$(select_directory) || exit 0

        # Unique cache hashes
        CACHE_HASH=$(printf '%s|%s' "$TARGET_DIR" "$QUERY" | md5sum | awk '{print $1}')
        PDF_RESULTS="$CACHE_DIR/pdf_results_${CACHE_HASH}.txt"
        PDF_DISPLAY="$CACHE_DIR/pdf_display_${CACHE_HASH}.txt"
        PDF_INDEX_META="$CACHE_DIR/pdf_meta_${CACHE_HASH}.txt"

        # Check if perfectly cached already and prompt for overwrite
        if [[ -s "$PDF_RESULTS" && -s "$PDF_DISPLAY" && -f "$PDF_INDEX_META" ]]; then
            OVERWRITE=$(printf 'No (Keep current cache)\nYes (Refetch and overwrite)' | rofi_menu "Cache exists. Refetch?")

            if [[ "$OVERWRITE" == "Yes (Refetch and overwrite)" ]]; then
                notify "🔄 Refetching PDF content in background..."
                # Clean up old cache before fetching anew
                rm -f "$PDF_RESULTS" "$PDF_DISPLAY" "$PDF_INDEX_META"
            elif [[ "$OVERWRITE" == "No (Keep current cache)" ]]; then
                notify "⚡ Cache kept. Open 'PDF View' to see results."
                exit 0
            else
                notify "Exited PDF Fetch"
                exit 0
            fi
        else
            notify "🚀 PDF fetch started in background..."
        fi

        # Spawn background fetch worker
        (
            # Use temp files so interrupted searches don't corrupt the cache
            TMP_RESULTS=$(mktemp)
            TMP_DISPLAY=$(mktemp)

            # Trap SIGTERM (from Global Cancel) to clean up temp files safely
            trap 'rm -f "$TMP_RESULTS" "$TMP_DISPLAY"; exit 130' TERM INT

            PDF_COUNT=$(fdfind --type f --extension pdf . "$TARGET_DIR" 2>/dev/null | wc -l)
            if (( PDF_COUNT == 0 )); then
                notify-send "PDF Fetch" "No PDF files found in $TARGET_DIR"
                rm -f "$TMP_RESULTS" "$TMP_DISPLAY"
                exit 0
            fi

            CURRENT=0
            fdfind --type f --extension pdf -0 . "$TARGET_DIR" 2>/dev/null | \
            while IFS= read -r -d '' PDF_FILE; do
                CURRENT=$((CURRENT + 1))

                # Report progress every 5 files or on completion
                if (( CURRENT % 5 == 0 || CURRENT == PDF_COUNT )); then
                    PERCENT=$((CURRENT * 100 / PDF_COUNT))
                    notify-send -t 1500 "PDF Fetch Progress" "Scanned: $CURRENT/$PDF_COUNT files ($PERCENT%)"
                fi

                MATCHES_ALL=1
                for KEYWORD in "${KEYWORDS[@]}"; do
                    if ! timeout 3s pdfgrep --ignore-case --quiet -- "$KEYWORD" "$PDF_FILE" 2>/dev/null; then
                        MATCHES_ALL=0
                        break
                    fi
                done

                if (( MATCHES_ALL == 1 )); then
                    for KEYWORD in "${KEYWORDS[@]}"; do
                        timeout 3s pdfgrep --ignore-case --page-number --with-filename -- "$KEYWORD" "$PDF_FILE" 2>/dev/null
                    done | sort -u >> "$TMP_RESULTS"

                    for KEYWORD in "${KEYWORDS[@]}"; do
                        timeout 3s pdfgrep --ignore-case --page-number --with-filename -- "$KEYWORD" "$PDF_FILE" 2>/dev/null
                    done | sort -u | \
                    awk -v home="$HOME" -v file_path="$PDF_FILE" '
                    {
                        line = $0
                        content = line
                        sub(/^.*:[0-9]+:/, "", content)
                        if (length(content) > 500) content = substr(content, 1, 500) "..."
                        prefix = line
                        sub(/:[^:]*$/, "", prefix)
                        page = prefix
                        sub(/^.*:/, "", page)
                        display = file_path
                        sub(home, "~", display)
                        n = split(display, path_parts, "/")
                        short = path_parts[1]
                        for (i = 2; i < n; i++) {
                            if (path_parts[i] != "") short = short "/" substr(path_parts[i], 1, 1)
                        }
                        if (n > 1) short = short "/" path_parts[n]
                        print short ":p" page ": " content
                    }' >> "$TMP_DISPLAY"
                fi
            done

            # SUCCESS COMMIT: Only move temps to cache if the loop finished without being killed
            mv "$TMP_RESULTS" "$PDF_RESULTS"
            mv "$TMP_DISPLAY" "$PDF_DISPLAY"

            # Save metadata record for the View stage list
            MATCH_COUNT=$(wc -l < "$PDF_RESULTS")
            printf '%s\t%s\t%s\n' "$TARGET_DIR" "$QUERY" "$MATCH_COUNT" > "$PDF_INDEX_META"

            notify-send "PDF Fetch Completed" "Successfully cached '$QUERY' ($MATCH_COUNT matches)."
        ) &

        # Register PID globally for Global Cancel support
        PDF_WORKER_PID=$!
        echo "$PDF_WORKER_PID" >> "$PID_FILE"
        ;;

    *PDF\ View*)
        # Gather all completed metadata tracking files
        # Check if there are any files matching the glob first
        shopt -s nullglob
        META_FILES=("$CACHE_DIR"/pdf_meta_*.txt)
        shopt -u nullglob

        if (( ${#META_FILES[@]} == 0 )); then
            notify "No cached PDF search pairs found. Run 'PDF Fetch' first."
            exit 0
        fi

        # Build selection list of pairs
        PAIR_LIST=""
        declare -A PAIR_MAP=()

        for meta in "${META_FILES[@]}"; do
            [[ -f "$meta" ]] || continue
            IFS=$'\t' read -r t_dir t_query t_count < "$meta"
            [[ -n "$t_dir" && -n "$t_query" ]] || continue

            display_str="[$t_dir]: [$t_query] ($t_count matches)"
            PAIR_LIST+="$display_str"$'\n'
            PAIR_MAP["$display_str"]="$t_dir|$t_query"
        done

        SELECTED_PAIR=$(printf '%s' "$PAIR_LIST" | rofi_menu "Select PDF Cache")
        [[ -n "$SELECTED_PAIR" ]] || { notify "Exited PDF View"; exit 0; }

        # Resolve selected pair back to its cache hash
        MAPPED_VAL="${PAIR_MAP["$SELECTED_PAIR"]}"
        IFS='|' read -r TARGET_DIR QUERY <<< "$MAPPED_VAL"

        CACHE_HASH=$(printf '%s|%s' "$TARGET_DIR" "$QUERY" | md5sum | awk '{print $1}')
        PDF_RESULTS="$CACHE_DIR/pdf_results_${CACHE_HASH}.txt"
        PDF_DISPLAY="$CACHE_DIR/pdf_display_${CACHE_HASH}.txt"

        [[ -s "$PDF_RESULTS" ]] || { notify "Cache data missing or corrupted."; exit 0; }

        # Interactive view loop for the chosen pair
        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Escape regex characters
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(head -n 5000 "$PDF_DISPLAY" | rofi_menu "PDF Results" -mesg "Query: <b>$QUERY</b> in <i>$TARGET_DIR</i>" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited PDF View"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action pdf) || continue

            if [[ "$ACTION" == "Preview match" ]]; then

                INDEX=$(grep -nF -m 1 -e "$LAST_SELECTION" "$PDF_DISPLAY" | cut -d: -f1)
                if [[ -n "$INDEX" ]]; then
                    FIRST_MATCH=$(sed -n "${INDEX}p" "$PDF_RESULTS")

                    # Parse the File and Page from the cached match
                    if [[ "$FIRST_MATCH" =~ ^(.*):([0-9]+):(.*)$ ]]; then
                        P_FILE="${BASH_REMATCH[1]}"
                        P_PAGE="${BASH_REMATCH[2]}"

                        if command -v pdftotext >/dev/null 2>&1; then
                            # Build a regex string from your keywords (e.g., "word1|word2")
                            GREP_REGEX=$(IFS='|'; echo "${KEYWORDS[*]}")

                            # Instantly extract ONLY the matching page, then grep with 5 lines of context
                            CONTEXT=$(pdftotext -f "$P_PAGE" -l "$P_PAGE" "$P_FILE" - 2>/dev/null | grep -i -E -C 5 "$GREP_REGEX")
                            [[ -z "$CONTEXT" ]] && CONTEXT="Could not extract text context from this page."

                            # Pop up a wider Rofi text window to read the context
                            rofi "${ROFI_OPTION[@]}" -e "$CONTEXT"
                        else
                            notify "Please install 'poppler-utils' to use context preview."
                            # Fallback to your old preview function if missing
                            run_pdf_preview "$FIRST_MATCH"
                        fi
                    fi
                else
                    notify "Unable to determine preview selection"
                fi
                continue
            fi

            PDF_ITEMS=()
            while IFS= read -r row_text; do
                [[ -z "$row_text" ]] && continue
                INDEX=$(grep -nF -m 1 -e "$row_text" "$PDF_DISPLAY" | cut -d: -f1)
                [[ -n "$INDEX" ]] || continue
                MATCH=$(sed -n "${INDEX}p" "$PDF_RESULTS")
                if [[ "$MATCH" =~ ^(.*):([0-9]+):(.*)$ ]]; then
                    FILE="${BASH_REMATCH[1]}"
                    PAGE="${BASH_REMATCH[2]}"
                    [[ -n "$FILE" && -n "$PAGE" ]] && PDF_ITEMS+=("$FILE"$'\t'"$PAGE")
                fi
            done <<< "$CLEAN_SELECTED"

            record_recent_files "${PDF_ITEMS[@]%%$'\t'*}" 2>/dev/null || true
            [[ ${#PDF_ITEMS[@]} -gt 0 ]] && run_pdf_action "$ACTION" "${PDF_ITEMS[@]}"
        done
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

        [[ -n "$HISTORY_DATA" ]] || { notify "🚫 No history data found."; exit 0; }

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(printf '%s\n' "$HISTORY_DATA" | cut -f2 | rofi_menu "History" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r title; do
                [[ -z "$title" ]] && continue
                URL=$(printf '%s\n' "$HISTORY_DATA" | awk -F'\t' -v t="$title" '$2 == t {print $1; exit}')
                [[ -n "$URL" ]] && URLS+=("$URL")
            done <<< "$CLEAN_SELECTED"

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

        [[ -n "$BMARK_DATA" ]] || { notify "🚫 No bookmarks found."; exit 0; }

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-format" "f"$'\t'"s")

            # Escape regex characters
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(printf '%s\n' "$BMARK_DATA" | cut -f2 | rofi_menu "Bookmarks" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            LAST_SELECTION="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION="${LAST_SELECTION%$'\r'}"

            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r title; do
                [[ -z "$title" ]] && continue
                URL=$(printf '%s\n' "$BMARK_DATA" | awk -F'\t' -v t="$title" '$2 == t {print $1; exit}')
                [[ -n "$URL" ]] && URLS+=("$URL")
            done <<< "$CLEAN_SELECTED"

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

    raw_payload = data[offset + record_header_size:record_end]

    # Split by null bytes to separate duplicate paste targets
    parts = raw_payload.split(b"\x00")

    # Grab the very first non-empty string and ignore the duplicates
    extracted_text = ""
    for p in parts:
        if p.strip():
            try:
                extracted_text = p.decode("utf-8")
            except UnicodeDecodeError:
                extracted_text = p.decode("utf-8", errors="replace")
            break

    if extracted_text:
        # Detect the 8-byte C memory alignment duplication and slice it off.
        # Grab the chunk starting at index 8 and check if the string starts with it.
        if len(extracted_text) > 8:
            chunk_to_match = extracted_text[8:16]
            if extracted_text.startswith(chunk_to_match):
                extracted_text = extracted_text[8:]

        entries.append(extracted_text)

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

        [[ -n "$SELECTED" ]] || { notify "🚫 No SSH hosts found or selection cancelled."; exit 0; }

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

        [[ -n "$SELECTED_PIDS" ]] || { notify "🚫 No processes selected."; exit 0; }

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
