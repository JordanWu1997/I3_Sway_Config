#!/usr/bin/env python3
"""Scan PDFs for the i3 Omnisearch menu and manage active scans."""

import argparse
import json
import os
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from datetime import datetime, timezone
from pathlib import Path


class SearchCancelled(Exception):
    pass


child = None


def process_start(pid):
    """Linux process start tick, so a recycled PID is never treated as our worker."""
    try:
        stat = Path(f"/proc/{pid}/stat").read_text()
        return stat.rsplit(") ", 1)[1].split()[19]
    except (OSError, IndexError):
        return None


def stop_worker(_signum, _frame):
    if child is not None and child.poll() is None:
        child.terminate()
    raise SearchCancelled


def write_json_atomic(path, value):
    target = Path(path)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=target.parent,
                                     prefix=".pdf-meta-", delete=False) as temp:
        json.dump(value, temp, ensure_ascii=False)
        temp.write("\n")
        temp_path = temp.name
    os.replace(temp_path, target)


def pdf_paths(directory):
    for root, dirs, files in os.walk(directory):
        dirs[:] = sorted(
            (d for d in dirs if not (Path(root) / d).is_symlink()),
            key=lambda d: (d != "Documents", d.startswith("."), d.casefold()),
        )
        for name in sorted(files):
            path = Path(root) / name
            if name.lower().endswith(".pdf") and path.is_file():
                yield path


