#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Author      : Kuan-Hsien Wu
# Contact     : jordankhwu@gmail.com
# Datetime    : 2026-08-27 21:26:49
# Description :
###########################################################

# Requirement
# -- sudo apt install fdfind ripgrep sqlite3

# Rofi options
ROFI_OPTION=(
    -config "$HOME/.config/rofi/config_omnisearch.rasi"
)

# Terminal
TERMINAL="${TERMINAL:-kitty}"

# Mode
MODE=$(echo -e "🔍 Grep\n📁 Files\n📝 Notes\n🌐 History\n🔖 Bookmarks\n📋 Clipboard\n🪟 Windows\n🏷️ Marks\n🖥️ SSH\n⌨️ Keybindings\n💀 Kill" \
    | rofi -dmenu -p "Search" -auto-select -i "${ROFI_OPTION[@]}")

# Directory
NOTE_DIR="$HOME/Documents"
HISTORY="$HOME/.config/BraveSoftware/Brave-Browser/Default/History"
BOOKMARK="$HOME/.config/BraveSoftware/Brave-Browser/Default/Bookmarks"

# Helper function to abbreviate file paths (e.g., ~/Desktop/test -> ~/D/test)
shorten_paths() {
    awk -v home="$HOME" '{
        orig = $0;
        sub(home, "~", $0);
        n = split($0, parts, "/");
        s = parts[1];
        for(i=2; i<n; i++) {
            if(parts[i] != "") s = s "/" substr(parts[i], 1, 1);
        }
        if(n>1) s = s "/" parts[n];
        print s " │ " orig;
    }'
}

# Main
case "$MODE" in
    *Files*)
        # Ask for directory
        TARGET_DIR=$(rofi -dmenu -p "Search in Dir (empty for ~)" ${ROFI_OPTION[@]})
        [[ $? -ne 0 ]] && exit 0  # Exit if user presses Esc

        # Default to ~ if empty, and expand ~ to actual $HOME path
        TARGET_DIR=${TARGET_DIR:-~}
        TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

        #fdfind --type f --hidden | rofi -dmenu -p "Files" -i | xargs -r xdg-open
        fdfind --type f "" "$TARGET_DIR" |
            shorten_paths |
            rofi -dmenu -p "Files" -i ${ROFI_OPTION[@]} |
            awk -F ' │ ' '{print $NF}' |
            xargs -r xdg-open
        ;;
    *Grep*)
        # interactive ripgrep via rofi
        QUERY=$(rofi -dmenu -p "Grep for" ${ROFI_OPTION[@]})
        if [[ -n "$QUERY" ]]; then
            # Ask for directory after getting the query
            TARGET_DIR=$(rofi -dmenu -p "Search in Dir (empty for ~)" ${ROFI_OPTION[@]})
            [[ $? -ne 0 ]] && exit 0  # Exit if user presses Esc

            # Default to ~ if empty, and expand ~ to actual $HOME path
            TARGET_DIR=${TARGET_DIR:-~}
            TARGET_DIR="${TARGET_DIR/#\~/$HOME}"

            rg --no-heading -l "$QUERY" "$TARGET_DIR" |
                shorten_paths |
                rofi -dmenu -p "Open" -i ${ROFI_OPTION[@]} |
                awk -F ' │ ' '{print $NF}' |
                xargs -r nvim
        fi
        ;;
    *History*)
        # Copy to bypass database lock when Brave is running
        cp "${HISTORY}" /tmp/brave_history.sqlite
        # 1. Fetch top 1000 recent items.
        # 2. Use awk '!seen[$2]++' to filter out duplicate titles while preserving chronological order.
        HISTORY_DATA=$(sqlite3 -separator $'\t' /tmp/brave_history.sqlite \
            "SELECT url, COALESCE(REPLACE(REPLACE(title, char(10), ' '), char(13), ' '), url) FROM urls ORDER BY last_visit_time DESC LIMIT 1000" \
            | awk -F'\t' '!seen[$2]++')
        # Send ONLY column 2 (Title) to Rofi, get back the chosen Index number
        INDEX=$(echo "$HISTORY_DATA" | cut -f2 | rofi -dmenu -p "History" -i ${ROFI_OPTION[@]} -format i)
        if [[ -n "$INDEX" ]]; then
            # Extract URL (column 1) from the chosen row index
            SELECTED_URL=$(echo "$HISTORY_DATA" | awk -F'\t' -v row="$((INDEX + 1))" 'NR == row {print $1}')
            xdg-open "$SELECTED_URL"
        fi
        ;;
    *Bookmarks*)
        # Parse JSON, then remove duplicate bookmark titles globally using awk
        BMARK_DATA=$(jq -r '.. | objects | select(.url != null) | "\(.url)\t\(.name // "Untitled" | gsub("\n"; " "))"' "$BOOKMARK" \
            | awk -F'\t' '!seen[$2]++')
        INDEX=$(echo "$BMARK_DATA" | cut -f2 | rofi -dmenu -p "Bookmarks" -i ${ROFI_OPTION[@]} -format i)
        if [[ -n "$INDEX" ]]; then
            SELECTED_URL=$(echo "$BMARK_DATA" | awk -F'\t' -v row="$((INDEX + 1))" 'NR == row {print $1}')
            xdg-open "$SELECTED_URL"
        fi
        ;;
    *Clipboard*)
        python3 - <<'PY'
