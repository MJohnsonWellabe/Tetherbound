#!/usr/bin/env python3
"""Report every creature colourway's hue and value, and FLAG CLUSTERS.

This exists because the same defect was introduced three separate times by three
separate fixes, each of which was correct on its own and wrong for the roster.

  Round 3  "seven of seventeen shinies land on pink/coral -- 'rare = turn it
           pink' is a filter language, not a design language."  Fixed.
  Owner,   "you should repaint the otter to not be blue... just too many are that
  2026-08-15  similar shade of blue."  Fixed.
  Round 6  "five of the rares are the same raspberry dip" -- terrapup-shiny hue
           340, mudsnout-shiny 330, ripplet-shiny 340, reedwing-shiny 350,
           paddlenewt-shiny 0.

Two of those five were moved INTO that band by the round-5 pass, for good
per-species reasons: terrapup's rare had to stop impersonating burrowback, and
reedwing's had to stop being a third yellow bird. Both were right in isolation.
Neither was checked against the other sixteen species, so the fix for one
cluster rebuilt another.

That is the failure this tool prevents. A colourway is never a per-species
decision -- it is a position in a roster-wide palette, and the only way to see
that is to look at all of them at once, BEFORE baking. Run it after editing
shiny_colourways.json and before running the repaint.

    python3 tools/roster_palette_audit.py            # every variant
    python3 tools/roster_palette_audit.py --only shiny
"""
import colorsys
import glob
import json
import os
import sys

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CREATURES = os.path.join(ROOT, "assets", "creatures", "tetherbound")

## Hue bands, named. A band holding three or more entries of the same variant is
## reported as a cluster: at that point the tier has stopped saying "this
## species" and started saying "this is the recolour we do".
BANDS = [(0, 20, "red"), (20, 45, "orange"), (45, 70, "gold"), (70, 100, "yellow-green"),
         (100, 150, "green"), (150, 190, "teal"), (190, 260, "blue"),
         (260, 300, "violet"), (300, 340, "magenta"), (340, 360, "crimson")]
CLUSTER_AT = 3


def band_of(hue):
    for lo, hi, name in BANDS:
        if lo <= hue < hi:
            return name
    return "crimson"


def measure(path):
    a = np.asarray(Image.open(path).convert("RGB")).astype(float) / 255.0
    flat = a.reshape(-1, 3)
    flat = flat[flat.sum(axis=1) > 0.08]
    if len(flat) == 0:
        return None
    s = flat[:: max(1, len(flat) // 30000)]
    hsv = np.array([colorsys.rgb_to_hsv(*p) for p in s])
    chroma = hsv[hsv[:, 1] > 0.18]
    if len(chroma) < 50:
        return {"hue": None, "value": float(hsv[:, 2].mean()),
                "dark": float((hsv[:, 2] < 0.12).mean())}
    # Dominant hue by histogram, never a mean -- hue is circular and a linear
    # mean across the 0/360 wrap reported a crimson creature as cyan once.
    counts = np.bincount((chroma[:, 0] * 36).astype(int) % 36, minlength=36)
    return {"hue": float(counts.argmax() * 10 + 5), "value": float(hsv[:, 2].mean()),
            "dark": float((hsv[:, 2] < 0.12).mean())}


def main():
    only = None
    if "--only" in sys.argv:
        only = sys.argv[sys.argv.index("--only") + 1]
    spec = json.load(open(os.path.join(ROOT, "data", "creatures", "shiny_colourways.json")))
    species = [k for k in spec.get("species", {}) if not k.startswith("_")]

    rows = {}
    for variant in ("vivid", "shiny", "alpha"):
        if only and variant != only:
            continue
        rows[variant] = []
        for sp in sorted(species):
            found = [f for f in glob.glob(os.path.join(CREATURES, sp, "models", "*_base_color_%s.png" % variant))]
            if not found:
                continue
            m = measure(found[0])
            if m:
                rows[variant].append((sp, m))

    for variant, entries in rows.items():
        label = {"vivid": "ORDINARY", "shiny": "RARE", "alpha": "ALPHA"}[variant]
        print("=== %s (%d species) ===" % (label, len(entries)))
        buckets = {}
        for sp, m in entries:
            hue_s = "achromatic" if m["hue"] is None else "%3.0f %s" % (m["hue"], band_of(m["hue"]))
            warn = "  <-- CRUSHED, %.0f%% of surface below val 0.12" % (m["dark"] * 100) if m["dark"] > 0.25 else ""
            print("  %-12s hue %-18s value %.2f%s" % (sp, hue_s, m["value"], warn))
            if m["hue"] is not None:
                buckets.setdefault(band_of(m["hue"]), []).append(sp)
        clustered = {b: v for b, v in buckets.items() if len(v) >= CLUSTER_AT}
        if clustered:
            print("  CLUSTERS in this tier:")
            for b, v in sorted(clustered.items(), key=lambda kv: -len(kv[1])):
                print("    %-14s %d species: %s" % (b, len(v), ", ".join(v)))
        else:
            print("  no band holds %d or more species" % CLUSTER_AT)
        print()


if __name__ == "__main__":
    main()
