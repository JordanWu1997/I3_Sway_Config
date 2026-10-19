#!/usr/bin/env bash
# Sourced by i3_rofi_omnisearch.sh after its common Rofi and clipboard helpers.

PDF_SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PDF_SEARCH_HELPER="$PDF_SCRIPT_DIR/i3_pdf_search.py"
PDF_DEFAULT_DIR="$HOME/Documents/PAPERS"
PDF_DEFAULT_LABEL=Papers
if [[ ! -d "$PDF_DEFAULT_DIR" ]]; then
    PDF_DEFAULT_DIR="$HOME/Documents/PDF"
    PDF_DEFAULT_LABEL="PDF folder"
fi
if [[ ! -d "$PDF_DEFAULT_DIR" ]]; then
    PDF_DEFAULT_DIR="$HOME/Documents"
    PDF_DEFAULT_LABEL=Documents
fi
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
    PDF_PROGRESS="$PDF_CACHE_DIR/$PDF_KEY.progress.json"
}

pdf_cancel() {
    local count
    count=$(python3 "$PDF_SEARCH_HELPER" cancel --cache-dir "$PDF_CACHE_DIR") || return 1
    notify "Cancelled $count active PDF search(es)."
}

pdf_choose_directory() {
    local choice
    choice=$({
        printf '%s\n' "$PDF_DEFAULT_LABEL"
        [[ "$PDF_DEFAULT_DIR" == "$HOME/Documents" ]] || printf 'All Documents\n'
        printf 'Home (~)\n'
        printf 'Choose directory\n'
    } | rofi_menu 'PDF search location' -no-custom) || return 1
    case "$choice" in
        "$PDF_DEFAULT_LABEL")
            [[ -d "$PDF_DEFAULT_DIR" ]] || {
                notify "PDF directory does not exist: $PDF_DEFAULT_DIR"
                return 1
            }
            printf '%s\n' "$PDF_DEFAULT_DIR"
            ;;
        'All Documents') printf '%s\n' "$HOME/Documents" ;;
        'Home (~)') printf '%s\n' "$HOME" ;;
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
            sioyek --new-window --page "$page" "$file" >/dev/null 2>&1 &
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

