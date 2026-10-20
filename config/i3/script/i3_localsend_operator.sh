#!/usr/bin/env bash

set -euo pipefail

usage() {
    printf 'Usage: %s send FILE_OR_DIRECTORY...\n' "${0##*/}" >&2
    exit 2
}

[[ ${1:-} == send ]] || usage
shift
(( $# > 0 )) || usage

if ! command -v localsend-cli >/dev/null 2>&1; then
    printf 'LocalSend CLI is not installed or is not on PATH.\n' >&2
    exit 127
fi

declare -a file_args=()
archive_dir=''
cleanup() {
    if [[ -n $archive_dir ]]; then
        rm -rf -- "$archive_dir"
    fi
}
trap cleanup EXIT

archive_number=0
for path in "$@"; do
    if [[ -f $path ]]; then
        file_args+=(--file "$path")
    elif [[ -d $path ]]; then
        # This CLI accepts files; preserve a selected directory in one archive.
        if [[ -z $archive_dir ]]; then
            archive_dir=$(mktemp -d "${TMPDIR:-/tmp}/i3-localsend.XXXXXXXX")
        fi
        (( archive_number += 1 ))
        archive="$archive_dir/${archive_number}_$(basename -- "$path").tar.gz"
        printf 'Preparing %s for LocalSend...\n' "$path"
        tar -C "$(dirname -- "$path")" -czf "$archive" -- "$(basename -- "$path")"
        file_args+=(--file "$archive")
    else
        printf 'Cannot send missing or unsupported path: %s\n' "$path" >&2
        exit 2
    fi
done

localsend-cli "${file_args[@]}"
