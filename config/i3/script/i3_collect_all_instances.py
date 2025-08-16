#!/usr/bin/python3
# -*- coding:utf-8 -*-

import os
import sys

import i3ipc


def move_all_instances_to_focused_workspace(target_instance: str,
                                            dest_workspace: str = None,
                                            verbose: bool = True):
    """
    Move all instances of a given window to the focused workspace.

    Parameters:
    - target_instance (str): The instance name of the window to be moved.
    - dest_workspace (str, optional): The destination workspace. If not provided, uses the focused workspace.
    - verbose (bool, optional): Whether to display a notification after moving the windows.

    Returns:
    None
    """
    i3 = i3ipc.Connection()
    windows = i3.get_tree().leaves()

    # Get focused_workspace
    focused_workspace = i3.get_tree().find_focused().workspace().name

    # Move collected instance window
    for window in windows:
        if target_instance in window.window_instance:
            i3.command(
                f'[con_id="{window.id}"] move container to workspace {focused_workspace}'
            )

    # Notification
    if verbose:
        os.system(
            f'notify-send -u low "I3-IPC" "All *{target_instance}* instance windows are moved to workspace {focused_workspace}" --icon="$HOME/.config/i3/share/64x64/window.png"'
        )


def main():

    # Input instance to collect
    if len(sys.argv) < 2:
        print(f'Wrong Usage:\n  {sys.argv}\n')
        print('Usage:\n  i3_collect_all_instances.py [target_instance]\n')
        sys.exit()

    target_instance = sys.argv[1]

    # Collect all instances and move them to the workspace
    move_all_instances_to_focused_workspace(target_instance)


if __name__ == '__main__':
    main()
