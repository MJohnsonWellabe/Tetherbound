#!/usr/bin/env python3
"""Apply remaining integrated Gate A batches on the Claude delivery branch.

The original modal-freeze/repeat-build batch is already committed on this branch.
Each active batch below is independently asserted/idempotent, so reruns continue
from the first not-yet-applied source edit and fail rather than guessing if main
has changed under us.
"""
from pathlib import Path
from gate_a_batch2 import apply as apply_batch2
from gate_a_batch3_beds import apply as apply_batch3
from gate_a_batch4_title import apply as apply_batch4

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    changed = False
    changed |= apply_batch2(ROOT)
    changed |= apply_batch3(ROOT)
    changed |= apply_batch4(ROOT)
    print("Gate A active batches complete" + (" (changes applied)" if changed else " (already applied)"))


if __name__ == "__main__":
    main()
