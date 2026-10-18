#!/usr/bin/env bash
# Sourced by i3_rofi_omnisearch.sh after its common Rofi and clipboard helpers.

PDF_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PDF_SEARCH_HELPER="$PDF_SCRIPT_DIR/i3_pdf_search.py"
PDF_DEFAULT_DIR="$HOME/Documents/PAPERS"
PDF_VIEWER=sioyek
PDF_CACHE_DIR="$CACHE_DIR/pdf"
mkdir -p "$PDF_CACHE_DIR"

pdf_cache_paths() {
    local directory=$1 query=$2 match_mode=$3 max_files=$4
    PDF_KEY=$(printf '%s\0%s\0%s\0%s' "$directory" "$query" "$match_mode" "$max_files" | sha256sum | cut -d' ' -f1)
    PDF_RECORDS="$PDF_CACHE_DIR/$PDF_KEY.jsonl"
    PDF_DISPLAY="$PDF_CACHE_DIR/$PDF_KEY.rows"
    PDF_META="$PDF_CACHE_DIR/$PDF_KEY.meta.json"
    PDF_LIVE_RECORDS="$PDF_CACHE_DIR/$PDF_KEY.live.jsonl"
    PDF_LIVE_DISPLAY="$PDF_CACHE_DIR/$PDF_KEY.live.rows"
    PDF_ACTIVE="$PDF_CACHE_DIR/pdf-active-$PDF_KEY.json"
}

pdf_cancel() {
    local count
    count=$(python3 "$PDF_SEARCH_HELPER" cancel --cache-dir "$PDF_CACHE_DIR") || return 1
    notify "Cancelled $count active PDF search(es)."
}

pdf_choose_directory() {
    local choice
    choice=$(printf '%s\n' 'Papers' 'Choose directory' |
        rofi_menu 'PDF search location' -no-custom) || return 1
    case "$choice" in
        Papers)
            [[ -d "$PDF_DEFAULT_DIR" ]] || {
                notify "Papers directory does not exist: $PDF_DEFAULT_DIR"
                return 1
            }
            printf '%s\n' "$PDF_DEFAULT_DIR"
            ;;
        'Choose directory') select_directory ;;
        *) return 1 ;;
    esac
}

pdf_choose_match_mode() {
    local choice
    choice=$(printf '%s\n' 'All words (literal)' 'Exact phrase' 'Regular expression' |
        rofi_menu 'PDF match type' -no-custom) || return 1
    case "$choice" in
        'All words (literal)') printf 'words\n' ;;
        'Exact phrase') printf 'phrase\n' ;;
        'Regular expression') printf 'regex\n' ;;
        *) return 1 ;;
    esac
}

pdf_open_record() {
    local record=$1 file page
    file=$(jq -r '.file' <<< "$record")
    page=$(jq -r '.page // empty' <<< "$record")
    [[ -f "$file" ]] || { notify "PDF no longer exists: $file"; return 1; }
    record_recent_files "$file"
    if [[ -n "$page" ]]; then
        if [[ "$PDF_VIEWER" == sioyek ]]; then
            sioyek --page "$page" "$file" >/dev/null 2>&1 &
        else
            "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
        fi
    else
        "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
    fi
}

pdf_record_for_id() {
    local records=$1 id=$2
    jq -c --argjson id "$id" 'select(.id == $id)' "$records" | head -n 1
}

pdf_action() {
    local selected=$1 records=$2 record action file page dir id
    local -a ids=() files=()
    while IFS= read -r row; do
        id=${row%%$'\t'*}
        [[ $id =~ ^[0-9]+$ ]] && ids+=("$id")
    done <<< "$selected"
    (( ${#ids[@]} > 0 )) || return 0
    record=$(pdf_record_for_id "$records" "${ids[0]}")
    [[ -n "$record" ]] || { notify 'PDF result is no longer available'; return 1; }
    file=$(jq -r '.file' <<< "$record")
    page=$(jq -r '.page // empty' <<< "$record")

    action=$(printf '%s\n' 'Open in Sioyek' 'Preview page' 'Open selected PDFs' \
        'Review matching PDFs' 'Open all matching PDFs' 'Open containing directory' \
        'Copy PDF path' 'Copy PDF:page' |
        rofi_menu 'PDF action' -no-custom) || return 0
    case "$action" in
        'Open in Sioyek') pdf_open_record "$record" ;;
        'Preview page')
            [[ -n "$page" ]] || page=1
            local preview
            preview=$(pdftotext -f "$page" -l "$page" "$file" - 2>/dev/null | head -c 6000)
            rofi -e "${preview:-No extractable text on this page}" "${ROFI_OPTION[@]}"
            ;;
        'Open selected PDFs')
            local selected_record
            local -A opened=()
            for id in "${ids[@]}"; do
                selected_record=$(pdf_record_for_id "$records" "$id")
                [[ -n "$selected_record" ]] || continue
                file=$(jq -r '.file' <<< "$selected_record")
                [[ -v opened["$file"] ]] && continue
                opened["$file"]=1
                pdf_open_record "$selected_record"
            done
            ;;
        'Review matching PDFs') pdf_review_files "$records" ;;
        'Open all matching PDFs') pdf_open_all "$records" ;;
        'Open containing directory')
            dir=$(dirname -- "$file")
            xdg-open "$dir"
            ;;
        'Copy PDF path') copy_text "$file" ;;
        'Copy PDF:page') copy_text "$file:${page:-1}" ;;
    esac
}

