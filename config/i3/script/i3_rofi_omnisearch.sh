#!/usr/bin/env bash
# vim: set fileencoding=utf-8

set -o pipefail

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Description : Rofi omnisearch / command palette
# Workflow    : See OMNISEARCH_WORKFLOW.md in this directory
###########################################################

# Requirements:
#   rofi(>=1.7.0) fd/fdfind ripgrep pdfgrep sqlite3 jq wmctrl xclip git neovim poppler-utils file xdg-utils
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
# Rofi reserves Alt+B for moving backward by a word. Free it only in menus
# with an explicit back action; Ctrl+Left still moves backward by a word.
ROFI_BACK_BINDING=(-kb-move-word-back 'Control+Left' -kb-custom-6 'Alt+b')
TERMINAL="${TERMINAL:-kitty}"
DOCUMENT_DIR="$HOME/Documents"
HISTORY="$HOME/.config/BraveSoftware/Brave-Browser/Default/History"
BOOKMARK="$HOME/.config/BraveSoftware/Brave-Browser/Default/Bookmarks"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/rofi-omnisearch"
LAST_DIR_FILE="$CACHE_DIR/last_dir"
LAST_GREP_QUERY_FILE="$CACHE_DIR/last_grep_query"
LAST_GREP_DIR_FILE="$CACHE_DIR/last_grep_dir"
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

stop_search_worker() {
    local pid=$1
    pkill -TERM -P "$pid" 2>/dev/null || true
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    rm -f -- "$CACHE_DIR/search-$pid.pid"
}

search_scope_flags() {
    local tool=$1
    local -n flags=$2
    flags=()
    [[ $INCLUDE_HIDDEN == yes ]] && flags+=(--hidden)
    [[ $INCLUDE_IGNORED == yes ]] && flags+=(--no-ignore)
    if [[ $INCLUDE_HIDDEN == yes || $INCLUDE_IGNORED == yes ]]; then
        if [[ $tool == fd ]]; then
            flags+=(--exclude .git)
        else
            flags+=(--glob '!.git/**')
        fi
    fi
}

search_scope_label() {
    printf 'Hidden: %s · Ignored: %s' "$INCLUDE_HIDDEN" "$INCLUDE_IGNORED"
}

toggle_search_scope() {
    local status=$1 selection=$2
    [[ $selection == *$'\t'* ]] && last_filter=${selection%%$'\t'*}
    if [[ $status == 13 ]]; then
        [[ $INCLUDE_HIDDEN == yes ]] && INCLUDE_HIDDEN=no || INCLUDE_HIDDEN=yes
    else
        [[ $INCLUDE_IGNORED == yes ]] && INCLUDE_IGNORED=no || INCLUDE_IGNORED=yes
    fi
    last_selection=''
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
        'Mode use   |  Enter: parent mode (top level: exit)' \
        'Mode use   |  Escape: return to normal keybindings' \
        'Mode use   |  Ctrl+[: exits most modes' \
        'Mode use   |  Insert/Vim: Ctrl+[ exits; Mouse: Ctrl+[ scrolls' \
        'Mode use   |  Adjustments and batch actions stay open for repeats' \
        'Mode use   |  One-off actions usually exit or return to parent' \
        'Launch     |  Applications                    Super+D' \
        'Launch     |  Commands                        Super+Shift+D' \
        'Launch     |  Omnisearch                      Super+Backslash' \
        'Launch     |  Terminal                        Super+Enter' \
        'Windows    |  Focus left/down/up/right        Super+H/J/K/L' \
        'Windows    |  Move left/down/up/right         Super+Shift+H/J/K/L' \
        'Windows    |  Resize or position              Super+Slash' \
        'Windows    |  Toggle floating                 Super+Shift+Space' \
        'Windows    |  Toggle fullscreen               Super+F' \
        'Windows    |  Close focused window            Super+Shift+Q' \
        'Windows    |  Hide in scratchpad              Super+Z' \
        'Windows    |  Show scratchpad                 Super+G' \
        'Windows    |  Mark focused window             Super+M' \
        'Windows    |  Go to marked window             Super+Apostrophe' \
        'Workspace  |  Go to workspace 1-10            Super+1-0' \
        'Workspace  |  Move window to workspace 1-10   Super+Shift+1-0' \
        'Workspace  |  Next / previous workspace       Super+Tab / Super+Shift+Tab' \
        'Modes      |  System controls                 Ctrl+Alt+S' \
        'Modes      |  Display controls                Super+Shift+X' \
        'Modes      |  Window layout                   Super+Shift+W' \
        'Modes      |  Workspace tools                 Super+Shift+P' \
        'Modes      |  Customization                   Super+Shift+C' \
        'Capture    |  Screenshot selection            Print Screen' \
        'Capture    |  Active window screenshot        Super+Print Screen' \
        'Media      |  Volume up/down                  Volume keys' \
        'Media      |  Play/pause                      Play/Pause key'
}

