#!/usr/bin/env python3
"""Which save did each segment actually enter from?

    tools/gate_f/diag/handoff_provenance.py ralph/reports/gate-f-run-<stamp>

Section B chains the journey by save handoff: each segment ends by saving to
slot 4 through the production Save tab and copying the slot out as
`saves/<segment>-exit.json`; the next boots, seeds that file back into slot 4,
and loads it through the title screen. A blocker then restarts at the last gate
rather than at the top of the chapter.

RIG-10 is that `operator_harness.gd::_step_save_out()` checks only that the slot
FILE EXISTS -- and `seed_save` put the previous segment's file there at step 3 of
the same segment, so the check can never fire for the reason it was written. A
segment that never reached the Save tab copies out the save it was handed, under
this segment's name, and reports a PASS.

The identity of the bytes is what settles it, so this reports the bytes: every
exit save in a run directory, grouped by content hash, with the Save-tab steps
that were supposed to produce each one and the verdicts they actually got. Two
segments sharing a hash did not both save; the later one handed on the earlier
one's world, and every segment after it entered somewhere other than where the
protocol says.

Reads only. Writes nothing, changes no verdict.
"""
import hashlib
import json
import pathlib
import re
import sys


def sha(path):
    return hashlib.md5(path.read_bytes()).hexdigest()


def save_steps(seg_dir):
    """The Save-tab steps and their verdicts, from the segment's own notes."""
    notes = list((seg_dir / "notes").glob("*.md")) if (seg_dir / "notes").is_dir() else []
    if not notes:
        return []
    text = notes[0].read_text(errors="replace")
    out = []
    for block in text.split("### ")[1:]:
        head = block.split("\n", 1)[0]
        if not re.search(r"(Save tab|press Save|pause shell|copy slot)", block.split("- verdict")[0], re.I):
            continue
        verdict = "?"
        m = re.search(r"^- verdict: (\w+)", block, re.M)
        if m:
            verdict = m.group(1)
        actual = ""
        m = re.search(r"^- actual: (.*)$", block, re.M)
        if m:
            actual = m.group(1)[:100]
        out.append((head.strip(), verdict, actual))
    return out


def main(run_dir):
    run = pathlib.Path(run_dir)
    if not run.is_dir():
        sys.exit(f"no such run directory: {run}")

    rows = []
    # Superseded directories are preserved but are explicitly "not evidence of
    # anything" (RESTARTS.md), and one of them carries a save this session's own
    # diagnostic probe put in slot 4 while that attempt was live. Including them
    # here would report a duplicate that says nothing about the handoff.
    for seg in sorted(p for p in run.iterdir() if p.is_dir() and "-superseded-" not in p.name):
        for save in sorted((seg / "saves").glob("*.json")) if (seg / "saves").is_dir() else []:
            rows.append({
                "segment": seg.name,
                "file": f"{seg.name}/saves/{save.name}",
                "bytes": save.stat().st_size,
                "md5": sha(save),
                "save_steps": save_steps(seg),
            })

    by_hash = {}
    for r in rows:
        by_hash.setdefault(r["md5"], []).append(r)

    print(f"# Handoff provenance — {run.name}\n")
    print("Section B chains the journey by save handoff. `_step_save_out` checks only")
    print("that the slot file EXISTS, and `seed_save` put the previous segment's file")
    print("there at step 3 of the same segment — so a segment that never reached the")
    print("Save tab copies out the save it was HANDED, under this segment's name, and")
    print("reports a PASS (RIG-10). Identity of bytes is what settles it.\n")

    print("| exit save | bytes | md5 (12) | distinct? |")
    print("|---|---|---|---|")
    for r in rows:
        shared = len(by_hash[r["md5"]])
        mark = "yes" if shared == 1 else f"**NO — shared with {shared - 1} other**"
        print(f"| `{r['file']}` | {r['bytes']} | `{r['md5'][:12]}` | {mark} |")

    dupes = {h: v for h, v in by_hash.items() if len(v) > 1}
    if not dupes:
        print("\nEvery exit save is distinct. Every segment saved its own world.")
        return 0

    print("\n## The duplicates, and what each segment's own notes say about saving\n")
    for h, group in dupes.items():
        names = ", ".join(g["segment"] for g in group)
        print(f"### `{h[:12]}` — {names}\n")
        print("Byte-identical. At most one of these segments wrote this file; the rest")
        print("handed it on. Their own Save-tab verdicts:\n")
        for g in group:
            print(f"**{g['segment']}**")
            if not g["save_steps"]:
                print("  - (no Save-tab steps found in its notes)")
            for head, verdict, actual in g["save_steps"]:
                print(f"  - `{verdict:9s}` {head}")
                if verdict == "FAIL" and actual:
                    print(f"      {actual}")
            print()

    print("## What this means for the chain\n")
    order = [r["segment"] for r in rows]
    print("A segment whose entry save is a duplicate did not start where §B says it")
    print("did. Reading the chain in order:\n")
    prev_hash = None
    for r in rows:
        if prev_hash == r["md5"]:
            print(f"- **{r['segment']}** ended in the same world it was handed; the segment")
            print(f"  after it entered from a state one or more gates EARLIER than its name says.")
        prev_hash = r["md5"]
    print(f"\nSegments with an exit save, in order: {', '.join(order)}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else "."))