pdf_preview_text() {
    local file=$1 content
    [[ -f "$file" ]] || { notify "PDF no longer exists: $file"; return 1; }
    # Keep the Rofi list bounded so large PDFs do not stall the X11 menu.
    content=$(pdftotext "$file" - 2>/dev/null | head -n 1000)
    [[ -n "$content" ]] || { notify "No extractable text in $(basename -- "$file")"; return 0; }
    printf '%s\n' "$content" |
        rofi_menu "PDF text: $(basename -- "$file")" -no-custom \
            -mesg 'First 1000 lines · Type to filter · Esc: PDF results' >/dev/null || true
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

    action=$(printf '%s\n' 'Open in Sioyek' 'Preview PDF text (Rofi)' 'Quick page preview' 'Open selected PDFs' \
        'Review selected PDFs' 'Review all matching PDFs' 'Open all matching PDFs' 'Open containing directory' \
        'Copy PDF path' 'Copy PDF:page' |
        rofi_menu 'PDF action' -no-custom) || return 0
    case "$action" in
        'Open in Sioyek') pdf_open_record "$record" ;;
        'Preview PDF text (Rofi)') pdf_preview_text "$file" ;;
        'Quick page preview')
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
        'Review selected PDFs') pdf_review_files "$records" "${ids[@]}" ;;
        'Review all matching PDFs') pdf_review_files "$records" ;;
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
    local records=$1 file choice window_id before after state index=0 selected_id selected_record
    shift
    local -a files=()
    local -A seen=()
    if (( $# > 0 )); then
        for selected_id in "$@"; do
            selected_record=$(pdf_record_for_id "$records" "$selected_id")
            [[ -n "$selected_record" ]] || continue
            file=$(jq -r '.file' <<< "$selected_record")
            [[ -v seen["$file"] ]] && continue
            seen["$file"]=1
            files+=("$file")
        done
    else
        mapfile -d '' -t files < <(jq -j 'select(.kind == "file") | .file, "\u0000"' "$records")
    fi
    (( ${#files[@]} > 0 )) || { notify 'No matching PDFs to review'; return 0; }
    state="$PDF_CACHE_DIR/review-$(printf '%s\0' "$records" "${files[@]}" | sha256sum | cut -d' ' -f1).position"
    if [[ -f "$state" ]]; then
        read -r index < "$state"
        [[ $index =~ ^[0-9]+$ ]] || index=0
        (( index < ${#files[@]} )) || index=0
    fi
    for (( ; index < ${#files[@]}; index++ )); do
        file=${files[index]}
        printf '%s\n' "$index" > "$state"
        choice=$(printf '%s\n' 'Open current PDF' 'Next PDF' 'End review' |
            rofi_menu "Review $((index + 1))/${#files[@]}: $(basename -- "$file")" -no-custom) || return 0
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
    rm -f -- "$state"
}

pdf_show_pages() {
    local records=$1 file=$2 selected status=0 id record
    local -a rows=()
    mapfile -t rows < <(jq -r --arg file "$file" \
        'select(.kind == "match" and .file == $file) | "\(.id | tostring | ("000000" + .)[-6:])\t p\(.page) \(.snippet | gsub("[\\r\\n\\t]"; " "))"' "$records")
    (( ${#rows[@]} > 0 )) || { notify 'No page excerpts for this PDF'; return 0; }
    while true; do
        status=0
        selected=$(printf '%s\n' "${rows[@]}" | rofi_menu "Pages: $(basename -- "$file")" \
            -no-custom -format s -kb-custom-3 'Alt+a' \
            -mesg 'Enter: open page · Alt+A: actions · Esc: PDF list') || status=$?
        [[ $status == 0 || $status == 12 ]] || return 0
        id=${selected%%$'\t'*}
        [[ $id =~ ^[0-9]+$ ]] || return 0
        record=$(pdf_record_for_id "$records" "$id")
        [[ -n "$record" ]] || { notify 'PDF result is no longer available'; return 1; }
        if [[ $status == 12 ]]; then
            pdf_action "$selected" "$records"
        else
            pdf_open_record "$record"
        fi
    done
}

pdf_show_results() {
    local key=$1 worker selected records display first_line clean_selected row id record file progress
    local last_filter='' last_selection='' rofi_status=0
    local -a rofi_args
    PDF_KEY=$key
    PDF_RECORDS="$PDF_CACHE_DIR/$key.jsonl"
    PDF_DISPLAY="$PDF_CACHE_DIR/$key.rows"
    PDF_LIVE_RECORDS="$PDF_CACHE_DIR/$key.live.jsonl"
    PDF_LIVE_DISPLAY="$PDF_CACHE_DIR/$key.live.rows"
    PDF_META="$PDF_CACHE_DIR/$key.meta.json"
    PDF_ACTIVE="$PDF_CACHE_DIR/pdf-active-$key.json"
    PDF_PROGRESS="$PDF_CACHE_DIR/$key.progress.json"
    while true; do
        worker=$(python3 "$PDF_SEARCH_HELPER" status --active "$PDF_ACTIVE" 2>/dev/null) || worker=
        records=$PDF_RECORDS
        display=$PDF_DISPLAY
        rofi_args=(-multi-select -no-custom -format "f"$'\t'"s")
        [[ -n "$last_filter" ]] && rofi_args+=(-filter "$last_filter")
        [[ -n "$last_selection" ]] && rofi_args+=(-select "$last_selection")
        rofi_status=0
        if [[ -n "$worker" ]]; then
            records=$PDF_LIVE_RECORDS
            display=$PDF_LIVE_DISPLAY
            progress=$(jq -r '"Scanned \(.scanned // 0) PDFs · \(.files // 0) matches · \(.skipped // 0) skipped · \(.seconds // 0)s"' "$PDF_PROGRESS" 2>/dev/null) || progress='Starting scan'
            selected=$({
                printf '↻ Refresh results\n'
                [[ -f "$display" ]] && awk -F '\t' 'index($2, "PDF ") == 1' "$display"
                :
            } | rofi_menu 'PDF results (scanning)' "${rofi_args[@]}" \
                -kb-custom-1 'Alt+r' \
                -kb-custom-2 'Alt+p' -kb-custom-3 'Alt+a' \
                -mesg "$progress · Enter: open · Alt+P: pages · Alt+A: actions · Alt+R: refresh · Esc: scan continues; PDF Search to reattach") || rofi_status=$?
        else
            [[ -f "$display" ]] || { notify 'PDF search ended without results'; break; }
            [[ -s "$display" ]] || {
                progress=$(jq -r '"Scanned \(.scanned // 0) PDFs; \(.skipped // 0) could not be read"' "$PDF_META" 2>/dev/null) || progress='No extractable matches'
                notify "No matching PDF text found. $progress"
                break
            }
            progress=$(jq -r '"\(.files // 0) matching PDFs · \(.matches // 0) excerpts · \(.scanned // 0) scanned"' "$PDF_META" 2>/dev/null) || progress=''
            selected=$(awk -F '\t' 'index($2, "PDF ") == 1' "$display" |
                rofi_menu 'PDF results' "${rofi_args[@]}" \
                    -kb-custom-2 'Alt+p' -kb-custom-3 'Alt+a' \
                    -mesg "$progress · Enter: open · Alt+P: pages · Alt+A: actions") || rofi_status=$?
        fi
        [[ "$rofi_status" == 0 || "$rofi_status" == 10 || "$rofi_status" == 11 || "$rofi_status" == 12 ]] || break
        [[ -n "$selected" ]] || { [[ "$rofi_status" == 10 ]] && continue; break; }
        first_line=${selected%%$'\n'*}
        if [[ "$first_line" == *$'\t'* ]]; then
            last_filter=${first_line%%$'\t'*}
            clean_selected=$(printf '%s\n' "$selected" | cut -f2-)
        else
            clean_selected=$selected
        fi
        while IFS= read -r row; do
            id=${row%%$'\t'*}
            if [[ $id =~ ^[0-9]+$ ]]; then
                last_selection=$row
                break
            fi
        done <<< "$clean_selected"
        [[ "$rofi_status" == 10 || "$clean_selected" == '↻ Refresh results' ]] && continue
        [[ -f "$records" ]] || records=$PDF_RECORDS
        id=${clean_selected%%$'\t'*}
        [[ $id =~ ^[0-9]+$ ]] || continue
        record=$(pdf_record_for_id "$records" "$id")
        [[ -n "$record" ]] || { notify 'PDF result is no longer available'; continue; }
        file=$(jq -r '.file' <<< "$record")
        case "$rofi_status" in
            11) pdf_show_pages "$records" "$file" ;;
            12) pdf_action "$clean_selected" "$records" ;;
            0)
                if [[ "$clean_selected" == *$'\n'* ]]; then
                    pdf_action "$clean_selected" "$records"
                else
                    pdf_open_record "$record"
                fi
                ;;
        esac
    done
}

pdf_attach_running() {
    local include_new=${1:-no} active_json task key pid query mode directory scanned files selected rofi_status count cancelled=no
    local -a tasks=() rows=() keys=()
    while true; do
        tasks=() rows=() keys=()
        active_json=$(python3 "$PDF_SEARCH_HELPER" active --cache-dir "$PDF_CACHE_DIR") || {
            notify 'Could not list running PDF searches'
            return 1
        }
        mapfile -t tasks < <(jq -r '.[] | [.key, (.pid | tostring), .query, .mode, .directory, (.scanned | tostring), (.files | tostring)] | @tsv' <<< "$active_json")
        if (( ${#tasks[@]} == 0 )); then
            if [[ "$cancelled" == yes ]]; then
                return
            elif [[ "$include_new" == yes ]]; then
                pdf_search choose
            else
                notify 'No PDF searches are running'
            fi
            return
        fi
        if [[ "$include_new" == yes ]]; then
            rows+=('Start new PDF search')
            keys+=('new')
        fi
        for task in "${tasks[@]}"; do
            IFS=$'\t' read -r key pid query mode directory scanned files <<< "$task"
            case "$mode" in
                words) mode='All words' ;;
                phrase) mode='Exact phrase' ;;
                regex) mode='Regex' ;;
            esac
            if [[ "$directory" == "$HOME" ]]; then
                directory='~'
            elif [[ "$directory" == "$HOME/"* ]]; then
                directory="~/${directory#"$HOME/"}"
            fi
            rows+=("[$mode] $query  ·  $directory  ·  $scanned scanned  ·  $files PDFs")
            keys+=("$key")
        done
        rofi_status=0
        selected=$(printf '%s\n' "${rows[@]}" |
            rofi_menu 'Running PDF searches' -no-custom -format i \
                -kb-custom-4 'Alt+c' \
                -mesg 'Enter: attach · Alt+C: cancel selected scan · Esc: back') || rofi_status=$?
        [[ $rofi_status == 0 || $rofi_status == 13 ]] || return 0
        [[ $selected =~ ^[0-9]+$ && $selected -lt ${#keys[@]} ]] || continue
        key=${keys[selected]}
        if [[ $key == new ]]; then
            [[ $rofi_status == 0 ]] && pdf_search choose
            return
        fi
        [[ $key =~ ^[0-9a-f]{64}$ ]] || continue
        if [[ $rofi_status == 13 ]]; then
            count=$(python3 "$PDF_SEARCH_HELPER" cancel --cache-dir "$PDF_CACHE_DIR" --key "$key") || return 1
            cancelled=yes
            if [[ $count == 1 ]]; then
                notify 'PDF search cancelled'
            else
                notify 'PDF search already finished'
            fi
            continue
        fi
        pdf_show_results "$key"
        return
    done
}

pdf_search() {
    local scope=${1:-choose} batch=${2:-no} query_override=${3:-}
    local directory_override=${4:-} mode_override=${5:-} max_files=${6:--1} force=${7:-no}
    local directory query mode worker attempt
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
        [[ "$batch" == all ]] && notify 'This PDF search is still running' || pdf_show_results "$PDF_KEY"
        return 0
    fi

    if [[ "$force" != yes && -f "$PDF_META" && -f "$PDF_RECORDS" && -f "$PDF_DISPLAY" ]]; then
        local choice
        choice=$(printf '%s\n' 'Show saved results' 'Search again' |
            rofi_menu 'PDF search already saved' -no-custom) || return 0
        [[ "$choice" == 'Show saved results' ]] && {
            [[ "$batch" == all ]] && pdf_open_all "$PDF_RECORDS" || pdf_show_results "$PDF_KEY"
            return
        }
        [[ "$choice" == 'Search again' ]] || return 0
    fi

    : > "$PDF_LIVE_RECORDS"
    : > "$PDF_LIVE_DISPLAY"
    rm -f -- "$PDF_PROGRESS"
    python3 "$PDF_SEARCH_HELPER" scan --directory "$directory" --query "$query" \
        --mode "$mode" --records "$PDF_LIVE_RECORDS" --display "$PDF_LIVE_DISPLAY" \
        --cache-records "$PDF_RECORDS" --cache-display "$PDF_DISPLAY" \
        --meta "$PDF_META" --active "$PDF_ACTIVE" --progress "$PDF_PROGRESS" \
        --max-files "$max_files" &
    worker=$!
    if [[ "$batch" == all ]]; then
        notify 'Searching PDFs before opening matches...'
        wait "$worker" || { notify 'PDF search failed or was cancelled'; return 1; }
        pdf_open_all "$PDF_RECORDS"
    else
        # Let the worker publish its identity before the results view checks it.
        for (( attempt=0; attempt<20; attempt++ )); do
            python3 "$PDF_SEARCH_HELPER" status --active "$PDF_ACTIVE" --quiet 2>/dev/null && break
            kill -0 "$worker" 2>/dev/null || break
            sleep 0.05
        done
        pdf_show_results "$PDF_KEY"
    fi
}

pdf_view_saved() {
    local meta row created query mode count directory when key label selected status=0
    local -a entries=() rows=() keys=() saved=()
    shopt -s nullglob
    for meta in "$PDF_CACHE_DIR"/*.meta.json; do
        row=$(jq -r '[.created, .query, .mode, (.files | tostring), .directory] | @tsv' "$meta") || continue
        IFS=$'\t' read -r created query mode count directory <<< "$row"
        [[ -n "$created" && -n "$query" ]] || continue
        case "$mode" in
            words) mode='All words' ;;
            phrase) mode='Exact phrase' ;;
            regex) mode='Regex' ;;
        esac
        when=$(date -d "$created" '+%b %d %H:%M' 2>/dev/null) || when=${created:0:16}
        if [[ "$directory" == "$HOME" ]]; then
            directory='~'
        elif [[ "$directory" == "$HOME/"* ]]; then
            directory="~/${directory#"$HOME/"}"
        fi
        key=$(basename "$meta" .meta.json)
        label="[$mode] $query  ·  $directory  ·  $count PDFs  ·  $when"
        entries+=("$created"$'\t'"$key"$'\t'"$label")
    done
    shopt -u nullglob
    (( ${#entries[@]} > 0 )) || { notify 'No saved PDF searches'; return 0; }
    mapfile -t entries < <(printf '%s\n' "${entries[@]}" | LC_ALL=C sort -r)
    for row in "${entries[@]}"; do
        key=${row#*$'\t'}
        keys+=("${key%%$'\t'*}")
        rows+=("${row#*$'\t'*$'\t'}")
    done
    selected=$(printf '%s\n' "${rows[@]}" |
        rofi_menu 'Saved PDF searches' -no-custom -format i \
            -kb-custom-1 'Alt+r' \
            -mesg 'Enter: open saved results · Alt+R: refresh selected search') || status=$?
    [[ $status == 0 || $status == 10 ]] || return 0
    [[ $selected =~ ^[0-9]+$ ]] || return 0
    key=${keys[selected]}
    [[ $key =~ ^[0-9a-f]{64}$ ]] || return 0
    if [[ $status == 0 ]]; then
        pdf_show_results "$key"
    else
        mapfile -d '' -t saved < <(jq -j '.query, "\u0000", .directory, "\u0000", .mode, "\u0000", ((.max_files // -1) | tostring), "\u0000"' "$PDF_CACHE_DIR/$key.meta.json")
        (( ${#saved[@]} == 4 )) || { notify 'Could not read saved PDF search'; return 1; }
        pdf_search custom no "${saved[0]}" "${saved[1]}" "${saved[2]}" "${saved[3]}" yes
    fi
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
    [[ -n "$choice" ]] || return 0
    file=${choice/#\~/$HOME}
    [[ "$file" == /* ]] || file="$directory/$file"
    [[ -f "$file" && "${file,,}" == *.pdf ]] || {
        notify "PDF does not exist: $file"
        return 1
    }
    record_recent_files "$file"
    "$PDF_VIEWER" "$file" >/dev/null 2>&1 &
}

pdf_command() {
    case ${1:-} in
        --pdf-search) pdf_attach_running yes ;;
        --pdf-attach) pdf_attach_running ;;
        --pdf-search-default) pdf_search default ;;
        --pdf-search-dir) pdf_search directory ;;
        --pdf-search-all) pdf_search default all ;;
        --pdf-search-dir-all) pdf_search directory all ;;
        --pdf-search-compat)
            shift
            PDF_VIEWER=${4:-sioyek}
            if [[ -n ${2:-} ]]; then
                pdf_search custom "${3:-no}" "${1:-}" "$2" words "${5:--1}"
            else
                pdf_search default "${3:-no}" "${1:-}" "" words "${5:--1}"
            fi
            ;;
        --pdf-open) pdf_open_by_name ;;
        --pdf-view) pdf_view_saved ;;
        --pdf-cancel) pdf_cancel ;;
        *) return 2 ;;
    esac
}
