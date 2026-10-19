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
mkdir -p "$CACHE_DIR"

# ============================================================
# Global Process Tracking
# ============================================================

# Track only background search workers. Include the Linux process start tick so
# a stale record cannot refer to an unrelated process after PID reuse.
process_start_tick() {
    local stat
    local -a fields
    [[ $1 =~ ^[0-9]+$ && -r /proc/$1/stat ]] || return 1
    IFS= read -r stat < "/proc/$1/stat" || return 1
    read -r -a fields <<< "${stat##*) }"
    [[ ${fields[19]:-} =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "${fields[19]}"
}

track_search_pid() {
    local start
    start=$(process_start_tick "$1") || return 0
    printf '%s\n' "$start" > "$CACHE_DIR/search-$1.pid"
}

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
# The separate "All keybindings" view is generated from config files at runtime.
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
    local count=0 pdf_count=0 marker pid start current

    # PDF workers have their own PID identity checks and graceful cleanup.
    if [[ -f "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_search.py" ]]; then
        pdf_count=$(python3 "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_search.py" cancel \
            --cache-dir "$CACHE_DIR/pdf" 2>/dev/null) || pdf_count=0
    fi

    # Stop tracked fd/rg workers. Stale markers are harmless and removed here.
    for marker in "$CACHE_DIR"/search-*.pid; do
        [[ -f "$marker" ]] || continue
        pid=${marker##*/search-}
        pid=${pid%.pid}
        IFS= read -r start < "$marker" || start=
        current=$(process_start_tick "$pid") || current=
        if [[ -n "$start" && "$current" == "$start" ]]; then
            pkill -TERM -P "$pid" 2>/dev/null || true
            kill -TERM "$pid" 2>/dev/null || true
            ((count++))
        fi
        rm -f -- "$marker"
    done

    if (( count + pdf_count > 0 )); then
        notify "Cancelled $count file/text search(es) and $pdf_count PDF search(es)."
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

    action=$(action_menu "$type" | rofi_menu "Action" -no-custom)
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
            local file
            for file in "${files[@]}"; do
                xdg-open "$file"
            done
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
            :
        } |
        rofi_menu "Search directory or enter path"
    ) || return 1

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

show_pdf_tools() {
    local choice
    choice=$(printf '%s\n' 'Running searches' 'Saved searches' 'Open PDF by name' 'Cancel PDF scan' |
        rofi_menu 'PDF tools' -no-custom) || return 0
    case "$choice" in
        'Running searches') pdf_command --pdf-attach ;;
        'Saved searches') pdf_command --pdf-view ;;
        'Open PDF by name') pdf_command --pdf-open ;;
        'Cancel PDF scan') pdf_command --pdf-cancel ;;
    esac
}

