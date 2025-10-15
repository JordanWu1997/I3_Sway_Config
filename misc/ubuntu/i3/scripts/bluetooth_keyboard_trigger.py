#!/usr/bin/python3
# -*- coding:utf-8 -*-
"""
[ADD MODULE DOCUMENTATION HERE]

# ========================================================================== #
#  _  __   _   _                                          __        ___   _  #
# | |/ /  | | | |  Author: Jordan Kuan-Hsien Wu           \ \      / / | | | #
# | ' /   | |_| |  E-mail: jordankhwu@gmail.com            \ \ /\ / /| | | | #
# | . \   |  _  |  Github: https://github.com/JordanWu1997  \ V  V / | |_| | #
# |_|\_\  |_| |_|  Datetime: 2025-07-17 02:36:07             \_/\_/   \___/  #
#                                                                            #
# ========================================================================== #
"""

import os
import subprocess
import time

import dbus
import dbus.mainloop.glib
from gi.repository import GLib


def get_keyboard_address(keyboard_keyword='HHKB'):
    """
    Executes 'bluetoothctl devices' and pipes the output through 'grep HHKB'
    and then 'cut -d' ' -f2' to extract the HHKB Bluetooth MAC address.
    """
    try:
        # 1. Execute 'bluetoothctl devices'
        # capture_output=True: captures stdout and stderr
        # text=True: decodes stdout/stderr as text
        bluetoothctl_result = subprocess.run(
            ['bluetoothctl', 'devices'],
            capture_output=True,
            text=True,
            check=True  # Raise an exception for non-zero exit codes
        )
        # 2. Pipe the output to 'grep HHKB'
        grep_result = subprocess.run(['grep', keyboard_keyword],
                                     input=bluetoothctl_result.stdout,
                                     capture_output=True,
                                     text=True,
                                     check=True)
        # 3. Pipe the output to 'cut -d' ' -f2'
        # The split argument in cut is a single space ' '
        cut_result = subprocess.run(['cut', '-d', ' ', '-f2'],
                                    input=grep_result.stdout,
                                    capture_output=True,
                                    text=True,
                                    check=True)
        # The final output is the stdout of the last command,
        # stripped of leading/trailing whitespace (like a final newline)
        return cut_result.stdout.strip()
    except subprocess.CalledProcessError as e:
        # Handle errors (e.g., if 'bluetoothctl' or 'grep' fails to find 'HHKB')
        print(f"Error executing subprocess: {e}")
        print(f"Stderr: {e.stderr}")
        return None
    except FileNotFoundError:
        # Handle cases where the command (e.g., 'bluetoothctl') is not found
        print(
            "Error: 'bluetoothctl' command not found. Ensure it is installed and in your PATH."
        )
        return None


def properties_changed(interface, changed, invalidated_props, path=None):
    if interface != "org.bluez.Device1":
        return
    if "Connected" in changed:
        if changed["Connected"] and DEVICE_MAC:
            if DEVICE_MAC.replace(":", "_") in path:
                print(f"Device {DEVICE_MAC} connected. Running script.")
                env = os.environ.copy()
                env["DISPLAY"] = DISPLAY
                env["XAUTHORITY"] = "/home/jordan/.Xauthority"
                # Need time for device connection to be stablized
                time.sleep(0.5)
                subprocess.Popen([RUN_SCRIPT, *SCRIPT_OPS], env=env)


if __name__ == '__main__':

    import argparse

    # Input arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('-n',
                        '--keyboard_name',
                        type=str,
                        help='Name of bluetooth keyboard',
                        default='HHKB')
    parser.add_argument(
        '-d',
        '--display_var',
        type=str,
        help=
        'DISPLAY Variable for X-window (by default Ubuntu -> :0, Pop-OS -> :1)',
        default=':0')
    args = parser.parse_args()

    # Init
    RUN_SCRIPT = "/home/jordan/.config/i3/script/i3_keyboard_operator.sh"
    SCRIPT_OPS = ["default"]
    KEYBOARD_NAME = args.keyboard_name
    DISPLAY = args.display_var
    DEVICE_MAC = get_keyboard_address(keyboard_keyword=KEYBOARD_NAME)

    # Main
    dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
    bus = dbus.SystemBus()
    bus.add_signal_receiver(properties_changed,
                            dbus_interface="org.freedesktop.DBus.Properties",
                            signal_name="PropertiesChanged",
                            path_keyword="path")
    loop = GLib.MainLoop()
    loop.run()
