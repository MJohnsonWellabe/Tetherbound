"""Validate Phase 2 defect scores and write each biome's current top 20."""

from __future__ import annotations

import csv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "ralph/reports/VISUAL/phase2"
EFFORT = {"S": 1, "M": 2, "L": 3}
BIOMES = ("meadows", "tidewake", "cloudreach", "stormwood")


def main() -> None:
    with (ROOT / "catalog.csv").open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        fields = reader.fieldnames
        rows = list(reader)
    assert fields is not None
    for row in rows:
        scores = [int(row[key]) for key in ("severity", "exposure", "importance")]
        if not all(1 <= score <= 5 for score in scores):
            raise ValueError(f"Out-of-range score in {row['item_id']}")
        if int(row["impact"]) != scores[0] * scores[1] * scores[2]:
            raise ValueError(f"Incorrect impact in {row['item_id']}")
        if row["est_effort"] not in EFFORT:
            raise ValueError(f"Unknown effort in {row['item_id']}")
    ranked = sorted(rows, key=lambda row: (
        -int(row["impact"]),
        -int(row["impact"]) / EFFORT[row["est_effort"]],
        row["item_id"],
    ))
    for biome in BIOMES:
        selected = [row for row in ranked if biome in row["biome(s)"].split(";")][:20]
        target = ROOT / biome / "top20.csv"
        target.parent.mkdir(parents=True, exist_ok=True)
        with target.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields)
            writer.writeheader()
            writer.writerows(selected)
        print(f"{biome}: {len(selected)} ranked items")


if __name__ == "__main__":
    main()
