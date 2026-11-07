#!/usr/bin/env bash
# ~/.config/sway/script/sway_run.sh <command> [args...]
# Run a command with the environment i3 got from ~/.profile, whatever way sway was started:
#   - PATH: pip --user tools (autotiling, bumblebee-status, flashfocus) in ~/.local/bin,
#     $I3_SCRIPT, $SWAY_SCRIPT, cargo/go bins, ~/.config/sway/bin (ueberzug wrapper)
#   - input method variables from ~/.config/environment.d/60-sway-input-method.conf
#     (GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS, GLFW_IM_MODULE, written by
#     sway_input_method.sh)
# test_v4: the environment.d file was not imported into the sway session, so the terminal
# and rofi bindings (which start nearly every application) now go through this script and
# hand the variables to everything they launch.
IM_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/60-sway-input-method.conf"
if [ -f "$IM_ENV" ]; then
    while IFS='=' read -r key value; do
        case $key in ''|\#*|PATH) continue ;; esac
        export "$key=$value"
    done < "$IM_ENV"
fi
for dir in "$HOME/.config/sway/script" "$HOME/.config/i3/script" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.local/bin" "$HOME/.config/sway/bin"; do
    [ -d "$dir" ] || continue
    case ":$PATH:" in *":$dir:"*) ;; *) PATH="$dir:$PATH" ;; esac
done
export PATH
export I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
export SWAY_SCRIPT="${SWAY_SCRIPT:-$HOME/.config/sway/script}"
[ $# -gt 0 ] && exec "$@"
