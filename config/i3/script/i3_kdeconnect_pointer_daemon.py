#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from time import sleep

from i3ipc import Connection


def find_kdeconnectd_window(container):
    """
    This function searches through the leaves of a given container to find the window with the class "kdeconnect.daemon".

    Parameters:
    container (i3ipc.Container): The container object to search within.

    Returns:
    i3ipc.Con: The window object representing the KDE Connect daemon if found, otherwise None.
    """
    kdeconnectd_leaf = None
    for leaf in container.leaves():
        if leaf.window_class == "kdeconnect.daemon":
            print(leaf.window_class)
            kdeconnectd_leaf = leaf
    return kdeconnectd_leaf


def make_window_float_and_maximized(i3, window, width, height):
    """
    This function takes an I3 session object `i3`, a window ID `window`, and dimensions `width` and `height`.
    It sets the specified window to floating mode, disables fullscreen, removes borders, resizes it to the given
    dimensions, and centers it on the screen.

    Parameters:
    i3 (i3ipc.Connection): The I3 session object used to interact with the i3 window manager.
    window (i3ipc.Con): The window ID of the window to be modified.
    width (int): The new width for the window in pixels.
    height (int): The new height for the window in pixels.

    Returns:
    None
    """

    i3.command(f"[con_id={window.id}] fullscreen disable")
    i3.command(f"[con_id={window.id}] floating enable")
    i3.command(f"[con_id={window.id}] border pixel 0")
    i3.command(
        f"[con_id={window.id}] resize set width {width} px height {height} px")
    i3.command(f"[con_id={window.id}] move position center")


def main():
    """ """

    i3 = Connection()

    while True:
        for reply in i3.get_workspaces():
            if reply.focused:
                workspace = i3.get_tree().find_by_id(reply.ipc_data["id"])
                window = find_kdeconnectd_window(workspace)
                if window is not None:
                    width, height = workspace.rect.width, workspace.rect.height
                    make_window_float_and_maximized(i3, window, width, height)
        sleep(0.05)


if __name__ == '__main__':
    main()
