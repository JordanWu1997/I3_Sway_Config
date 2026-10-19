#!/usr/bin/env bash
# Compatibility entry point. PDF scanning and result actions live in Omnisearch.

set -u
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
query=''
directory=''
batch=no
viewer=sioyek
max_files=-1

show_help() {
    cat <<EOF
Usage: i3_pdf_keyword_search.sh [options]
  --keywords=WORD1,WORD2, -w=...  Literal words that must all occur in a PDF
  --dir=DIR, -d=DIR               Directory to search (default: PDF search location)
  --max_num=N, -n=N               Stop after N matching PDFs (default: unlimited)
  --viewer=PROGRAM                Viewer for opening results (default: sioyek)
  --all_at_once, -a               Open matching PDFs after search
  --kill, -k                      Cancel active PDF searches
  --help, -h                      Show this message
EOF
}

for option in "$@"; do
    case "$option" in
        --keywords=*|-w=*) query=${option#*=} ;;
        --dir=*|-d=*) directory=${option#*=} ;;
        --max_num=*|-n=*) max_files=${option#*=} ;;
        --viewer=*) viewer=${option#*=} ;;
        --all_at_once|-a) batch=all ;;
        --kill|-k) exec "$script_dir/i3_rofi_omnisearch.sh" --pdf-cancel ;;
        --help|-h) show_help; exit 0 ;;
        *) show_help >&2; exit 2 ;;
    esac
done

if [[ ! $max_files =~ ^-?[0-9]+$ ]] || (( max_files == 0 )); then
    printf 'Invalid --max_num value: %s\n' "$max_files" >&2
    exit 2
fi

# The former script treated comma-separated terms as literal AND words.
query=${query//,/ }
exec "$script_dir/i3_rofi_omnisearch.sh" --pdf-search-compat \
    "$query" "$directory" "$batch" "$viewer" "$max_files"
