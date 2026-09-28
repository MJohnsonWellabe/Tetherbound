"""Summarize manifest coverage without treating a frame as proof of visual quality."""

from __future__ import annotations

import csv
import json
from collections import Counter
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1] / "ralph/reports/VISUAL/phase2"
BIOMES = ("meadows", "tidewake", "cloudreach", "stormwood")
SYSTEM_STATES = (
    "flying", "riding", "swimming", "catching", "fights", "camp", "bed",
    "building", "crafting",
)


def main() -> None:
    output: dict[str, object] = {"biomes": {}, "notes": [
        "Each indexed capture is retained as a 320x180 contact-sheet tile, not a full-resolution image.",
        "Counts confirm indexed previews, not successful framing or gameplay access.",
        "Open visual and checklist gaps are tracked in the catalog notes and validation reports.",
    ]}
    for biome in BIOMES:
        with (ROOT / biome / "manifest.csv").open(newline="", encoding="utf-8") as stream:
            rows = list(csv.DictReader(stream))
        missing_files = [row["id"] for row in rows if not (ROOT.parents[3] / row["frame_path"]).is_file()]
        bad_tiles = [row["id"] for row in rows if row.get("evidence_format") != "contact_sheet_tile_320x180"
                     or not row.get("tile_index", "").isdigit() or not 0 <= int(row["tile_index"]) < 24]
        retained_raw = [row["id"] for row in rows if (ROOT.parents[3] / row["source_frame_path"]).exists()]
        sheets = {row["frame_path"] for row in rows}
        bad_commits = [row["id"] for row in rows if len(row["commit"]) != 40]
        missing_repro = [row["id"] for row in rows if not row["repro"] or not row["render_path"]]
        category_counts = Counter(row["category"] for row in rows)
        times = Counter(row["time_of_day"] for row in rows)
        systems = Counter(row["subject"] for row in rows if row["category"] == "systems")
        ui_ids = sorted(row["id"] for row in rows if row["category"] == "ui")
        dialogue = sum(row["id"].endswith("__dialogue") for row in rows)
        defeated = sum("__defeated" in row["id"] for row in rows)
        indexed = {row["id"] for row in rows}
        planned: dict[str, set[str]] = {}
        for source in (ROOT / biome).glob("*/engine_manifest_*.json"):
            data = json.loads(source.read_text(encoding="utf-8"))
            ids = data.get("planned_frame_ids", [])
            if not ids:
                continue
            category = source.parent.name
            planned.setdefault(category, set()).update(
                "tidewake__" + str(frame_id)[len("water__") :]
                if str(frame_id).startswith("water__") else str(frame_id)
                for frame_id in ids
            )
        for category, ids in planned.items():
            suite = f"{biome}__system__build_suite"
            if category == "systems" and suite in ids and all(
                f"{biome}__system__{state}" in indexed
                for state in ("camp", "bed", "building", "crafting")
            ):
                ids.remove(suite)
        missing_planned = {
            category: sorted(ids - indexed)
            for category, ids in planned.items() if ids - indexed
        }
        output["biomes"][biome] = {
            "frames": len(rows), "categories": dict(sorted(category_counts.items())),
            "times": dict(sorted(times.items())),
            "systems": dict(sorted(systems.items())),
            "expected_systems_without_indexed_frames": [state for state in SYSTEM_STATES if not systems[state]],
            "dialogue_frames": dialogue, "defeated_frames": defeated,
            "ui_ids": ui_ids, "missing_files": missing_files,
            "bad_tiles": bad_tiles, "retained_raw_frames": retained_raw,
            "contact_sheets": len(sheets),
            "missing_planned_frames": missing_planned,
            "bad_commits": bad_commits, "missing_repro_or_render_path": missing_repro,
        }
    (ROOT / "coverage_audit.json").write_text(json.dumps(output, indent=2) + "\n", encoding="utf-8")
    for biome, report in output["biomes"].items():
        print(biome, report["frames"], "frames;", report["dialogue_frames"],
              "dialogue;", report["defeated_frames"], "defeated;",
              len(report["missing_files"]), "missing files")


if __name__ == "__main__":
    main()
