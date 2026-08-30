#!/usr/bin/env python3
"""CREATURE-IDENTITY-2: the fantasy layer, painted onto existing UVs.

Consumed by tools/repaint_creature_textures.py, which owns the colourway
pipeline; this module owns only the step that comes after it. Nothing here
touches a mesh -- an overlay is paint composited into a texture, which is what
keeps the owner board's identity layer legal under the hard rule (no new
creature meshes, no Meshy for creatures).

What an overlay is
------------------
The owner board does not show recoloured animals. It shows animals the meadow
has grown into: leaves sprouting from bramblebun's ears, moss carpeting
mudsnout's and tuskroot's shoulders, foliage on terrapup's and trailpup's
backs, meadowhart's antler tips greened, mosshell's shell carrying real moss on
stone, galecrest's flight feathers tipped storm blue. Round 1 delivered the
colour and none of that, which a blind critic named as "correct but half-depth".

An overlay is authored in ANATOMY, never in UV rectangles:

    {"id": "leaf_ears",
     "where": {"y_min": 0.80, "radial_min": 0.15},   # anatomy predicates
     "mode": "grow",                                  # or "tint"
     "color": "#4f8f31", "shade": "#22491c",
     "coverage": 0.55, "grain": 5.0, "softness": 0.18}

`where` reads the channels tools/creature_anatomy_maps.py rasterises out of the
species' own glb -- normalised height, surface normal, distance from the spine.
"The top fifth of the animal, away from the centre line" is an ear on every
mesh in the roster and stays an ear if anything is ever re-unwrapped. A UV
rectangle is none of those things, and picking one is exactly how round 1's
galecrest patches ended up crossing feather boundaries: automatic unwraps
scatter a wing across islands, so a rectangle that looks like a wing tip on the
texture sheet is several unrelated pieces of bird.

Two composite modes, because the board shows two different things:

  * `grow` -- material that is NOT the animal: moss, leaf, lichen. It replaces
    hue and saturation and re-lights the patch with its own two-tone ramp,
    while keeping the host surface's high-frequency value detail so the moss
    creases where the body creases instead of reading as flat green sticker.

  * `tint` -- the animal's own material in a different colour: storm-blue
    feather tips, greened antler. Hue and saturation move; VALUE IS UNTOUCHED.
    That is the whole feather-following trick -- a feather's quill lines,
    barb shadows and specular edge all live in the value channel, so leaving
    value alone means the recolour flows along the feather the painter drew
    rather than sitting on top of it.

Breakup is 3D noise, not UV noise
---------------------------------
A patch thresholded straight off an anatomy predicate has a mathematically
smooth border, which reads as an airbrush stencil. Real growth is clumpy, so
the mask is multiplied by value noise -- but the noise is sampled in MODEL
space off the anatomy map's own position channel, not in texture space. UV
noise is discontinuous across every island boundary, so a clump would be sliced
in half at each seam, which is the same defect as the decal problem wearing a
different hat. Model-space noise is continuous over the whole animal.

Everything is seeded from (species, overlay id), so output is a pure function
of its inputs and the tool stays idempotent.
"""
import zlib

import numpy as np

from creature_anatomy_maps import build as build_anatomy