pdf_open_all() {
    local records=$1 count choice file
    local -a files=()
    mapfile -d '' -t files < <(jq -j 'select(.kind == "file") | .file, "\u0000"' "$records")
    count=${#files[@]}
    (( count > 0 )) || { notify 'No matching PDFs'; return 0; }
    if (( count > 10 )); then
        choice=$(printf '%s\n' 'Open first 10' "Open all $count" 'Cancel' |
            rofi_menu "Open $count PDFs?" -no-custom) || return 0
        case "$choice" in
            'Open first 10') files=("${files[@]:0:10}") ;;
            "Open all $count") ;;
            *) return 0 ;;
        esac
    fi
    for file in "${files[@]}"; do
        [[ -f "$file" ]] || continue
        record_recent_files "$file"
        "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
    done
}

pdf_review_files() {
    local records=$1 file choice window_id before after
    local -a files=()
    mapfile -d '' -t files < <(jq -j 'select(.kind == "file") | .file, "\u0000"' "$records")
    for file in "${files[@]}"; do
        choice=$(printf '%s\n' 'Open current PDF' 'Next PDF' 'End review' |
            rofi_menu "Review: $(basename -- "$file")" -no-custom) || return 0
        case "$choice" in
            'End review') return 0 ;;
            'Next PDF') continue ;;
            'Open current PDF')
                [[ -f "$file" ]] || continue
                record_recent_files "$file"
                before=
                [[ "$PDF_VIEWER" == sioyek ]] && before=$(wmctrl -lx 2>/dev/null | awk 'tolower($3 $4) ~ /sioyek/ {print $1}')
                if [[ "$PDF_VIEWER" == sioyek ]]; then
                    sioyek --new-window "$file" >/dev/null 2>&1 &
                else
                    "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
                fi
                window_id=
                if [[ "$PDF_VIEWER" == sioyek ]] && command -v wmctrl >/dev/null 2>&1; then
                    for _ in {1..20}; do
                        after=$(wmctrl -lx 2>/dev/null | awk 'tolower($3 $4) ~ /sioyek/ {print $1}')
                        window_id=$(comm -13 <(printf '%s\n' "$before" | sort) \
                            <(printf '%s\n' "$after" | sort) | head -n 1)
                        [[ -n "$window_id" ]] && break
                        sleep 0.1
                    done
                fi
                if command -v dunstify >/dev/null 2>&1; then
                    choice=$(dunstify --action='keep,Keep Open' \
                        --action='close,Close PDF' --action='end,End Review' \
                        --timeout=0 'PDF review' "$(basename -- "$file")") || return 0
                else
                    choice=$(printf '%s\n' 'Keep open and continue' 'Close PDF' 'End review' |
                        rofi_menu 'Review opened PDF' -no-custom) || return 0
                fi
                case "$choice" in
                    close|'Close PDF'|end|'End review')
                        [[ -n "$window_id" ]] && wmctrl -ic "$window_id" 2>/dev/null
                        ;;
                esac
                [[ "$choice" == end || "$choice" == 'End review' ]] && return 0
                ;;
        esac
    done
}

pdf_show_results() {
    local key=$1 worker=${2:-} selected records display
    PDF_KEY=$key
    PDF_RECORDS="$PDF_CACHE_DIR/$key.jsonl"
    PDF_DISPLAY="$PDF_CACHE_DIR/$key.rows"
    PDF_LIVE_RECORDS="$PDF_CACHE_DIR/$key.live.jsonl"
    PDF_LIVE_DISPLAY="$PDF_CACHE_DIR/$key.live.rows"
    while true; do
        records=$PDF_RECORDS
        display=$PDF_DISPLAY
        if [[ -n "$worker" ]] && kill -0 "$worker" 2>/dev/null; then
            records=$PDF_LIVE_RECORDS
            display=$PDF_LIVE_DISPLAY
            selected=$(python3 "$PDF_SEARCH_HELPER" follow --display "$display" \
                --pid "$worker" |
                rofi_menu 'PDF results' -multi-select -no-custom) || break
        else
            [[ -f "$display" ]] || { notify 'PDF search ended without results'; break; }
            selected=$(rofi_menu 'PDF results' -multi-select -no-custom < "$display") || break
        fi
        [[ -n "$selected" ]] || break
        [[ -f "$records" ]] || records=$PDF_RECORDS
        pdf_action "$selected" "$records"
    done
}