show_all_keybindings() {
    # This is a guide: selecting a row must never run an arbitrary i3 command.
    awk '
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
            -mesg 'Read-only guide · Esc: back' >/dev/null
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

    case "$action" in
        "Preview (Rofi)")
            local file encoding mime size choice
            for file in "${files[@]}"; do
                [[ -r $file ]] || { notify "File is no longer readable: $file"; continue; }
                # Limit Rofi content preview to 1000 lines to prevent X11 freeze
                if [[ "${file,,}" == *.pdf ]]; then
                    pdftotext "$file" - | head -n 1000 | rofi_menu "PDF View"
                else
                    encoding=$(file --brief --mime-encoding -- "$file" 2>/dev/null) || encoding=binary
                    if [[ $encoding == binary ]]; then
                        mime=$(xdg-mime query filetype "$file" 2>/dev/null) || mime='Unknown type'
                        size=$(stat -c '%s bytes' -- "$file" 2>/dev/null) || size='Unknown size'
                        choice=$(printf '%s\n' 'Open' 'Open containing directory' 'Copy path' |
                            rofi_menu "$(basename -- "$file")" -no-custom \
                                -mesg "${mime:-Unknown type} · $size · $file") || continue
                        run_file_action "$choice" "$file"
                    else
                        head -n 1000 -- "$file" | rofi_menu "File Content" -no-custom \
                            -mesg "First 1000 lines · $(basename -- "$file")"
                    fi
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
                xdg-open "$file" && record_recent_files "$file"
            done
            ;;
        "Edit in Neovim")
            "$TERMINAL" -e nvim "${files[@]}" && record_recent_files "${files[@]}"
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

preview_grep_match() {
    local file=$1 focus=$2 level start end selected_row prompt message
    [[ -r $file && $focus =~ ^[0-9]+$ && $focus -gt 0 ]] || {
        notify "Match is no longer available: $file"
        return 1
    }

    for level in 0 1 2; do
        case $level in
            0)
                start=$((focus > 10 ? focus - 10 : 1))
                end=$((focus + 10))
                prompt="Match ±10: $(basename -- "$file"):$focus"
                message='Matched line selected · Enter: ±1000 lines · Esc: results'
                ;;
            1)
                start=$((focus > 1000 ? focus - 1000 : 1))
                end=$((focus + 1000))
                prompt="Match ±1000: $(basename -- "$file"):$focus"
                message='Matched line selected · Enter: full file · Esc: results'
                ;;
            2)
                start=1
                end=0
                prompt="Full file: $(basename -- "$file"):$focus"
                message='Matched line selected · Enter or Esc: results'
                ;;
        esac
        selected_row=$((focus - start))

        # Read through the match before showing Rofi so its selected row is present.
        # Later rows can load asynchronously, including in the full-file view.
        (set +o pipefail
            awk -v first="$start" -v last="$end" -v focus="$focus" '
                NR < first { next }
                last > 0 && NR > last { exit }
                {
                    content = $0
                    sub(/\r$/, "", content)
                    if (last > 0 && length(content) > 500)
                        content = substr(content, 1, 500) "…"
                    printf "%s %7d │ %s\n", NR == focus ? "▶" : " ", NR, content
                }
            ' "$file" |
                rofi_menu "$prompt" -no-custom -selected-row "$selected_row" \
                    -async-pre-read "$((selected_row + 1))" -mesg "$message" >/dev/null
        ) || return 0
    done
}

