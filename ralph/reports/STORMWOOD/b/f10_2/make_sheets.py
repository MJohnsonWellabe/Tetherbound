#!/usr/bin/env python3
"""F10#2 footage post-process: downscale the raw 1280x720 production-camera
PNGs to 960x540 JPG (<150 KB) and build one labelled contact sheet per fight.

    python3 make_sheets.py <raw_png_dir> <out_frames_dir>
"""
import os
import sys
from PIL import Image, ImageDraw

IDS = ["hollows_alpha", "capacitor_alpha", "crown_guardian",
       "old_rodfolk_hall_guardian", "blackwater_elder", "glass_field_alpha"]


def jpg(src, dst):
    im = Image.open(src).convert("RGB").resize((960, 540), Image.LANCZOS)
    for q in (85, 78, 70, 60, 50):
        im.save(dst, "JPEG", quality=q, optimize=True)
        if os.path.getsize(dst) < 150_000:
            break
    return im


def main(raw, out):
    os.makedirs(out, exist_ok=True)
    for fid in IDS:
        names = sorted(n for n in os.listdir(raw) if n.startswith(fid + "-") and n.endswith(".png"))
        if not names:
            continue
        thumbs = []
        for n in names:
            dst = os.path.join(out, n[:-4] + ".jpg")
            im = jpg(os.path.join(raw, n), dst)
            thumbs.append((n[len(fid) + 1:-4], im.resize((320, 180), Image.LANCZOS)))
        cols = 6
        rows = (len(thumbs) + cols - 1) // cols
        sheet = Image.new("RGB", (cols * 320, rows * 200), (20, 20, 20))
        draw = ImageDraw.Draw(sheet)
        for i, (label, t) in enumerate(thumbs):
            x, y = (i % cols) * 320, (i // cols) * 200
            sheet.paste(t, (x, y))
            draw.text((x + 4, y + 182), label, fill=(240, 240, 240))
        path = os.path.join(out, "sheet-%s.jpg" % fid)
        for q in (80, 70, 60, 50):
            sheet.save(path, "JPEG", quality=q, optimize=True)
            if os.path.getsize(path) < 600_000:
                break
        print(fid, len(thumbs), "frames ->", path)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
