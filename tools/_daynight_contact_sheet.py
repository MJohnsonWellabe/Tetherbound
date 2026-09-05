#!/usr/bin/env python3
"""N13-NIGHT-RESUME. One contact sheet from `probe_daynight_contrast.gd`'s frames.

    python3 tools/_daynight_contact_sheet.py OUT.png DIR [DIR2] [--labels A,B]

One row per directory (e.g. before / after), one column per hour, columns
ordered by hour and labelled with nothing but the hour, so a judge sees the same
camera across a day and can say whether any of it reads as night without being
told which row is which or what changed.
"""
import os
import re
import sys

from PIL import Image, ImageDraw

CELL_W = 320


def frames(directory):
    found = []
    for name in sorted(os.listdir(directory)):
        match = re.fullmatch(r"hour_(\d+\.\d)\.png", name)
        if match:
            found.append((float(match.group(1)), os.path.join(directory, name)))
    # Shot order is the day's own order (8, 12, 18, 20, 22, 0, 3), which reads
    # as a day rather than as a sort, so keep it and only wrap past midnight.
    found.sort(key=lambda item: item[0] if item[0] >= 8.0 else item[0] + 24.0)
    return found


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    labels = ""
    for a in sys.argv[1:]:
        if a.startswith("--labels="):
            labels = a.split("=", 1)[1]
    out, dirs = args[0], args[1:]
    label_list = labels.split(",") if labels else [""] * len(dirs)

    rows = [frames(d) for d in dirs]
    if not rows or not rows[0]:
        print("no hour_*.png frames found", file=sys.stderr)
        return 1
    sample = Image.open(rows[0][0][1])
    cell_h = int(sample.height * CELL_W / sample.width)
    pad, header, gutter = 6, 22, 64

    cols = max(len(r) for r in rows)
    width = gutter + cols * (CELL_W + pad) + pad
    height = header + len(rows) * (cell_h + pad + header) + pad
    sheet = Image.new("RGB", (width, height), (24, 24, 26))
    draw = ImageDraw.Draw(sheet)

    for ri, row in enumerate(rows):
        y = header + ri * (cell_h + pad + header)
        if label_list[ri]:
            draw.text((6, y + cell_h // 2), label_list[ri], fill=(220, 220, 220))
        for ci, (hour, path) in enumerate(row):
            img = Image.open(path).convert("RGB").resize((CELL_W, cell_h))
            x = gutter + ci * (CELL_W + pad)
            sheet.paste(img, (x, y))
            draw.text((x + 4, y + cell_h + 4), "%04.1f" % hour, fill=(200, 200, 200))
    sheet.save(out)
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
