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
    buf = b''
    while length:
        data = sock.recv(length)
        if not data:
            break
        buf += data
        length -= len(data)
    return buf


def send_msg(sock, command, payload=''):
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
    reply = recv(sock, 14)
    if not reply:
        raise SocketClosedException
    length, type = struct.unpack('ii', reply[6:])
    if type & 0x80000000:
        type = EVENTS[type & 0x7fffffff]
    else:
        type = COMMANDS[type]
    return type, json.loads(recv(sock, length))


def add_all_marks(sock, marks):

    # # Sort workspace in x-dir (left to right) and  y-dir (top to bottom)
    # workspaces = sorted(send_msg(sock, 'get_workspaces'),
    # key=lambda w: (w['rect']['x'], w['rect']['y']))

    # # Sort workspace in y-dir (top to bottom) and x-dir (left to right)
    # workspaces = sorted(send_msg(sock, 'get_workspaces'),
    # key=lambda w: (w['rect']['y'], w['rect']['x']))

    # # Sort workspace in workspace name (A1 -> A2 -> ... -> B1 -> ...)
    #workspaces = sorted(
    #    send_msg(sock, 'get_workspaces'),
    #    key=lambda w: w['name']
    #    if len(w['name'].split(':')) <= 1 else w['name'].split(':')[1])

    # Sort workspace in workspace ID (1 -> 2 -> ... -> 11 -> ...)
    workspaces = sorted(
        send_msg(sock, 'get_workspaces'),
        key=lambda w: w['name']
        if len(w['name'].split(':')) <= 1 else w['name'].split(':')[0])

    visible_ws = [w['name'] for w in workspaces if w['visible']]
    tree = send_msg(sock, 'get_tree')

    windows = itertools.chain.from_iterable(
        get_windows(tree, workspace) for workspace in visible_ws)
    for mark, id in zip(marks, windows):
        send_msg(sock, 'run_command',
                 '[con_id="{}"] mark --add {}'.format(id, mark))


def get_windows(node, workspace):
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
