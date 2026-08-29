#!/usr/bin/env bash
# vim: set fileencoding=utf-8

set -o pipefail

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Description : Rofi omnisearch / command palette
###########################################################

# Requirements:
#   rofi fd/fdfind ripgrep pdfgrep sqlite3 jq wmctrl xclip git neovim
#
# Optional:
#   notify-send xdg-open parcellite i3-msg

# Installation:
#   apt install fdfind ripgrep pdfgrep sqlite jq wmctrl xclip git neovim
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
        notify-send "Rofi Omnisearch" "$1"
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
        file)
            printf '%s\n' \
                "Open" \
                "Edit in Neovim" \
                "Open in terminal" \
                "Open containing directory" \
                "Copy path"
            ;;
        grep)
            printf '%s\n' \
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

MODE=$(
    printf '%s\n' \
        "🔍 Grep" \
        "📁 Files" \
        "📝 Documents" \
        "📕 PDF Content" \
        "🕒 Recent" \
        "📦 Git Modified" \
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

        SELECTED=$(
            fdfind --type f "" "$TARGET_DIR" |
            shorten_paths |
            rofi_menu "Files" -multi-select
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

    *Grep*)
        QUERY=$(rofi_menu "Grep for")
        [[ -n "$QUERY" ]] || exit 0

        TARGET_DIR=$(select_directory) || exit 0

        GREP_RESULTS=$(mktemp)
        trap 'rm -f "$GREP_RESULTS"' EXIT

        rg \
            --line-number \
            --no-heading \
            --color=never \
            --field-match-separator $'\t' \
            "$QUERY" \
            "$TARGET_DIR" > "$GREP_RESULTS"

        [[ -s "$GREP_RESULTS" ]] || {
            notify "No matches found"
            exit 0
        }

        SELECTED_INDEXES=$(
            build_grep_rows < "$GREP_RESULTS" |
            rofi_menu "Grep" -multi-select -format i
        )

        [[ -n "$SELECTED_INDEXES" ]] || exit 0

        ACTION=$(select_action grep) || exit 0

        GREP_ITEMS=()

        while IFS= read -r INDEX; do
            [[ "$INDEX" =~ ^[0-9]+$ ]] || continue

            MATCH=$(sed -n "$((INDEX + 1))p" "$GREP_RESULTS")
            IFS=$'\t' read -r FILE LINE CONTENT <<< "$MATCH"

            [[ -n "$FILE" && -n "$LINE" ]] &&
                GREP_ITEMS+=("$FILE"$'\t'"$LINE")
        done <<< "$SELECTED_INDEXES"

        run_grep_action "$ACTION" "${GREP_ITEMS[@]}"
        ;;

    *Documents*)
        SELECTED=$(
            fdfind --type f --extension md . "$DOCUMENT_DIR" |
            shorten_paths |
            rofi_menu "Documents" -multi-select
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

    *PDF\ Content*)
        DEBUG_LOG="$CACHE_DIR/pdfgrep-debug.log"

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

        # Split the query into whitespace-separated keywords.
        read -r -a KEYWORDS <<< "$QUERY"

        (( ${#KEYWORDS[@]} > 0 )) || exit 0

        TARGET_DIR=$(select_directory) || exit 0

        log_pdf_debug "Query: $QUERY"
        log_pdf_debug "Keywords: ${KEYWORDS[*]}"
        log_pdf_debug "Directory: $TARGET_DIR"

        PDF_COUNT=$(
            fdfind \
                --type f \
                --extension pdf \
                . "$TARGET_DIR" \
                2>> "$DEBUG_LOG" |
            wc -l
        )

        log_pdf_debug "PDF files found: $PDF_COUNT"

        if (( PDF_COUNT == 0 )); then
            notify "No PDF files found"
            exit 0
        fi

        notify "Found $PDF_COUNT PDF file(s), searching..."

        # Temporary directory for keyword result sets.
        PDF_SEARCH_DIR=$(mktemp -d)

        trap '
            rm -rf "$PDF_SEARCH_DIR"
            rm -f "$PDF_RESULTS"
        ' EXIT

        # --------------------------------------------------------
        # Search every keyword independently.
        #
        # Each file contains a sorted list of PDF paths matching
        # that individual keyword.
        # --------------------------------------------------------

        for INDEX in "${!KEYWORDS[@]}"; do
            KEYWORD="${KEYWORDS[$INDEX]}"

            log_pdf_debug "Searching keyword: [$KEYWORD]"

            pdfgrep \
                --recursive \
                --ignore-case \
                --page-number \
                --with-filename \
                -- "$KEYWORD" "$TARGET_DIR" \
                2>> "$DEBUG_LOG" |
                sed -E 's/^(.*):[0-9]+:.*/\1/' |
                sort -u \
                > "$PDF_SEARCH_DIR/$INDEX.files"

            KEYWORD_COUNT=$(wc -l < "$PDF_SEARCH_DIR/$INDEX.files")

            log_pdf_debug \
                "Keyword [$KEYWORD] matched $KEYWORD_COUNT PDF file(s)"

            # If any keyword has no matching PDFs, no PDF can
            # possibly match all keywords.
            if (( KEYWORD_COUNT == 0 )); then
                notify "No PDFs match keyword: $KEYWORD"
                log_pdf_debug \
                    "No matches for keyword [$KEYWORD]"
                exit 0
            fi
        done

        # --------------------------------------------------------
        # Intersect all keyword file lists.
        #
        # Result: PDFs containing EVERY keyword somewhere in the
        # document, not necessarily on the same page.
        # --------------------------------------------------------

        cp \
            "$PDF_SEARCH_DIR/0.files" \
            "$PDF_SEARCH_DIR/common.files"

        for INDEX in "${!KEYWORDS[@]}"; do
            (( INDEX == 0 )) && continue

            comm -12 \
                "$PDF_SEARCH_DIR/common.files" \
                "$PDF_SEARCH_DIR/$INDEX.files" \
                > "$PDF_SEARCH_DIR/common.next"

            mv \
                "$PDF_SEARCH_DIR/common.next" \
                "$PDF_SEARCH_DIR/common.files"
        done

        MATCHING_PDF_COUNT=$(
            wc -l < "$PDF_SEARCH_DIR/common.files"
        )

        log_pdf_debug \
            "PDFs containing all keywords: $MATCHING_PDF_COUNT"

        if (( MATCHING_PDF_COUNT == 0 )); then
            notify "No PDF contains all ${#KEYWORDS[@]} keywords"
            exit 0
        fi

        notify \
            "$MATCHING_PDF_COUNT PDF(s) match all keyword(s)"

        # --------------------------------------------------------
        # Generate the actual result lines.
        #
        # Search every matching PDF again for every keyword so Rofi
        # can display the matching text and page number.
        # --------------------------------------------------------

        PDF_RESULTS=$(mktemp)

        : > "$PDF_RESULTS"

        while IFS= read -r PDF_FILE; do
            [[ -n "$PDF_FILE" ]] || continue

            for KEYWORD in "${KEYWORDS[@]}"; do
                pdfgrep \
                    --ignore-case \
                    --page-number \
                    --with-filename \
                    -- "$KEYWORD" "$PDF_FILE" \
                    2>> "$DEBUG_LOG"
            done

        done < "$PDF_SEARCH_DIR/common.files" |
            sort -u > "$PDF_RESULTS"

        MATCH_COUNT=$(wc -l < "$PDF_RESULTS")

        log_pdf_debug \
            "Matching result lines: $MATCH_COUNT"

        if (( MATCH_COUNT == 0 )); then
            notify "Matching PDFs found, but no result lines generated"
            log_pdf_debug "ERROR: PDF_RESULTS is empty"
            exit 0
        fi

        # --------------------------------------------------------
        # Convert full paths into shortened display paths.
        #
        # Expected pdfgrep format:
        #
        # /full/path/file.pdf:PAGE:matching text
        # --------------------------------------------------------

        PDF_DISPLAY=$(
            awk -v home="$HOME" '
            {
                line = $0

                # Split from the end:
                #
                # FILE:PAGE:CONTENT
                #
                # First remove CONTENT, then extract PAGE.
                content = line
                sub(/^.*:[0-9]+:/, "", content)

                prefix = line
                sub(/:[^:]*$/, "", prefix)

                page = prefix
                sub(/^.*:/, "", page)

                file = prefix
                sub(/:[0-9]+$/, "", file)

                # Skip malformed lines.
                if (file == "" || page == "")
                    next

                # Shorten the path for display.
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

        DISPLAY_COUNT=$(
            printf '%s\n' "$PDF_DISPLAY" |
            grep -c .
        )

        log_pdf_debug \
            "Display entries generated: $DISPLAY_COUNT"

        if (( DISPLAY_COUNT == 0 )); then
            notify "PDF matches found, but display parsing failed"
            exit 0
        fi

        # --------------------------------------------------------
        # Show results.
        #
        # Use indexes so the shortened display never needs to be
        # parsed back into the original PDF path.
        # --------------------------------------------------------

        SELECTED_INDEXES=$(
            printf '%s\n' "$PDF_DISPLAY" |
            rofi_menu "PDF Content ($MATCHING_PDF_COUNT PDFs)" \
                -multi-select \
                -format i
        )

        [[ -n "$SELECTED_INDEXES" ]] || exit 0

        ACTION=$(select_action pdf) || exit 0

        PDF_ITEMS=()

        while IFS= read -r INDEX; do
            [[ "$INDEX" =~ ^[0-9]+$ ]] || continue

            MATCH=$(
                sed -n "$((INDEX + 1))p" "$PDF_RESULTS"
            )

            # Parse:
            #
            # FILE:PAGE:CONTENT
            #
            # Greedily match the file path so ':' characters before
            # the final :PAGE:CONTENT section are handled.
            if [[ "$MATCH" =~ ^(.*):([0-9]+):(.*)$ ]]; then
                FILE="${BASH_REMATCH[1]}"
                PAGE="${BASH_REMATCH[2]}"

                [[ -n "$FILE" && -n "$PAGE" ]] &&
                    PDF_ITEMS+=(
                        "$FILE"$'\t'"$PAGE"
                    )
            else
                log_pdf_debug \
                    "Failed to parse selected result: $MATCH"
            fi

        done <<< "$SELECTED_INDEXES"

        if (( ${#PDF_ITEMS[@]} == 0 )); then
            notify "Failed to parse selected PDF results"
            exit 0
        fi

        log_pdf_debug \
            "Executing action [$ACTION] on ${#PDF_ITEMS[@]} result(s)"

        run_pdf_action \
            "$ACTION" \
            "${PDF_ITEMS[@]}"

        log_pdf_debug "===== PDF search finished ====="
        ;;

    *Recent*)
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

        SELECTED_INDEXES=$(
            printf '%s\n' "$HISTORY_DATA" |
            cut -f2 |
            rofi_menu "History" -multi-select -format i
        )

        [[ -n "$SELECTED_INDEXES" ]] || exit 0

        ACTION=$(select_action url) || exit 0

        URLS=()
        while IFS= read -r INDEX; do
            [[ "$INDEX" =~ ^[0-9]+$ ]] || continue
            URL=$(printf '%s\n' "$HISTORY_DATA" |
                awk -F'\t' -v row="$((INDEX + 1))" 'NR == row {print $1}')
            [[ -n "$URL" ]] && URLS+=("$URL")
        done <<< "$SELECTED_INDEXES"

        run_url_action "$ACTION" "${URLS[@]}"
        ;;

    *Bookmarks*)
        [[ -f "$BOOKMARK" ]] || {
            notify "Brave bookmarks file not found"
            exit 0
        }

        BMARK_DATA=$(
            jq -r '
                .. | objects | select(.url != null) |
                "\(.url)\t\((.name // "Untitled") | gsub("\n"; " "))"
            ' "$BOOKMARK" |
            awk -F'\t' '!seen[$2]++'
        )

        [[ -n "$BMARK_DATA" ]] || exit 0

        SELECTED_INDEXES=$(
            printf '%s\n' "$BMARK_DATA" |
            cut -f2 |
            rofi_menu "Bookmarks" -multi-select -format i
        )

        [[ -n "$SELECTED_INDEXES" ]] || exit 0

        ACTION=$(select_action url) || exit 0

        URLS=()
        while IFS= read -r INDEX; do
            [[ "$INDEX" =~ ^[0-9]+$ ]] || continue
            URL=$(printf '%s\n' "$BMARK_DATA" |
                awk -F'\t' -v row="$((INDEX + 1))" 'NR == row {print $1}')
            [[ -n "$URL" ]] && URLS+=("$URL")
        done <<< "$SELECTED_INDEXES"

        run_url_action "$ACTION" "${URLS[@]}"
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
    subprocess.run(["notify-send", "Parcellite", message],
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
