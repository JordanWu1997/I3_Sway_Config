#!/usr/bin/env bash

# Compare a repository checkout with the configuration currently used by i3.
# Override these for another home directory or a noninteractive diff viewer.
host_root=${I3_DIFF_HOST_ROOT:-$HOME}
diff_editor=${I3_DIFF_EDITOR:-nvim}

show_help_message () {
    cat <<'HELP'
Usage: i3_diff_check_operator.sh input_dir REPO_DIR [--i3-only] [--diff-missing | --diff-missing-i3]
       i3_diff_check_operator.sh latest_git [REPO_DIR] [--i3-only] [--diff-missing | --diff-missing-i3]

input_dir   Compare tracked config/ and dotfile/ files in the checkout with
            the host. Also report host-only files in the covered app folders.
latest_git  Compare files changed since the previous commit (including working
            tree edits). If REPO_DIR is omitted, use this script's checkout.
--i3-only   Limit either mode to i3/config, i3/config.d, and i3/script.
--diff-missing
            Also open the diff editor for REPO ONLY and HOST ONLY files. The
            missing side opens as an empty new file: copy lines over (do / dp
            in nvim) and save with :w ++p to create it and its parent folders,
            or quit without saving to leave it missing.
--diff-missing-i3
            Like --diff-missing, but only for files under config/i3/. Missing
            files of other apps are still only listed.

config/ maps to ~/.config/; dotfile/NAME maps to ~/.NAME.
Sway is excluded. Git-ignored host-only files are skipped.
HELP
}

# Set host_file for a checkout-relative path. etc/ and misc/ need separate maps.
map_host_file () {
    local path=$1 i3_only=$2 name
    if (( i3_only )); then
        case $path in
            config/i3/config|config/i3/config.d/*|config/i3/script/*) ;;
            *) return 1 ;;
        esac
    fi
    case $path in
        config/sway/*|config/README.md|dotfile/README.md) return 1 ;;
        config/*)
            host_file="$host_root/.${path}"
            return 0
            ;;
        dotfile/*)
            name=${path#dotfile/}
            [[ $name != */* ]] || return 1
            host_file="$host_root/.$name"
            return 0
            ;;
    esac
    return 1
}

# Open the diff editor; a missing side is passed as a new, unsaved file.
open_diff () {
    local path=$1 repo_file=$2 local_file=$3
    if ! "$diff_editor" -d "$repo_file" "$local_file"; then
        ((error_count+=1))
        printf 'Diff editor failed for %s\n' "$path" >&2
    fi
}

