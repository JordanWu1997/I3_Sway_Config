#!/usr/bin/env python3

import itertools
import json
import os
import socket
import struct
import subprocess
import sys


class SocketClosedException(Exception):
    pass


# MARKS = '1234567890qwertyuiopasdfghjklzxcvbnm'
MARKS = ''
with open(
        os.path.expanduser('~') + '/.config/i3/share/i3_automark_list.txt',
        'r') as automark_txt:
    for mark in automark_txt.readlines():
        MARKS += mark.strip('\n')

COMMANDS = [
    'run_command',
    'get_workspaces',
    'subscribe',
    'get_outputs',
    'get_tree',
    'get_marks',
    'get_bar_config',
    'get_version',
    'get_binding_modes',
    'send_tick',
]

EVENTS = [
    'workspace',
    'output',
    'mode',
    'window',
    'barconfig_update',
    'binding',
    'shutdown',
    'tick',
]


def recv(sock, length):
    """
    Receive a specified number of bytes from the socket.

    Args:
    - sock: The socket object to receive data from.
    - length: The number of bytes to receive.

    Returns:
    - A byte string containing the received data.
    """
    buf = b''
    while length:
        data = sock.recv(length)
        if not data:
            break
        buf += data
        length -= len(data)
    return buf


def send_msg(sock, command, payload=''):
    """
    Send a message over the socket with the given command and optional payload.

    Args:
        sock (socket.socket): The socket to send the message over.
        command (str): The command to be sent. Supported commands are 'run_command'.
        payload (str, optional): The payload to be sent along with the command. Defaults to an empty string.

    Returns:
        dict: The response from the server if the command is successful, otherwise raises an exception.
    """
    payload = payload.encode('utf-8')
    msg = struct.pack('II', len(payload), COMMANDS.index(command))
    sock.sendall(b'i3-ipc' + msg + payload)
    while True:
        type, response = read_msg(sock)
        if type == command:
            if command == 'run_command':
                response = response[0]
            if isinstance(response,
                          dict) and not response.get('success', True):
                raise Exception(response.get('error'))
            return response


def read_msg(sock):
    """
    Reads a message from the socket and parses it.

    Args:
        sock (socket.socket): The socket object to read from.

    Returns:
        tuple: A tuple containing the parsed command and its corresponding JSON data.
    """
    reply = recv(sock, 14)
    if not reply:
        raise SocketClosedException
    length, type = struct.unpack('ii', reply[6:])
    if type & 0x80000000:
        type = EVENTS[type & 0x7fffffff]
    else:
        type = COMMANDS[type]
    return type, json.loads(recv(sock, length))


def add_all_marks(sock, marks, sort_by='WS_ID'):
    """
    Adds all specified marks to the visible workspaces.

    Args:
    - sock: The socket object for communication with the workspace manager.
    - marks: A list of marks to be added.
    - sort_by (str): The sorting order for the workspaces. Can be one of the following:
        - 'x_then_y': Sort by workspace ID in ascending order and then by workspace name.
        - 'y_then_x': Sort by workspace name in ascending order and then by workspace ID.
        - 'WS_name': Sort by workspace name in alphabetical order.
        - 'WS_ID': Sort by workspace ID in descending order.

    Returns:
    None
    """
    # Sort workspace in x-dir (left to right) and  y-dir (top to bottom)
    if sort_by == 'x_then_y':
        workspaces = sorted(send_msg(sock, 'get_workspaces'),
                            key=lambda w:
                            (int(w['rect']['x']), int(w['rect']['y'])))
    # Sort workspace in y-dir (top to bottom) and x-dir (left to right)
    elif sort_by == 'y_then_x':
        workspaces = sorted(send_msg(sock, 'get_workspaces'),
                            key=lambda w:
                            (int(w['rect']['y']), int(w['rect']['x'])))
    # Sort workspace in workspace name (A1 -> A2 -> ... -> B1 -> ...)
    elif sort_by == 'WS_name':
        workspaces = sorted(
            send_msg(sock, 'get_workspaces'),
            key=lambda w: w['name']
            if len(w['name'].split(':')) <= 1 else w['name'].split(':')[1])
    # Sort workspace in workspace ID (1 -> 2 -> ... -> 11 -> ...)
    elif sort_by == 'WS_ID':
        workspaces = sorted(send_msg(sock, 'get_workspaces'),
                            key=lambda w: -1 if len(w['name'].split(':')) <= 1
                            else int(w['name'].split(':')[0]))
    else:
        print(
            f'[ERROR] Unsupported sort_by option: {sort_by} (Available: x_then_y, y_then_x, WS_name, WS_ID)'
        )
        return

    visible_ws = [w['name'] for w in workspaces if w['visible']]
    tree = send_msg(sock, 'get_tree')

    windows = itertools.chain.from_iterable(
        get_windows(tree, workspace) for workspace in visible_ws)
    for mark, id in zip(marks, windows):
        send_msg(sock, 'run_command',
                 '[con_id="{}"] mark --add {}'.format(id, mark))


def get_windows(node, workspace):
    """
    Recursively retrieves window IDs from a given tree structure.

    Args:
    - node: A dictionary representing the current node in the tree.
    - workspace: A string representing the target workspace name.

    Yields:
    - Window IDs of nodes that match the specified workspace.
    """
    if node['window']:
        yield node['id']
    elif node['type'] == 'dockarea':
        return
    elif node['type'] == 'workspace' and node['name'] != workspace:
        return
    else:
        for child in node['nodes'] + node['floating_nodes']:
            yield from get_windows(child, workspace)


if __name__ == '__main__':
    marks = sys.argv[1] if len(sys.argv) > 1 else MARKS
    socketpath = subprocess.check_output(['i3',
                                          '--get-socketpath']).rstrip(b'\n')
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as sock:
        sock.connect(socketpath)
        send_msg(sock, 'subscribe',
                 json.dumps(['workspace', 'output', 'window']))

        # Initialize marks for all windows
        add_all_marks(sock, marks)
        send_msg(sock, 'run_command', 'mark --add " "')