pdf_search() {
    local scope=${1:-choose} batch=${2:-no} query_override=${3:-}
    local directory_override=${4:-} mode_override=${5:-} max_files=${6:--1}
    local directory query mode worker
    if [[ -n "$query_override" ]]; then
        query=$query_override
    else
        query=$(rofi_menu 'Search PDF text') || return 0
    fi
    [[ -n "$query" ]] || return 0
    if [[ -n "$directory_override" ]]; then
        directory=$directory_override
    elif [[ "$scope" == default ]]; then
        directory=$PDF_DEFAULT_DIR
    elif [[ "$scope" == choose ]]; then
        directory=$(pdf_choose_directory) || return 0
    else
        directory=$(select_directory) || return 0
    fi
    [[ -d "$directory" ]] || { notify "Directory does not exist: $directory"; return 1; }
    directory=$(realpath -- "$directory")
    mode=${mode_override:-words}
    [[ "$scope" == choose && -z "$mode_override" ]] && mode=$(pdf_choose_match_mode) || true
    [[ -n "$mode" ]] || return 0
    pdf_cache_paths "$directory" "$query" "$mode" "$max_files"

    worker=$(python3 "$PDF_SEARCH_HELPER" status --active "$PDF_ACTIVE" 2>/dev/null) || worker=
    if [[ -n "$worker" ]]; then
        [[ "$batch" == all ]] && notify 'This PDF search is still running' || pdf_show_results "$PDF_KEY" "$worker"
        return 0
    fi

    if [[ -f "$PDF_META" && -f "$PDF_RECORDS" && -f "$PDF_DISPLAY" ]]; then
        local choice
        choice=$(printf '%s\n' 'Show saved results' 'Search again' |
            rofi_menu 'PDF search already saved' -no-custom) || return 0
        [[ "$choice" == 'Show saved results' ]] && {
            [[ "$batch" == all ]] && pdf_open_all "$PDF_RECORDS" || pdf_show_results "$PDF_KEY"
            return
        }
        [[ "$choice" == 'Search again' ]] || return 0
    fi

    [[ -e "$PDF_LIVE_RECORDS" ]] || : > "$PDF_LIVE_RECORDS"
    [[ -e "$PDF_LIVE_DISPLAY" ]] || : > "$PDF_LIVE_DISPLAY"
    python3 "$PDF_SEARCH_HELPER" scan --directory "$directory" --query "$query" \
        --mode "$mode" --records "$PDF_LIVE_RECORDS" --display "$PDF_LIVE_DISPLAY" \
        --cache-records "$PDF_RECORDS" --cache-display "$PDF_DISPLAY" \
        --meta "$PDF_META" --active "$PDF_ACTIVE" --max-files "$max_files" &
    worker=$!
    if [[ "$batch" == all ]]; then
        notify 'Searching PDFs before opening matches...'
        wait "$worker" || { notify 'PDF search failed or was cancelled'; return 1; }
        pdf_open_all "$PDF_RECORDS"
    else
        pdf_show_results "$PDF_KEY" "$worker"
    fi
}

pdf_view_saved() {
    local meta row selected key
    local -a rows=()
    shopt -s nullglob
    for meta in "$PDF_CACHE_DIR"/*.meta.json; do
        row=$(jq -r '[.created, (.files | tostring) + " PDFs", .query, .directory] | @tsv' "$meta")
        rows+=("$(basename "$meta" .meta.json)"$'\t'"$row")
    done
    shopt -u nullglob
    (( ${#rows[@]} > 0 )) || { notify 'No saved PDF searches'; return 0; }
    selected=$(printf '%s\n' "${rows[@]}" |
        rofi_menu 'Saved PDF searches' -no-custom) || return 0
    key=${selected%%$'\t'*}
    [[ $key =~ ^[0-9a-f]{64}$ ]] && pdf_show_results "$key"
}

pdf_open_by_name() {
    local directory clipboard choice file
    clipboard=$(xclip -o -selection clipboard 2>/dev/null || true)
    if [[ -f "$clipboard" && "${clipboard,,}" == *.pdf ]]; then
        pdf_open_record "$(jq -nc --arg file "$clipboard" '{file: $file, page: null}')"
        return
    fi
    directory=$(pdf_choose_directory) || return 0
    choice=$(
        { [[ -f "$clipboard" && "${clipboard,,}" == *.pdf ]] && printf '%s\n' "$clipboard"
          find "$directory" -type f -iname '*.pdf' -print; } |
        rofi_menu 'Open PDF by filename or path'
    ) || return 0
    file=${choice/#\~/$HOME}
    [[ -f "$file" && "${file,,}" == *.pdf ]] || {
        notify "PDF does not exist: $file"
        return 1
    }
    record_recent_files "$file"
    "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
}

pdf_command() {
    case ${1:-} in
        --pdf-search) pdf_search choose ;;
        --pdf-search-default) pdf_search default ;;
        --pdf-search-dir) pdf_search directory ;;
        --pdf-search-all) pdf_search default all ;;
        --pdf-search-dir-all) pdf_search directory all ;;
        --pdf-search-compat)
            shift
            PDF_VIEWER=${4:-sioyek}
            pdf_search custom "${3:-no}" "${1:-}" "${2:-}" words "${5:--1}"
            ;;
        --pdf-open) pdf_open_by_name ;;
        --pdf-view) pdf_view_saved ;;
        --pdf-cancel) pdf_cancel ;;
        *) return 2 ;;
    esac
}
