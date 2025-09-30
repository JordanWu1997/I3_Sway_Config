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

DEVICE_MAC = "D9:5A:24:D8:B5:77"
# DEVICE_MAC = "CF:06:C8:15:7D:E1"
RUN_SCRIPT = "/home/jordan/.config/i3/script/i3_keyboard_operator.sh"
SCRIPT_OPS = ["default"]


def properties_changed(interface, changed, invalidated, path):
    if interface != "org.bluez.Device1":
        return
    if "Connected" in changed:
        if changed["Connected"]:
            if DEVICE_MAC.replace(":", "_") in path:
                print(f"Device {DEVICE_MAC} connected. Running script.")

                env = os.environ.copy()
                env["DISPLAY"] = ":0"
                env["XAUTHORITY"] = "/home/jordan/.Xauthority"
                # Need time for device connection to be stablized
                time.sleep(0.5)
                subprocess.Popen([RUN_SCRIPT, *SCRIPT_OPS], env=env)


dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
bus = dbus.SystemBus()
bus.add_signal_receiver(properties_changed,
                        dbus_interface="org.freedesktop.DBus.Properties",
                        signal_name="PropertiesChanged",
                        path_keyword="path")

loop = GLib.MainLoop()
loop.run()
