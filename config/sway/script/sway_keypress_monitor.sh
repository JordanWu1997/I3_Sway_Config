#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Notify when specific key combinations are pressed
###########################################################

# Requirements:
#   libinput (Ubuntu: libinput-tools) notify-send
#   Read access to /dev/input/event*: sudo usermod -aG input "$USER", then log in again
#   (any program you run can then read the keyboard, the same as libinput-gestures)

# [SWAY] Wayland port of i3_keypress_monitor.sh. xinput only sees XWayland windows,
#        so key events come from libinput instead. Like the i3 version, it only
#        observes: the focused app (and ibus) still receive every key. A sway
#        bindsym would grab the combination instead.

shopt -s extglob
source "$I3_SCRIPT/i3_single_instance.sh"

# ============================================================
# Rules
# ============================================================

# One rule per line: combination | notification title | notification body
# Combination: [Shift+][Ctrl+][Alt+][Super+]<key>. Keys are keysym names as in the
# i3 version (space, Return, a, F1, ...), mapped to evdev names (KEY_SPACE, ...).
# A rule matches only when exactly those modifiers are held, so Ctrl+Shift+space
# does not match Shift+space.
RULES=(
    'Shift+space | ibus-chewing Input Method | Shift+space pressed\nFull/half character mode toggled'
)

MODIFIERS=(Shift Ctrl Alt Super)
declare -A MODIFIER_KEYS=(
    [Shift]='KEY_LEFTSHIFT KEY_RIGHTSHIFT'
    [Ctrl]='KEY_LEFTCTRL KEY_RIGHTCTRL'
    [Alt]='KEY_LEFTALT KEY_RIGHTALT'
    [Super]='KEY_LEFTMETA KEY_RIGHTMETA'
)

# Keysyms whose evdev name is not simply KEY_<KEYSYM IN UPPERCASE>
declare -A EVDEV_ALIASES=(
    [Return]=KEY_ENTER [Escape]=KEY_ESC [Prior]=KEY_PAGEUP [Next]=KEY_PAGEDOWN
    [bracketleft]=KEY_LEFTBRACE [bracketright]=KEY_RIGHTBRACE [Print]=KEY_SYSRQ
)

# ============================================================
# Checks
# ============================================================

if ! command -v libinput >/dev/null; then
    notify-send -u normal 'Keypress monitor' 'libinput is not installed (Ubuntu: libinput-tools)'
    exit 1
fi
readable=no
for device in /dev/input/event*; do
    [[ -r $device ]] && readable=yes && break
done
if [[ $readable == no ]]; then
    notify-send -u normal 'Keypress monitor' \
        "Cannot read /dev/input, key combinations are not monitored\nsudo usermod -aG input $USER, then log in again"
    exit 1
fi

# ============================================================
# Resolve rules to evdev key names
# ============================================================

trim() {
    local text=${1##+([[:space:]])}
    printf '%s' "${text%%+([[:space:]])}"
}

# Modifier keys: "<evdev name>:<modifier index>" pairs
MODIFIER_PAIRS=''
for index in "${!MODIFIERS[@]}"; do
    for key in ${MODIFIER_KEYS[${MODIFIERS[index]}]}; do
        MODIFIER_PAIRS+="$key:$((index + 1)) "
    done
done

# Rules for awk: fields split by \037, rules by \036. Each rule becomes
# <trigger key> <modifier mask, e.g. 1000 for Shift> <title> <body>.
RULE_DATA=''
for rule in "${RULES[@]}"; do
    IFS='|' read -r combo title body <<< "$rule"
    combo=$(trim "$combo")
    IFS='+' read -ra parts <<< "$combo"
    trigger=${EVDEV_ALIASES[${parts[-1]}]:-KEY_${parts[-1]^^}}
    mask=''
    for modifier in "${MODIFIERS[@]}"; do
        bit=0
        for part in "${parts[@]:0:${#parts[@]}-1}"; do
            [[ $part == "$modifier" ]] && bit=1
        done
        mask+=$bit
    done
    RULE_DATA+="$trigger"$'\037'"$mask"$'\037'"$(trim "$title")"$'\037'"$(trim "$body")"$'\036'
done

# ============================================================
# Monitor
# ============================================================

# Key lines look like: " event3   KEYBOARD_KEY   +1.234s   KEY_SPACE (57) pressed".
# --show-keycodes is needed, otherwise libinput prints *** for most keys. The output
# only goes to awk below and is never stored. Track which keys are down so a key
# reported by two devices still matches once per press.
export MODIFIER_PAIRS RULE_DATA MODIFIER_COUNT=${#MODIFIERS[@]}
stdbuf -oL libinput debug-events --show-keycodes 2>/dev/null | awk '
    BEGIN {
        n = split(ENVIRON["MODIFIER_PAIRS"], pairs, " ")
        for (i = 1; i <= n; i++) {
            split(pairs[i], pair, ":")
            modifier[pair[1]] = pair[2]
        }
        modifier_count = ENVIRON["MODIFIER_COUNT"]
        rule_count = split(ENVIRON["RULE_DATA"], rules, "\036")
        for (i = 1; i <= rule_count; i++) {
            split(rules[i], field, "\037")
            trigger[i] = field[1]; mask[i] = field[2]; title[i] = field[3]; body[i] = field[4]
        }
    }

    function held_mask(    g, key, held, result) {
        for (key in down)
            if (key in modifier)
                held[modifier[key]] = 1
        result = ""
        for (g = 1; g <= modifier_count; g++)
            result = result ((g in held) ? 1 : 0)
        return result
    }

    function quote(text) {
        gsub(/\047/, "\047\"\047\"\047", text)
        return "\047" text "\047"
    }

    $2 == "KEYBOARD_KEY" {
        key = $(NF - 2)
        if ($NF == "released") {
            delete down[key]
        } else if ($NF == "pressed" && !(key in down)) {
            current = held_mask()
            for (i = 1; i <= rule_count; i++)
                if (trigger[i] != "" && key == trigger[i] && current == mask[i])
                    system("notify-send -u low -h string:x-dunst-stack-tag:keypress-" i \
                        " " quote(title[i]) " " quote(body[i]))
            down[key] = 1
        }
    }'