def extract_text(path, timeout):
    global child
    child = subprocess.Popen(["pdftotext", "-enc", "UTF-8", "-q", "--", str(path), "-"],
                             stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    try:
        output, _ = child.communicate(timeout=timeout)
        if child.returncode != 0:
            return None
        return output.decode("utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        child.kill()
        child.communicate()
        return None
    finally:
        child = None


def matching_lines(text, query, mode, limit):
    pages = text.split("\f")
    words = query.casefold().split()
    if mode == "words" and not all(word in text.casefold() for word in words):
        return []
    if mode == "phrase" and query.casefold() not in text.casefold():
        return []
    pattern = re.compile(query, re.IGNORECASE) if mode == "regex" else None
    if pattern and not pattern.search(text):
        return []

    matches = []
    for page_number, page in enumerate(pages, start=1):
        for line in page.splitlines():
            if (any(word in line.casefold() for word in words) if mode == "words"
                    else query.casefold() in line.casefold() if mode == "phrase"
                    else bool(pattern.search(line))):
                snippet = " ".join(line.split())[:180]
                if snippet:
                    matches.append((page_number, snippet))
                    if len(matches) >= limit:
                        return matches
    # A phrase can span lines; still return a file result in that case.
    return matches


def safe_label(value):
    return " ".join(str(value).split()).replace("\t", " ")


def scan(args):
    directory = Path(args.directory).expanduser().resolve()
    if not directory.is_dir() or not args.query.strip():
        raise ValueError("A valid directory and non-empty query are required")
    if args.mode == "regex":
        re.compile(args.query)

    signal.signal(signal.SIGTERM, stop_worker)
    signal.signal(signal.SIGINT, stop_worker)
    active = Path(args.active)
    identity = {"pid": os.getpid(), "start": process_start(os.getpid())}
    if active.exists():
        try:
            prior = json.loads(active.read_text())
        except (OSError, ValueError, KeyError, TypeError):
            prior = {}
        if prior.get("pid") and process_start(int(prior["pid"])) == prior.get("start"):
            raise ValueError("This PDF search is already running")
        active.unlink(missing_ok=True)
    with active.open("x", encoding="utf-8") as active_file:
        json.dump(identity, active_file)
    next_id = 1
    file_count = 0
    match_count = 0
    skipped = 0
    scanned = 0
    started = time.monotonic()
    last_progress = 0
    completed = False
    def progress(force=False):
        nonlocal last_progress
        now = time.monotonic()
        if force or now - last_progress >= 0.5:
            write_json_atomic(args.progress, {"scanned": scanned, "files": file_count,
                                              "matches": match_count, "skipped": skipped,
                                              "seconds": int(now - started),
                                              "done": completed})
            last_progress = now

    try:
        progress(True)
        with open(args.records, "w", encoding="utf-8") as records, \
                open(args.display, "w", encoding="utf-8") as display:
            for path in pdf_paths(directory):
                scanned += 1
                text = extract_text(path, args.timeout)
                if text is None:
                    skipped += 1
                    progress()
                    continue
                matches = matching_lines(text, args.query, args.mode, args.max_matches_per_file)
                eligible = bool(matches)
                if not eligible:
                    folded = text.casefold()
                    if args.mode == "words":
                        eligible = all(word in folded for word in args.query.casefold().split())
                    elif args.mode == "phrase":
                        eligible = args.query.casefold() in folded
                    else:
                        eligible = bool(re.search(args.query, text, re.IGNORECASE))
                if not eligible:
                    progress()
                    continue

                file_count += 1
                path_str = str(path)
                rows = [{"id": next_id, "kind": "file", "file": path_str,
                         "page": None, "snippet": ""}]
                next_id += 1
                for page, snippet in matches:
                    rows.append({"id": next_id, "kind": "match", "file": path_str,
                                 "page": page, "snippet": snippet})
                    next_id += 1
                match_count += len(matches)

                for row in rows:
                    records.write(json.dumps(row, ensure_ascii=False) + "\n")
                    records.flush()
                    if row["kind"] == "file":
                        if args.mode == "words":
                            detail = f"all words in PDF; {len(matches)} excerpt lines"
                        else:
                            detail = f"{len(matches)} matching lines"
                        label = f"PDF {path.name} — {path.parent} ({detail})"
                    else:
                        label = f"  p{row['page']} {path.name}: {row['snippet']}"
                    if row["kind"] == "file":
                        display.write(f"{row['id']:06d}\t{safe_label(label)}\n")
                        display.flush()
                progress()
                if args.max_files > 0 and file_count >= args.max_files:
                    break

        shutil.copyfile(args.records, args.cache_records)
        shutil.copyfile(args.display, args.cache_display)
        write_json_atomic(args.meta, {"directory": str(directory), "query": args.query,
                                      "mode": args.mode, "files": file_count,
                                      "matches": match_count, "skipped": skipped,
                                      "scanned": scanned, "max_files": args.max_files,
                                      "created": datetime.now(timezone.utc).isoformat()})
        completed = True
        progress(True)
        return 0
    except SearchCancelled:
        return 130
    finally:
        if not completed:
            for path in (args.records, args.display, args.progress):
                try:
                    Path(path).unlink()
                except FileNotFoundError:
                    pass
        try:
            if json.loads(active.read_text()) == identity:
                active.unlink()
        except (OSError, ValueError):
            pass


def cancel(args):
    count = 0
    for active in Path(args.cache_dir).glob("pdf-active-*.json"):
        try:
            identity = json.loads(active.read_text())
            pid = int(identity["pid"])
            if process_start(pid) == identity.get("start") and pid != os.getpid():
                os.kill(pid, signal.SIGTERM)
                count += 1
            else:
                active.unlink()
        except (OSError, ValueError, KeyError):
            continue
    print(count)
    return 0


def status(args):
    try:
        identity = json.loads(Path(args.active).read_text())
        pid = int(identity["pid"])
        if process_start(pid) == identity.get("start"):
            if not getattr(args, "quiet", False):
                print(pid)
            return 0
    except (OSError, ValueError, KeyError, TypeError):
        pass
    return 1


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    scanner = commands.add_parser("scan")
    scanner.add_argument("--directory", required=True)
    scanner.add_argument("--query", required=True)
    scanner.add_argument("--mode", choices=("words", "phrase", "regex"), default="words")
    scanner.add_argument("--records", required=True)
    scanner.add_argument("--display", required=True)
    scanner.add_argument("--cache-records", required=True)
    scanner.add_argument("--cache-display", required=True)
    scanner.add_argument("--meta", required=True)
    scanner.add_argument("--active", required=True)
    scanner.add_argument("--progress", required=True)
    scanner.add_argument("--timeout", type=int, default=30)
    scanner.add_argument("--max-matches-per-file", type=int, default=200)
    scanner.add_argument("--max-files", type=int, default=-1)
    canceller = commands.add_parser("cancel")
    canceller.add_argument("--cache-dir", required=True)
    checker = commands.add_parser("status")
    checker.add_argument("--active", required=True)
    args = parser.parse_args()
    try:
        return {"scan": scan, "cancel": cancel, "status": status}[args.command](args)
    except (OSError, ValueError, re.error) as error:
        print(f"PDF search: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