def _hex_to_rgb(value):
    value = value.lstrip("#")
    return np.array([int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


def _smoothstep(edge0, edge1, x):
    if abs(edge1 - edge0) < 1e-9:
        return (x >= edge1).astype(np.float64)
    t = np.clip((x - edge0) / (edge1 - edge0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


def _value_noise_3d(unit, freq, seed, octaves=3):
    """Fractal value noise sampled at `unit` (H, W, 3) model-space coords.

    A random lattice trilinearly interpolated, summed over octaves at halving
    amplitude. Deliberately not gradient noise: value noise's slightly blobby
    character is what moss and lichen actually look like, and it is a dozen
    lines instead of a dependency.
    """
    total = np.zeros(unit.shape[:2])
    amplitude = 1.0
    norm = 0.0
    rng = np.random.default_rng(seed)
    for octave in range(octaves):
        n = max(2, int(round(freq * (2 ** octave))) + 1)
        lattice = rng.random((n, n, n))
        coord = np.clip(unit, 0.0, 1.0) * (n - 1)
        i0 = np.floor(coord).astype(int)
        i0 = np.minimum(i0, n - 2)
        frac = coord - i0
        # Smoothstep the interpolant so octave boundaries do not show as a grid.
        frac = frac * frac * (3.0 - 2.0 * frac)
        x0, y0, z0 = i0[..., 0], i0[..., 1], i0[..., 2]
        fx, fy, fz = frac[..., 0], frac[..., 1], frac[..., 2]
        c000 = lattice[x0, y0, z0]
        c100 = lattice[x0 + 1, y0, z0]
        c010 = lattice[x0, y0 + 1, z0]
        c110 = lattice[x0 + 1, y0 + 1, z0]
        c001 = lattice[x0, y0, z0 + 1]
        c101 = lattice[x0 + 1, y0, z0 + 1]
        c011 = lattice[x0, y0 + 1, z0 + 1]
        c111 = lattice[x0 + 1, y0 + 1, z0 + 1]
        c00 = c000 * (1 - fx) + c100 * fx
        c10 = c010 * (1 - fx) + c110 * fx
        c01 = c001 * (1 - fx) + c101 * fx
        c11 = c011 * (1 - fx) + c111 * fx
        c0 = c00 * (1 - fy) + c10 * fy
        c1 = c01 * (1 - fy) + c11 * fy
        total += amplitude * (c0 * (1 - fz) + c1 * fz)
        norm += amplitude
        amplitude *= 0.5
    return total / max(norm, 1e-9)


def anatomy_mask(where, anatomy, softness):
    """Soft 0..1 mask from anatomy predicates.

    Every predicate is a smoothstep rather than a hard cut, over a band of
    `softness` in the predicate's own units, so patches fade in at their
    boundary. `up_min` reads the surface normal's Y -- what makes moss sit on a
    turtle's shell top and not under its belly.
    """
    unit = anatomy["unit"]
    nrm = anatomy["nrm"]
    radial = anatomy["radial"]
    mask = anatomy["valid"].astype(np.float64)

    checks = (
        ("y_min", unit[..., 1], +1), ("y_max", unit[..., 1], -1),
        ("x_min", unit[..., 0], +1), ("x_max", unit[..., 0], -1),
        ("z_min", unit[..., 2], +1), ("z_max", unit[..., 2], -1),
        ("radial_min", radial, +1), ("radial_max", radial, -1),
        ("up_min", nrm[..., 1], +1), ("up_max", nrm[..., 1], -1),
    )
    for key, channel, sign in checks:
        if key not in where:
            continue
        threshold = float(where[key])
        if sign > 0:
            mask *= _smoothstep(threshold - softness, threshold + softness, channel)
        else:
            mask *= 1.0 - _smoothstep(threshold - softness, threshold + softness, channel)

    # `lateral` selects a symmetric pair of sides (both ears, both wings)
    # rather than one, by folding x about the model's centre line first.
    if "lateral_min" in where:
        fold = np.abs(unit[..., 0] - 0.5) * 2.0
        mask *= _smoothstep(float(where["lateral_min"]) - softness,
                            float(where["lateral_min"]) + softness, fold)
    return mask


def _rgb_to_hsv(arr):
    r, g, b = arr[..., 0], arr[..., 1], arr[..., 2]
    maxc = np.max(arr[..., :3], axis=-1)
    minc = np.min(arr[..., :3], axis=-1)
    v = maxc
    delta = maxc - minc
    s = np.where(maxc > 0, delta / np.maximum(maxc, 1e-9), 0.0)
    h = np.zeros_like(maxc)
    mask = delta > 1e-9
    rc = np.where(mask, (maxc - r) / np.maximum(delta, 1e-9), 0)
    gc = np.where(mask, (maxc - g) / np.maximum(delta, 1e-9), 0)
    bc = np.where(mask, (maxc - b) / np.maximum(delta, 1e-9), 0)
    h = np.where((maxc == r) & mask, bc - gc, h)
    h = np.where((maxc == g) & mask, 2.0 + rc - bc, h)
    h = np.where((maxc == b) & mask, 4.0 + gc - rc, h)
    return (h / 6.0) % 1.0 * 360.0, s, v


def _hsv_to_rgb(h, s, v):
    h = (h % 360.0) / 60.0
    i = np.floor(h).astype(int) % 6
    f = h - np.floor(h)
    p = v * (1 - s)
    q = v * (1 - s * f)
    t = v * (1 - s * (1 - f))
    r = np.choose(i, [v, q, p, p, t, v])
    g = np.choose(i, [t, v, v, q, p, p])
    b = np.choose(i, [p, p, t, v, v, q])
    return np.stack([r, g, b], axis=-1)


def colour_mask(match, h, s, v):
    """0..1 mask from HSV bounds on the HOST texture.

    Overlays that pick out a feature the painter already drew -- an iris, a
    belly plate, a beak -- need colour as well as anatomy: "the head region" is
    most of a skull, "the saturated blue inside the head region" is an eye.
    Same predicate vocabulary as the colourway rules in
    tools/repaint_creature_textures.py, so one spec file reads consistently.
    """
    mask = np.ones_like(h)
    if "hue" in match:
        lo, hi = match["hue"]
        band = ((h >= lo) & (h <= hi)) if lo <= hi else ((h >= lo) | (h <= hi))
        mask = mask * band
    for key, channel, sign in (("sat_min", s, +1), ("sat_max", s, -1),
                               ("val_min", v, +1), ("val_max", v, -1)):
        if key not in match:
            continue
        threshold = float(match[key])
        mask = mask * (channel >= threshold if sign > 0 else channel <= threshold)
    return mask.astype(np.float64)


def _erode(mask, radius):
    """Binary-ish erosion of a soft mask, via PIL's min filter.

    Used to split a patch into interior and rim: `mask - erode(mask)` is the
    outer band, which is how an iris gets a limbal ring without anyone having
    to author one in UV space. PIL rather than scipy because this container has
    no scipy and the art tools are not worth a dependency for one morphology.
    """
    if radius < 1:
        return mask
    from PIL import Image as _Image, ImageFilter as _Filter
    img = _Image.fromarray((np.clip(mask, 0, 1) * 255).astype(np.uint8), "L")
    size = min(radius * 2 + 1, 9)
    img = img.filter(_Filter.MinFilter(size=size))
    return np.asarray(img).astype(np.float64) / 255.0


def apply_overlays(rgb, species, overlays, size):
    """Composite every overlay onto `rgb` (float 0..1, HxWx3, square, `size`).

    Returns (rgb, notes) where notes is a list of one line per overlay giving
    the share of the surface it actually covered -- the number that says
    whether an overlay landed at all, and the first thing to look at when a
    patch does not show up in a render.
    """
    if not overlays:
        return rgb, []
    # Several species ship a flat, near-empty emissive map a few pixels square.
    # Rasterising an anatomy map at that size produces a mask of nothing, and
    # asking for one evicts the real 1024 cache and forces it to be rebuilt on
    # the next texture -- so the whole roster pays a double rasterisation for a
    # composite that could never have landed. There is no identity layer to put
    # on an 8-pixel texture; skip it.
    if size < 256:
        return rgb, ["%s: emissive map is %dpx -- too small to carry an overlay"
                     % (species, size)]
    anatomy, _cache = build_anatomy(species, size=size)
    if int(anatomy["size"]) != size:
        anatomy, _cache = build_anatomy(species, size=size, force=True)

    notes = []
    for overlay in overlays:
        ident = str(overlay.get("id", "overlay"))
        softness = float(overlay.get("softness", 0.12))
        mask = anatomy_mask(overlay.get("where", {}), anatomy, softness)
        if mask.max() <= 0.0:
            notes.append("%s/%s: covered nothing -- check the `where` block" % (species, ident))
            continue

        host_h, host_s, host_v = _rgb_to_hsv(rgb)
        if overlay.get("match"):
            mask = mask * colour_mask(overlay["match"], host_h, host_s, host_v)
            if mask.max() <= 0.0:
                notes.append("%s/%s: the `match` block found no such colour in the region"
                             % (species, ident))
                continue

        # `ring` keeps only the outer band of the patch -- what turns a matched
        # iris into a limbal ring around it rather than a flat repaint of the
        # whole eye.
        ring = int(overlay.get("ring", 0) or 0)
        if ring > 0:
            mask = np.clip(mask - _erode(mask, ring), 0.0, 1.0)
            if mask.max() <= 0.0:
                notes.append("%s/%s: the region is thinner than its own ring" % (species, ident))
                continue

        # Clumping. 1.0 fills the predicate region solid; below that the noise
        # breaks it into a patchy carpet. `coverage` is a threshold on the
        # noise field's own distribution over the WHOLE map, not over the
        # masked region -- so it is a density dial rather than a promise about
        # the resulting area, and the coverage figure each overlay prints (the
        # share of the model's surface it actually painted) is the number to
        # judge by. Measured over the roster: 0.3 gives a sparse scatter of
        # clumps, 0.6 a broken carpet with the host surface still showing.
        grain = float(overlay.get("grain", 4.0))
        coverage = float(overlay.get("coverage", 1.0))
        if coverage < 0.999 and grain > 0.0:
            # T1-VARIANTS 2026-08-30 fix: the builtin `hash()` on a
            # tuple-of-strings is salted per PROCESS (PYTHONHASHSEED), not
            # per value -- this module's own docstring promises "output is a
            # pure function of its inputs", and running the SAME spec twice
            # in a row without changing anything produced a different clump
            # pattern and a different printed coverage number each time
            # (confirmed directly: two back-to-back runs of
            # tools/generate_aspect_variant_textures.py, which calls this
            # path via repaint()'s own overlay compositing, disagreed by
            # several percentage points of coverage on the exact same spec).
            # zlib.crc32 over the encoded value is deterministic across
            # processes and interpreter runs.
            seed = zlib.crc32(("%s|%s" % (species, ident)).encode("utf-8"))
            noise = _value_noise_3d(anatomy["unit"], grain, seed,
                                    int(overlay.get("octaves", 3)))
            cut = float(np.quantile(noise, 1.0 - coverage))
            fade = float(overlay.get("clump_softness", 0.12))
            mask = mask * _smoothstep(cut - fade, cut + fade, noise)

        alpha = np.clip(mask * float(overlay.get("strength", 1.0)), 0.0, 1.0)
        if alpha.max() <= 0.001:
            notes.append("%s/%s: covered nothing after clumping" % (species, ident))
            continue

        h, s, v = _rgb_to_hsv(rgb)
        colour = _hex_to_rgb(str(overlay.get("color", "#4f8f31")))
        ch, cs, cv = (float(c.ravel()[0]) for c in _rgb_to_hsv(colour.reshape(1, 1, 3)))
        mode = str(overlay.get("mode", "grow"))

        if mode == "shade":
            # No new colour at all: the region's OWN paint, pushed. This is the
            # one roster pass -- capping an anime iris's saturation, deepening a
            # naturalist's eye socket so a face can be found at thumbnail size,
            # flattening the contrast of a belly's scallop grid so it stops
            # reading as fishnet. `detail` below 1 pulls local contrast toward
            # the region mean, which is the actual fix for a moire-ing surface;
            # a blur would just smear it at the same frequency.
            detail = float(overlay.get("detail", 1.0))
            pushed_v = v
            if detail != 1.0:
                weight = np.clip(mask, 0, 1)
                mean_v = float((v * weight).sum() / max(weight.sum(), 1e-9))
                pushed_v = mean_v + (v - mean_v) * detail
            new_h = h
            new_s = np.clip(s * float(overlay.get("sat_scale", 1.0)), 0, 1)
            if overlay.get("set_sat") is not None:
                new_s = np.full_like(s, float(overlay["set_sat"]))
            new_v = np.clip(pushed_v * float(overlay.get("val_scale", 1.0)), 0, 1)
            if overlay.get("set_val") is not None:
                new_v = np.full_like(v, float(overlay["set_val"]))
        elif mode == "tint":
            # The animal's own material, another colour. Value untouched: that
            # is what makes a recolour follow the feathers/fur the painter drew
            # instead of covering them.
            new_h = ch
            new_s = np.clip(np.maximum(s, cs * float(overlay.get("sat_floor", 0.85))), 0, 1)
            new_v = np.clip(v * float(overlay.get("val_scale", 1.0)), 0, 1)
        else:
            # Growth. Its own two-tone ramp, but driven by the HOST surface's
            # local value so the moss creases where the body creases. `relief`
            # is how much of the host's detail survives; 0 would be a flat
            # sticker, 1 an unlit copy of the body in green.
            shade = _hex_to_rgb(str(overlay.get("shade", "#22491c")))
            _sh, _ss, shade_v = _rgb_to_hsv(shade.reshape(1, 1, 3))
            shade_v = float(shade_v.ravel()[0])
            relief = float(overlay.get("relief", 0.55))
            local = np.clip((v - float(np.mean(v))) * 2.0 + 0.5, 0.0, 1.0)
            ramp = shade_v + (cv - shade_v) * local
            new_h = ch
            new_s = np.clip(cs * (0.75 + 0.35 * local), 0, 1)
            new_v = np.clip(cv * (1.0 - relief) + ramp * relief, 0.02, 1.0)

        # Hue is an angle: a straight lerp from 350 to 10 travels backwards
        # through the whole wheel and passes through every colour on the way.
        # Blend the two hues as unit vectors instead.
        target_h = new_h if isinstance(new_h, np.ndarray) else np.full_like(h, float(new_h))
        vec = (np.stack([np.cos(np.deg2rad(h)), np.sin(np.deg2rad(h))], -1)
               * (1.0 - alpha)[..., None]
               + np.stack([np.cos(np.deg2rad(target_h)), np.sin(np.deg2rad(target_h))], -1)
               * alpha[..., None])
        h = np.rad2deg(np.arctan2(vec[..., 1], vec[..., 0])) % 360.0
        s = s * (1 - alpha) + new_s * alpha
        v = v * (1 - alpha) + new_v * alpha
        rgb = _hsv_to_rgb(h, np.clip(s, 0, 1), np.clip(v, 0, 1))
        notes.append("%s/%s: %s over %.1f%% of the surface"
                     % (species, ident, mode, 100.0 * float(
                         (alpha > 0.25).sum()) / max(float(anatomy["valid"].sum()), 1.0)))
    return np.clip(rgb, 0, 1), notes
