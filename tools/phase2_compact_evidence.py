"""Keep Phase 2's capture inventory as contact-sheet tiles, without raw JPGs.

Run once after captures are indexed. The source frame path remains in the CSV
for provenance, while frame_path becomes the retained page and tile_index its
zero-based position on that page. This intentionally removes full-resolution
images from the current checkout; Git history is unchanged.
"""

from __future__ import annotations

import argparse
import csv
import hashlib
import json
import math
import re
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


def compact_round(capture_manifest: Path, output: Path, commit: str, repro: str,
                  root: Path = ROOT) -> None:
    """Retain a new capture round without touching the original inventory.

    Raw input stays local for full-resolution judging. Only the fresh output
    directory (pages plus manifest.json) is intended for version control.
    """
    root, output = root.resolve(), output.resolve()
    if not output.is_relative_to(root) or output == root or output.exists():
        raise ValueError("output must be a new directory inside the repository")
    if re.fullmatch(r"[0-9a-fA-F]{40}", commit) is None or not repro.strip():
        raise ValueError("a full capture commit and nonempty reproduction command are required")
    source_bytes = capture_manifest.read_bytes()
    source = json.loads(source_bytes)
    frames = source.get("frames", [])
    if not isinstance(frames, list) or not frames:
        raise ValueError("capture manifest has no frames")
    rows, ids = [], set()
    for frame in frames:
        identity = frame.get("frame_id", frame.get("id", ""))
        raw = frame.get("file", frame.get("path", frame.get("frame_path", "")))
        if not isinstance(identity, str) or not identity or identity in ids or not raw:
            raise ValueError(f"missing or duplicate frame identity/path: {identity!r}")
        ids.add(identity)
        path = (root / str(raw).removeprefix("res://")).resolve()
        if not path.is_relative_to(root) or not path.is_file():
            raise ValueError(f"frame must exist inside the repository: {path}")
        with Image.open(path) as picture:
            picture.verify()
        rows.append({"id": identity, "frame_path": path.relative_to(root).as_posix(),
                     "capture": frame, "source_sha256": hashlib.sha256(path.read_bytes()).hexdigest()})
    output.mkdir(parents=True)
    retained = []
    for page, start in enumerate(range(0, len(rows), PAGE_SIZE), 1):
        target = output / f"contact_sheet_{page:02d}.jpg"
        members = rows[start:start + PAGE_SIZE]
        render_sheet(root, members, target)
        for index, row in enumerate(members):
            retained.append({**row, "source_frame_path": row["frame_path"],
                             "frame_path": target.relative_to(root).as_posix(),
                             "tile_index": index, "evidence_format": FORMAT})
    result = {"schema_version": 1, "evidence_format": FORMAT, "commit": commit,
              "repro": repro, "source_manifest_sha256": hashlib.sha256(source_bytes).hexdigest(),
              "capture_metadata": {key: value for key, value in source.items() if key != "frames"},
              "frames": retained}
    (output / "manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
    verify_round(output, root)


def verify_round(output: Path, root: Path = ROOT) -> None:
    """Check retained mapping after the local raw images are no longer present."""
    root, output = root.resolve(), output.resolve()
    if not output.is_relative_to(root):
        raise ValueError("round must be inside the repository")
    result = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
    assert result["evidence_format"] == FORMAT
    assert re.fullmatch(r"[0-9a-fA-F]{40}", result["commit"])
    assert result["repro"].strip()
    frames = result["frames"]
    assert frames and len({row["id"] for row in frames}) == len(frames)
    pages = math.ceil(len(frames) / PAGE_SIZE)
    for index, row in enumerate(frames):
        expected = output / f"contact_sheet_{index // PAGE_SIZE + 1:02d}.jpg"
        assert (root / row["frame_path"]).resolve() == expected
        assert row["tile_index"] == index % PAGE_SIZE
        assert row["evidence_format"] == FORMAT
        assert row["source_frame_path"] != row["frame_path"]
        assert re.fullmatch(r"[0-9a-f]{64}", row["source_sha256"])
    for page in range(1, pages + 1):
        count = min(PAGE_SIZE, len(frames) - (page - 1) * PAGE_SIZE)
        with Image.open(output / f"contact_sheet_{page:02d}.jpg") as picture:
            assert picture.size == (1280, math.ceil(count / 4) * 215)
            picture.verify()
    assert len(list(output.glob("contact_sheet_*.jpg"))) == pages
    print(f"{len(frames)} capture tiles verified in {pages} round pages")


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
    parser.add_argument("--capture-manifest", type=Path, help="compact one Phase 2c engine manifest")
    parser.add_argument("--output", type=Path, help="fresh per-item/round directory")
    parser.add_argument("--commit", help="full source commit used for this capture")
    parser.add_argument("--repro", help="exact command including seed and rendering driver")
    parser.add_argument("--verify-round", type=Path, help="verify a retained Phase 2c round")
    args = parser.parse_args()
    if args.capture_manifest:
        if args.verify or args.verify_round or not all([args.output, args.commit, args.repro]):
            parser.error("--capture-manifest requires --output, --commit and --repro, without verify modes")
        compact_round(args.capture_manifest, args.output, args.commit, args.repro)
    elif args.verify_round:
        if args.verify or args.output or args.commit or args.repro:
            parser.error("--verify-round cannot be combined with other modes")
        verify_round(args.verify_round)
    elif args.output or args.commit or args.repro:
        parser.error("--output, --commit and --repro require --capture-manifest")
    else:
        verify() if args.verify else compact()