# Whether a REPO ONLY / HOST ONLY file should open in the diff editor.
want_missing_diff () {
    case $diff_missing in
        all) return 0 ;;
        i3) [[ $1 == config/i3/* ]] ;;
        *) return 1 ;;
    esac
}

compare_file () {
    local path=$1 repo_file=$2 local_file=$3 cmp_status

    if [[ -f $repo_file && -f $local_file ]]; then
        cmp -s -- "$repo_file" "$local_file"
        cmp_status=$?
        case $cmp_status in
            0) ((same_count+=1)); return 0 ;;
            1)
                ((changed_count+=1))
                printf '\nCHANGED %s\n  REPO: %s\n  HOST: %s\n' "$path" "$repo_file" "$local_file"
                open_diff "$path" "$repo_file" "$local_file"
                return 0
                ;;
        esac
        ((error_count+=1))
        printf 'CANNOT COMPARE %s\n  REPO: %s\n  HOST: %s\n' "$path" "$repo_file" "$local_file" >&2
        return 0
    fi

    if { [[ -L $repo_file && ! -e $repo_file ]] || [[ -L $local_file && ! -e $local_file ]]; }; then
        ((error_count+=1))
        printf 'BROKEN LINK %s\n  REPO: %s\n  HOST: %s\n' "$path" "$repo_file" "$local_file" >&2
    elif [[ -f $repo_file ]]; then
        ((repo_only_count+=1))
        printf 'REPO ONLY %s\n  REPO: %s\n' "$path" "$repo_file"
        want_missing_diff "$path" && open_diff "$path" "$repo_file" "$local_file"
    elif [[ -f $local_file ]]; then
        ((host_only_count+=1))
        printf 'HOST ONLY %s\n  HOST: %s\n' "$path" "$local_file"
        want_missing_diff "$path" && open_diff "$path" "$repo_file" "$local_file"
    else
        ((error_count+=1))
        printf 'CANNOT READ %s\n  REPO: %s\n  HOST: %s\n' "$path" "$repo_file" "$local_file" >&2
    fi
    return 0
}

check_diff () {
    local mode=${1:-} repo= script_path path root_name local_file arg i3_only=0 diff_missing=
    local -a repo_files pathspecs
    local -A tracked=() app_roots=()
    local same_count=0 changed_count=0 repo_only_count=0 host_only_count=0 error_count=0

    if (( $# < 1 )); then
        show_help_message >&2
        return 2
    fi
    shift
    for arg in "$@"; do
        case $arg in
            --i3-only) i3_only=1 ;;
            --diff-missing|--diff-missing-i3)
                # The two scopes are alternatives; giving both is a usage error.
                [[ -z $diff_missing ]] || { show_help_message >&2; return 2; }
                [[ $arg == --diff-missing ]] && diff_missing=all || diff_missing=i3
                ;;
            --* ) show_help_message >&2; return 2 ;;
            *)
                [[ -z $repo ]] || { show_help_message >&2; return 2; }
                repo=$arg
                ;;
        esac
    done

    if [[ $mode == input_dir ]]; then
        [[ -n $repo ]] || { show_help_message >&2; return 2; }
    elif [[ $mode == latest_git ]]; then
        if [[ -z $repo ]]; then
            script_path=$(readlink -f -- "${BASH_SOURCE[0]}") || return 1
            repo=$(dirname -- "$script_path")
        fi
    else
        show_help_message >&2
        return 2
    fi

    repo=$(git -C "$repo" rev-parse --show-toplevel 2>/dev/null) || {
        printf 'Not a Git checkout: %s\n' "$repo" >&2
        return 1
    }
    [[ -d $repo/config ]] || { printf 'No config/ directory in %s\n' "$repo" >&2; return 1; }

    if (( i3_only )); then
        pathspecs=(config/i3/config config/i3/config.d config/i3/script)
    else
        pathspecs=(config dotfile)
    fi
    if [[ $mode == latest_git ]] && git -C "$repo" rev-parse --verify HEAD^ >/dev/null 2>&1; then
        mapfile -d '' -t repo_files < <(git -C "$repo" diff --name-only -z HEAD^ -- "${pathspecs[@]}")
    else
        mapfile -d '' -t repo_files < <(git -C "$repo" ls-files -z -- "${pathspecs[@]}")
    fi

    printf 'Comparing %s with %s\n' "$repo" "$host_root"
    for path in "${repo_files[@]}"; do
        map_host_file "$path" "$i3_only" || continue
        tracked["$path"]=1
        if [[ $path == config/*/* ]]; then
            root_name=${path#config/}
            app_roots["${root_name%%/*}"]=1
        fi
        compare_file "$path" "$repo/$path" "$host_file"
    done

    # A full comparison also reports extra host files under apps in this repo.
    # -H follows a ~/.config/app symlink but not symlinked directories inside it.
    if [[ $mode == input_dir ]]; then
        while IFS= read -r -d '' root_name; do
            [[ -n $root_name ]] || continue
            [[ -d $host_root/.config/$root_name ]] || continue
            while IFS= read -r -d '' local_file; do
                path="config/${local_file#"$host_root/.config/"}"
                map_host_file "$path" "$i3_only" || continue
                [[ -n ${tracked[$path]+x} ]] && continue
                git -C "$repo" check-ignore -q -- "$path" && continue
                if [[ -L $local_file && ! -e $local_file ]]; then
                    ((error_count+=1))
                    printf 'BROKEN HOST LINK %s\n  HOST: %s\n' "$path" "$local_file" >&2
                else
                    ((host_only_count+=1))
                    printf 'HOST ONLY %s\n  HOST: %s\n' "$path" "$local_file"
                    want_missing_diff "$path" && open_diff "$path" "$repo/$path" "$local_file"
                fi
            done < <(find -H "$host_root/.config/$root_name" -name .git -prune -o \
                \( -type f -o -type l \) -print0 | sort -z)
        done < <(printf '%s\0' "${!app_roots[@]}" | sort -z)
    fi

    printf '\nSummary: %d same, %d changed, %d repo only, %d host only, %d errors\n' \
        "$same_count" "$changed_count" "$repo_only_count" "$host_only_count" "$error_count"
    (( error_count == 0 ))
}

check_diff "$@"
