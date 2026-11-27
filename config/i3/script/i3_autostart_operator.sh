#!/usr/bin/env bash
# Run XDG autostart entries (~/.config/autostart, /etc/xdg/autostart) under i3 with dex,
# skipping the ones i3_startup.config already starts, so nothing runs twice.

# Desktop files i3_startup.config already manages (file names, same on Ubuntu and Fedora)
SKIP_LIST=(
    blueman.desktop                            # blueman-applet
    udiskie.desktop                            # udiskie --automount (USB auto-mount)
    nm-applet.desktop                          # nm-applet
    picom.desktop                              # i3_picom_operator.sh (own config)
    parcellite-startup.desktop                 # i3_toolkit_operator.sh reload_parcellite
    polkit-gnome-authentication-agent-1.desktop
    gnome-keyring-secrets.desktop              # gnome-keyring-daemon --start
    gnome-keyring-pkcs11.desktop
    gnome-keyring-ssh.desktop
    im-launch.desktop                          # ibus-daemon -r -d -x
    org.kde.kdeconnect.daemon.desktop          # kdeconnect-indicator
    org.kde.kdeconnect.nonplasma.desktop
    org.flameshot.Flameshot.desktop            # flameshot
    magnus-autostart.desktop                   # magnifier, started on demand
)

# Wrong message
show_wrong_usage_message () {
    echo "Wrong Usage:"
    echo "  $0"
}

# Help message
show_help_message () {
    echo "Usage:"
    echo "  i3_autostart_operator.sh [operations]"
    echo ""
    echo "OPERATIONS"
    echo "  [start]: run XDG autostart entries with dex (skips entries i3 already starts)"
    echo "  [list]: dry run, print the commands start would run"
}

# Build a directory of symlinks to the autostart entries to run. User entries in
# ~/.config/autostart override system entries with the same file name (XDG rule),
# so a user copy with Hidden=true still disables an entry.
build_autostart_dir () {
    local dir=$1 search_dir entry name skip
    local -a search_dirs=("${XDG_CONFIG_HOME:-$HOME/.config}/autostart")
    local IFS=:
    for search_dir in ${XDG_CONFIG_DIRS:-/etc/xdg}; do
        search_dirs+=("$search_dir/autostart")
    done
    unset IFS
    rm -rf "$dir" && mkdir -p "$dir" || return 1
    for search_dir in "${search_dirs[@]}"; do
        for entry in "$search_dir"/*.desktop; do
            [[ -f "$entry" ]] || continue
            name=${entry##*/}
            [[ -e "$dir/$name" || -L "$dir/$name" ]] && continue
            skip=no
            for skip_name in "${SKIP_LIST[@]}"; do
                [[ "$name" == "$skip_name" ]] && skip=yes && break
            done
            # Placeholder keeps a skipped name from being picked up from a later directory
            if [[ $skip == yes ]]; then
                printf '[Desktop Entry]\nType=Application\nHidden=true\n' > "$dir/$name"
            else
                ln -s "$entry" "$dir/$name"
            fi
        done
    done
}

autostart_operation () {
    if ! command -v dex >/dev/null; then
        notify-send -u normal "Autostart" "dex is not installed, XDG autostart entries were not started"
        exit 1
    fi
    local dir="${XDG_RUNTIME_DIR:-/tmp/$USER}/i3-autostart"
    case $1 in
        'start')
            build_autostart_dir "$dir" || exit 1
            dex --autostart --environment i3 --search-paths "$dir"
            ;;
        'list')
            build_autostart_dir "$dir" || exit 1
            dex --autostart --environment i3 --search-paths "$dir" --dry-run
            ;;
        *)
            show_wrong_usage_message
            echo
            show_help_message
            exit
    esac
}

# Main
autostart_operation $1
