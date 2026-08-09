"""Grade a creature's baked textures toward its concept sheet's palette.

    # the pipeline path: a GLB in, a graded GLB out
    blender --background --python tools/art_pipeline/blender/grade.py \
            -- --species terrapup <animated.glb> --out <graded.glb>

    # the repair path: an already-installed creature's loose maps, in place.
    # No Blender: this half is plain numpy + Pillow.
    python3 tools/art_pipeline/blender/grade.py \
            --species ripplet --textures assets/pals/tetherbound/ripplet/models

Replaces `grade_terrapup.py`, `grade_ripplet.py` and `grade_galewisp.py`. They
were three copies of one algorithm with three sets of constants, and the copies
had drifted: only Terrapup's guarded its eyes, only Terrapup's classified
textures by what they feed rather than by colour space, and the shared parts
that were wrong were wrong in all three. Everything species-specific now lives
in SPECIES below; everything else is written once.

WHAT THE THREE OLD SCRIPTS GOT WRONG, and what this does instead:

  1. EYES. Terrapup's eye guard is a hue test — "teal and saturated is the
     iris, leave it alone" — and it works because nothing else on a brown
     badger is teal. Copied to a turquoise otter and a blue-grey fox-bird it
     is worse than useless: on Ripplet the body IS the eye's hue, so the guard
     either fires everywhere or (as shipped) was left out, and 50-56% of the
     texture — eyes included — got blended toward one flat teal. The iris ring
     and the catchlight are the two smallest marks on the creature and the
     first casualties of any averaging operation. A blind reviewer's words for
     the result: "a black almond with a smeared crescent".

     So the guard is generalised, not merely copied: a species declares an eye
     guard as a set of SELECTORS, and a selector may be a UV rectangle or a
     hue/saturation band. Terrapup keeps the hue band that works and gains
     rectangles; Ripplet and Galewisp get rectangles, because rectangles are
     the only thing that can separate an eye from a body of the same colour.

     Declaring no guard at all is an error, not a default — see require_guard().

  2. NO ALBEDO CEILING. Ungraded, 44.5% of Ripplet's albedo and 38.2% of
     Galewisp's sits above value 0.80, and a fifth of each is above 0.90. An
     albedo that bright has no shading headroom: under the game's key light it
     renders at 1.0 and the creature's dominant read becomes WHITE, which is
     exactly the finding both gate critiques opened with. Fixed with a soft
     knee (see ceiling()) rather than a hard clamp, because a hard clamp is
     the same mistake as (3).

  3. ROUGHNESS_FLOOR FLATTENED THE MAP. `G = max(G, 0.78)` sounds like a floor.
     It is one only if some of the map is above the floor, and none of it was:
     Terrapup's roughness arrived spanning 0.09-0.765, and every one of its
     173 distinct values became the single value 0.78. Shipped Terrapup,
     Ripplet and Galewisp all carry a roughness map with exactly ONE distinct
     value in it, which is a constant wearing a 4 MB texture's clothes. The
     replacement rescales the map's own range into a matte band, so the
     surface stays matte AND fur still differs from stone. See roughness().

  4. EMISSIVE WAS GRADED AS ALBEDO, AND EVERY MODEL GLOWS. The old scripts
     branch on colour space: sRGB means "base colour, grade it". An emissive
     map is sRGB too. Ripplet's emissive map covers 38% of the creature at up
     to 0.93, its material carries emissiveFactor [1,1,1], and the grade
     dutifully recoloured the glow to match the body. Nothing in the Meadows
     is supposed to emit light. Emissive is now identified and zeroed unless a
     species explicitly declares `"emissive": "glow"`, and no species does.

Textures are classified by ROLE, and role is decided by what an image feeds
(GLB path) or by the pipeline's own filename suffix (texture path) — never by
colour space, which cannot tell base colour from emissive, and never by
"Non-Color means roughness", which is also true of the normal map and once got
its Z channel zeroed, turning surface normals into noise.
"""

from __future__ import annotations

import argparse
import pathlib
import sys

import numpy as np

## Reference resolution for every UV rectangle in SPECIES below. The rects were
## read off 2048-square albedo maps; they are rescaled to whatever the image
## actually is, so a 4K retexture does not silently protect a quarter of a face.
RECT_REFERENCE = 2048

## How far outside a rect the guard fades to nothing, in reference pixels. A
## hard-edged guard leaves a visible rectangle of ungraded body around the eye
## — the grade lands on one side of a straight line and not the other, and at
## 2048 across a 1.6 m creature that line is about 1.5 mm of skin. 24 px of
## falloff hides it without letting the grade reach the sclera.
GUARD_FEATHER = 24

## Albedo soft knee. Below KNEE nothing moves; above it, values compress
## asymptotically toward CEILING. 0.82 is the usual game-albedo cap — real
## dielectrics rarely reflect more than that diffusely, and anything above it
## is a texture claiming to be brighter than paper.
ALBEDO_KNEE = 0.62
ALBEDO_CEILING = 0.82

## Where a rescaled roughness map is allowed to land. Centred so a typical
## map's median comes out near 0.78, which is the value the Terrapup gate
## review passed as "reads as fur under the game sun" — the point is to keep
## that look while getting the VARIATION back, not to pick a new look.
ROUGHNESS_BAND = (0.60, 0.86)

## Percentiles used to find the map's own range. Not min/max: one stray dark
## texel would compress everything else into the top of the band.
ROUGHNESS_PERCENTILES = (1.0, 99.0)


