#!/usr/bin/env bash
# vim: set fileencoding=utf-8

###########################################################
# Description : Notify when specific key combinations are pressed
###########################################################

# Requirements:
#   xinput xmodmap notify-send

# Raw key events only observe the keyboard: the focused app (and ibus) still
# receive every key. An i3 bindsym would grab the combination instead.

shopt -s extglob
source "$(dirname "$(readlink -f "$0")")/i3_single_instance.sh"

# ============================================================
# Rules
# ============================================================

# One rule per line: combination | notification title | notification body
# Combination: [Shift+][Ctrl+][Alt+][Super+]<keysym>, keysyms as listed by
# `xmodmap -pke` (space, Return, a, F1, ...). A rule matches only when exactly
# those modifiers are held, so Ctrl+Shift+space does not match Shift+space.
RULES=(
    'Shift+space | ibus-chewing Input Method | Shift+space pressed\nFull/half character mode toggled'
)

MODIFIERS=(Shift Ctrl Alt Super)
declare -A MODIFIER_KEYSYMS=(
    [Shift]='Shift_L Shift_R'
    [Ctrl]='Control_L Control_R'
    [Alt]='Alt_L Alt_R'
    [Super]='Super_L Super_R'
)

# ============================================================
# Resolve rules to keycodes
# ============================================================

KEYMAP=$(xmodmap -pke)

keycode() {
    awk -v sym="$1" '{ for (i = 4; i <= NF; i++) if ($i == sym) { print $2; exit } }' <<< "$KEYMAP"
}

trim() {
    local text=${1##+([[:space:]])}
    printf '%s' "${text%%+([[:space:]])}"
}

# Modifier keycodes: "<keycode>:<modifier index>" pairs
MODIFIER_KEYS=''
for index in "${!MODIFIERS[@]}"; do
    for keysym in ${MODIFIER_KEYSYMS[${MODIFIERS[index]}]}; do
        code=$(keycode "$keysym")
        [[ -n $code ]] && MODIFIER_KEYS+="$code:$((index + 1)) "
    done
done

# Rules for awk: fields split by \037, rules by \036. Each rule becomes
# <trigger keycode> <modifier mask, e.g. 1000 for Shift> <title> <body>.
RULE_DATA=''
for rule in "${RULES[@]}"; do
    IFS='|' read -r combo title body <<< "$rule"
    combo=$(trim "$combo")
    IFS='+' read -ra parts <<< "$combo"
    trigger=$(keycode "${parts[-1]}")
    if [[ -z $trigger ]]; then
        printf 'Skipping %s: unknown keysym %s\n' "$combo" "${parts[-1]}" >&2
        continue
    fi
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

[[ -n $RULE_DATA ]] || { echo 'No valid rules' >&2; exit 1; }

# ============================================================
# Monitor
# ============================================================

# Raw events can arrive once per device (master and slave), and held keys
# auto-repeat, so track which keys are down and match once per press.
export MODIFIER_KEYS RULE_DATA MODIFIER_COUNT=${#MODIFIERS[@]}
stdbuf -oL xinput test-xi2 --root | awk '
    BEGIN {
        n = split(ENVIRON["MODIFIER_KEYS"], pairs, " ")
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

    /^EVENT type/ { press = /RawKeyPress/; release = /RawKeyRelease/; next }
    (press || release) && $1 == "detail:" {
        key = $2
        if (release) {
            delete down[key]
        } else if (!(key in down)) {
            current = held_mask()
            for (i = 1; i <= rule_count; i++)
                if (trigger[i] != "" && key == trigger[i] && current == mask[i])
                    system("notify-send -u low -h string:x-dunst-stack-tag:keypress-" i \
                        " " quote(title[i]) " " quote(body[i]))
            down[key] = 1
        }
        press = release = 0
    }'
