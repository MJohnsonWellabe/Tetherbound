#!/usr/bin/env python3
"""T1-CREATURE-ART: generate the four Aspect-variant recolor + glow textures.

Nightburrow (Burrowback), Stormtrail (Trailpup), Riftfrill (Paddlenewt) and
Ashtusk (Tuskroot) -- the owner brief in
docs/owner-direction/TETHERBOUND_MEADOWS_CREATURE_EXPANSION.md and the four
reference boards under docs/art/reference/creature-expansion-2026-08-30/.
Spec lives in data/creatures/aspect_variants.json; read that file's own
`_comment`/`_comment_glow` first, they explain the two-pass design (an
HSV recolor pass on the albedo, reusing tools/repaint_creature_textures.py's
own machinery unchanged, plus a SYNTHESISED glow map for the emissive slot,
because none of the four source creatures ship a usable one -- confirmed by
tools/_probe_aspect_source_materials.gd).

Output naming matches the exact sibling convention
scripts/creatures/creature_body.gd::_texture_for() already reads for
vivid/shiny/alpha, generalised to an arbitrary suffix (the variant id) and an
explicit SOURCE species (creature_body.gd's set_aspect_variant() takes one,
because the variant's own eventual species id -- e.g. "stormtrail" -- is not
the folder its textures live in):

    <source's own live albedo/emission texture, minus extension>_<variant>.png

Run from the repo root:  python3 tools/generate_aspect_variant_textures.py [variant...]
No args = all four. Idempotent -- output is a pure function of (source
texture, spec, anatomy map).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from repaint_creature_textures import (  # noqa: E402
    find_textures, repaint, variant_path, rgb_to_hsv,
)
from creature_overlays import anatomy_mask, _hex_to_rgb  # noqa: E402
from creature_anatomy_maps import build as build_anatomy  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "data", "creatures", "aspect_variants.json")

## Both the recolored albedo and the synthesised glow map are written at this
## edge length regardless of the source's own resolution (2048, or a 4x4
## emissive stub that carries no information at all) -- matching
## shiny_colourways.json's own `_finish_default.output_size`, and for the
## same two reasons that file gives: a wild creature never occupies enough
## screen space to need the source resolution, and every one of these is a
## tracked binary in a repo that already carries hundreds of MB of art.
OUTPUT_SIZE = 1024

## Glow feature masks are found per-texel, which on a photoreal Meshy albedo
## is often a single stray dark texel rather than a continuous seam -- a
## one-pixel-wide glow is exactly the kind of detail this project's own
## `finish_pass` despeckle comment warns aliases away at gameplay distance.
## Dilated by this many pixels (scaled to OUTPUT_SIZE the same way
## `finish_pass`'s despeckle radius scales to width) so a seam reads as a
## seam rather than as noise.
GLOW_DILATE_PX = 3


def load_spec():
    with open(SPEC_PATH) as f:
        return json.load(f)["variants"]


def _dilate(mask, radius):
    if radius < 1:
        return mask
    size = radius * 2 + 1
    img = Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8), "L")
    img = img.filter(ImageFilter.MaxFilter(size=min(size, 9)))
    return np.asarray(img).astype(np.float64) / 255.0


def build_glow_map(albedo_rgb, source_rgb, anatomy, glow_specs, size):
    """Black canvas with each glow layer painted on where it selects.

    `albedo_rgb` is the ALREADY-RECOLOURED albedo (float 0..1, HxWx3);
    `source_rgb` is the ORIGINAL shipped texture at the same resolution.
    `select: feature` (darkest-N-percentile seams) samples the RECOLOURED
    paint, because a seam's relative darkness survives a uniform darken/hue
    shift. `select: match` (a PALE feature picked out by colour, e.g.
    Ashtusk's ivory tusks) samples the SOURCE instead -- a recolour rule that
    darkens the whole body toward basalt/soot darkens the tusks right along
    with it, which would make a same-image match rule find nothing (measured:
    0.04% of the surface, i.e. noise). The tusks are still exactly where they
    were before the repaint; only their colour moved, and colour is the one
    thing `match` mode is selecting on.
    Returns (rgb, notes); a layer that selects nothing prints why, the same
    diagnostic discipline tools/creature_overlays.py's own apply_overlays()
    uses for exactly the same reason (a `where` block covering nothing is a
    silent no-op otherwise).
    """
    h, s, v = rgb_to_hsv(albedo_rgb)
    sh, ss, sv = rgb_to_hsv(source_rgb)
    canvas = np.zeros((size, size, 3), dtype=np.float64)
    notes = []
    valid_count = max(float(anatomy["valid"].sum()), 1.0)
    for spec in glow_specs:
        ident = str(spec.get("id", "glow"))
        softness = float(spec.get("softness", 0.12))
        region = anatomy_mask(spec.get("where", {}), anatomy, softness)
        if region.max() <= 0.0:
            notes.append("%s: `where` selected nothing" % ident)
            continue

        select = spec.get("select", "feature")
        if select == "feature":
            pool = v[region > 0.3]
            if pool.size == 0:
                notes.append("%s: region too small to sample a percentile" % ident)
                continue
            cut = min(float(np.percentile(pool, float(spec.get("percentile", 5.0)))),
                      float(spec.get("max_val", 0.2)))
            feature = (v <= cut) & (region > 0.15)
        else:  # "match": a PALE feature (e.g. ivory tusks) -- HSV bounds on the SOURCE.
            feature = region > 0.15
            if "sat_min" in spec:
                feature &= ss >= float(spec["sat_min"])
            if "sat_max" in spec:
                feature &= ss <= float(spec["sat_max"])
            if "val_min" in spec:
                feature &= sv >= float(spec["val_min"])
            if "val_max" in spec:
                feature &= sv <= float(spec["val_max"])

        if not feature.any():
            notes.append("%s: selected nothing after the colour/value bounds" % ident)
            continue

        mask = _dilate(feature.astype(np.float64), GLOW_DILATE_PX) * region
        colour = _hex_to_rgb(str(spec.get("color", "#ffffff")))
        intensity = float(spec.get("intensity", 1.5))
        canvas = np.maximum(canvas, (mask * intensity)[..., None] * colour[None, None, :])
        share = 100.0 * float((mask > 0.25).sum()) / valid_count
        notes.append("%s: %.2f%% of the surface" % (ident, share))
    return np.clip(canvas, 0.0, 1.0), notes


def main():
    spec = load_spec()
    wanted = sys.argv[1:] or sorted(spec.keys())
    for variant in wanted:
        if variant not in spec:
            print("skip %s: not in %s" % (variant, SPEC_PATH))
            continue
        entry = spec[variant]
        source = entry["source_species"]
        textures = find_textures(source)

        finish = dict(entry.get("finish", {}))
        finish.setdefault("output_size", OUTPUT_SIZE)
        rules = entry.get("rules", [])
        overlays = list(entry.get("overlays", []))

        albedo_dst, albedo_share, albedo_notes = repaint(
            textures["base_color"], rules, variant_path(textures["base_color"], variant),
            finish, species=source, overlays=overlays)
        print("%s: base_color -> %s (%.0f%% terrain-hue)" % (
            variant, os.path.relpath(albedo_dst, ROOT), albedo_share * 100.0))
        for note in albedo_notes:
            print("   overlay: %s" % note)

        anatomy, _cache = build_anatomy(source, size=OUTPUT_SIZE)
        albedo_arr = np.asarray(Image.open(albedo_dst).convert("RGB")).astype(np.float64) / 255.0
        source_arr = np.asarray(
            Image.open(textures["base_color"]).convert("RGB").resize((OUTPUT_SIZE, OUTPUT_SIZE), Image.LANCZOS)
        ).astype(np.float64) / 255.0
        glow_rgb, glow_notes = build_glow_map(
            albedo_arr, source_arr, anatomy, entry.get("glow", []), OUTPUT_SIZE)
        for note in glow_notes:
            print("   glow: %s" % note)

        emissive_dst = variant_path(textures["emissive"], variant)
        alpha = np.full(glow_rgb.shape[:2] + (1,), 255, dtype=np.uint8)
        out = np.concatenate([(glow_rgb * 255).astype(np.uint8), alpha], axis=-1)
        Image.fromarray(out, "RGBA").save(emissive_dst, optimize=True)
        print("%s: emissive -> %s (synthesised glow map)" % (
            variant, os.path.relpath(emissive_dst, ROOT)))


if __name__ == "__main__":
    main()
