"""BAND-SPLIT: the Python side of the per-band content merge.

`scripts/data/band_content.gd` is the authority — this is the same rule for the
offline probes under `tools/`, which read the content configs directly and would
otherwise silently see an empty array and print a confidently wrong number. A
pacing probe that reports "the critical path pays 0 XP" because the file layout
changed under it is worse than one that crashes.

Keep the two in step: same band order, same sort by `order`.
"""

import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

BANDS = [
    "band1_lower_meadows",
    "band2_stone_and_root",
    "band3_the_river_lock",
    "band4_upper_meadows_ironwood",
    "band5_stronghold_approach",
]


def load_config(rel, array_key):
    """Head config + its per-band files, merged into one dictionary."""
    with open(os.path.join(ROOT, rel)) as fh:
        head = json.load(fh)

    name = os.path.basename(rel)
    rows = []
    for band_index, band in enumerate(BANDS):
        path = os.path.join(ROOT, "data/config/bands", band, name)
        if not os.path.exists(path):
            continue
        with open(path) as fh:
            entries = json.load(fh).get(array_key, [])
        for file_index, entry in enumerate(entries):
            rows.append((entry.get("order", 10 ** 6 + band_index * 10 ** 4 + file_index),
                         band_index, file_index, entry))

    rows.sort(key=lambda r: r[:3])
    head[array_key] = [r[3] for r in rows]
    return head
