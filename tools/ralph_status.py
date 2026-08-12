#!/usr/bin/env python3
"""Claim, heartbeat, release and validate blocks in ralph/STATUS.md's live
lease list (the file on the `ralph-status` branch, never `main`'s frozen copy).

    tools/ralph_status.py claim    --file ralph/STATUS.md --firing X --session Y \
        --task Z --area A [--area B ...] --state started [--note "..."]
    tools/ralph_status.py heartbeat --file ralph/STATUS.md --firing X --task Z \
        --state working --note "..."
    tools/ralph_status.py release  --file ralph/STATUS.md --firing X --task Z
    tools/ralph_status.py check    --file ralph/STATUS.md

LP6: STATUS.md kept growing past its own `## END LEASES` marker because a
firing edited the file by eye, scrolled to what it thought was the end, and
appended there instead of before the marker. That is a mistake a script
cannot make — `claim`/`heartbeat` always compute the insertion point by
finding the marker line, never by "the end of the file", so the failure mode
this item exists to close is structurally unavailable. `check` gives any
firing (or a human) a one-line yes/no on whether drift has happened anyway,
without reading the whole file.
"""

import argparse
import datetime
import re
import sys

MARKER = "## END LEASES"
BLOCK_FIELD_RE = re.compile(r"^\s{4}(\w[\w-]*):\s*(.*)$")


def read_lines(path):
    with open(path, encoding="utf-8") as f:
        return f.read().splitlines(keepends=True)


def write_lines(path, lines):
    with open(path, "w", encoding="utf-8") as f:
        f.writelines(lines)


def marker_index(lines):
    for i, line in enumerate(lines):
        if line.strip() == MARKER:
            return i
    raise SystemExit(f"error: no '{MARKER}' line found — refusing to guess where leases end")


def split_blocks(lines, end):
    """Blocks are runs of non-blank lines before `end`, separated by >=1 blank line."""
    blocks = []
    current = []
    current_start = None
    for i in range(end):
        if lines[i].strip() == "":
            if current:
                blocks.append((current_start, i, current))
                current = []
                current_start = None
            continue
        if current_start is None:
            current_start = i
        current.append(lines[i])
    if current:
        blocks.append((current_start, end, current))
    return blocks


def block_fields(block_lines):
    fields = {}
    for line in block_lines:
        m = BLOCK_FIELD_RE.match(line.rstrip("\n"))
        if m:
            key, val = m.group(1), m.group(2)
            if key not in fields:
                fields[key] = val
    return fields


def is_lease_block(block_lines):
    """A real lease block, not the HTML-comment instructions block."""
    joined = "".join(block_lines)
    return bool(re.search(r"^\s{4}firing:\s", joined, re.MULTILINE))


def now_iso():
    return datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def cmd_check(args):
    lines = read_lines(args.file)
    end = marker_index(lines)
    tail = "".join(lines[end + 1:])
    stray = re.findall(r"^\s{4}firing:\s.*$", tail, re.MULTILINE)
    if stray:
        print(f"DRIFT: {len(stray)} lease block(s) found after '{MARKER}':", file=sys.stderr)
        for s in stray:
            print(f"  {s.strip()}", file=sys.stderr)
        return 1
    print(f"clean: no lease content after '{MARKER}' (line {end + 1})")
    return 0


def cmd_claim(args):
    lines = read_lines(args.file)
    end = marker_index(lines)
    for _, _, block in split_blocks(lines, end):
        if not is_lease_block(block):
            continue
        f = block_fields(block)
        if f.get("firing") == args.firing and f.get("task") == args.task:
            raise SystemExit(
                f"error: {args.firing} already has a block for task {args.task} — use heartbeat, not claim"
            )

    area = ", ".join(args.area)
    note_lines = wrap_note(args.note) if args.note else []
    block = [
        f"    firing:    {args.firing}\n",
        f"    session:   {args.session}\n",
        f"    task:      {args.task}\n",
        f"    area:      {area}\n",
        f"    state:     {args.state}\n",
        f"    updated:   {args.updated or now_iso()}\n",
    ] + note_lines + ["\n"]

    # Insert immediately before the marker line, preceded by a blank line
    # if the previous line is not already blank — never at end-of-file.
    insert_at = end
    if insert_at > 0 and lines[insert_at - 1].strip() != "":
        block = ["\n"] + block
    lines[insert_at:insert_at] = block
    write_lines(args.file, lines)
    print(f"claimed: {args.firing} / {args.task} (area: {area})")
    return 0


