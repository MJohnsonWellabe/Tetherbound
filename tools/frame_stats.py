#!/usr/bin/env python3
"""Measure survey frames the way the blind critic measures them.

    tools/frame_stats.py                 # survey + combat + references
    tools/frame_stats.py shots/*.png     # just these

A critic round is expensive and slow, and spending one to discover that a fix
did not land is waste. Everything here is a metric the critic itself quantified
in `archive/reports/docs-reviews-full/MA-02-*.md`, reimplemented so the same number can be checked
after every change.

This measures. It does not judge — the numbers say whether a change moved the
thing it aimed at, never whether the result is any good. That question stays
with the blind critic and with a human, and no threshold in this file is an
acceptance criterion.

The reference columns are the point of comparison. They are computed from the
same code as the build's, so a metric that flatters the build by construction
shows up immediately as a reference value that makes no sense.
"""

import sys
import glob
import os
import numpy as np
from PIL import Image

# Rec. 709 luma. The critic quoted "luminance", and matching its weighting
# matters more than picking the theoretically best one.
LUMA = np.array([0.2126, 0.7152, 0.0722])

# Hue bands in degrees, named the way the critic named them.
HUE_FAMILIES = [
    ("red", 345, 15), ("orange", 15, 40), ("yellow", 40, 65),
    ("chartreuse", 65, 90), ("green", 90, 150), ("cyan", 150, 195),
    ("blue", 195, 250), ("indigo", 250, 280), ("violet", 280, 315),
    ("magenta", 315, 345),
]

# A pixel has to carry some colour before its hue means anything.
CHROMA_FLOOR = 0.15
# "Non-green chroma" — the critic's wildflower metric — counts saturated
# pixels below the horizon outside the green/cyan band.
FLOWER_SAT_FLOOR = 0.25
GREEN_BAND = (65, 195)


def load(path):
    img = Image.open(path).convert("RGB")
    return np.asarray(img, dtype=np.float32) / 255.0


def to_hsv(rgb):
    mx = rgb.max(axis=2)
    mn = rgb.min(axis=2)
    delta = mx - mn
    hue = np.zeros_like(mx)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    nz = delta > 1e-6
    with np.errstate(invalid="ignore", divide="ignore"):
        hr = np.where(nz, ((g - b) / np.where(nz, delta, 1)) % 6, 0)
        hg = np.where(nz, ((b - r) / np.where(nz, delta, 1)) + 2, 0)
        hb = np.where(nz, ((r - g) / np.where(nz, delta, 1)) + 4, 0)
    hue = np.where(mx == r, hr, np.where(mx == g, hg, hb)) * 60.0
    hue = np.where(nz, hue % 360.0, 0.0)
    sat = np.where(mx > 1e-6, delta / np.where(mx > 1e-6, mx, 1), 0.0)
    return hue, sat, mx


def in_band(hue, lo, hi):
    if lo <= hi:
        return (hue >= lo) & (hue < hi)
    return (hue >= lo) | (hue < hi)      # wraps through 0


def sky_mask(rgb, hue, sat, val):
    """Sky is what you see looking up before anything solid interrupts.

    Classified per column from the top down rather than by colour alone: a pale
    hazy horizon and a pale hazy hillside are nearly the same colour, and only
    their position in the column separates them.
    """
    h, w, _ = rgb.shape
    skyish = (
        (in_band(hue, 170, 260) & (val > 0.35))          # blue through cyan
        | ((sat < 0.16) & (val > 0.55))                  # haze, overcast, glare
    )
    # A column stops being sky at its first non-sky pixel and never resumes, so
    # a pale rock face partway down the frame is not counted as sky.
    mask = np.logical_and.accumulate(skyish, axis=0)
    return mask


def horizon_row(mask):
    """Mean row at which the sky stops, as a fraction of frame height."""
    h = mask.shape[0]
    per_column = mask.sum(axis=0)
    return float(per_column.mean()) / h


def hue_families(hue, sat, val):
    chromatic = (sat > CHROMA_FLOOR) & (val > 0.12)
    total = int(chromatic.sum())
    if total == 0:
        return 0, []
    found = []
    for name, lo, hi in HUE_FAMILIES:
        share = float((in_band(hue, lo, hi) & chromatic).sum()) / total
        if share > 0.05:
            found.append((name, share))
    found.sort(key=lambda p: -p[1])
    return len(found), found