import os
import struct
import subprocess
import sys

history_file = os.path.expanduser(
    "~/.local/share/parcellite/history"
)

SIGNATURE = b"1.0ParcelliteHistoryFile"
HEADER_SIZE = 32
RECORD_HEADER_SIZE = 28


def notify(message):
    subprocess.run(
        ["notify-send", "Parcellite", message],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


# ------------------------------------------------------------
# Read Parcellite history
# ------------------------------------------------------------

try:
    with open(history_file, "rb") as f:
        data = f.read()
except FileNotFoundError:
    notify("Parcellite history file not found")
    sys.exit(1)


if not data.startswith(SIGNATURE):
    notify("Unknown Parcellite history format")
    sys.exit(1)


entries = []
offset = HEADER_SIZE


while offset + RECORD_HEADER_SIZE <= len(data):

    # Total size of this record.
    record_size = struct.unpack_from("<I", data, offset)[0]

    # Basic sanity check.
    if record_size < RECORD_HEADER_SIZE:
        break

    record_end = offset + record_size

    if record_end > len(data):
        break


    # --------------------------------------------------------
    # The actual clipboard text occupies the rest of the record.
    #
    # DO NOT use offset + 4 as the text length.
    # That field is metadata, not the payload length.
    # --------------------------------------------------------

    text_offset = offset + RECORD_HEADER_SIZE
    raw_text = data[text_offset:record_end]


    # Remove only NUL bytes used as possible terminators.
    #
    # Do not use strip() or rstrip() without arguments because
    # trailing spaces and newlines may be legitimate clipboard data.
    raw_text = raw_text.rstrip(b"\x00")


    try:
        text = raw_text.decode("utf-8")
    except UnicodeDecodeError:
        text = raw_text.decode(
            "utf-8",
            errors="replace"
        )


    if text:
        entries.append(text)


    # Move to the next record.
    offset = record_end


if not entries:
    notify("No clipboard history found")
    sys.exit(0)


# ------------------------------------------------------------
# Build Rofi menu
#
# Rofi requires one physical line per entry.
# Keep the original text separately in `entries`.
# ------------------------------------------------------------

display_entries = []

for i, text in enumerate(entries):

    display = (
        text
        .replace("\r\n", "\n")
        .replace("\r", "\n")
        .replace("\n", " ↵ ")
    )

    # Optional preview length limit.
    max_length = 400

    if len(display) > max_length:
        display = display[:max_length] + " …"

    # Prefix with an ID used to recover the original entry.
    display_entries.append(
        f"{i}\t{display}"
    )


# ------------------------------------------------------------
# Show Rofi
# ------------------------------------------------------------

result = subprocess.run(
    [
        "rofi",
        "-dmenu",
        "-i",
        "-config",
        "~/.config/rofi/config_omnisearch.rasi",
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
    index = int(
        selected.split("\t", 1)[0]
    )
except (ValueError, IndexError):
    sys.exit(0)


clipboard_text = entries[index]


# ------------------------------------------------------------
# Put the EXACT original content back into the clipboard.
# ------------------------------------------------------------

clipboard_bytes = clipboard_text.encode("utf-8")

subprocess.run(
    [
        "xclip",
        "-selection",
        "clipboard",
    ],
    input=clipboard_bytes,
)

subprocess.run(
    [
        "xclip",
        "-selection",
        "primary",
    ],
    input=clipboard_bytes,
)
PY
        ;;
    *Notes*)
        fdfind --type f --extension md . "$NOTE_DIR" |
            rofi -dmenu -p "Notes" -i "${ROFI_OPTION[@]}" |
            xargs -r -I{} ${TERMINAL} -e nvim "{}"
        ;;
    *Windows*)
        wmctrl -l |
            rofi -dmenu -p "Windows" -i "${ROFI_OPTION[@]}" -auto-select |
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
            rofi -dmenu \
                -i \
                -auto-select \
                -p "Jump to mark" \
                "${ROFI_OPTION[@]}" \
                -format 's' |
            cut -f1 |
            xargs -r -I{} i3-msg '[con_mark="{}"] focus'
        ;;
    *Keybindings*)
        # i3 keybindings hinter
        # -- https://www.reddit.com/r/i3wm/comments/e1x9n6/keybindings_menu_not_dmenurofi/
        i3 $(cat ~/.config/i3/config.d/* |
            grep '^bindsym' |
            grep -v '^\s*#' |
            sed 's/bindsym / /' |
            rofi -dmenu -i -p 'i3 Keybinds' ${ROFI_OPTION[@]} |
            sed 's/^\s*//' |
            cut -d' ' -f 2- )
        ;;
    *SSH*)
        # Search SSH config and launch in terminal
        grep -E '^Host ' ~/.ssh/config 2>/dev/null |
            awk '{print $2}' |
            rofi -dmenu -auto-select -p "SSH to" -i "${ROFI_OPTION[@]}" |
            xargs -r -I{} kitty -e ssh {}
        ;;
    *Kill*)
        # Changed 'comm' to 'cmd' for the full path.
        # Added 'ww' to force unlimited width and '--no-headers' to remove the PID/CMD title line.
        ps axww --no-headers -o pid,cmd |
            rofi -dmenu -p "Kill Process" -i "${ROFI_OPTION[@]}" |
            awk '{print $1}' |
            xargs -r kill -TERM
        ;;
esac