# --------------------------------------------------------------------------
# Per-species configuration. Everything that differs between creatures is here
# and nothing else is.
#
# eye_guard   Required. A list of selectors; their union is the region no
#             colour operation may touch. Selectors are either
#               ("uv", x0, y0, x1, y1)  image pixels at RECT_REFERENCE,
#                                       origin TOP-LEFT, as you read the PNG
#               ("hue", lo, hi, min_saturation)
# palette     Ordered list of colour operations. Each is evaluated against the
#             CURRENT state of the image, not the original — the old scripts
#             did the same by reassigning their hue/saturation/value arrays as
#             they went, and Terrapup's stone and cream masks depend on it.
# roughness   Band to rescale the roughness map into. None leaves it alone.
# emissive    "off" (zero it) or "glow" (leave it, and keep emissiveFactor).
# specular    Principled "Specular IOR Level", GLB path only.
# --------------------------------------------------------------------------

SPECIES: dict[str, dict] = {

    # ------------------------------------------------------------------
    # TERRAPUP — the quality benchmark, and the only creature that passed
    # its blind gate outright. Its numbers are transcribed unchanged from
    # grade_terrapup.py, including the two that were already the result of
    # a correction: BROWN_SATURATION dropped from 1.15 to 0.97 after a
    # passing review still called the fur "warmer, redder and more
    # saturated than the concept's muted matte chocolate", and the cream
    # blend gained a saturation floor after matching "any bright
    # low-saturation pixel" turned the stone mantle into pale cream caps
    # that a critic read as "a painted turtle shell or mushroom caps".
    # Do not retune these without a gate review saying to.
    # ------------------------------------------------------------------
    "terrapup": {
        "eye_guard": [
            # The hue band that has always worked here: on a brown badger
            # nothing else is a saturated teal, so the iris selects itself.
            ("hue", 150.0, 220.0, 0.25),
            # Rectangles as well, because the hue band protects the iris and
            # nothing else — the pupil, the sclera and the lid are not teal,
            # and they are half of what makes an eye read as an eye. The 3,569
            # teal texels resolve to exactly two clusters, which grown to
            # include sclera and lid are these, and which the mesh puts at
            # (+0.14, -0.82, 1.11) and (-0.16, -0.81, 1.11) — a symmetric pair
            # on the head of a 1.48 m creature.
            ("uv", 1320, 1524, 1460, 1700),
            ("uv", 1460, 1745, 1630, 1895),
        ],
        "palette": [
            # Browns and golds — the fur and the claws — deepen toward the
            # sheet's chocolate.
            {"op": "shift", "hue": (10.0, 55.0), "saturation": (0.22, 1.01),
             "value_mul": 0.72, "saturation_mul": 0.97},
            # Moss on the mantle: lime toward olive.
            {"op": "shift", "hue": (55.0, 140.0), "saturation": (0.15, 1.01),
             "value_mul": 0.78, "saturation_mul": 0.85,
             "hue_toward": 75.0, "hue_amount": 0.1},
            # Stone plates: bright NEUTRAL pixels, darkened toward the sheet's
            # mid-grey. Never creamed — that is what the saturation ceiling of
            # 0.10 here and the saturation floor of 0.10 below are for.
            {"op": "shift", "saturation": (0.0, 0.10), "value": (0.55, 1.01),
             "value_mul": 0.70},
            # Whites last, and in RGB: warm near-whites blend toward cream and
            # keep their shading variation.
            {"op": "blend", "value": (0.72, 1.01), "saturation": (0.10, 0.28),
             "target": (0.92, 0.86, 0.74), "amount": 0.55,
             "shade": "mean", "shade_norm": 0.9},
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.25,
    },

    # ------------------------------------------------------------------
    # RIPPLET — "the body is two or three value steps too pale ... washed-out
    # ice-cyan that blows out to white under the scene light, so the
    # creature's dominant read is WHITE, not blue, and the water-creature
    # identity evaporates." Target named by the critique: #5FA8BE.
    #
    # One pass covers the body and the tail fan together because they share
    # the same washed-out cyan; the fan turns from "opaque white squirrel
    # plume" into a glassy blue in the same stroke. True translucency is not
    # attempted — the whole creature is one glTF material, so per-region alpha
    # means splitting the mesh, and the critique itself rated membrane
    # treatment "over-investment for one of nineteen".
    # ------------------------------------------------------------------
    "ripplet": {
        # Two eyes, one UV patch each, found by thresholding the albedo for
        # near-black blobs and then asking the mesh where each blob's UVs
        # actually land: these two are a symmetric pair at z=1.577 on a 1.89 m
        # creature, 0.36 m apart. Every other dark blob in this atlas resolved
        # to a nostril, a mouth or a claw at ankle height. Boxes are the blob
        # bounds grown by ~40% so the cream sclera and the lid are inside too.
        "eye_guard": [
            ("uv", 104, 226, 320, 470),
            ("uv", 1440, 394, 1656, 638),
        ],
        "palette": [
            # Pale cyan body and fan -> the concept teal. Near-white pixels
            # whose small residual hue is still cool — the blown-out body the
            # critique named — are already inside this band: grade_ripplet.py
            # OR-ed in a second "blown white" clause of saturation < 0.08 and
            # value > 0.80, and every pixel it could select was in the first
            # clause's saturation < 0.55 and value > 0.55 already. It was a
            # no-op there. Written as a second operation here it would NOT be
            # one — it would blend that subset toward the target twice, for an
            # effective 0.86 — so it is gone rather than transcribed.
            # Warm near-whites (the cream belly and muzzle) are correct
            # already and do not qualify.
            {"op": "blend", "hue": (150.0, 230.0), "value": (0.55, 1.01),
             "saturation": (0.0, 0.55), "target": (0.373, 0.659, 0.745),
             "amount": 0.62, "shade": "value", "shade_norm": 0.95},
            # Pink frill interiors: more saturation, same value, so the coral
            # survives combat distance without turning neon.
            {"op": "shift", "hue": (310.0, 380.0), "saturation": (0.10, 1.01),
             "value": (0.5, 1.01), "saturation_mul": 1.35},
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.30,
    },

    # ------------------------------------------------------------------
    # GALEWISP — "the in-engine model is stark white with saturated, glossy
    # ice-cyan ears and wings, so at gameplay distance it reads as an Ice-type
    # sprite, not a wind-fox." Sheet 03 is warm cream/beige down, MUTED
    # slate-blue feathers, gold accents. The gold is guarded because it is the
    # accent the critique missed.
    # ------------------------------------------------------------------
    "galewisp": {
        # SIX rectangles for TWO eyes. This atlas carries the eye region in
        # several overlapping shells: the six boxes below resolve to exactly
        # two dense clusters of geometry, at (-0.13, -0.49, 1.37) and
        # (+0.12, -0.50, 1.39) — a symmetric pair on the head of a 2.07 m
        # creature. Guarding only the one obvious eye-looking patch would have
        # left the other five to be averaged away, which is the failure mode
        # this whole file exists to stop. Two further dark blobs resolved to
        # z=0.03 (toes) and are deliberately NOT guarded.
        "eye_guard": [
            ("uv", 486, 323, 642, 453),
            ("uv", 1925, 1651, 2048, 1853),
            ("uv", 1238, 1936, 1498, 2048),
            ("uv", 848, 949, 992, 1107),
            ("uv", 198, 1066, 314, 1166),
            ("uv", 80, 702, 224, 818),
        ],
        "palette": [
            # Blown whites -> warm cream.
            {"op": "blend", "saturation": (0.0, 0.12), "value": (0.72, 1.01),
             "not_hue": (25.0, 70.0), "not_saturation": 0.18,
             "target": (0.90, 0.84, 0.72), "amount": 0.45,
             "shade": "value", "shade_norm": 0.95},
            # Saturated cyans -> muted slate.
            {"op": "blend", "hue": (150.0, 235.0), "saturation": (0.15, 1.01),
             "not_hue": (25.0, 70.0), "not_saturation": 0.18,
             "target": (0.42, 0.55, 0.66), "amount": 0.60,
             "shade": "value", "shade_norm": 0.95},
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.25,
    },

    # ------------------------------------------------------------------
    # TUSKROOT — first of the ten Meadows wild creatures (R0.6). This is a
    # first-pass grade, not a critique-iterated one like the three above:
    # no blind gate has reviewed it yet, so only the structural fixes every
    # creature in this file needs (eye guard, albedo ceiling, roughness
    # rescale, emissive off) are applied. No hand-tuned hue-shift rules are
    # added without a review naming what is actually wrong with the colour —
    # inventing them here would be guessing at a problem nobody has looked at.
    # ------------------------------------------------------------------
    "tuskroot": {
        # Three eyes found in the 2048x2048 base_color atlas by visual
        # inspection (own reference crop gives no head-only close-up to
        # threshold against, unlike Terrapup's). Confirmed as eyes, not
        # shadow, by cropping and zooming each region: all three show a
        # white catchlight over a dark pupil. Boxes grown generously beyond
        # the visible pupil/sclera so the surrounding lid is protected too —
        # over-guarding costs a few ungraded fur texels, under-guarding
        # destroys the eye. May be the same eye duplicated across UV islands
        # rather than three distinct eyes; not resolved further since
        # guarding one eye twice is harmless.
        "eye_guard": [
            ("uv", 1170, 210, 1280, 320),
            ("uv", 1560, 855, 1660, 955),
            ("uv", 1330, 1130, 1460, 1250),
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.20,
    },

    # ------------------------------------------------------------------
    # MEADOWHART — second of the ten. Same first-pass philosophy as Tuskroot:
    # structural fixes only, no hand-tuned palette until a blind gate names
    # an actual colour defect.
    # ------------------------------------------------------------------
    "meadowhart": {
        # Two eyes found by visual inspection of the 2048x2048 base_color
        # atlas, both clearly a pale blue-grey iris with a white catchlight
        # over a dark pupil, unmistakable against the tan/brown coat.
        "eye_guard": [
            ("uv", 1490, 430, 1620, 555),
            ("uv", 245, 910, 370, 1040),
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.20,
    },

    # ------------------------------------------------------------------
    # BURROWBACK — third of the ten. Same first-pass philosophy.
    # ------------------------------------------------------------------
    "burrowback": {
        # Only ONE eye found by visual inspection of the 2048x2048
        # base_color atlas -- a clear amber/yellow iris with a white
        # catchlight, sitting in the black-and-white striped face patch the
        # canon calls for. The badger's dense stone/moss camouflage pattern
        # makes a second symmetric eye hard to distinguish from the general
        # texture noise with confidence; rather than guess a second
        # rectangle and risk it landing on ordinary fur, only the confirmed
        # one is guarded. If a later pass finds the second eye getting
        # graded away, add it then.
        "eye_guard": [
            ("uv", 1060, 1080, 1170, 1180),
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.20,
    },

    # ------------------------------------------------------------------
    # PADDLENEWT — fourth of the ten. Same first-pass philosophy.
    # ------------------------------------------------------------------
    "paddlenewt": {
        # Five rectangles, same duplicated-across-UV-islands pattern as
        # Galewisp's six and Tuskroot's three: every one shows the same
        # amber/gold iris ring around a dark pupil (four of the five also
        # carry a white catchlight), which is a texel-for-texel-consistent
        # signature no ordinary skin blemish produces, and a systematic scan
        # of the whole 2048x2048 atlas (both halves, all four quadrants)
        # found no sixth. Two other dark patches were checked and rejected:
        # one had no iris ring at all (just a shadowed crease), the other an
        # amber smear with no black pupil — neither guarded. Boxes grown
        # generously beyond each visible pupil/sclera per the Tuskroot
        # convention.
        "eye_guard": [
            ("uv", 1150, 375, 1320, 595),
            ("uv", 805, 730, 975, 905),
            ("uv", 890, 875, 1125, 1035),
            ("uv", 690, 1095, 860, 1235),
            ("uv", 390, 1270, 625, 1465),
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.20,
    },

    # ------------------------------------------------------------------
    # MOSSHELL — fifth of the ten. Same first-pass philosophy.
    # ------------------------------------------------------------------
    "mosshell": {
        # Four rectangles found by a full quadrant-by-quadrant scan of the
        # 2048x2048 atlas, same duplicated-across-UV-islands pattern as the
        # previous four species. Every guarded region shows a distinct dark
        # pupil (two black-with-cream-sclera, two amber-ringed). Several
        # other candidates were checked and rejected: a pair of uniform
        # amber blobs with no pupil at all (matching the small scale/wart
        # spots scattered across the rest of the shell texture, not eyes),
        # a tan almond/slit shape with no pupil (plausibly a closed eyelid
        # rendered into the stone-shell texture, but not confident enough to
        # guard), and a dark crevice with an amber edge but no round iris.
        "eye_guard": [
            ("uv", 155, 250, 270, 350),
            ("uv", 825, 310, 935, 400),
            ("uv", 1310, 930, 1430, 1050),
            ("uv", 1605, 1245, 1710, 1350),
        ],
        "roughness": ROUGHNESS_BAND,
        "emissive": "off",
        "specular": 0.20,
    },
}


# --------------------------------------------------------------------------
# Colour space. Vectorised HSV both ways; the old scripts each carried their
# own copy of these and Galewisp's was missing hsv_to_rgb entirely, which is
# why it could only ever blend and never shift saturation.
# --------------------------------------------------------------------------

def rgb_to_hsv(rgb: np.ndarray):
    maxc = rgb.max(axis=-1)
    minc = rgb.min(axis=-1)
    value = maxc
    delta = maxc - minc
    saturation = np.where(maxc > 1e-6, delta / np.maximum(maxc, 1e-6), 0.0)

    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.zeros_like(maxc)
    mask = delta > 1e-6
    rmax = mask & (maxc == r)
    gmax = mask & (maxc == g) & ~rmax
    bmax = mask & ~rmax & ~gmax
    hue[rmax] = ((g - b)[rmax] / delta[rmax]) % 6
    hue[gmax] = ((b - r)[gmax] / delta[gmax]) + 2
    hue[bmax] = ((r - g)[bmax] / delta[bmax]) + 4
    return hue * 60.0, saturation, value


def hsv_to_rgb(hue: np.ndarray, saturation: np.ndarray, value: np.ndarray) -> np.ndarray:
    h = (hue / 60.0) % 6
    c = value * saturation
    x = c * (1 - np.abs(h % 2 - 1))
    m = value - c
    zeros = np.zeros_like(c)
    rgb = np.zeros(h.shape + (3,), dtype=np.float32)
    for mask, (rr, gg, bb) in [
            (h < 1, (c, x, zeros)), ((1 <= h) & (h < 2), (x, c, zeros)),
            ((2 <= h) & (h < 3), (zeros, c, x)), ((3 <= h) & (h < 4), (zeros, x, c)),
            ((4 <= h) & (h < 5), (x, zeros, c)), (h >= 5, (c, zeros, x))]:
        rgb[..., 0] = np.where(mask, rr, rgb[..., 0])
        rgb[..., 1] = np.where(mask, gg, rgb[..., 1])
        rgb[..., 2] = np.where(mask, bb, rgb[..., 2])
    return rgb + m[..., None]


# --------------------------------------------------------------------------
# The eye guard.
# --------------------------------------------------------------------------

def require_guard(species: str, config: dict, opted_out: bool) -> list:
    """Refuse to grade a creature whose eyes nobody has located.

    This is the one check in the file that stops rather than warns. Grading is
    an averaging operation and an eye is a handful of high-contrast texels; a
    species with no declared guard will come out of here with its expression
    smoothed off, and nobody notices until the in-engine gate, four steps
    later, by which time the model is installed and the frames are rendered.
    Two of the three creatures already in the game left by exactly that door.

    `--no-eye-guard` exists because a creature may genuinely have no painted
    eyes — a modelled-eye asset, or a prop. It is deliberately loud: it prints
    a banner, and the caller has to have typed it.
    """
    guard = config.get("eye_guard") or []
    if guard:
        return guard
    if opted_out:
        print("!" * 70)
        print(f"!! {species}: GRADING WITH NO EYE GUARD, because --no-eye-guard was")
        print("!! passed. Every colour operation below will run over the eyes. If this")
        print("!! creature has painted eyes, they will be averaged into the body and")
        print("!! the loss is not recoverable from the graded texture.")
        print("!" * 70)
        return []
    raise SystemExit(
        f"{species} declares no eye_guard.\n"
        f"\n"
        f"Add one to SPECIES in {pathlib.Path(__file__).name}. To find the rects:\n"
        f"  1. threshold the albedo for near-black blobs (pupils are the darkest\n"
        f"     thing on these textures) and crop each one out to look at;\n"
        f"  2. for every blob that looks like an eye, ask the MESH where that UV\n"
        f"     rect's geometry actually is — a real eye resolves to a dense\n"
        f"     cluster on the head, a false positive to a toe or a nostril;\n"
        f"  3. record the blob bounds grown by ~40%, so the sclera and lid are in.\n"
        f"\n"
        f"If this creature really has no painted eyes, pass --no-eye-guard and say\n"
        f"so in its production report.")


def guard_weight(shape: tuple[int, int], guard: list, rgb: np.ndarray) -> np.ndarray:
    """Per-texel protection, 1.0 = untouchable, 0.0 = grade freely.

    UV selectors feather at the edge; hue selectors do not, because Terrapup's
    hue guard shipped hard-edged and softening it would move pixels on the one
    creature that is not allowed to move.
    """
    height, width = shape
    weight = np.zeros(shape, dtype=np.float32)

    rects = [s for s in guard if s[0] == "uv"]
    if rects:
        scale_x = width / RECT_REFERENCE
        scale_y = height / RECT_REFERENCE
        feather_x = max(GUARD_FEATHER * scale_x, 1.0)
        feather_y = max(GUARD_FEATHER * scale_y, 1.0)
        xs = np.arange(width, dtype=np.float32)[None, :]
        ys = np.arange(height, dtype=np.float32)[:, None]
        for _, x0, y0, x1, y1 in rects:
            # Distance OUTSIDE the box, zero within it. Analytic, so a 2048
            # square costs two broadcasts rather than a dilation kernel.
            dx = np.maximum(np.maximum(x0 * scale_x - xs, xs - x1 * scale_x), 0.0)
            dy = np.maximum(np.maximum(y0 * scale_y - ys, ys - y1 * scale_y), 0.0)
            distance = np.sqrt((dx / feather_x) ** 2 + (dy / feather_y) ** 2)
            weight = np.maximum(weight, np.clip(1.0 - distance, 0.0, 1.0))

    hues = [s for s in guard if s[0] == "hue"]
    if hues:
        hue, saturation, _ = rgb_to_hsv(rgb)
        for _, lo, hi, min_saturation in hues:
            selected = (hue > lo) & (hue < hi) & (saturation > min_saturation)
            weight = np.maximum(weight, selected.astype(np.float32))
    return weight


# --------------------------------------------------------------------------
# Colour operations.
# --------------------------------------------------------------------------

def select(spec: dict, hue, saturation, value) -> np.ndarray:
    """Build an operation's mask from hue/saturation/value bands plus guards.

    Ranges are half-open-ish and deliberately written as pairs so the config
    reads like the thing it replaces. `not_hue`/`not_saturation` is the
    "guarded accent" idiom — Galewisp's gold, which both of its operations
    have to step around.
    """
    mask = np.ones(value.shape, dtype=bool)
    if "hue" in spec:
        lo, hi = spec["hue"]
        # A hue band may wrap past 360 (Ripplet's pink runs 310..380).
        mask &= ((hue > lo) & (hue < hi)) | ((hue + 360.0 > lo) & (hue + 360.0 < hi))
    if "saturation" in spec:
        lo, hi = spec["saturation"]
        mask &= (saturation >= lo) & (saturation < hi)
    if "value" in spec:
        lo, hi = spec["value"]
        mask &= (value >= lo) & (value < hi)
    if "not_hue" in spec:
        lo, hi = spec["not_hue"]
        mask &= ~((hue > lo) & (hue < hi) & (saturation > spec.get("not_saturation", 0.0)))
    return mask


def shading(spec: dict, rgb: np.ndarray, value: np.ndarray) -> np.ndarray:
    """How much of the blend target a texel gets, so shading survives a blend.

    Two forms because the old scripts used two: Terrapup's cream blend scaled
    by the texel's RGB mean over 0.9, Ripplet's and Galewisp's by value over
    0.95. Kept distinct rather than unified, because unifying them would move
    Terrapup.
    """
    if spec.get("shade") == "mean":
        return np.clip(rgb.mean(axis=-1, keepdims=True) / spec.get("shade_norm", 0.9), 0.0, None)
    return np.clip(value[..., None] / spec.get("shade_norm", 0.95), 0.0, 1.0)


def apply_palette(rgb: np.ndarray, palette: list) -> np.ndarray:
    for spec in palette:
        hue, saturation, value = rgb_to_hsv(rgb)
        mask = select(spec, hue, saturation, value)
        if not mask.any():
            continue
        if spec["op"] == "shift":
            if "value_mul" in spec:
                value = np.where(mask, value * spec["value_mul"], value)
            if "saturation_mul" in spec:
                saturation = np.where(
                    mask, np.minimum(saturation * spec["saturation_mul"], 1.0), saturation)
            if "hue_toward" in spec:
                amount = spec.get("hue_amount", 0.1)
                hue = np.where(mask, hue * (1 - amount) + spec["hue_toward"] * amount, hue)
            rgb = hsv_to_rgb(hue, saturation, value)
        elif spec["op"] == "blend":
            target = np.array(spec["target"], dtype=np.float32)
            amount = spec["amount"]
            blended = rgb * (1 - amount) + (target * shading(spec, rgb, value)) * amount
            rgb = np.where(mask[..., None], blended, rgb)
        else:
            raise SystemExit(f"unknown palette op: {spec['op']}")
    return rgb.astype(np.float32)


def ceiling(rgb: np.ndarray) -> np.ndarray:
    """Compress the top of the albedo range instead of clipping it.

    A hard `min(v, 0.82)` would fix the clipping number and produce the same
    defect one channel over: every highlight lands on the same value, the
    shading in the bright areas turns into a flat plateau, and the fix reads
    as a paint bucket. That is literally what ROUGHNESS_FLOOR did.

    So: a soft knee. Below ALBEDO_KNEE nothing moves at all. Above it the
    remaining range is mapped through 1 - exp(-t), which is monotonic — so no
    two texels that differed before are equal after — and asymptotic, so the
    result approaches ALBEDO_CEILING without ever reaching it. Scaling is
    applied to value, with R:G:B held in ratio, so nothing shifts hue.
    """
    value = rgb.max(axis=-1)
    span = ALBEDO_CEILING - ALBEDO_KNEE
    over = value > ALBEDO_KNEE
    compressed = ALBEDO_KNEE + span * (1.0 - np.exp(-(value - ALBEDO_KNEE) / span))
    scale = np.where(over, compressed / np.maximum(value, 1e-6), 1.0)
    return rgb * scale[..., None]


def roughness(channel: np.ndarray, band: tuple[float, float]) -> tuple[np.ndarray, str]:
    """Rescale a roughness map's own range into a matte band, keeping variation.

    Returns the new channel and a line about what happened, because the
    interesting case is the one where nothing can happen: if the map has
    already been flattened by the old ROUGHNESS_FLOOR it has a single value in
    it, there is no variation left to preserve, and rescaling a constant is a
    constant. That is not a failure of this function and it is not fixable
    here — the data is gone from the shipped file and only a re-bake brings it
    back. Say so rather than quietly emitting a slightly different constant.
    """
    low, high = np.percentile(channel, ROUGHNESS_PERCENTILES)
    if high - low < 1e-4:
        return channel, (f"roughness is a single value ({float(channel.flat[0]):.3f}) — "
                         f"already flattened, nothing to preserve; left alone")
    scaled = band[0] + (channel - low) / (high - low) * (band[1] - band[0])
    scaled = np.clip(scaled, 0.0, 1.0)
    return scaled, (f"roughness {low:.3f}..{high:.3f} (sd {channel.std():.4f}) rescaled to "
                    f"{band[0]:.2f}..{band[1]:.2f} (sd {scaled.std():.4f}), "
                    f"{len(np.unique(np.round(scaled * 255)))} distinct levels kept")


# --------------------------------------------------------------------------
# Measurement. Every number the caller reports comes from here, so that
# "highlights no longer clip" is something the run prints rather than
# something a commit message asserts.
# --------------------------------------------------------------------------

def albedo_stats(rgb: np.ndarray, guard: np.ndarray) -> dict:
    """Clipping, measured only where the grade is actually allowed to act.

    `free` is guard == 0, not guard < 0.5. Texels in the feathered edge are
    part original and part graded by construction, so a few of them sit above
    the ceiling and would make "0% above the ceiling afterwards" read as a
    near miss rather than the arithmetic certainty it is.
    """
    value = rgb.max(axis=-1)
    free = guard <= 1e-6
    bright = value[free] > ALBEDO_KNEE
    return {
        "mean_value": float(value.mean()),
        "over_0.85": float((value[free] > 0.85).mean() * 100.0),
        "over_0.90": float((value[free] > 0.90).mean() * 100.0),
        "over_ceiling": float((value[free] > ALBEDO_CEILING).mean() * 100.0),
        "levels": int(len(np.unique(np.round(value[free][bright] * 255)))),
    }


def report_albedo(source: np.ndarray, graded: np.ndarray, config: dict,
                  guard: np.ndarray, matte_only: bool) -> None:
    """Print the before/after that makes the fix checkable rather than claimed.

    The number that matters most is the last one. "The eyes are guarded" is
    trivially true of a guard that covers nothing; what says the guard is
    doing work is how far the eye texels WOULD have moved without it, which is
    measured by grading the same image again with the guard switched off.
    """
    before, after = albedo_stats(source, guard), albedo_stats(graded, guard)
    print(f"    albedo, clipping (measured only where the grade may act):")
    print(f"      value > 0.85      {before['over_0.85']:6.2f}%  ->  {after['over_0.85']:6.2f}%")
    print(f"      value > 0.90      {before['over_0.90']:6.2f}%  ->  {after['over_0.90']:6.2f}%")
    print(f"      value > {ALBEDO_CEILING:.2f} ceil  {before['over_ceiling']:6.2f}%  ->  "
          f"{after['over_ceiling']:6.2f}%   (0 by construction)")
    print(f"      mean value        {before['mean_value']:6.3f}   ->  {after['mean_value']:6.3f}")
    print(f"      distinct levels above the knee: {before['levels']} -> {after['levels']} "
          f"(a hard clamp would give 1)")

    inside = guard > 0.999
    moved = np.abs(graded - source).mean(axis=-1)
    print(f"    eye guard: {int(inside.sum()):,} texels fully protected "
          f"({inside.mean() * 100:.3f}% of the map)")
    print(f"      mean |delta| where the grade acted   {moved[guard <= 1e-6].mean() * 255:6.2f}/255")
    print(f"      mean |delta| inside the eye guard    {moved[inside].mean() * 255:6.2f}/255"
          f"   (must be 0.00)")
    if inside.any():
        unguarded = grade_albedo(source.copy(), config, np.zeros_like(guard), matte_only)
        would = np.abs(unguarded - source).mean(axis=-1)[inside]
        print(f"      ... which the same grade with the guard OFF would have moved by "
              f"{would.mean() * 255:.2f}/255 mean, {would.max() * 255:.2f}/255 worst")


# --------------------------------------------------------------------------
# The grade itself, over plain arrays. Both front-ends call this.
# --------------------------------------------------------------------------

def grade_albedo(rgb: np.ndarray, config: dict, guard: np.ndarray,
                 matte_only: bool) -> np.ndarray:
    """Palette, then ceiling, then put the guarded texels back untouched.

    Order matters. The ceiling is an output-referred safety net and has to see
    the palette's result: Terrapup's brown grade multiplies value by 0.72, so
    running the ceiling first would compress highlights that the palette was
    about to darken anyway.

    The guard is restored last and covers BOTH stages, including the ceiling.
    That leaves the catchlight at full brightness, on purpose: it is the
    smallest mark on the creature, it is what makes an eye look wet and alive,
    and dimming it is a smaller version of the exact defect this file exists
    to undo.
    """
    original = rgb.copy()
    if not matte_only:
        rgb = apply_palette(rgb, config.get("palette", []))
    rgb = ceiling(rgb)
    rgb = np.clip(rgb, 0.0, 1.0)
    weight = guard[..., None]
    return (original * weight + rgb * (1.0 - weight)).astype(np.float32)


# --------------------------------------------------------------------------
# Front-end 1: loose texture files. No Blender.
#
# This exists because a creature can be broken AFTER it is installed, and the
# thing the engine actually samples by then is not the GLB — Godot's glTF
# importer runs in Extract mode and reads the loose maps sitting next to it.
# Regrading an installed creature through Blender would mean rewriting its
# GLB, re-importing, and re-validating a mesh that has nothing wrong with it.
# --------------------------------------------------------------------------

ROLES = {
    "base_color": "albedo",
    "metallic_roughness": "roughness",
    "emissive": "emissive",
    "normal": "normal",
}


def texture_paths(directory: pathlib.Path, species: str) -> dict[str, dict[str, pathlib.Path]]:
    """Group `pal_<species>_lod0_<role>.<ext>` by role, keeping every extension.

    Both extensions turn up in a models/ directory and they are NOT duplicates:
    Godot's extractor names the file after the glTF image's mime type, so a map
    that was JPEG when the model was first installed and PNG after a grade
    leaves one file of each — and the JPEG is then a byte-exact copy of the
    PRE-GRADE original, which is the only reason regrading an already-graded
    creature is possible at all rather than being a second grade on top of a
    first.
    """
    found: dict[str, dict[str, pathlib.Path]] = {}
    prefix = f"pal_{species}_lod0_"
    for path in sorted(directory.iterdir()):
        if not path.name.startswith(prefix) or path.suffix.lower() not in (".png", ".jpg"):
            continue
        role = ROLES.get(path.stem[len(prefix):])
        if role:
            found.setdefault(role, {})[path.suffix.lower().lstrip(".")] = path
    return found


def load_image(path: pathlib.Path) -> np.ndarray:
    from PIL import Image
    Image.MAX_IMAGE_PIXELS = None
    return np.asarray(Image.open(path).convert("RGB"), dtype=np.float32) / 255.0


def save_image(path: pathlib.Path, rgb: np.ndarray) -> None:
    from PIL import Image
    Image.fromarray(np.round(np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB").save(path)


def grade_textures(directory: pathlib.Path, species: str, config: dict,
                   guard_spec: list, matte_only: bool, source_ext: str | None,
                   dry_run: bool) -> None:
    maps = texture_paths(directory, species)
    if "albedo" not in maps:
        raise SystemExit(f"no base_color map under {directory}")

    # Which file the engine reads (destination) versus which file we grade FROM.
    # They are usually the same; --from jpg says "the destination is a second
    # grade of an already-graded map, use the untouched original instead".
    destination = maps["albedo"].get("png") or next(iter(maps["albedo"].values()))
    source = maps["albedo"].get(source_ext) if source_ext else None
    if source_ext and source is None:
        raise SystemExit(f"--from {source_ext}: no {source_ext} base_color beside {destination}")
    source = source or destination

    rgb = load_image(source)
    guard = guard_weight(rgb.shape[:2], guard_spec, rgb)
    graded = grade_albedo(rgb.copy(), config, guard, matte_only)

    print(f"  albedo: {source.name} -> {destination.name}")
    report_albedo(rgb, graded, config, guard, matte_only)
    if not dry_run:
        save_image(destination, graded)

    # Re-encoding a map this changed nothing about still produces a different
    # file on disk, and a texture that big turning up in a diff for no reason
    # is how a reviewer stops reading diffs. Write only what moved.
    def save_if_changed(path: pathlib.Path, old: np.ndarray, new: np.ndarray) -> None:
        if np.array_equal(np.round(old * 255), np.round(new * 255)):
            print(f"      unchanged, not rewritten")
        elif not dry_run:
            save_image(path, new)

    if "roughness" in maps and config.get("roughness"):
        path = maps["roughness"].get("png") or next(iter(maps["roughness"].values()))
        source_mr = maps["roughness"].get(source_ext) if source_ext else None
        mr = load_image(source_mr or path)
        new_mr = mr.copy()
        new_mr[..., 1], note = roughness(mr[..., 1], config["roughness"])
        new_mr[..., 2] = 0.0                                # B = metallic, never
        print(f"  {path.name}: {note}; metallic zeroed")
        save_if_changed(path, load_image(path), new_mr)

    if "emissive" in maps:
        path = maps["emissive"].get("png") or next(iter(maps["emissive"].values()))
        em = load_image(path)
        lit = float((em.max(axis=-1) > 0.05).mean() * 100.0)
        if config.get("emissive") == "glow":
            print(f"  {path.name}: species declares a glow — left alone "
                  f"({lit:.1f}% of the map emits)")
        else:
            print(f"  {path.name}: {lit:.1f}% of the map emits (max {em.max():.3f}) -> zeroed")
            if em.any():
                # Only worth saying when there was something to switch off.
                print(f"      NOTE: the GLB still carries emissiveFactor [1,1,1], because")
                print(f"      --textures cannot reach it. A black emissive map is the same")
                print(f"      result in engine (factor x texture); the GLB path is what")
                print(f"      writes [0,0,0] properly, and should be run when the model is")
                print(f"      next rebuilt.")
            save_if_changed(path, em, np.zeros_like(em))

    if "normal" in maps:
        print(f"  normal map: not touched (it is not a colour, and flooring its "
              f"channels turns surface normals into noise)")


# --------------------------------------------------------------------------
# Front-end 2: the GLB, under Blender. The pipeline path.
# --------------------------------------------------------------------------

def image_role(node) -> str | None:
    """What a texture IS, decided by where its output goes.

    Not by colour space. "sRGB means base colour" is false — emissive is sRGB
    too, and that single wrong assumption is how Ripplet's glow map came to be
    recoloured to match its body. "Non-Color means roughness" is false as
    well: the normal map is Non-Color, and it once had its green channel
    floored and its blue zeroed, which is not a grading bug, it is vandalism
    of the surface normals.
    """
    feeds = set()
    for output in node.outputs:
        for link in output.links:
            feeds.add((link.to_node.type, link.to_socket.name))
    if any(kind == "NORMAL_MAP" for kind, _ in feeds):
        return "normal"
    for kind, socket in feeds:
        if kind == "BSDF_PRINCIPLED":
            if socket in ("Base Color",):
                return "albedo"
            if socket.startswith("Emission"):
                return "emissive"
            if socket in ("Roughness", "Metallic", "Specular IOR Level"):
                return "roughness"
    if any(kind == "SEPARATE_COLOR" for kind, _ in feeds):
        return "roughness"       # the packed ORM split the glTF importer builds
    return None


def image_array(image) -> np.ndarray:
    """RGBA float array, height-major.

    foreach_get, not `np.array(image.pixels[:])`. A 2048-square map is 16.7
    million floats and the slice form builds a Python list of every one of
    them; all three old scripts did that twice per image, which is most of why
    a grade took minutes rather than seconds.
    """
    buffer = np.empty(image.size[0] * image.size[1] * 4, dtype=np.float32)
    image.pixels.foreach_get(buffer)
    return buffer.reshape(image.size[1], image.size[0], 4)


def write_image(image, pixels: np.ndarray) -> None:
    image.pixels.foreach_set(np.ascontiguousarray(pixels, dtype=np.float32).ravel())
    image.pack()


def grade_glb(model: pathlib.Path, out: pathlib.Path, species: str, config: dict,
              guard_spec: list, matte_only: bool) -> None:
    import bpy

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(model))

    handled = 0
    for material in bpy.data.materials:
        if not material.use_nodes:
            continue
        for node in material.node_tree.nodes:
            if node.type != "TEX_IMAGE" or node.image is None:
                continue
            role = image_role(node)
            # Blender's pixel buffer is bottom-up and every rect in SPECIES is
            # written top-down, the way a human reads the PNG. Flip on the way
            # in and back on the way out rather than storing two conventions.
            if role == "albedo":
                pixels = image_array(node.image)[::-1]
                rgb = pixels[..., :3]
                guard = guard_weight(rgb.shape[:2], guard_spec, rgb)
                graded = grade_albedo(rgb.copy(), config, guard, matte_only)
                print(f"  albedo {node.image.name}:")
                report_albedo(rgb, graded, config, guard, matte_only)
                pixels[..., :3] = graded
                write_image(node.image, pixels[::-1])
                handled += 1
            elif role == "roughness" and config.get("roughness"):
                pixels = image_array(node.image)
                new_g, note = roughness(pixels[..., 1], config["roughness"])
                pixels[..., 1] = new_g
                pixels[..., 2] = 0.0
                print(f"  {node.image.name}: {note}; metallic zeroed")
                write_image(node.image, pixels)
                handled += 1
            elif role == "emissive":
                pixels = image_array(node.image)
                lit = float((pixels[..., :3].max(axis=-1) > 0.05).mean() * 100.0)
                if config.get("emissive") == "glow":
                    print(f"  {node.image.name}: species declares a glow — left alone")
                else:
                    print(f"  {node.image.name}: {lit:.1f}% of the map emitted -> zeroed")
                    pixels[..., :3] = 0.0
                    write_image(node.image, pixels)
                handled += 1
            elif role == "normal":
                print(f"  {node.image.name}: normal map, not touched")
            else:
                print(f"  {node.image.name}: unrecognised role, not touched")

        for node in material.node_tree.nodes:
            if node.type != "BSDF_PRINCIPLED":
                continue
            node.inputs["Metallic"].default_value = 0.0
            node.inputs["Specular IOR Level"].default_value = config.get("specular", 0.25)
            # emissiveFactor. Every model this pipeline has shipped carries
            # [1,1,1], which is glTF for "multiply the emissive map through at
            # full strength" — harmless while the map is black and a
            # self-illuminated creature the moment it is not. Nothing in the
            # Meadows glows, so unless the species says otherwise this goes to
            # zero at the factor as well as at the map, and the exporter then
            # writes emissiveFactor [0,0,0].
            if config.get("emissive") != "glow":
                if "Emission Color" in node.inputs:
                    node.inputs["Emission Color"].default_value = (0.0, 0.0, 0.0, 1.0)
                if "Emission Strength" in node.inputs:
                    node.inputs["Emission Strength"].default_value = 0.0

    if handled == 0:
        raise SystemExit("no gradeable textures found — is this model textured?")

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                              export_animations=True, export_animation_mode="NLA_TRACKS",
                              export_skins=True, export_yup=True)
    print(f"\n-> {out}")


# --------------------------------------------------------------------------

def argv_after_double_dash() -> list[str]:
    """Blender swallows everything before `--`; plain python does not use one."""
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="grade.py", description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("model", nargs="?", help="GLB to grade (pipeline path)")
    parser.add_argument("--species", required=True, choices=sorted(SPECIES),
                        help="whose palette to use; there is no guessing from filenames")
    parser.add_argument("--out", help="where to write the graded GLB")
    parser.add_argument("--textures", help="grade the loose maps in this models/ directory")
    parser.add_argument("--from", dest="source_ext", choices=("jpg", "png"),
                        help="read from this extension instead of the destination — "
                             "use jpg to regrade from the pre-grade original")
    parser.add_argument("--matte-only", action="store_true",
                        help="skip the palette; ceiling, roughness and emissive still run")
    parser.add_argument("--no-eye-guard", action="store_true",
                        help="grade a species with no declared eye guard (loud)")
    parser.add_argument("--dry-run", action="store_true",
                        help="measure and report, write nothing")
    args = parser.parse_args(argv_after_double_dash())

    config = SPECIES[args.species]
    guard_spec = require_guard(args.species, config, args.no_eye_guard)
    print(f"{args.species}: {len([s for s in guard_spec if s[0] == 'uv'])} eye rect(s), "
          f"{len([s for s in guard_spec if s[0] == 'hue'])} hue guard(s), "
          f"{len(config.get('palette', []))} palette op(s)"
          f"{'  [--matte-only: palette skipped]' if args.matte_only else ''}")

    if args.textures:
        grade_textures(pathlib.Path(args.textures).resolve(), args.species, config,
                       guard_spec, args.matte_only, args.source_ext, args.dry_run)
        return
    if not args.model:
        raise SystemExit("give a GLB, or --textures <models dir>")
    model = pathlib.Path(args.model).resolve()
    out = pathlib.Path(args.out or model.with_name("graded.glb")).resolve()
    if args.dry_run:
        raise SystemExit("--dry-run is only implemented for --textures")
    grade_glb(model, out, args.species, config, guard_spec, args.matte_only)


if __name__ == "__main__":
    main()
