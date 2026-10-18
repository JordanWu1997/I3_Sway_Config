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

# A short, searchable guide. Keep these labels in sync with the i3 config.
# The complete list below is generated from the config files at runtime.
shortcut_guide_items() {
    printf '%s\n' \
        'Launch    |  Applications                    Super+D' \
        'Launch    |  Commands                        Super+Shift+D' \
        'Launch    |  Omnisearch                      Super+Backslash' \
        'Launch    |  Terminal                        Super+Enter' \
        'Windows   |  Focus left/down/up/right        Super+H/J/K/L' \
        'Windows   |  Move left/down/up/right         Super+Shift+H/J/K/L' \
        'Windows   |  Resize or position              Super+Slash' \
        'Windows   |  Toggle floating                 Super+Shift+Space' \
        'Windows   |  Toggle fullscreen               Super+F' \
        'Windows   |  Close focused window            Super+Shift+Q' \
        'Windows   |  Hide in scratchpad              Super+Z' \
        'Windows   |  Show scratchpad                 Super+G' \
        'Windows   |  Mark focused window             Super+M' \
        'Windows   |  Go to marked window             Super+Apostrophe' \
        'Workspace |  Go to workspace 1-10            Super+1-0' \
        'Workspace |  Move window to workspace 1-10   Super+Shift+1-0' \
        'Workspace |  Next / previous workspace       Super+Tab / Super+Shift+Tab' \
        'Modes     |  System controls                 Ctrl+Alt+S' \
        'Modes     |  Display controls                Super+Shift+X' \
        'Modes     |  Window layout                   Super+Shift+W' \
        'Modes     |  Workspace tools                 Super+Shift+P' \
        'Modes     |  Customization                   Super+Shift+C' \
        'Capture   |  Screenshot selection            Print Screen' \
        'Capture   |  Active window screenshot        Super+Print Screen' \
        'Media     |  Volume up/down                  Volume keys' \
        'Media     |  Play/pause                      Play/Pause key'
}

