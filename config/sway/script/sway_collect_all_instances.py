#!/usr/bin/python3
# -*- coding:utf-8 -*-
#
# Ported from i3_collect_all_instances.py for sway.
# What changed:
#   - X11 WM_CLASS instance matching (window.window_instance, None for native
#     Wayland windows) -> match the target against the Wayland app_id for native
#     windows and against the X11 instance/class for XWayland windows
#   - i3ipc leaves() skips sway floating views (type "floating_con"), so views are
#     collected from all descendants instead
#   - workspace name is quoted in the move command (names may contain spaces)
# Usage is identical: sway_collect_all_instances.py [target_instance]

import os
import shlex
import sys

import i3ipc


def is_view(con):
    """
    True for a sway view (native Wayland or XWayland window).
    """
    if con.type not in ('con', 'floating_con') or con.nodes:
        return False
    data = con.ipc_data
    return bool(
        data.get('pid') or data.get('app_id') is not None
        or data.get('window') or data.get('shell'))


def window_identifiers(con):
    """
    Names a window can be matched by: app_id (native Wayland), and the X11
    instance and class (XWayland).
    """
    data = con.ipc_data
    props = data.get('window_properties') or {}
    names = [data.get('app_id'), props.get('instance'), props.get('class')]
    return [name for name in names if name]


def move_all_instances_to_focused_workspace(target_instance: str,
                                            dest_workspace: str = None,
                                            verbose: bool = True):
    """
    Move all instances of a given window to the focused workspace.

    Parameters:
    - target_instance (str): app_id (Wayland) or instance/class (XWayland) of the windows to move.
    - dest_workspace (str, optional): The destination workspace. If not provided, uses the focused workspace.
    - verbose (bool, optional): Whether to display a notification after moving the windows.

    Returns:
    None
    """
    sway = i3ipc.Connection()
    tree = sway.get_tree()
    windows = [con for con in tree.descendants() if is_view(con)]

    # Get focused_workspace
    if dest_workspace is None:
        focused = tree.find_focused()
        dest_workspace = focused.workspace().name if focused else None
    if not dest_workspace:
        return

    quoted_workspace = '"' + dest_workspace.replace('\\', '\\\\').replace(
        '"', '\\"') + '"'

    # Move collected instance window
    for window in windows:
        if any(target_instance in name for name in window_identifiers(window)):
            sway.command(
                f'[con_id="{window.id}"] move container to workspace {quoted_workspace}'
            )

    # Notification
    if verbose:
        message = (f'All *{target_instance}* instance windows are moved to '
                   f'workspace {dest_workspace}')
        os.system('notify-send -u low "Sway-IPC" ' + shlex.quote(message) +
                  ' --icon="$HOME/.config/i3/share/64x64/window.png"')


def main():

    # Input instance to collect
    if len(sys.argv) < 2:
        print(f'Wrong Usage:\n  {sys.argv}\n')
        print('Usage:\n  sway_collect_all_instances.py [target_instance]\n')
        sys.exit()

    target_instance = sys.argv[1]

    # Collect all instances and move them to the workspace
    move_all_instances_to_focused_workspace(target_instance)


if __name__ == '__main__':
    main()
