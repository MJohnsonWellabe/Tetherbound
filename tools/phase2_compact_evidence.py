"""Keep Phase 2's capture inventory as contact-sheet tiles, without raw JPGs.

Run once after captures are indexed. The source frame path remains in the CSV
for provenance, while frame_path becomes the retained page and tile_index its
zero-based position on that page. This intentionally removes full-resolution
images from the current checkout; Git history is unchanged.
"""

from __future__ import annotations

import argparse
import csv
import math
from collections import defaultdict
from pathlib import Path

from PIL import Image

from phase2_index_captures import render_sheet


ROOT = Path(__file__).resolve().parents[1]
REPORT = ROOT / "ralph/reports/VISUAL/phase2"
BIOMES = ("meadows", "tidewake", "cloudreach", "stormwood")
ADDED_COLUMNS = ("source_frame_path", "tile_index", "evidence_format")
FORMAT = "contact_sheet_tile_320x180"
PAGE_SIZE = 24


def read_manifest(biome: str) -> tuple[list[str], list[dict[str, str]]]:
    with (REPORT / biome / "manifest.csv").open(newline="", encoding="utf-8") as stream:
        reader = csv.DictReader(stream)
        assert reader.fieldnames is not None
        return list(reader.fieldnames), list(reader)


def verify() -> None:
    all_ids: set[str] = set()
    for biome in BIOMES:
        fields, rows = read_manifest(biome)
        assert all(column in fields for column in ADDED_COLUMNS)
        for row in rows:
            assert row["id"] not in all_ids, row["id"]
            all_ids.add(row["id"])
            assert row["biome"] == biome and row["evidence_format"] == FORMAT
            page = (ROOT / row["frame_path"]).resolve()
            assert page.is_relative_to((REPORT / biome).resolve()) and page.is_file(), page
            assert row["source_frame_path"] != row["frame_path"]
            assert not (ROOT / row["source_frame_path"]).exists(), row["source_frame_path"]
            tile = int(row["tile_index"])
            assert 0 <= tile < PAGE_SIZE, row["id"]
        for category in {row["category"] for row in rows}:
            members = sorted((row for row in rows if row["category"] == category), key=lambda row: row["id"])
            for index, row in enumerate(members):
                expected = REPORT / biome / f"contact_sheet_{category}_{index // PAGE_SIZE + 1:02d}.jpg"
                assert ROOT / row["frame_path"] == expected, row["id"]
                assert int(row["tile_index"]) == index % PAGE_SIZE, row["id"]
            assert len(list((REPORT / biome).glob(f"contact_sheet_{category}_??.jpg"))) == math.ceil(len(members) / PAGE_SIZE)
        print(f"{biome}: {len(rows)} indexed tiles verified")
    with (REPORT / "catalog.csv").open(newline="", encoding="utf-8") as stream:
        catalog = list(csv.DictReader(stream))
    for item in catalog:
        assert all(sighting in all_ids for sighting in item["sightings"].split(";")), item["item_id"]
    print(f"{len(all_ids)} captures and {len(catalog)} catalog items verified")


def compact() -> None:
    for biome in BIOMES:
        base = REPORT / biome
        fields, rows = read_manifest(biome)
        if "evidence_format" in fields:
            raise SystemExit(f"{biome} is already compact; use --verify")
        grouped: dict[str, list[dict[str, str]]] = defaultdict(list)
        raw_paths: list[Path] = []
        for row in rows:
            source = (ROOT / row["frame_path"]).resolve()
            assert source.is_relative_to(base.resolve()) and source.parent != base.resolve()
            assert source.suffix.lower() in (".jpg", ".png") and source.is_file(), source
            raw_paths.append(source)
            grouped[row["category"]].append(row)
        assert len(raw_paths) == len(set(raw_paths)) == len(rows)
        retained: set[Path] = set()
        for category, members in grouped.items():
            members.sort(key=lambda row: row["id"])
            for page_number, start in enumerate(range(0, len(members), PAGE_SIZE), 1):
                page_rows = members[start:start + PAGE_SIZE]
                target = base / f"contact_sheet_{category}_{page_number:02d}.jpg"
                render_sheet(ROOT, page_rows, target)
                with Image.open(target) as image:
                    image.verify()
                retained.add(target.resolve())
                for tile_index, row in enumerate(page_rows):
                    row["source_frame_path"] = row["frame_path"]
                    row["frame_path"] = target.relative_to(ROOT).as_posix()
                    row["tile_index"] = str(tile_index)
                    row["evidence_format"] = FORMAT
        target_csv = base / "manifest.csv"
        temp_csv = target_csv.with_suffix(".compact.tmp")
        with temp_csv.open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=fields + list(ADDED_COLUMNS))
            writer.writeheader()
            writer.writerows(rows)
        temp_csv.replace(target_csv)
        for source in raw_paths:
            source.unlink()
        for sheet in base.glob("contact_sheet_*.jpg"):
            if sheet.resolve() not in retained:
                sheet.unlink()
        print(f"{biome}: compacted {len(rows)} frames into {len(retained)} pages")
    verify()


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--verify", action="store_true")
    args = parser.parse_args()
    verify() if args.verify else compact()