if (( $# > 0 )); then
    pdf_command "$@"
    exit $?
fi

MODE=$(
    printf '%s\n' \
        "📁 Find · Files" \
        "🔍 Find · Grep" \
        "📝 Find · Documents" \
        "🔍 Find · PDF Search" \
        "🚀 Open · Apps" \
        "🕒 Open · Recent Files" \
        "🌐 Open · History" \
        "🔖 Open · Bookmarks" \
        "🪟 Go · Windows" \
        "🏷️ Go · Marks" \
        "🖥️ Go · SSH" \
        "🧮 Tool · Calculator" \
        "🌐 Tool · Translate" \
        "📋 Tool · Clipboard" \
        "📄 Tool · PDF Tools" \
        "⌨️ Help · Keybindings" \
        "💀 System · Kill" \
        "🛑 System · Cancel" |
    rofi_menu "Search" -auto-select -no-custom \
        -theme-str '
#window {
    padding: 0px 20%;
    children: [top-space, mainbox, bottom-space];
}
#mainbox { expand: false; }
#listview { lines: 11; columns: 2; }
top-space, bottom-space { expand: true; }
'
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

            # Pass input as data and allow only arithmetic and math functions.
            RESULT=$(python3 - "$EXPR" <<'PY'
import ast
import math
import operator
import sys

binary = {
    ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
    ast.Div: operator.truediv, ast.FloorDiv: operator.floordiv,
    ast.Mod: operator.mod, ast.Pow: operator.pow,
}
unary = {ast.UAdd: operator.pos, ast.USub: operator.neg}
names = {name: getattr(math, name) for name in dir(math) if not name.startswith('_')}
names.update(abs=abs, round=round, pow=pow)

def calculate(node):
    if isinstance(node, ast.Expression):
        return calculate(node.body)
    if isinstance(node, ast.Constant) and type(node.value) in (int, float):
        return node.value
    if isinstance(node, ast.Name) and node.id in names:
        return names[node.id]
    if isinstance(node, ast.BinOp) and type(node.op) in binary:
        return binary[type(node.op)](calculate(node.left), calculate(node.right))
    if isinstance(node, ast.UnaryOp) and type(node.op) in unary:
        return unary[type(node.op)](calculate(node.operand))
    if isinstance(node, ast.Call) and isinstance(node.func, ast.Name) and not node.keywords:
        function = calculate(node.func)
        if callable(function):
            return function(*(calculate(arg) for arg in node.args))
    raise ValueError('Unsupported expression')

try:
    print(calculate(ast.parse(sys.argv[1], mode='eval')))
except (ArithmeticError, SyntaxError, TypeError, ValueError, OverflowError):
    print('Error: Invalid Expression')
PY
)

            # Display the result
            ACTION=$(printf "📋 Copy to clipboard\n🔙 Edit expression" | rofi_menu "= $RESULT" -no-custom)

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
                    rofi_menu "Target Language" -no-custom
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
                        rofi_menu "Translation Error" -no-custom \
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
                    rofi_menu "Translation Result" -no-custom \
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
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"s")

            # Restore the previous input and selected row after an action.
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
        track_search_pid "$SEARCH_PID"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            # Use a real tab character ($'\t') to separate the typed filter from the result
            ROFI_ARGS=("-multi-select" "-no-custom" "-async-pre-read" "0" "-format" "f"$'\t'"s")

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            # Stream dynamically if search is still running, otherwise read cache
            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | rofi_menu "Files" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$RESULTS_FILE" | rofi_menu "Files" "${ROFI_ARGS[@]}")
            fi

            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

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
        rm -f -- "$CACHE_DIR/search-$SEARCH_PID.pid"
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
                -- "$QUERY" \
                "$TARGET_DIR" | \
            tee "$GREP_RAW" | build_grep_rows > "$GREP_DISPLAY"
        ) &
        SEARCH_PID=$!
        track_search_pid "$SEARCH_PID"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            # Rofi returns the original row index, so duplicate display text
            # still resolves to the correct file and line.
            ROFI_ARGS=("-multi-select" "-no-custom" "-async-pre-read" "0" "-format" "f"$'\t'"i")

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$GREP_DISPLAY" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$GREP_DISPLAY" | rofi_menu "Grep" "${ROFI_ARGS[@]}")
            fi

            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            FIRST_INDEX="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION=""
            if [[ "$FIRST_INDEX" =~ ^[0-9]+$ ]]; then
                LAST_SELECTION=$(sed -n "$((FIRST_INDEX + 1))p" "$GREP_DISPLAY")
            fi

            ACTION=$(select_action grep) || continue

            GREP_ITEMS=()
            while IFS= read -r row_index; do
                [[ "$row_index" =~ ^[0-9]+$ ]] || continue
                MATCH=$(sed -n "$((row_index + 1))p" "$GREP_RAW")
                FILE="${MATCH%%$'\t'*}"
                REST="${MATCH#*$'\t'}"
                LINE="${REST%%$'\t'*}"

                [[ -n "$FILE" && -n "$LINE" ]] && GREP_ITEMS+=("$FILE"$'\t'"$LINE")
            done <<< "$CLEAN_SELECTED"

            run_grep_action "$ACTION" "${GREP_ITEMS[@]}"
        done

        kill "$SEARCH_PID" 2>/dev/null
        rm -f -- "$CACHE_DIR/search-$SEARCH_PID.pid"
        ;;

    *Documents*)
        RESULTS_FILE=$(mktemp)
        trap 'rm -f "$RESULTS_FILE"' EXIT

        ( fdfind --type f --extension md . "$DOCUMENT_DIR" | shorten_paths > "$RESULTS_FILE" ) &
        SEARCH_PID=$!
        track_search_pid "$SEARCH_PID"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-no-custom" "-async-pre-read" "0" "-format" "f"$'\t'"s")

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            if kill -0 "$SEARCH_PID" 2>/dev/null; then
                SELECTED=$(tail -n +1 -f --pid="$SEARCH_PID" "$RESULTS_FILE" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            else
                SELECTED=$(cat "$RESULTS_FILE" | rofi_menu "Documents" "${ROFI_ARGS[@]}")
            fi

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

            ACTION=$(select_action file) || continue

            FILES=()
            while IFS= read -r row; do
                FILE="${row##* │ }"
                [[ -n "$FILE" ]] && FILES+=("$FILE")
            done <<< "$CLEAN_SELECTED"

            run_file_action "$ACTION" "${FILES[@]}"
        done

        kill "$SEARCH_PID" 2>/dev/null
        rm -f -- "$CACHE_DIR/search-$SEARCH_PID.pid"
        ;;

    *Cancel*)
        global_cancel
        ;;

    *PDF\ Search*)
        pdf_command --pdf-search
        ;;

    *PDF\ Tools*)
        show_pdf_tools
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
                "SELECT url, COALESCE(REPLACE(REPLACE(REPLACE(title, char(10), ' '), char(13), ' '), char(9), ' '), url)
                 FROM urls
                 ORDER BY last_visit_time DESC
                 LIMIT 1000"
        )

        [[ -n "$HISTORY_DATA" ]] || { notify "🚫 No history data found."; exit 0; }

        HISTORY_ROWS=()
        HISTORY_URLS=()
        while IFS=$'\t' read -r URL TITLE; do
            [[ -n "$URL" ]] || continue
            HISTORY_ROWS+=("${TITLE:-$URL} │ $URL")
            HISTORY_URLS+=("$URL")
        done <<< "$HISTORY_DATA"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"i")

            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(printf '%s\n' "${HISTORY_ROWS[@]}" | rofi_menu "History" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            FIRST_INDEX="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION=""
            [[ "$FIRST_INDEX" =~ ^[0-9]+$ ]] && LAST_SELECTION="${HISTORY_ROWS[FIRST_INDEX]:-}"

            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r row_index; do
                [[ "$row_index" =~ ^[0-9]+$ ]] || continue
                URL="${HISTORY_URLS[row_index]:-}"
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
                "\(.url)\t\((.name // "Untitled") | gsub("[\\n\\r\\t]"; " "))"
            ' "$BOOKMARK"
        )

        [[ -n "$BMARK_DATA" ]] || { notify "🚫 No bookmarks found."; exit 0; }

        BMARK_ROWS=()
        BMARK_URLS=()
        while IFS=$'\t' read -r URL TITLE; do
            [[ -n "$URL" ]] || continue
            BMARK_ROWS+=("${TITLE:-Untitled} │ $URL")
            BMARK_URLS+=("$URL")
        done <<< "$BMARK_DATA"

        LAST_SELECTION=""
        LAST_FILTER=""
        while true; do
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"i")

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            SELECTED=$(printf '%s\n' "${BMARK_ROWS[@]}" | rofi_menu "Bookmarks" "${ROFI_ARGS[@]}")
            [[ -n "$SELECTED" ]] || { notify "Exited $MODE"; break; }

            if [[ "$SELECTED" == *$'\t'* ]]; then
                FIRST_LINE="${SELECTED%%$'\n'*}"
                LAST_FILTER="${FIRST_LINE%%$'\t'*}"
                CLEAN_SELECTED=$(printf '%s\n' "$SELECTED" | cut -f2-)
            else
                LAST_FILTER=""
                CLEAN_SELECTED="$SELECTED"
            fi

            FIRST_INDEX="${CLEAN_SELECTED%%$'\n'*}"
            LAST_SELECTION=""
            [[ "$FIRST_INDEX" =~ ^[0-9]+$ ]] && LAST_SELECTION="${BMARK_ROWS[FIRST_INDEX]:-}"

            ACTION=$(select_action url) || continue

            URLS=()
            while IFS= read -r row_index; do
                [[ "$row_index" =~ ^[0-9]+$ ]] || continue
                URL="${BMARK_URLS[row_index]:-}"
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
    try:
        subprocess.run(["notify-send", "-i", os.path.expanduser("~/.config/i3/share/64x64/list.png"),
                        "Rofi Omnisearch", message],
                       stdout=subprocess.DEVNULL,
                       stderr=subprocess.DEVNULL)
    except FileNotFoundError:
        pass

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
        "-no-custom",
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
if not 0 <= index < len(entries):
    sys.exit(0)

clipboard_text = entries[index]
clipboard_bytes = clipboard_text.encode("utf-8")

for selection in ("clipboard", "primary"):
    try:
        subprocess.run(
            ["xclip", "-selection", selection],
            input=clipboard_bytes,
        )
    except FileNotFoundError:
        notify("xclip is not installed")
        break
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
            rofi_menu "SSH to" -multi-select -no-custom
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
            rofi_menu "Kill process" -multi-select -no-custom |
            awk '{print $1}'
        )

        [[ -n "$SELECTED_PIDS" ]] || { notify "🚫 No processes selected."; exit 0; }

        COUNT=$(printf '%s\n' "$SELECTED_PIDS" | grep -c .)

        SIGNAL=$(
            printf '%s\n' \
                "SIGTERM" \
                "Cancel" \
                "SIGKILL" |
            rofi_menu "Kill $COUNT process(es)" -auto-select -no-custom
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
