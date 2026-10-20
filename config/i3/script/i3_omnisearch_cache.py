#!/usr/bin/env python3
"""List and remove Omnisearch cache entries without touching search source files."""

import argparse
import json
import re
from datetime import datetime
from pathlib import Path

from i3_pdf_search import live_worker_pid

PDF_KEY = re.compile(r"[0-9a-f]{64}")
PDF_PART = re.compile(r"([0-9a-f]{64})\.(?:jsonl|rows|meta\.json|live\.jsonl|live\.rows|progress\.json)")
ACTIVE = re.compile(r"pdf-active-([0-9a-f]{64})\.json")
STATE_NAMES = {
    "recent_files": "Recent files",
    "last_dir": "Last file search directory",
    "last_grep_dir": "Last text search directory",
    "last_grep_query": "Last text search query",
}


def regular_files(folder):
    if not folder.is_dir() or folder.is_symlink():
        return []
    return [path for path in folder.iterdir() if path.is_file() and not path.is_symlink()]


def live_pdf(path):
    try:
        return bool(live_worker_pid(json.loads(path.read_text(encoding="utf-8"))))
    except (OSError, ValueError, TypeError):
        return False


def live_search(path):
    match = re.fullmatch(r"search-(\d+)\.pid", path.name)
    if not match:
        return False
    try:
        start = path.read_text(encoding="utf-8").strip()
        stat = Path(f"/proc/{match[1]}/stat").read_text()
        return bool(start and stat.rsplit(") ", 1)[1].split()[19] == start)
    except (OSError, IndexError):
        return False


def human_size(size):
    for unit in ("B", "KiB", "MiB", "GiB"):
        if size < 1024 or unit == "GiB":
            return f"{size:.0f} {unit}" if unit == "B" else f"{size:.1f} {unit}"
        size /= 1024


def short(value):
    return " ".join(str(value).split())[:100]


def entry(identifier, label, paths, locked=False):
    existing = []
    stats = []
    for path in paths:
        try:
            if path.is_symlink():
                continue
            stats.append(path.stat())
            existing.append(path)
        except OSError:
            continue  # A running search may remove a temporary file while listing.
    if not existing:
        return None
    size = sum(info.st_size for info in stats)
    newest = max(info.st_mtime for info in stats)
    when = datetime.fromtimestamp(newest).strftime("%b %d %H:%M")
    return {"id": identifier, "label": f"{label}  ·  {human_size(size)}  ·  {when}",
            "size": size, "locked": locked, "paths": existing, "mtime": newest}


def inventory(cache):
    result = []

    def add(*args):
        item = entry(*args)
        if item is not None:
            result.append(item)

    for path in regular_files(cache):
        label = STATE_NAMES.get(path.name, f"Other cache · {short(path.name)}")
        nav = re.fullmatch(r"nav-back-(\d+)", path.name)
        locked = live_search(path) or bool(nav and Path(f"/proc/{nav[1]}").exists())
        add(f"root:{path.name}", label, [path], locked)

    pdf = cache / "pdf"
    families = {}
    active_paths = {}
    pdf_files = regular_files(pdf)
    for path in pdf_files:
        active = ACTIVE.fullmatch(path.name)
        if active:
            active_paths[active[1]] = path
    any_running = any(live_pdf(path) for path in active_paths.values())
    for path in pdf_files:
        match = PDF_PART.fullmatch(path.name)
        active = ACTIVE.fullmatch(path.name)
        if match or active:
            key = (match or active)[1]
            families.setdefault(key, []).append(path)
        elif path.name.startswith("review-") and path.name.endswith(".position"):
            add(f"pdf-file:{path.name}",
                f"PDF review position · {short(path.name[7:19])}", [path])
        else:
            add(f"pdf-file:{path.name}",
                f"Other PDF cache · {short(path.name)}", [path],
                path.name.startswith(".pdf-meta-") and any_running)

    for key, paths in families.items():
        meta = pdf / f"{key}.meta.json"
        try:
            details = json.loads(meta.read_text(encoding="utf-8")) if meta in paths else {}
        except (OSError, ValueError, TypeError):
            details = {}
        if not isinstance(details, dict):
            details = {}
        query = short(details.get("query", "Unfinished or old search"))
        directory = short(details.get("directory", "Unknown directory"))
        if directory == str(Path.home()):
            directory = "~"
        elif directory.startswith(str(Path.home()) + "/"):
            directory = "~/" + directory[len(str(Path.home())) + 1:]
        count = details.get("files")
        count_text = f" · {count} PDFs" if isinstance(count, int) else ""
        locked = key in active_paths and live_pdf(active_paths[key])
        label = f"PDF search · {query} · {directory}{count_text}"
        if locked:
            label = "🔒 Running · " + label
        add(f"pdf:{key}", label, paths, locked)
    return sorted(result, key=lambda item: (not item["locked"], -item["mtime"]))


def remove(cache, identifiers):
    current = {item["id"]: item for item in inventory(cache)}
    deleted = skipped = failed = bytes_removed = 0
    for identifier in dict.fromkeys(identifiers):
        item = current.get(identifier)
        if item is None:
            skipped += 1
            continue
        # Recheck the worker identity immediately before removing a PDF family.
        if identifier.startswith("pdf:"):
            active = cache / "pdf" / f"pdf-active-{identifier[4:]}.json"
            if active.is_file() and live_pdf(active):
                skipped += 1
                continue
        elif identifier.startswith("root:search-") and live_search(cache / identifier[5:]):
            skipped += 1
            continue
        if item["locked"]:
            skipped += 1
            continue
        count = 0
        for path in item["paths"]:
            try:
                if path.is_symlink() or not path.is_file():
                    failed += 1
                    continue
                size = path.stat().st_size
                path.unlink()
                bytes_removed += size
                count += 1
            except OSError:
                failed += 1
        if count:
            deleted += 1
    return {"deleted": deleted, "skipped": skipped, "failed": failed,
            "bytes": bytes_removed}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("list", "delete"))
    parser.add_argument("--cache-dir", type=Path, required=True)
    parser.add_argument("ids", nargs="*")
    args = parser.parse_args()
    if args.command == "list":
        print(json.dumps([{key: value for key, value in item.items() if key not in ("paths", "mtime")}
                          for item in inventory(args.cache_dir)], ensure_ascii=False))
    else:
        print(json.dumps(remove(args.cache_dir, args.ids)))


if __name__ == "__main__":
    main()
