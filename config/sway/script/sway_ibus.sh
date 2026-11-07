#!/usr/bin/env bash
# ~/.config/sway/script/sway_ibus.sh [start|restart]
# Start ibus-daemon so that it is usable on sway (test_v2: "ibus not working, no tray icon").
#
#   XDG_CURRENT_DESKTOP=KDE  The ibus panel (ibus-ui-gtk3) only exports its tray icon as a
#                            StatusNotifierItem (what swaybar's tray shows) on KDE. Anywhere
#                            else it uses a GtkStatusIcon (XEmbed), which swaybar ignores,
#                            so the icon and its engine menu were missing.
#   GDK_BACKEND=x11          Candidate/property windows become X11 popups through XWayland.
#                            As native Wayland windows, sway would tile and focus them like
#                            normal windows. The IM targets on sway are XWayland apps
#                            (kitty is forced to x11, browsers default to X11) anyway.
# Only ibus-daemon and its children get these variables, not the session.
case ${1:-start} in
    start)
        # Keep a running daemon only if it was started with the KDE tray mode; one started
        # by something else (D-Bus activation, im-config, an older config) has no tray icon.
        pid=$(pgrep -u "$USER" -x ibus-daemon | head -n1)
        if [ -n "$pid" ]; then
            tr '\0' '\n' < "/proc/$pid/environ" 2>/dev/null | grep -qx 'XDG_CURRENT_DESKTOP=KDE' && exit 0
            pkill -u "$USER" -x ibus-daemon; sleep 0.5
        fi ;;
    restart) pkill -u "$USER" -x ibus-daemon; sleep 0.5 ;;
    *) echo "Usage: $0 [start|restart]"; exit 1 ;;
esac
command -v ibus-daemon >/dev/null || { notify-send -u critical "ibus" "ibus-daemon is not installed"; exit 1; }
XDG_CURRENT_DESKTOP=KDE GDK_BACKEND=x11 exec ibus-daemon -r -d -x
