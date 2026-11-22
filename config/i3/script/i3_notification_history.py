#!/usr/bin/env python3
"""Browse the existing Dunst DBus log as complete notifications in Rofi."""

import argparse
import json
import os
import re
import subprocess
import textwrap
from dataclasses import dataclass
from pathlib import Path


HEADER = re.compile(r"^--- (\d{4}-\d\d-\d\d \d\d:\d\d:\d\d)( v2)? ---$")
DBUS_STRING = re.compile(r'string\s+("(?:\\.|[^"\\])*")')
DEFAULT_LOG = Path.home() / ".config/dunst/log.txt"
ROFI_CONFIG = Path.home() / ".config/rofi/config_omnisearch.rasi"
FALLBACK_ICON = Path.home() / ".config/i3/share/64x64/notification.png"


@dataclass
class Notification:
    when: str
    app: str
    summary: str
    body: str
    icon: str = ""


def decode_string(value: str) -> str:
    try:
        return json.loads(value)
    except json.JSONDecodeError:
        return value[1:-1]


def parse_history(lines):
    """Read every record from both the old log and the v2 log."""
    entries = []
    when = None
    version = 1
    parts = []

    def add_entry():
        if not when or not parts:
            return
        values = [decode_string(match) for match in DBUS_STRING.findall(" ".join(parts))]
        if not values:
            return
        app = values[0] or "Unknown app"
        icon = ""
        if version == 2:
            # The logger now retains empty icon, summary, and body arguments.
            icon = values[1] if len(values) > 1 else ""
            summary = values[2] if len(values) > 2 else ""
            body = values[3] if len(values) > 3 else ""
        elif len(values) >= 4 and not re.search(r"\s", values[1]):
            # Old records dropped empty fields. A short icon name or path is
            # usually the second value when four or more values are present.
            icon = values[1]
            summary, body = values[2], values[3]
        else:
            summary = values[1] if len(values) > 1 else ""
            body = values[2] if len(values) > 2 else ""
        entries.append(Notification(when, app, summary, body, icon))

    for line in lines:
        line = line.rstrip("\n")
        header = HEADER.match(line)
        if header:
            add_entry()
            when, version, parts = header.group(1), 2 if header.group(2) else 1, []
        elif when is not None:
            parts.append(line)
    add_entry()
    entries.reverse()
    return entries


def one_line(value: str) -> str:
    return " ".join(value.split())


def label(entry: Notification) -> str:
    title = one_line(entry.summary or "(no summary)")
    body = one_line(entry.body)
    detail = f"  —  {body}" if body else ""
    return f"{entry.when}  │  {one_line(entry.app)}  │  {title}{detail}"


def history_row(entry: Notification) -> str:
    # Rofi uses the icon property for the image. The theme places it after text.
    icon = (entry.icon or str(FALLBACK_ICON)).replace("\n", "").replace("\x00", "")
    meta = " ".join((entry.summary, entry.body)).replace("\n", " ").replace("\x00", "")
    return f"{label(entry)}\0icon\x1f{icon}\x1fmeta\x1f{meta}"


def rofi(rows, prompt, message, selected=0, controls=False):
    shortcuts = ["-kb-custom-1", "Alt+e", "-kb-custom-2", "Alt+d"] if controls else []
    result = subprocess.run(
        [
            "rofi", "-dmenu", "-i", "-no-custom", "-format", "i",
            "-config", str(ROFI_CONFIG), "-show-icons", "-p", prompt,
            "-mesg", message, "-selected-row", str(selected),
            "-kb-custom-6", "Alt+b", "-kb-move-word-back", "Control+Left",
            *shortcuts,
            "-theme-str", "#window { fullscreen: true; padding: 2% 3%; }"
            " #listview { columns: 1; lines: 17; }"
            " #element { orientation: horizontal; children: [element-text, element-icon]; spacing: 8px; }"
            " #element-text { expand: true; } #element-icon { size: 2ch; }",
        ],
        input="\n".join(rows) + "\n",
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode in (10, 11, 15):
        return -result.returncode
    if result.returncode != 0:
        return None
    try:
        return int(result.stdout.strip())
    except ValueError:
        return None


def detail_rows(entry: Notification, width=120):
    """Wrap complete text into scrollable rows, preserving paragraph breaks."""
    rows = [f"Time  │  {entry.when}", f"App   │  {entry.app}", "Summary"]
    for heading, value in ((None, entry.summary), ("Body", entry.body)):
        if heading:
            rows.append(heading)
        for line in value.split("\n"):
            rows.extend(textwrap.wrap(line, width=width, replace_whitespace=False,
                                      drop_whitespace=False, break_long_words=True,
                                      break_on_hyphens=False) or [" "])
    return rows


def show_detail(entry: Notification) -> bool:
    rows = detail_rows(entry)
    selected = 0
    while True:
        choice = rofi(rows, "Notification details",
                      "Full text · Scroll to read · Esc: history · Alt+B: Search",
                      selected)
        if choice is None:
            return False
        if choice == -15:
            return True
        if choice >= 0:
            selected = choice


def browse(entries):
    if not entries:
        return rofi(["No logged notifications yet"], "Notification history", "Esc: back") == -15
    rows = [history_row(entry) for entry in entries]
    selected = 0
    while True:
        index = rofi(
            rows,
            "Notification history",
            "All logged notifications, newest first · Type to filter · Enter: full text · Esc: back · Alt+B: Search",
            selected,
        )
        if index == -15:
            return True
        if index is None or index < 0 or index >= len(entries):
            return False
        selected = index
        if show_detail(entries[index]):
            return True


def load_entries(log: Path):
    try:
        with log.open(encoding="utf-8", errors="replace") as stream:
            return parse_history(stream)
    except FileNotFoundError:
        return []


def logger_running() -> bool:
    script = Path.home() / ".config/i3/script/i3_notify_logger.sh"
    return subprocess.run(
        ["pgrep", "-u", str(os.getuid()), "-f", str(script)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False,
    ).returncode == 0


def notification_menu(log: Path, operator: Path):
    feedback = ""
    while True:
        state = "on" if logger_running() else "off"
        choice = rofi(
            ["Open · Notification history", "Logger · Enable", "Logger · Disable"],
            "Notifications",
            f"Logger: {state}{' · ' + feedback if feedback else ''} · Alt+E: enable · Alt+D: disable · Esc/Alt+B: Search",
            controls=True,
        )
        if choice is None or choice == -15:
            return
        if choice == 0:
            if browse(load_entries(log)):
                return
            feedback = ""
            continue
        action = "enable_dunst_logger" if choice in (1, -10) else "disable_dunst_logger" if choice in (2, -11) else ""
        if not action:
            return
        result = subprocess.run([str(operator), action], capture_output=True, text=True, check=False)
        feedback = ("Logger enabled" if action.startswith("enable") else "Logger disabled") if result.returncode == 0 else "Logger action failed"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--log", type=Path, default=DEFAULT_LOG)
    parser.add_argument("--dump", action="store_true", help="print parsed rows without Rofi")
    parser.add_argument("--menu", action="store_true", help="show history and logger controls")
    parser.add_argument("--operator", type=Path, default=Path.home() / ".config/i3/script/i3_dunst_operator.sh")
    args = parser.parse_args()
    if args.dump:
        for entry in load_entries(args.log):
            print(label(entry))
    elif args.menu:
        notification_menu(args.log, args.operator)
    else:
        browse(load_entries(args.log))


if __name__ == "__main__":
    main()