def non_green_chroma(hue, sat, sky):
    """Wildflowers, dirt, exposed rock — anything below the horizon that is not
    another green. The critic measured 0.000%-0.035% against a brief that says
    'wildflower meadows'."""
    below = ~sky
    if below.sum() == 0:
        return 0.0
    interesting = below & (sat > FLOWER_SAT_FLOOR) & ~in_band(hue, *GREEN_BAND)
    return 100.0 * float(interesting.sum()) / float(below.sum())


def seam(luma):
    """Largest single-row full-width luminance step.

    The critic found a 0.18 step across the entire 1280px width of
    `03-rise-overlook` at row 253 and called it a bug. Edges belong to objects;
    an edge that spans every column at one row is a rendering boundary.
    """
    rows = luma.mean(axis=1)
    steps = np.abs(np.diff(rows))
    if steps.size == 0:
        return 0.0, 0
    i = int(steps.argmax())
    return float(steps[i]), i + 1


def warm_impact(rgb, hue, sat, val):
    """Bright warm pixels — the critic's proxy for whether a blow reads as an
    event. It measured 10px in `combat/05` against 24,623 in `palworld-01`."""
    hot = (sat > 0.5) & (val > 0.7) & in_band(hue, 10, 65)
    return 100.0 * float(hot.sum()) / hot.size


def measure(path):
    rgb = load(path)
    hue, sat, val = to_hsv(rgb)
    luma = rgb @ LUMA
    sky = sky_mask(rgb, hue, sat, val)

    lo, hi = np.percentile(luma, [1, 99])
    families, named = hue_families(hue, sat, val)
    step, row = seam(luma)
    h = rgb.shape[0]
    near = luma[int(h * 0.85):, :].mean()

    return {
        "sky_pct": 100.0 * float(sky.sum()) / sky.size,
        "horizon": horizon_row(sky),
        "families": families,
        "family_names": ", ".join("%s %.0f%%" % (n, s * 100) for n, s in named[:4]),
        "chroma_pct": non_green_chroma(hue, sat, sky),
        "value_spread": float(hi - lo),
        "mean_sat": float(sat.mean()),
        "near_luma": float(near),
        "seam": step,
        "seam_row": row,
        "impact_pct": warm_impact(rgb, hue, sat, val),
    }


HEADER = ("%-34s %6s %6s %4s %7s %7s %6s %7s %8s %7s"
          % ("frame", "sky%", "horiz", "hue", "chrom%", "vspread",
             "sat", "nearL", "seam", "hit%"))


def row(path, s):
    return ("%-34s %6.1f %6.2f %4d %7.3f %7.2f %6.2f %7.3f %5.3f@%-3d %6.3f"
            % (os.path.basename(path), s["sky_pct"], s["horizon"], s["families"],
               s["chroma_pct"], s["value_spread"], s["mean_sat"], s["near_luma"],
               s["seam"], s["seam_row"], s["impact_pct"]))


def section(title, paths):
    paths = [p for p in paths if os.path.exists(p)]
    if not paths:
        return
    print("\n%s" % title)
    print("-" * len(HEADER))
    for p in sorted(paths):
        s = measure(p)
        print(row(p, s))
        if s["family_names"]:
            print("%-34s   %s" % ("", s["family_names"]))


def main():
    print(HEADER)
    if len(sys.argv) > 1:
        section("frames", sys.argv[1:])
        return
    section("exploration", glob.glob("shots/*.png"))
    section("combat", glob.glob("shots/combat/*.png"))
    section("REFERENCE — Palworld (the bar)", glob.glob("docs/reference/palworld-*.jpg"))
    section("REFERENCE — key art board", glob.glob("docs/reference/tetherbound-*.png"))
    print("""
Reading these:
  sky%     fraction of frame that is empty sky. References: Palworld 2-21%,
           key art 18%. MA-02 measured the build at 40-52%.
  horiz    mean height of the horizon as a fraction of frame. 0.50 is dead
           centre, which is the least interesting place for it.
  hue      hue families holding >5% of chromatic pixels. Key art 6,
           Palworld 3-5, MA-02 measured the build at 2-3.
  chrom%   saturated non-green pixels below the horizon. The wildflower
           metric. MA-02 measured 0.000-0.035%.
  vspread  1-99 percentile luminance range. Already passing as of MA-02.
  seam     largest single-row full-width luminance step, and its row. A real
           edge belongs to an object; one spanning every column is a bug.
           MA-02 found 0.18 at row 253 of 03-rise-overlook.
  hit%     bright warm pixels, the "does a blow read as an event" proxy.
           palworld-01 measures 10.7%; MA-02 measured combat/05 at 0.001%.

None of these is a pass mark. They say whether a change moved what it aimed
at. Whether the result looks good is the blind critic's call and the owner's.""")


if __name__ == "__main__":
    main()
