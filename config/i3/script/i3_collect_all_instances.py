#!/usr/bin/env python3

import i3ipc
import os
import sys


def move_all_instances_to_focused_workspace(target_instance,
                                            dest_workspace=None,
                                            verbose=True):

    # Get windows in i3
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
            f'notify-send -u low "I3-IPC" "All *{target_instance}* instance windows are moved to workspace {focused_workspace}"'
        )


def main():

    # Input instance to collect
    if len(sys.argv) < 2:
        print(f'Wrong Usage:\n  {sys.argv}\n')
        print(f'Usage:\n  i3_collect_all_instances.py [target_instance]\n')
        sys.exit()

    target_instance = sys.argv[1]

    # Collect all instances and move them to the workspace
    move_all_instances_to_focused_workspace(target_instance)


if __name__ == '__main__':
    main()
