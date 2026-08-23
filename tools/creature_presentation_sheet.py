#!/usr/bin/env python3
"""CREATURE-PRESENTATION. Contact sheets from capture_creature_presentation.gd.

    python3 tools/creature_presentation_sheet.py shots/creature_presentation

Writes two sheets next to the frames:

  `_portraits.png` -- every species' portrait, labelled, for the face read.
  `_field_thumbs.png` -- every species' field frame at 30%, which is the size
    the creature actually occupies on the player's screen when they decide
    whether it is worth walking toward. A creature that vanishes into the
    ground here vanishes in the game; that is the whole test.

Also prints, per species, the measured hue/value distance between the creature
pixels and the grass behind them -- the numeric half of "must separate at 30%
thumbnail size", so a round can be judged as movement or not without arguing
about it.
"""
import colorsys
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

THUMB = 0.30
# The card's lit grass, measured from the field frames' own bottom strip.
GRASS_SAMPLE_ROWS = slice(-60, None)


def label(img, text):
    out = img.copy()
    d = ImageDraw.Draw(out)
    d.rectangle([0, 0, 160, 18], fill=(0, 0, 0))
    d.text((4, 4), text, fill=(255, 255, 255))
    return out


def sheet(images, cols, path):
    if not images:
        return
    w, h = images[0].size
    rows = (len(images) + cols - 1) // cols
    out = Image.new("RGB", (cols * w, rows * h), (16, 16, 16))
    for i, im in enumerate(images):
        out.paste(im, ((i % cols) * w, (i // cols) * h))
    out.save(path)
    print("wrote", path, out.size)


def separation(path):
    """Hue/value distance between the subject and the ground BEHIND IT.

    The reference is taken per row from an empty strip of the same frame, not
    from one global average: the subject overlaps both sky and grass, and a
    global reference made every creature look well separated because half its
    silhouette was being compared against the wrong background. Per row, the
    comparison is against exactly what that row would have shown with the
    creature absent.
    """
    a = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255.0
    h, w, _ = a.shape
    y0, y1 = int(h * 0.30), int(h * 0.85)
    x0, x1 = int(w * 0.40), int(w * 0.62)
    hues, vals, ground_vals = [], [], []
    total = 0
    for y in range(y0, y1):
        ref = np.median(a[y, int(w * 0.04):int(w * 0.18)], axis=0)
        rh, _rs, rv = colorsys.rgb_to_hsv(*ref)
        for x in range(x0, x1):
            total += 1
            px = a[y, x]
            if float(np.abs(px - ref).max()) < 0.06:
                continue  # background, not subject
            ph, _ps, pv = colorsys.rgb_to_hsv(*px)
            dh = abs(ph - rh)
            dh = min(dh, 1.0 - dh) * 360.0
            hues.append(dh)
            vals.append(abs(pv - rv))
            ground_vals.append(rv)
    if not hues:
        return 0.0, 0.0, 0.0, 0.0
    return (float(np.mean(ground_vals)), float(np.median(hues)),
            float(np.median(vals)), len(hues) / max(total, 1))


def main(folder):
    names = sorted({f.rsplit("_", 1)[0] for f in os.listdir(folder)
                    if f.endswith("_portrait.png")})
    portraits, thumbs = [], []
    print("%-12s grass_val  d_hue  d_val  subject_frac" % "species")
    for n in names:
        p = os.path.join(folder, n + "_portrait.png")
        f = os.path.join(folder, n + "_field.png")
        im = Image.open(p).convert("RGB")
        portraits.append(label(im.resize((im.width // 2, im.height // 2)), n))
        if os.path.exists(f):
            fi = Image.open(f).convert("RGB")
            thumbs.append(label(fi.resize((int(fi.width * THUMB), int(fi.height * THUMB))), n))
            gv, dh, dv, frac = separation(f)
            print("%-12s %7.2f %7.1f %6.2f %8.2f" % (n, gv, dh, dv, frac))
    sheet(portraits, 5, os.path.join(folder, "_portraits.png"))
    sheet(thumbs, 5, os.path.join(folder, "_field_thumbs.png"))


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "shots/creature_presentation")
