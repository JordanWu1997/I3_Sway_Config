#!/usr/bin/python3
# -*- coding:utf-8 -*-
# Ported from i3_kdeconnect_pointer_daemon.py for sway.
# Replaced: X window class match (leaf.window_class) -> Wayland app_id match with an
# XWayland class fallback. i3ipc still works on sway because sway exports I3SOCK/SWAYSOCK.
# KDE Connect's presenter pointer is the daemon's own window; on a native Wayland
# session its app_id is "org.kde.kdeconnect.daemon" (or "kdeconnectd"/"kdeconnect.daemon").

from time import sleep

from i3ipc import Connection

KDECONNECT_APP_IDS = {
    "org.kde.kdeconnect.daemon",
    "kdeconnect.daemon",
    "kdeconnectd",
}
KDECONNECT_CLASS = "kdeconnect.daemon"


def is_kdeconnectd(leaf):
    """Return True if a sway container is the KDE Connect daemon window."""
    app_id = leaf.ipc_data.get("app_id")
    if app_id in KDECONNECT_APP_IDS:
        return True
    window_properties = leaf.ipc_data.get("window_properties") or {}
    return window_properties.get("class") == KDECONNECT_CLASS


def find_kdeconnectd_window(container):
    """
    Search the leaves of a container for the KDE Connect daemon window.

    Returns the last matching i3ipc.Con, otherwise None.
    """
    kdeconnectd_leaf = None
    for leaf in container.leaves():
        if is_kdeconnectd(leaf):
            print(leaf.ipc_data.get("app_id") or KDECONNECT_CLASS)
            kdeconnectd_leaf = leaf
    return kdeconnectd_leaf


def make_window_float_and_maximized(sway, window, width, height):
    """Float the window, drop its border, resize it to width x height and center it."""
    sway.command(f"[con_id={window.id}] fullscreen disable")
    sway.command(f"[con_id={window.id}] floating enable")
    sway.command(f"[con_id={window.id}] border pixel 0")
    sway.command(
        f"[con_id={window.id}] resize set width {width} px height {height} px")
    sway.command(f"[con_id={window.id}] move position center")


def main():
    """ """

    sway = Connection()

    while True:
        for reply in sway.get_workspaces():
            if reply.focused:
                workspace = sway.get_tree().find_by_id(reply.ipc_data["id"])
                if workspace is None:
                    continue
                window = find_kdeconnectd_window(workspace)
                if window is not None:
                    width, height = workspace.rect.width, workspace.rect.height
                    make_window_float_and_maximized(sway, window, width, height)
        sleep(0.05)


if __name__ == '__main__':
    main()