def wrap_note(note, key="note"):
    # Matches the file's own column convention: 4-space indent, then
    # "key:" padded so every field's value starts at column 15.
    prefix = f"    {key}:".ljust(15)
    return [f"{prefix}{note}\n"]


def next_note_key(block_lines):
    """First unused key among note, note-2, note-3, ... — matches the file's
    existing convention for a block that gets more than one status update."""
    used = set()
    for line in block_lines:
        m = re.match(r"^\s{4}(note(?:-\d+)?):\s", line)
        if m:
            used.add(m.group(1))
    if "note" not in used:
        return "note"
    n = 2
    while f"note-{n}" in used:
        n += 1
    return f"note-{n}"


def cmd_heartbeat(args):
    lines = read_lines(args.file)
    end = marker_index(lines)
    for start, stop, block in split_blocks(lines, end):
        if not is_lease_block(block):
            continue
        f = block_fields(block)
        if f.get("firing") == args.firing and f.get("task") == args.task:
            new_block = []
            for line in block:
                if re.match(r"^\s{4}state:\s", line) and args.state:
                    new_block.append(f"    state:     {args.state}\n")
                elif re.match(r"^\s{4}updated:\s", line):
                    new_block.append(f"    updated:   {args.updated or now_iso()}\n")
                else:
                    new_block.append(line)
            if args.note:
                key = args.note_key if args.note_key != "note" else next_note_key(block)
                new_block.append(wrap_note(args.note, key=key)[0])
            lines[start:stop] = new_block
            write_lines(args.file, lines)
            print(f"heartbeat: {args.firing} / {args.task}")
            return 0
    raise SystemExit(f"error: no existing block for {args.firing} / {args.task} — use claim first")


def cmd_release(args):
    lines = read_lines(args.file)
    end = marker_index(lines)
    for start, stop, block in split_blocks(lines, end):
        if not is_lease_block(block):
            continue
        f = block_fields(block)
        if f.get("firing") == args.firing and f.get("task") == args.task:
            del lines[start:stop]
            # Collapse a resulting double-blank-line at the seam.
            while start < len(lines) and start > 0 and lines[start - 1].strip() == "" and lines[start].strip() == "":
                del lines[start]
            write_lines(args.file, lines)
            print(f"released: {args.firing} / {args.task}")
            return 0
    raise SystemExit(f"error: no existing block for {args.firing} / {args.task} — nothing to release")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    common = dict(required=True)

    pc = sub.add_parser("claim", help="append a new lease block before the marker")
    pc.add_argument("--file", **common)
    pc.add_argument("--firing", **common)
    pc.add_argument("--session", **common)
    pc.add_argument("--task", **common)
    pc.add_argument("--area", nargs="+", **common)
    pc.add_argument("--state", default="started")
    pc.add_argument("--note")
    pc.add_argument("--updated")
    pc.set_defaults(func=cmd_claim)

    ph = sub.add_parser("heartbeat", help="update an existing block's state/timestamp/note")
    ph.add_argument("--file", **common)
    ph.add_argument("--firing", **common)
    ph.add_argument("--task", **common)
    ph.add_argument("--state")
    ph.add_argument("--note")
    ph.add_argument("--note-key", default="note")
    ph.add_argument("--updated")
    ph.set_defaults(func=cmd_heartbeat)

    pr = sub.add_parser("release", help="delete a firing's block for a task")
    pr.add_argument("--file", **common)
    pr.add_argument("--firing", **common)
    pr.add_argument("--task", **common)
    pr.set_defaults(func=cmd_release)

    pk = sub.add_parser("check", help="exit 1 if any lease content drifted past the marker")
    pk.add_argument("--file", **common)
    pk.set_defaults(func=cmd_check)

    args = p.parse_args()
    sys.exit(args.func(args))


if __name__ == "__main__":
    main()
