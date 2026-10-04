"""F26 Low frame scan and contact sheets (evidence helper, no acceptance verdict).

Flags placeholder-error colour (Godot's missing-material magenta), near-black
coverage and flat "void" sky bands in captured 1920x1080 PNGs, then builds
downscaled labelled contact sheets for a code-blind judge. Pixel flags are
prompts for review, not a substitute for the judge.

  python3 tools/f26_low_frame_scan.py --frames <dir> [--frames <dir>...] \
      --out <evidence dir> --sheet-name <prefix>
"""
from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw

MAGENTA_FLAG_FRACTION = 0.001  # 0.1% of the frame is ~2000 px at 1080p.
BLACK_FLAG_FRACTION = 0.25
TILE = (480, 270)
COLUMNS = 4


def scan(path: Path) -> dict:
    rgb = np.asarray(Image.open(path).convert("RGB")).astype(np.int16)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    magenta = (r > 200) & (b > 200) & (g < 70)
    black = (r < 8) & (g < 8) & (b < 8)
    top = rgb[: rgb.shape[0] // 4]
    top_std = float(top.reshape(-1, 3).std(axis=0).mean())
    top_mean = [round(float(v), 1) for v in top.reshape(-1, 3).mean(axis=0)]
    row = {"file": path.name, "size": [rgb.shape[1], rgb.shape[0]],
           "magenta_fraction": round(float(magenta.mean()), 6),
           "near_black_fraction": round(float(black.mean()), 4),
           "top_quarter_mean_rgb": top_mean, "top_quarter_std": round(top_std, 2),
           "mean_luma": round(float((0.2126 * r + 0.7152 * g + 0.0722 * b).mean()), 1)}
    flags = []
    if row["magenta_fraction"] >= MAGENTA_FLAG_FRACTION:
        flags.append("magenta_placeholder_colour")
    if row["near_black_fraction"] >= BLACK_FLAG_FRACTION:
        flags.append("large_near_black_area")
    if top_std < 1.5:
        flags.append("flat_top_band_possible_void_sky")
    row["flags"] = flags
    return row


def sheet(paths: list[Path], out: Path) -> None:
    rows = (len(paths) + COLUMNS - 1) // COLUMNS
    canvas = Image.new("RGB", (TILE[0] * COLUMNS, (TILE[1] + 18) * rows), (20, 20, 20))
    draw = ImageDraw.Draw(canvas)
    for index, path in enumerate(paths):
        x, y = (index % COLUMNS) * TILE[0], (index // COLUMNS) * (TILE[1] + 18)
        canvas.paste(Image.open(path).convert("RGB").resize(TILE, Image.LANCZOS), (x, y + 18))
        draw.text((x + 4, y + 3), f"[{index:02d}] {path.stem}"[:76], fill=(235, 235, 235))
    canvas.save(out, quality=82)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--frames", type=Path, action="append", required=True)
    parser.add_argument("--out", type=Path, required=True)
    parser.add_argument("--sheet-name", required=True)
    parser.add_argument("--per-sheet", type=int, default=16)
    args = parser.parse_args()
    paths = sorted(p for d in args.frames for p in d.glob("*.png"))
    if not paths:
        parser.error("no PNG frames found")
    args.out.mkdir(parents=True, exist_ok=True)
    results = [scan(p) | {"dir": p.parent.name} for p in paths]
    sheets = []
    for start in range(0, len(paths), args.per_sheet):
        name = f"{args.sheet_name}-{start // args.per_sheet + 1:02d}.jpg"
        sheet(paths[start:start + args.per_sheet], args.out / name)
        sheets.append({"sheet": name, "frames": [p.stem for p in paths[start:start + args.per_sheet]]})
    report = {"frame_count": len(results), "flagged": [r for r in results if r["flags"]],
              "thresholds": {"magenta_fraction": MAGENTA_FLAG_FRACTION,
                             "near_black_fraction": BLACK_FLAG_FRACTION, "top_quarter_std": 1.5},
              "sheets": sheets, "frames": results}
    (args.out / f"{args.sheet_name}-scan.json").write_text(json.dumps(report, indent=1) + "\n")
    print(f"{len(results)} frames, {len(report['flagged'])} flagged, {len(sheets)} sheets")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