show_all_keybindings() {
    local selected binding command
    # Include bindings inside modes, but only global bindings may be run
    # directly from this menu.
    selected=$(awk '
        /^[[:space:]]*mode[[:space:]]/ && /\{[[:space:]]*$/ {
            mode=$0
            sub(/^[[:space:]]*mode[[:space:]]*/, "", mode)
            sub(/[[:space:]]*\{[[:space:]]*$/, "", mode)
            next
        }
        /^[[:space:]]*}[[:space:]]*$/ { mode=""; next }
        /^[[:space:]]*bindsym[[:space:]]/ {
            binding=$0
            sub(/^[[:space:]]*/, "", binding)
            if (mode == "") print "[Global] " binding
            else print "[Mode " mode "] " binding
        }
    ' "$HOME"/.config/i3/config.d/*.config |
        rofi_menu "All keybindings" -no-custom \
            -mesg 'Global rows run on Enter; mode rows are for reference.' )
    [[ $selected == '[Global] bindsym '* ]] || return 0

    binding=${selected#'[Global] bindsym '}
    while [[ $binding == --* ]]; do
        binding=${binding#* }
    done
    command=${binding#* }
    # A selected global binding retains the old menu's run-on-selection behavior.
    i3-msg "$command"
}

show_keybinding_menu() {
    local choice
    while true; do
        choice=$(printf '%s\n' 'Shortcut guide' 'All keybindings' |
            rofi_menu "Keybindings" -no-custom) || return 0
        case $choice in
            'Shortcut guide')
                shortcut_guide_items |
                    rofi_menu "Shortcut guide" -no-custom \
                        -mesg 'Search actions or keys. This guide is read-only.' >/dev/null
                ;;
            'All keybindings')
                show_all_keybindings
                ;;
        esac
    done
}

notify() {
    command -v notify-send >/dev/null 2>&1 &&
        notify-send -t 1000 "Rofi Omnisearch" "$1" --icon="$HOME/.config/i3/share/64x64/list.png"
}

global_cancel() {
    local count=0

    # PDF workers have their own PID identity checks and graceful cleanup.
    if [[ -f "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_search.py" ]]; then
        python3 "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_search.py" cancel \
            --cache-dir "$CACHE_DIR/pdf" >/dev/null 2>&1 || true
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

source "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_menu.sh"

if (( $# > 0 )); then
    pdf_command "$@"
    exit $?
fi

MODE=$(
    printf '%s\n' \
        "🚀 Apps" \
        "🧮 Calculator" \
        "🌐 Translate" \
        "🔍 Grep" \
        "📁 Files" \
        "📝 Documents" \
        "🔍 PDF Search" \
        "📖 PDF Saved Searches" \
        "📄 PDF Open" \
        "🛑 PDF Cancel" \
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

    *Translate*)
        # translate-shell is required for actual translation.
        if ! command -v trans >/dev/null 2>&1; then
            notify "Please install 'translate-shell' (trans)."
            exit 0
        fi

        QUERY=""
        TL=""
        LANG_TARGET=""
        while true; do

            # 1. Get input text
            QUERY=$(
                printf '%s\n' "" |
                    rofi_menu "Translate (Enter text)" \
                        -filter "$QUERY"
            )
            RofiStatus=$?

            if [[ $RofiStatus -ne 0 ]]; then
                notify "Translation closed"
                break
            fi

            if [[ -z "$QUERY" ]]; then
                notify "No text entered"
                continue
            fi

            # 2. Select target language
            LANG_TARGET=$(
                printf '%s\n' \
                    '🇹🇼 To Chinese' \
                    '🇺🇸 To English' |
                    rofi_menu "Target Language"
            )
            RofiStatus=$?

            if [[ $RofiStatus -ne 0 ]]; then
                # Return to text input instead of closing everything.
                continue
            fi

            [[ -n "$LANG_TARGET" ]] || continue
            case "$LANG_TARGET" in
                *Chinese*)
                    TL="zh"
                    ;;
                *English*)
                    TL="en"
                    ;;
                *)
                    notify "Unsupported target language"
                    continue
                    ;;
            esac

            # 3. Translate
            notify "Translating..."
            RESULT=$(
                trans \
                    -b \
                    -t "$TL" \
                    -- "$QUERY" \
                    2>/dev/null
            )
            TransStatus=$?

            # translate-shell may return an empty result on failure.
            if [[ $TransStatus -ne 0 || -z "$RESULT" ]]; then
                RESULT="Error: Could not fetch translation."

                # Show the error and let the user decide what to do.
                ACTION=$(
                    printf '%s\n' \
                        '🔙 Edit text' \
                        '❌ Close' |
                        rofi_menu "Translation Error" \
                            -mesg "$(printf \
                                'Input:\n%s\n\n%s' \
                                "$QUERY" \
                                "$RESULT"
                            )"
                )
                RofiStatus=$?
                if [[ $RofiStatus -ne 0 ||
                      "$ACTION" == *"Close"* ]]; then
                    notify "Translation closed"
                    break
                fi
                # Edit text
                continue
            fi

            # 4. Display translation result
            ACTION=$(
                printf '%s\n' \
                    '📋 Copy to clipboard' \
                    '🔙 Edit text' \
                    '🌐 Translate again' |
                    rofi_menu "Translation Result" \
                        -mesg "$(printf \
                            'Input:\n%s\n\nTranslation:\n%s' \
                            "$QUERY" \
                            "$RESULT"
                        )"
            )
            RofiStatus=$?

            # 5. Handle result window close / Escape
            if [[ $RofiStatus -ne 0 ]]; then
                notify "Translation closed"
                break
            fi

            # 6. Copy result
            if [[ "$ACTION" == *"Copy"* ]]; then
                copy_lines "$RESULT"
                notify "Translation copied"
                break
            fi

            # 7. Edit text
            if [[ "$ACTION" == *"Edit"* ]]; then
                continue
            fi

            # 8. Translate again
            if [[ "$ACTION" == *"Translate again"* ]]; then
                LANG_TARGET=""
                TL=""
                continue
            fi

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
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | rofi_menu "Files" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$RESULTS_FILE" | rofi_menu "Files" "${ROFI_ARGS[@]}")
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
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$GREP_DISPLAY" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$GREP_DISPLAY" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
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
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$RESULTS_FILE" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
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

    *PDF\ Search*)
        pdf_command --pdf-search
        ;;

    *PDF\ Saved\ Searches*)
        pdf_command --pdf-view
        ;;

    *PDF\ Open*)
        pdf_command --pdf-open
        ;;

    *PDF\ Cancel*)
        pdf_command --pdf-cancel
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
    subprocess.run(["notify-send", "-i", os.path.expanduser("~/.config/i3/share/64x64/list.png"),
                    "Rofi Omnisearch", message],
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
        show_keybinding_menu
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
