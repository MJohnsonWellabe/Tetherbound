"""
Put local contrast back into Rock030_Color.jpg (the hillside "rock" band
texture), in place, without moving its mean value or its hue.

Written for OF11 round 5.

WHY THIS AND NOT ANOTHER BRIGHTNESS/AO/TINT PASS. OF11 rebuilt the rises'
geometry from scratch -- warped ridged ribs, tilted bedding planes,
metre-scale crumble -- and four blind critique rounds confirmed the landform
itself now reads as sculpted ("real jagged peaks and crevices... it's not a
smooth dome in silhouette", round 3; "there is real form-shadow in the rock
folds, not flat-lit... the terrain does have shape", round 4). What the same
two rounds kept naming instead was the MATERIAL at close range: "the base
rock material itself is a fine, even, low-contrast speckle with no strata, no
cracks, no distinct rock chunks or slabs" (round 4, on `road-end-lookup`).

That is measurable, and it is measurably true. Rock030_Color.jpg's value
standard deviation is 0.058 -- the flattest of the four ground textures in
this project against Ground003's 0.101 -- and it is flat partly by our own
hand: `brighten_rock_texture.py` (EV4-hillside-seam-remainder-3) applies a
screen blend, `new = 1 - (1-old)*(1-0.18)`, which by construction raises the
darks more than the lights. Raising a floor IS reducing contrast. Every
other lever the five pre-OF11 rounds and OF11's own first four touched moves
the same way: brightening flattens, cutting `normal_depth` flattens, cutting
`ao_strength` flattens, desaturating flattens. Nobody has ever pushed the
other direction on this photograph. That is what this does.

Two transforms, both applied to LUMINANCE only and written back as a
per-pixel scale on all three channels, so hue is mathematically untouched
(scaling R, G and B by one common factor cannot rotate hue):

  1. Local contrast (unsharp mask at a large radius). This is the one that
     matters. It amplifies structure at the scale of the blur radius --
     veining, mottling, the boundaries between stone patches -- while leaving
     the overall tonality alone. At the shipped `uv_scale` of 0.46 (one tile
     every ~2.2m) a 24px radius on a 1024px tile is roughly 5cm of real
     surface, so what it amplifies is exactly the crack-and-patch detail the
     critic said was missing, not film grain.

  2. A gentle S-curve about the mean, to widen the global range that the
     screen blend compressed.

The mean value is then renormalised back to what it was before, so
`brighten_rock_texture.py`'s own finding -- that this photo's darks crush to
black under this scene's grazing sun, solved at mean value 0.436 -- is not
quietly undone. This round widens the distribution around that mean; it does
not move it.

    python3 tools/art_pipeline/contrast_rock_texture.py [--dry-run]

Rock030 is CC0 (docs/ASSET_LEDGER.md), so a derivative is permitted; the
ledger entry records this edit alongside the brightness one. Run once --
running it twice compounds, the same caveat the sibling scripts carry.
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

TEXTURE = os.path.join(
    os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
    "assets", "environment", "terrain", "Rock030_Color.jpg",
)

# Unsharp radius in pixels on the 1024px tile. See the module docstring for why
# this is large rather than the usual sharpening radius of 1-2px: the target is
# patch-and-vein structure at centimetres of real surface, not edge acutance.
LOCAL_RADIUS = 24.0
LOCAL_AMOUNT = 0.85

# S-curve strength about the mean. Small on purpose; the local pass does most
# of the work, and a strong global curve is how a photograph starts to look
# posterised.
SCURVE = 0.35

# Rec. 709, matching tools/frame_stats.py so the numbers here and there mean
# the same thing.
LUMA = np.array([0.2126, 0.7152, 0.0722])

JPEG_QUALITY = 95


def _luma(rgb: np.ndarray) -> np.ndarray:
    return rgb @ LUMA


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true",
                        help="measure and report, write nothing")
    args = parser.parse_args()

    if not os.path.exists(TEXTURE):
        print("missing %s" % TEXTURE, file=sys.stderr)
        return 1

    image = Image.open(TEXTURE).convert("RGB")
    rgb = np.asarray(image).astype(np.float64) / 255.0

    before = _luma(rgb)
    before_mean = float(before.mean())
    before_std = float(before.std())

    # 1. Local contrast, on luminance.
    luma_image = Image.fromarray((np.clip(before, 0.0, 1.0) * 255.0).astype(np.uint8), mode="L")
    blurred = np.asarray(luma_image.filter(ImageFilter.GaussianBlur(LOCAL_RADIUS))).astype(np.float64) / 255.0
    lifted = before + (before - blurred) * LOCAL_AMOUNT

    # 2. Gentle S-curve about the ORIGINAL mean, so the curve is symmetric
    #    around this photo's own tonality rather than around 0.5.
    centred = np.clip(lifted - before_mean, -1.0, 1.0)
    lifted = before_mean + centred + SCURVE * centred * (1.0 - np.abs(centred))

    # 3. Put the mean back exactly. Widening the distribution is the point;
    #    moving it would undo brighten_rock_texture.py's own solved value.
    lifted = np.clip(lifted, 0.0, 1.0)
    lifted = lifted * (before_mean / max(float(lifted.mean()), 1e-6))
    lifted = np.clip(lifted, 0.0, 1.0)

    # 4. Back to RGB as a per-pixel SCALE, identical on all three channels, so
    #    hue cannot move. Guard the near-black pixels against divide-by-zero.
    scale = lifted / np.maximum(before, 1e-4)
    out = np.clip(rgb * scale[..., None], 0.0, 1.0)

    after = _luma(out)
    hsv_before = np.asarray(image.convert("HSV")).astype(np.float64)
    hsv_after = np.asarray(
        Image.fromarray((out * 255.0).astype(np.uint8), mode="RGB").convert("HSV")
    ).astype(np.float64)

    print("Rock030_Color.jpg")
    print("  value mean  %.4f -> %.4f  (held on purpose)" % (before_mean, float(after.mean())))
    print("  value std   %.4f -> %.4f  (+%.0f%%, the point of this pass)" % (
        before_std, float(after.std()), 100.0 * (float(after.std()) / before_std - 1.0)))
    print("  p5..p95     %.3f..%.3f -> %.3f..%.3f" % (
        float(np.percentile(before, 5)), float(np.percentile(before, 95)),
        float(np.percentile(after, 5)), float(np.percentile(after, 95))))
    print("  hue mean    %.2f -> %.2f degrees" % (
        float(hsv_before[..., 0].mean()) * 360.0 / 255.0,
        float(hsv_after[..., 0].mean()) * 360.0 / 255.0))
    print("  saturation  %.4f -> %.4f" % (
        float(hsv_before[..., 1].mean()) / 255.0, float(hsv_after[..., 1].mean()) / 255.0))

    if args.dry_run:
        print("  (dry run, nothing written)")
        return 0

    Image.fromarray((out * 255.0).astype(np.uint8), mode="RGB").save(
        TEXTURE, quality=JPEG_QUALITY, subsampling=0)
    print("  written in place")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