run_grep_action() {
    local action="$1"
    shift
    local files=()
    local lines=()
    local locations=()
    local item file line i

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
            local f line
            for i in "${!files[@]}"; do
                f=${files[$i]}
                line=${lines[$i]}
                if [[ "${f,,}" == *.pdf ]]; then
                    pdf_preview_text "$f" '' 'Grep results'
                else
                    preview_grep_match "$f" "$line"
                fi
            done
            ;;
        "Preview file (Less)")
            local f line
            for i in "${!files[@]}"; do
                f=${files[$i]}
                line=${lines[$i]}
                if [[ "${f,,}" == *.pdf ]]; then
                    "$TERMINAL" -e bash -c 'pdftotext "$1" - | less' _ "$f"
                else
                    "$TERMINAL" -e less "+${line}g" "$f"
                fi
            done
            ;;
        "Open at match")
            local nvim_args=()
            for i in "${!files[@]}"; do
                nvim_args+=("+${lines[$i]}" "${files[$i]}")
            done
            "$TERMINAL" -e nvim "${nvim_args[@]}" && record_recent_files "${files[@]}"
            ;;
        "Open file")
            "$TERMINAL" -e nvim "${files[@]}" && record_recent_files "${files[@]}"
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
    local preferred_dir=${1:-}

    [[ -f "$LAST_DIR_FILE" ]] &&
        last_dir=$(<"$LAST_DIR_FILE")

    choice=$(
        {
            [[ -n "$preferred_dir" && -d "$preferred_dir" ]] &&
                printf '🔍 Last Grep │ %s\n' "$preferred_dir"

            [[ -n "$last_dir" && -d "$last_dir" && "$last_dir" != "$preferred_dir" ]] &&
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
# Shared file, document, and grep search flow
# ============================================================

start_search_worker() {
    local kind=$1 directory=$2 query=$3 display=$4 raw=$5 status_file=$6 error_file=$7
    local -a scope_flags=()
    : > "$status_file"
    : > "$error_file"

    if [[ $kind == grep ]]; then
        search_scope_flags rg scope_flags
        : > "$raw"
        : > "$display"
        (
            rg --line-buffered --line-number --no-heading --color=never --max-columns=500 \
                --field-match-separator $'\t' --smart-case --max-filesize 10M --no-binary \
                "${scope_flags[@]}" -- "$query" "$directory" 2> "$error_file" |
            tee "$raw" | build_grep_rows > "$display"
            printf '%s\n' "$?" > "$status_file"
        ) &
    else
        search_scope_flags fd scope_flags
        : > "$display"
        if [[ $kind == documents ]]; then
            ( fdfind --type f --extension md "${scope_flags[@]}" . "$directory" 2> "$error_file" |
                shorten_paths > "$display"; printf '%s\n' "$?" > "$status_file" ) &
        else
            ( fdfind --type f "${scope_flags[@]}" "" "$directory" 2> "$error_file" |
                shorten_paths > "$display"; printf '%s\n' "$?" > "$status_file" ) &
        fi
    fi
    SEARCH_PID=$!
    track_search_pid "$SEARCH_PID"
}

run_search_results() (
    local kind=$1 directory=$2 query=${3:-}
    local prompt format default_action preview_action action_type empty_message enter_label
    local display raw status_file error_file worker_status error_message selected clean_selected first_line row first_index action file match rest line
    local rofi_status=0 last_filter='' last_selection='' SEARCH_PID=''
    local INCLUDE_HIDDEN=no INCLUDE_IGNORED=no
    local -a rofi_args=() files=() grep_items=()

    case $kind in
        files)
            prompt=Files; format=s; default_action=Open; preview_action='Preview (Rofi)'; action_type=file
            enter_label=open
            empty_message="No files found in $directory"
            ;;
        grep)
            prompt=Grep; format=i; default_action='Open at match'; preview_action='Preview file (Rofi)'; action_type=grep
            enter_label='open at match'
            empty_message="No grep matches for '$query' in $directory"
            ;;
        documents)
            prompt=Documents; format=s; default_action=Open; preview_action='Preview (Rofi)'; action_type=file
            enter_label=open
            empty_message="No Markdown documents found in $directory"
            ;;
        *) return 2 ;;
    esac

    display=$(mktemp) || return 1
    raw=$display
    if [[ $kind == grep ]]; then
        raw=$(mktemp) || { rm -f -- "$display"; return 1; }
    fi
    status_file=$(mktemp) || { rm -f -- "$display" "$raw"; return 1; }
    error_file=$(mktemp) || { rm -f -- "$display" "$raw" "$status_file"; return 1; }
    trap '[[ -z $SEARCH_PID ]] || stop_search_worker "$SEARCH_PID"; rm -f -- "$display" "$raw" "$status_file" "$error_file"' EXIT
    start_search_worker "$kind" "$directory" "$query" "$display" "$raw" "$status_file" "$error_file"

    while true; do
        rofi_args=(-multi-select -no-custom -async-pre-read 0 -format "f"$'\t'"$format"
            -kb-row-left 'Control+h' -kb-custom-2 'Alt+p' -kb-custom-3 'Alt+a'
            -kb-custom-4 'Alt+h' -kb-custom-5 'Alt+i' "${ROFI_BACK_BINDING[@]}"
            -mesg "$(search_scope_label) · Enter: $enter_label · Alt+P: preview · Alt+A: actions · Alt+H: hidden · Alt+I: ignored · Alt+B: Search")
        [[ -n $last_selection ]] && rofi_args+=(-select "$last_selection")
        [[ -n $last_filter ]] && rofi_args+=(-filter "$last_filter")

        rofi_status=0
        if kill -0 "$SEARCH_PID" 2>/dev/null; then
            selected=$(set +o pipefail; tail -n +1 -f --pid="$SEARCH_PID" "$display" | rofi_menu "$prompt" "${rofi_args[@]}") || rofi_status=$?
        else
            selected=$(set +o pipefail; cat "$display" | rofi_menu "$prompt" "${rofi_args[@]}") || rofi_status=$?
        fi

        [[ $rofi_status == 15 ]] && return 42

        # A finished worker may have produced partial rows before failing.
        # Report its error even when the user has selected one of those rows.
        worker_status=$(<"$status_file")
        if [[ -n $worker_status && $worker_status != 0 &&
              ! ( $kind == grep && $worker_status == 1 && ! -s $error_file ) ]]; then
            error_message=$(head -n 1 -- "$error_file")
            notify "$prompt search failed${error_message:+: $error_message}"
            break
        fi

        if [[ $rofi_status == 13 || $rofi_status == 14 ]]; then
            toggle_search_scope "$rofi_status" "$selected"
            stop_search_worker "$SEARCH_PID"
            start_search_worker "$kind" "$directory" "$query" "$display" "$raw" "$status_file" "$error_file"
            continue
        fi
        if [[ $rofi_status != 0 && $rofi_status != 11 && $rofi_status != 12 ]] || [[ -z $selected ]]; then
            if [[ ! -s $display ]] && ! kill -0 "$SEARCH_PID" 2>/dev/null; then
                notify "$empty_message"
            fi
            break
        fi

        if [[ $selected == *$'\t'* ]]; then
            first_line=${selected%%$'\n'*}
            last_filter=${first_line%%$'\t'*}
            clean_selected=$(printf '%s\n' "$selected" | cut -f2-)
        else
            last_filter=''
            clean_selected=$selected
        fi

        if [[ $kind == grep ]]; then
            first_index=${clean_selected%%$'\n'*}
            last_selection=''
            if [[ $first_index =~ ^[0-9]+$ ]]; then
                last_selection=$(sed -n "$((first_index + 1))p" "$display")
            fi
        else
            last_selection=${clean_selected%%$'\n'*}
            last_selection=${last_selection%$'\r'}
        fi

        case $rofi_status in
            0) action=$default_action ;;
            11) action=$preview_action ;;
            12) action=$(select_action "$action_type") || continue ;;
        esac

        if [[ $kind == grep ]]; then
            grep_items=()
            while IFS= read -r row; do
                [[ $row =~ ^[0-9]+$ ]] || continue
                match=$(sed -n "$((row + 1))p" "$raw")
                file=${match%%$'\t'*}
                rest=${match#*$'\t'}
                line=${rest%%$'\t'*}
                [[ -n $file && $line =~ ^[0-9]+$ ]] && grep_items+=("$file"$'\t'"$line")
            done <<< "$clean_selected"
            run_grep_action "$action" "${grep_items[@]}"
        else
            files=()
            while IFS= read -r row; do
                file=${row##* │ }
                [[ -n $file ]] && files+=("$file")
            done <<< "$clean_selected"
            run_file_action "$action" "${files[@]}"
        fi
    done
)

# ============================================================
# Main mode selector
# ============================================================

source "$(dirname -- "${BASH_SOURCE[0]}")/i3_pdf_menu.sh"

show_pdf_tools() {
    local choice status=0
    choice=$(printf '%s\n' 'Running searches' 'Saved searches' 'Open PDF by name' 'Cancel all PDF scans' |
        rofi_menu 'PDF tools' -no-custom "${ROFI_BACK_BINDING[@]}" \
            -mesg 'Alt+B: Search') || status=$?
    [[ $status == 15 ]] && return 42
    [[ $status == 0 ]] || return 0
    case "$choice" in
        'Running searches') pdf_command --pdf-attach ;;
        'Saved searches') pdf_command --pdf-view ;;
        'Open PDF by name') pdf_command --pdf-open ;;
        'Cancel all PDF scans') pdf_command --pdf-cancel ;;
    esac
}

