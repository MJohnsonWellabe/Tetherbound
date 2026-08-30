#!/usr/bin/env python3
"""T1-CAST. Bring the seven generated Team Tether bodies into the game's own colour language.

    python3 tools/regrade_tether_textures.py --check     # measure, write nothing
    python3 tools/regrade_tether_textures.py             # regrade in place

WHY. JUDGE-5 (D2) read the Warden's courtyard figure blind and called it "from a
different game" -- "hair as a solid magenta mass" in "a world of painted stylised
realism". T1-HALL-3 answered that by deleting the body from the courtyard, which
fixed the frame and stranded the asset. The owner's direction is the opposite:
use the bodies that were generated. So the defect has to be fixed where it
actually lives, which is the atlas.

MEASURED, not asserted. Over saturated pixels (s > 0.30, v > 0.10) of each
character atlas, the share whose hue falls in the purple/magenta band 260-340
degrees:

    trainer            0.0%      grunt (production rig)   0.1%
    villager_male      0.0%      grunt_a                  2.7%
    grandpa            0.0%      grunt_c                  4.7%
                                 captain_b               19.6%
                                 captain_a               20.9%
                                 officer_a               24.3%
                                 grunt_b                 24.5%
                                 officer_b               34.8%

Every rig the project shipped by hand is at zero. Every rig the generator made
carries a purple the Meadows palette does not contain. `data/config/palette.json`
reserves `tether_oxblood` (#332228) as the faction's own colour and says so in
its `_reserved` note -- "it appears only on Team Tether banners, equipment and
uniforms, never on friendly or neutral elements. A reserved colour is what lets
a player read threat at distance without a marker." A faction whose uniforms
render magenta is not spending that reservation; JUDGE-5 said the swap "cost the
Team Tether colour identity", and this is that cost in numbers.

WHAT IT DOES. Rotates only the purple/magenta band toward the hue the hand-built
grunt rig already sits at (median 354.7 degrees -- the target is measured off the
faction's own shipped body, not picked), pulls the worst of the chroma down so
dyed cloth reads as cloth rather than as a neon, and leaves everything else --
skin, leather, metal, cream, the teal that `palette.json` reserves separately for
live Tether machinery -- untouched. The rotation is weighted by how far into the
band a pixel sits and by its own saturation, so near-neutral pixels do not step
and no banding is introduced at the edges of the selection.

NO MESHY SPEND. This edits committed PNGs. No generation, no new mesh, no
re-rig: `CLAUDE.md` names materials and textures as the sanctioned way to
differentiate an installed body, and this is the same lever `npc_ranks.json`
already used when it moved the faction colour "into the texture".

Originals are copied to `<name>_lod0_texture_0.orig.png` on the first run and
never overwritten after, so a second run regrades from the ORIGINAL rather than
compounding a rotation on an already-rotated image.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np
from PIL import Image

Image.MAX_IMAGE_PIXELS = None

REPO = pathlib.Path(__file__).resolve().parent.parent

# The seven generated Team Tether bodies. `grunt` (the hand-built production rig)
# is deliberately NOT in this list -- it is the reference, not a subject.
SUBJECTS = [
    "grunt_a", "grunt_b", "grunt_c",
    "officer_a", "officer_b",
    "captain_a", "captain_b",
]

# The offending hue band, in degrees. Purple through magenta.
BAND_LO, BAND_HI = 258.0, 342.0
# Where it goes: the production grunt rig's own measured median saturated hue.
TARGET_HUE = 354.7
# Chroma ceiling for rotated pixels. The band's own saturation runs well past
# this on the accents; dyed wool does not.
SAT_CEILING = 0.46
# Below this saturation a pixel is effectively neutral and is left alone --
# rotating it would only introduce a tint where the painter put none. Round 1
# used 0.12 with the ramp reaching full weight at 0.30, and the render showed
# what that missed: the officers' and captains' chest chevrons and coat panels
# are PALE lilac, high value and low chroma, so they sat near the bottom of that
# ramp and barely rotated while the saturated uniform field moved fully. The
# floor is the point where a pixel has no hue worth preserving, which is lower
# than the point where a hue is vivid.
# ROUND 3. 0.06/0.20 still missed the two things a render kept showing: the
# officers' and captains' pale lilac chest chevrons and coat panels, and the
# mint-green HIGHLIGHT SPECKLES scattered through Pell's hair once its brown
# base had rotated correctly. Both are the same pixel class -- high value, low
# chroma -- and both sat low on the ramp, so they rotated a fraction of the way
# and parked at an intermediate hue, which is not an improvement over the
# original, just a different wrong colour. A pale pixel with a real hue should
# rotate FULLY: pale lilac and pale rose differ in nothing but hue, and a pixel
# with no hue at all has `d < 1e-6` and is already excluded by rgb_to_hsv's own
# guard. The ramp now exists only to keep quantisation noise near true grey out
# of the selection, which is all it was ever needed for.
SAT_FLOOR = 0.02
SAT_RAMP = 0.06


def rgb_to_hsv(a: np.ndarray) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
    r, g, b = a[..., 0], a[..., 1], a[..., 2]
    mx = a.max(-1)
    mn = a.min(-1)
    d = mx - mn
    h = np.zeros_like(mx)
    m = d > 1e-6
    i = (mx == r) & m
    h[i] = ((g - b)[i] / d[i]) % 6
    i = (mx == g) & m
    h[i] = ((b - r)[i] / d[i]) + 2
    i = (mx == b) & m
    h[i] = ((r - g)[i] / d[i]) + 4
    h *= 60.0
    s = np.where(mx > 1e-6, d / np.maximum(mx, 1e-6), 0.0)
    return h, s, mx


def hsv_to_rgb(h: np.ndarray, s: np.ndarray, v: np.ndarray) -> np.ndarray:
    h = np.mod(h, 360.0) / 60.0
    i = np.floor(h).astype(np.int32)
    f = h - i
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    i = i % 6
    out = np.zeros(h.shape + (3,), dtype=np.float32)
    for idx, (rr, gg, bb) in enumerate([(v, t, p), (q, v, p), (p, v, t),
                                        (p, q, v), (t, p, v), (v, p, q)]):
        m = i == idx
        out[m] = np.stack([rr[m], gg[m], bb[m]], axis=-1)
    return out


def purple_share(a: np.ndarray) -> float:
    """Share of a texture's saturated pixels sitting in the purple/magenta band.

    Same measure quoted in this file's header, so a --check run before and after
    is directly comparable to the table above.
    """
    h, s, v = rgb_to_hsv(a)
    sel = (s > 0.30) & (v > 0.10)
    if not sel.any():
        return 0.0
    hh = h[sel]
    return float(((hh >= 260) & (hh <= 340)).mean())


def regrade(a: np.ndarray) -> np.ndarray:
    h, s, v = rgb_to_hsv(a)

    # A PLATEAU with soft shoulders, not a peak. The whole band has to move --
    # a triangular falloff from the band's centre was tried first and left
    # grunt_b at 23.7% from 24.5%, because its purple sits out near the band
    # edges where a triangle has almost no weight left. Full rotation across
    # the interior, a SHOULDER-wide fade at each end so nothing steps.
    shoulder = 14.0
    depth = np.clip(
        np.minimum(h - (BAND_LO - shoulder), (BAND_HI + shoulder) - h) / shoulder,
        0.0, 1.0)
    # Smoothstep, so there is no visible seam at the ends of the fade.
    depth = depth * depth * (3.0 - 2.0 * depth)
    # A near-neutral pixel has no meaningful hue to rotate.
    weight = depth * np.clip((s - SAT_FLOOR) / (SAT_RAMP - SAT_FLOOR), 0.0, 1.0)

    # Rotate along the short way round the wheel toward the target.
    delta = np.mod(TARGET_HUE - h + 180.0, 360.0) - 180.0
    h_out = h + delta * weight

    # Pull the chroma of the rotated pixels down to something a dyed cloth
    # reaches, in proportion to how much they were rotated.
    s_out = np.where(s > SAT_CEILING, s + (SAT_CEILING - s) * weight, s)

    # SECOND PASS: the cyan/blue hair. `grunt_c` (Pell, the Warrens watch) came
    # out of the generator with bright cyan hair, which is wrong twice over.
    # It is not a hair colour anyone else in the Meadows has, and
    # `data/config/palette.json` RESERVES teal -- "it appears only where Team
    # Tether's machinery is live -- pylon crystals, conduits, rift energy" -- so
    # a teal-headed grunt spends a colour that is supposed to mean one specific
    # thing at distance. Only `grunt_c` carries any (1.9% of its saturated
    # pixels; every other subject measures 0.0%), so this pass is effectively
    # about one head, and it is scoped to the Tether subjects, which is why it
    # cannot touch the trainer's own legitimately teal jacket (6.5%).
    #
    # Hair is not rotated onto the uniform hue -- a grunt whose hair is the
    # exact colour of their coat reads as a paint error. It goes to a desaturated
    # dark brown, the plainest thing that is unmistakably hair.
    h2, s2, v2 = rgb_to_hsv(np.clip(hsv_to_rgb(h_out, s_out, v), 0.0, 1.0))
    # Band widened from [158,214] after round 1: at 158 the rotation toward
    # brown stalled partway and left Pell's hair GREEN rather than cyan, which
    # is not an improvement, just a different wrong colour. The band now covers
    # everything from green-cyan through blue so a partial rotation cannot park
    # inside it.
    cyan = np.clip(np.minimum(h2 - 132.0, 232.0 - h2) / 14.0, 0.0, 1.0)
    cyan = cyan * cyan * (3.0 - 2.0 * cyan)
    cyan = cyan * np.clip((s2 - SAT_FLOOR) / (SAT_RAMP - SAT_FLOOR), 0.0, 1.0)
    h2 = h2 + (np.mod(26.0 - h2 + 180.0, 360.0) - 180.0) * cyan
    s2 = s2 + (0.34 - s2) * cyan
    # Cyan hair is also painted LIGHT; dark hair is what the rest of the cast has.
    v2 = v2 * (1.0 - 0.42 * cyan)

    return np.clip(hsv_to_rgb(h2, s2, v2), 0.0, 1.0)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true",
                    help="measure and print; write nothing")
    args = ap.parse_args()

    print(f"{'rig':12} {'purple% before':>15} {'purple% after':>14}")
    changed = 0
    for name in SUBJECTS:
        d = REPO / "assets" / "characters" / name
        live = d / f"{name}_lod0_texture_0.png"
        orig = d / f"{name}_lod0_texture_0.orig.png"
        if not live.exists():
            print(f"{name:12}  MISSING {live}")
            continue
        # Always regrade from the original, so runs do not compound.
        source = orig if orig.exists() else live
        im = Image.open(source)
        if orig.exists() is False:
            # No local backup (a fresh clone -- `*.orig.png` is deliberately
            # not committed, git history is the real backup). Refuse to
            # regrade an atlas that has already been regraded, which is what
            # compounding would look like: a second rotation pushes the band
            # past oxblood and out the warm side.
            live_share = purple_share(
                np.asarray(im.convert("RGB")).astype(np.float32) / 255.0)
            if live_share < 0.01:
                print(f"{name:12}  already regraded ({live_share * 100:.1f}%), skipped")
                continue
        mode = im.mode
        arr = np.asarray(im.convert("RGB")).astype(np.float32) / 255.0
        before = purple_share(arr)
        out = regrade(arr)
        after = purple_share(out)
        print(f"{name:12} {before * 100:14.1f}% {after * 100:13.1f}%")
        if args.check:
            continue
        if not orig.exists():
            im.save(orig)
        result = Image.fromarray((out * 255.0 + 0.5).astype(np.uint8), "RGB")
        if mode == "RGBA":
            result = result.convert("RGBA")
            result.putalpha(im.getchannel("A"))
        result.save(live)
        changed += 1
    if not args.check:
        print(f"\nregraded {changed} texture(s); originals kept as *.orig.png")
        print("run `godot --headless --path . --import` before capturing")
    return 0


if __name__ == "__main__":
    sys.exit(main())
