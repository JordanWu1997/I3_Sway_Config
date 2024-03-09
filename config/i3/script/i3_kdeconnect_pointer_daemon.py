#!/usr/bin/env python3
# -*- coding:utf-8 -*-

from time import sleep

from i3ipc import Connection


def find_kdeconnectd_window(container):
    """

    Parameters
    ----------
    container :


    Returns
    -------

    """
    kdeconnectd_leaf = None
    for leaf in container.leaves():
        if leaf.window_class == "kdeconnect.daemon":
            print(leaf.window_class)
            kdeconnectd_leaf = leaf
    return kdeconnectd_leaf


def make_window_float_and_maximized(i3, window, width, height):
    """

    Parameters
    ----------
    i3 :

    window :

    width :

    height :


    Returns
    -------

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
