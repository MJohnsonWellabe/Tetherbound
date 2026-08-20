#!/usr/bin/env python3
"""Apply remaining integrated Gate A batches on the Claude delivery branch."""
from pathlib import Path
from gate_a_batch2 import apply as apply_batch2
from gate_a_batch3_beds import apply as apply_batch3
from gate_a_batch4_title import apply as apply_batch4
from gate_a_batch5_build import apply as apply_batch5
from gate_a_batch6_catch import apply as apply_batch6

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    changed = False
    changed |= apply_batch2(ROOT)
    changed |= apply_batch3(ROOT)
    changed |= apply_batch4(ROOT)
    changed |= apply_batch5(ROOT)
    changed |= apply_batch6(ROOT)
    print("Gate A active batches complete" + (" (changes applied)" if changed else " (already applied)"))


if __name__ == "__main__":
    main()