if (( $# > 0 )); then
    pdf_command "$@"
    PDF_COMMAND_STATUS=$?
    [[ $PDF_COMMAND_STATUS == 42 ]] || exit "$PDF_COMMAND_STATUS"
fi

while true; do
BACK_TO_SEARCH=no
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
        "💀 System · Kill" \
        "🛑 System · Cancel" \
        "🧮 Tool · Calculator" \
        "🌐 Tool · Translate" \
        "📋 Tool · Clipboard" \
        "📄 Tool · PDF Tools" \
        "🪟 Go · Windows" \
        "🗂️ Go · Workspaces" \
        "🏷️ Go · Marks" \
        "🖥️ Go · SSH" \
        "⌨️ Help · Keybindings" |
    rofi_menu "Search" -auto-select -no-custom \
        -theme-str '
#window {
    padding: 0px 20%;
    children: [top-space, mainbox, bottom-space];
}
#mainbox { expand: false; }
#listview { lines: 10; columns: 2; }
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
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"s"
                -kb-custom-2 'Alt+p' -kb-custom-3 'Alt+a' "${ROFI_BACK_BINDING[@]}"
                -mesg 'Enter: open · Alt+P: preview · Alt+A: actions · Alt+B: Search')

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            ROFI_STATUS=0
            SELECTED=$(printf '%s\n' "$RECENT_DISPLAY" | rofi_menu "Recent files" "${ROFI_ARGS[@]}") || ROFI_STATUS=$?
            [[ $ROFI_STATUS == 15 ]] && { BACK_TO_SEARCH=yes; break; }
            [[ -n "$SELECTED" && ( $ROFI_STATUS == 0 || $ROFI_STATUS == 11 || $ROFI_STATUS == 12 ) ]] || break

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

            case $ROFI_STATUS in
                0) ACTION=Open ;;
                11) ACTION='Preview (Rofi)' ;;
                12) ACTION=$(select_action file) || continue ;;
            esac

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
        run_search_results files "$TARGET_DIR"
        [[ $? == 42 ]] && BACK_TO_SEARCH=yes
        ;;

    *Grep*)
        LAST_GREP_QUERY=''
        [[ -f "$LAST_GREP_QUERY_FILE" ]] && LAST_GREP_QUERY=$(<"$LAST_GREP_QUERY_FILE")
        ROFI_ARGS=()
        [[ -n "$LAST_GREP_QUERY" ]] && ROFI_ARGS+=(-filter "$LAST_GREP_QUERY")
        QUERY=$(rofi_menu "Grep for" "${ROFI_ARGS[@]}")
        [[ -n "$QUERY" ]] || { notify "Exited $MODE"; exit 0; }
        # Reuse the previous Grep directory while keeping the full directory picker available.
        if [[ -s "$LAST_GREP_DIR_FILE" ]]; then
            LAST_GREP_DIR=$(<"$LAST_GREP_DIR_FILE")
        else
            LAST_GREP_DIR=''
        fi
        TARGET_DIR=$(select_directory "${LAST_GREP_DIR:-}") || exit 0
        printf '%s' "$QUERY" > "$LAST_GREP_QUERY_FILE"
        printf '%s' "$TARGET_DIR" > "$LAST_GREP_DIR_FILE"
        notify "🔍 Grepping for '$QUERY' in $TARGET_DIR..."
        run_search_results grep "$TARGET_DIR" "$QUERY"
        [[ $? == 42 ]] && BACK_TO_SEARCH=yes
        ;;

    *Documents*)
        run_search_results documents "$DOCUMENT_DIR"
        [[ $? == 42 ]] && BACK_TO_SEARCH=yes
        ;;

    *Cancel*)
        global_cancel
        ;;

    *PDF\ Search*)
        pdf_command --pdf-search
        [[ $? == 42 ]] && BACK_TO_SEARCH=yes
        ;;

    *PDF\ Tools*)
        show_pdf_tools
        [[ $? == 42 ]] && BACK_TO_SEARCH=yes
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
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"i"
                -kb-custom-3 'Alt+a' "${ROFI_BACK_BINDING[@]}"
                -mesg 'Enter: open · Alt+A: actions · Alt+B: Search')

            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            ROFI_STATUS=0
            SELECTED=$(printf '%s\n' "${HISTORY_ROWS[@]}" | rofi_menu "History" "${ROFI_ARGS[@]}") || ROFI_STATUS=$?
            [[ $ROFI_STATUS == 15 ]] && { BACK_TO_SEARCH=yes; break; }
            [[ -n "$SELECTED" && ( $ROFI_STATUS == 0 || $ROFI_STATUS == 12 ) ]] || break

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

            if [[ $ROFI_STATUS == 12 ]]; then
                ACTION=$(select_action url) || continue
            else
                ACTION=Open
            fi

            URLS=()
            while IFS= read -r row_index; do
                [[ "$row_index" =~ ^[0-9]+$ ]] || continue
                URL="${HISTORY_URLS[row_index]:-}"
                [[ -n "$URL" ]] && URLS+=("$URL")
            done <<< "$CLEAN_SELECTED"

            run_url_action "$ACTION" "${URLS[@]}"
        done
        rm -f -- "$HISTORY_COPY"
        trap - EXIT
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
            ROFI_ARGS=("-multi-select" "-no-custom" "-format" "f"$'\t'"i"
                -kb-custom-3 'Alt+a' "${ROFI_BACK_BINDING[@]}"
                -mesg 'Enter: open · Alt+A: actions · Alt+B: Search')

            # Restore the previous input and selected row after an action.
            [[ -n "$LAST_SELECTION" ]] && ROFI_ARGS+=("-select" "$LAST_SELECTION")
            [[ -n "$LAST_FILTER" ]] && ROFI_ARGS+=("-filter" "$LAST_FILTER")

            ROFI_STATUS=0
            SELECTED=$(printf '%s\n' "${BMARK_ROWS[@]}" | rofi_menu "Bookmarks" "${ROFI_ARGS[@]}") || ROFI_STATUS=$?
            [[ $ROFI_STATUS == 15 ]] && { BACK_TO_SEARCH=yes; break; }
            [[ -n "$SELECTED" && ( $ROFI_STATUS == 0 || $ROFI_STATUS == 12 ) ]] || break

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

            if [[ $ROFI_STATUS == 12 ]]; then
                ACTION=$(select_action url) || continue
            else
                ACTION=Open
            fi

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

    *Workspaces*)
        "$(dirname -- "${BASH_SOURCE[0]}")/i3_workspace_operator.sh" goto
        ;;

    *Marks*)
        MARK_ENTRIES=$(i3-msg -t get_tree | jq -r '
                recurse(.nodes[], .floating_nodes[]?)
                | select(.marks != null and (.marks | length > 0))
                | . as $node
                | .marks[]
                | [$node.id, .,
                   ($node.name // $node.window_properties.title // "(untitled)")
                  ]
                | @tsv
            ') || { notify 'Could not read i3 marks'; exit 1; }
        [[ -n $MARK_ENTRIES ]] || { notify 'No marked windows'; exit 0; }

        MARK_ROWS=()
        MARK_IDS=()
        while IFS=$'\t' read -r MARK_ID MARK_LABEL MARK_TITLE; do
            [[ $MARK_ID =~ ^[0-9]+$ ]] || continue
            MARK_IDS+=("$MARK_ID")
            MARK_ROWS+=("$MARK_LABEL"$'\t'"$MARK_TITLE")
        done <<< "$MARK_ENTRIES"
        (( ${#MARK_ROWS[@]} > 0 )) || { notify 'No marked windows'; exit 0; }

        MARK_INDEX=$(printf '%s\n' "${MARK_ROWS[@]}" |
            rofi_menu "Jump to mark" -auto-select -no-custom -format i) || exit 0
        [[ $MARK_INDEX =~ ^[0-9]+$ && -n ${MARK_IDS[MARK_INDEX]:-} ]] || exit 0
        i3-msg "[con_id=${MARK_IDS[MARK_INDEX]}] focus" >/dev/null
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
[[ $BACK_TO_SEARCH == yes ]] || break
done
