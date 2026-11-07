#!/usr/bin/env bash
# ~/.config/sway/script/sway_session_check.sh
# Login-time sanity check of the sway environment. Problems are shown as one notification
# and written to $XDG_RUNTIME_DIR/sway_session_check.log (run it from a terminal to print).
problems=()
IM_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/60-sway-input-method.conf"
if [ ! -f "$IM_ENV" ]; then
    "$HOME/.config/sway/script/sway_input_method.sh" write_env >/dev/null 2>&1
    problems+=("$IM_ENV was missing and has been created now. Log out and back in once so that applications get the input method variables.")
fi
missing=()
for var in GTK_IM_MODULE QT_IM_MODULE XMODIFIERS GLFW_IM_MODULE; do
    [ -n "${!var:-}" ] || missing+=("$var")
done
if [ ${#missing[@]} -gt 0 ]; then
    if [ "${SWAY_SESSION_LAUNCHER:-}" = "sway-session" ]; then
        problems+=("Not set: ${missing[*]}, although sway-session ran. Check $IM_ENV.")
    else
        problems+=("Not set: ${missing[*]} (in sway itself). sway was started without sway-session. Rerun install_sway.sh Section 3: it makes both 'Sway' login entries use sway-session. Applications opened from the terminal and rofi bindings still get the variables through sway_run.sh.")
    fi
fi
for cmd in bumblebee-status autotiling ibus-daemon; do
    "$HOME/.config/sway/script/sway_run.sh" sh -c "command -v $cmd" >/dev/null ||
        problems+=("'$cmd' is not installed.")
done
im=$(awk '$1 == "set" && $2 == "$default_input_method" {print $3; exit}' "$HOME/.config/sway/config")
if [ "$im" = fcitx5 ]; then
    [ -f /usr/share/fcitx5/addon/chewing.conf ] || problems+=("fcitx5-chewing is not installed (sudo apt install fcitx5-chewing).")
    [ -f /usr/share/fcitx5/addon/ibusfrontend.conf ] || problems+=("fcitx5 has no ibus front end: kitty (GLFW_IM_MODULE=ibus) cannot use fcitx5.")
fi
problems_hint="Details: ~/.config/sway/script/sway_input_method.sh doctor"
LOG="${XDG_RUNTIME_DIR:-/tmp}/sway_session_check.log"
{ date; printf '%s\n' "${problems[@]:-OK}"; } > "$LOG"
if [ ${#problems[@]} -gt 0 ]; then
    [ -t 1 ] && printf '%s\n' "${problems[@]}"
    notify-send -u critical "Sway session check (${#problems[@]} problem(s))" "$(printf -- '- %s\n' "${problems[@]}")${problems_hint}"
else
    [ -t 1 ] && echo "OK"
fi
