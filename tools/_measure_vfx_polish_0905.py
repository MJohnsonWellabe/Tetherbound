#!/usr/bin/env python3
"""N07-VFX-POLISH (0905 follow-up). The numbers behind the pictures.

Whole-frame pixel counts on the clean frames `tools/_capture_vfx_polish_0905.gd`
writes, so a before round and an after round of the same shot are compared by
count rather than by eye. Every band below was fixed BEFORE the first render.

    python3 tools/_measure_vfx_polish_0905.py shots/vfx_polish/before shots/vfx_polish/after

Bands (HSV, hue in degrees, sat/val 0..1):
  oxblood   H in [345, 25], S >= 0.45, V in [0.20, 0.90]
            the game's reserved Team Tether red family (#6b2a20 sits at H 7 S 0.70
            V 0.42, #7a2430 at H 351 S 0.71 V 0.48) widened to take in the dull
            rendered form of the old telegraph #ff5a3c (H 9 S 0.76)
  amber     H in [28, 58], S >= 0.45, V >= 0.55
            the HUD's own WARNING token family (#e8b74a, H 42), which the retuned
            telegraph ring joins
  wash      S <= 0.30, V >= 0.72
            the pale near-white sheet the old seal flash lays over the resolve
            close-up (its ring at #ffe9a8, its spikes and core near white)
  gold      R > 220, G > 180, B < 150 -- W09's own `gold` rule, unchanged, so
            the seal can be compared against W09's catch numbers

Telegraph rule: oxblood(05) - oxblood(07) is the ring's own reserved-band
footprint; after the retune it must fall to at most a tenth of the before value
and amber(05) - amber(07) must be positive.
Catch rule: wash(04a) as a share of the frame must fall by at least half and
gold(04a) must stay above zero -- smaller and still gold, not gone.
"""
import sys
from pathlib import Path

import numpy as np
from PIL import Image

SHOTS = ["05-telegraph", "06-telegraph-behind", "07-telegraph-control", "04a-catch-seal", "04-catch-success"]


def hsv(img):
    arr = np.asarray(img.convert("RGB")).astype(np.float32) / 255.0
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    mx = arr.max(axis=-1)
    mn = arr.min(axis=-1)
    delta = mx - mn
    s = np.where(mx > 0, delta / np.maximum(mx, 1e-6), 0.0)
    h = np.zeros_like(mx)
    nz = delta > 1e-6
    rc = np.where(nz, (mx - r) / np.maximum(delta, 1e-6), 0)
    gc = np.where(nz, (mx - g) / np.maximum(delta, 1e-6), 0)
    bc = np.where(nz, (mx - b) / np.maximum(delta, 1e-6), 0)
    h = np.where(mx == r, bc - gc, np.where(mx == g, 2.0 + rc - bc, 4.0 + gc - rc))
    h = (h * 60.0) % 360.0
    h = np.where(nz, h, 0.0)
    return h, s, mx, arr


def counts(path):
    img = Image.open(path)
    h, s, v, arr = hsv(img)
    r, g, b = (arr[..., i] * 255.0 for i in range(3))
    ox = ((h >= 345) | (h <= 25)) & (s >= 0.45) & (v >= 0.20) & (v <= 0.90)
    am = (h >= 28) & (h <= 58) & (s >= 0.45) & (v >= 0.55)
    wash = (s <= 0.30) & (v >= 0.72)
    gold = (r > 220) & (g > 180) & (b < 150)
    total = h.size
    return {
        "oxblood": int(ox.sum()),
        "amber": int(am.sum()),
        "wash": int(wash.sum()),
        "wash_share": float(wash.sum()) / total,
        "gold": int(gold.sum()),
        "total": total,
    }


def load_round(d):
    out = {}
    for shot in SHOTS:
        p = Path(d) / f"{shot}-clean.png"
        if p.exists():
            out[shot] = counts(p)
    return out


def main():
    rounds = [(Path(d).name or str(d), load_round(d)) for d in sys.argv[1:]]
    for name, data in rounds:
        print(f"== {name}")
        for shot, c in data.items():
            print(f"  {shot:22s} oxblood={c['oxblood']:6d} amber={c['amber']:6d} wash={c['wash']:7d} ({c['wash_share']*100:5.1f}%) gold={c['gold']:6d}")
        if "05-telegraph" in data and "07-telegraph-control" in data:
            a, b = data["05-telegraph"], data["07-telegraph-control"]
            print(f"  telegraph delta over control: oxblood {a['oxblood'] - b['oxblood']:+d}  amber {a['amber'] - b['amber']:+d}")
    if len(rounds) == 2:
        (n0, d0), (n1, d1) = rounds
        print(f"== {n0} -> {n1}")
        if all("05-telegraph" in d and "07-telegraph-control" in d for d in (d0, d1)):
            ox0 = d0["05-telegraph"]["oxblood"] - d0["07-telegraph-control"]["oxblood"]
            ox1 = d1["05-telegraph"]["oxblood"] - d1["07-telegraph-control"]["oxblood"]
            am1 = d1["05-telegraph"]["amber"] - d1["07-telegraph-control"]["amber"]
            verdict = "PASS" if (ox0 <= 0 or ox1 <= max(0, ox0 * 0.1)) and am1 > 0 else "FAIL"
            print(f"  telegraph: oxblood ring footprint {ox0:+d} -> {ox1:+d}; amber footprint after {am1:+d}  [{verdict}]")
        for shot in ("04a-catch-seal", "04-catch-success"):
            if shot in d0 and shot in d1:
                w0, w1 = d0[shot]["wash_share"], d1[shot]["wash_share"]
                g1 = d1[shot]["gold"]
                verdict = "PASS" if (w1 <= w0 * 0.5 and g1 > 0) else "FAIL"
                print(f"  {shot}: wash {w0*100:.1f}% -> {w1*100:.1f}%; gold after {g1}  [{verdict}]")


if __name__ == "__main__":
    main()
