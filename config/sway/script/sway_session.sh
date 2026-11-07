#!/usr/bin/env bash
# ~/.config/sway/script/sway_session.sh
# Session launcher for sway, used by share/sway-session.desktop (display managers) or
# from a TTY. Fixes "sway does not load ~/.profile": GDM/SDDM start Wayland sessions
# with the user's login shell, and fish never sources ~/.profile, so $I3_SCRIPT,
# $WALLPAPER*, $BROWSER, input-method variables etc. were missing inside sway.

# 1. User environment (the same file i3 relied on)
[ -f "$HOME/.profile" ] && . "$HOME/.profile"

# 1b. Guarantee the PATH entries i3 had, even if ~/.profile lacks them
#     (~/.local/bin = pip --user: autotiling, bumblebee-status, flashfocus)
for dir in "$HOME/.config/sway/script" "$HOME/.config/i3/script" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.local/bin" "$HOME/.config/sway/bin"; do
    [ -d "$dir" ] || continue
    case ":$PATH:" in *":$dir:"*) ;; *) PATH="$dir:$PATH" ;; esac
done
export PATH
export I3_SCRIPT="${I3_SCRIPT:-$HOME/.config/i3/script}"
export SWAY_SESSION_LAUNCHER=sway-session   # checked by sway_session_check.sh

# 2. Wayland session identity
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export SWAY_SCRIPT="$HOME/.config/sway/script"

# 3. Toolkits: prefer native Wayland, fall back to XWayland
export MOZ_ENABLE_WAYLAND=1                 # Firefox (default since 121, harmless)
export QT_QPA_PLATFORM="wayland;xcb"        # Qt apps (kdeconnect, vlc ...); needs qtwayland
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
export SDL_VIDEODRIVER="wayland,x11"        # SDL2 games/tools
export CLUTTER_BACKEND=wayland
export GDK_BACKEND="wayland,x11"            # GTK3/4
export ELECTRON_OZONE_PLATFORM_HINT=auto    # Electron >= 28 (VS Code, Slack, Discord, Obsidian)
export _JAVA_AWT_WM_NONREPARENTING=1        # Java/Swing apps on XWayland (blank windows otherwise)
export XCURSOR_SIZE="${XCURSOR_SIZE:-24}"

# 4. Input method + PATH: the environment.d file written by sway_input_method.sh wins over
#    ~/.profile (which always says ibus, and has the XMODIFIER typo)
IM_ENV="${XDG_CONFIG_HOME:-$HOME/.config}/environment.d/60-sway-input-method.conf"
[ -f "$IM_ENV" ] || "$HOME/.config/sway/script/sway_input_method.sh" write_env >/dev/null 2>&1
if [ -f "$IM_ENV" ]; then
    while IFS='=' read -r key value; do
        case $key in ''|\#*) continue ;; esac
        value=${value//\$\{PATH\}/$PATH}
        export "$key=$value"
    done < "$IM_ENV"
fi

# 5. NVIDIA proprietary driver (the i3 config's "HDMI-0" output name is nvidia-X naming).
#    sway refuses to start on it without --unsupported-gpu; it also needs
#    nvidia-drm.modeset=1 on the kernel command line (Pop!_OS: kernelstub -a nvidia-drm.modeset=1).
SWAY_ARGS=()
if [ -d /sys/module/nvidia_drm ]; then
    SWAY_ARGS+=(--unsupported-gpu)
    export WLR_NO_HARDWARE_CURSORS=1        # invisible/corrupt cursor on many driver versions
    export GBM_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
fi

# 6. Start sway (log for troubleshooting)
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/sway.log"
mkdir -p "$(dirname "$LOG")"
exec sway "${SWAY_ARGS[@]}" "$@" >"$LOG" 2>&1
