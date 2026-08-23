#!/usr/bin/env python3
"""OF28: generate shiny colourway textures by REPAINTING, not tinting.

Owner directive (2026-08-15, quoted in ralph/BACKLOG.md OF28): "the shinys
shouldn't be a tint. it should be repainting the character... if our newt is
blue, I want red. not blue with a red shade over it. for the white and black
striped badger maybe it becomes blue stripes."

A colour multiplier cannot turn blue into red -- it can only darken toward
black. So this tool loads each species' painted albedo (base_color) texture,
remaps colour REGIONS in HSV space per a per-species rule list
(data/creatures/shiny_colourways.json), and writes a checked-in
`*_base_color_shiny.png` sibling. The emissive texture is the SAME painted
image on these assets (self-lit look -- see creature_body.gd's variant-tint
comment for the NP2 history), so it gets the identical remap into
`*_emissive_shiny.png`; swapping albedo alone would be invisible.

Rules are region matches, not global shifts, so pattern survives repaint:
stripes stay stripes, they just change colour. Rule shape:

  {"match": {"hue": [150, 210],      # optional hue band, degrees, wraps
             "sat_min": 0.15,        # optional saturation floor 0..1
             "sat_max": 1.0,         # optional saturation ceiling
             "val_min": 0.0,         # optional value floor
             "val_max": 1.0},        # optional value ceiling
   "set_hue": 5,                     # optional absolute target hue (deg)
   "hue_shift": 0,                   # optional relative shift instead
   "set_sat": null, "sat_scale": 1.0,
   "set_val": null, "val_scale": 1.0}

First matching rule wins per pixel. Luminance/texture detail is preserved
because value is (by default) untouched -- that is what keeps the repaint
reading as the same painted surface in a new colourway rather than a flat
fill.

CREATURE-PRESENTATION (2026-08-23) adds a FINISH pass that runs after the
rules, because two blind critics ranked creature presentation a top-3 gap
against the Palworld bar and named three defects a hue remap alone cannot
reach:

  * high-frequency speckle that reads as dithering rather than as fur or
    feather (these are photoreal-ish Meshy albedos; every fleck survives into
    a 40-pixel creature as noise);
  * faces that cannot be found, because a rule that pushes a whole animal to
    one hue and one saturation flattens the value contrast the eyes and muzzle
    were carrying;
  * bodies painted inside the terrain's own hue band.

The finish block therefore despeckles, quantises value into bounded zones,
re-stamps the darkest features so eyes and outlines survive the smoothing, and
downsamples. Per species, or inherited from the spec's `_finish_default`:

  "finish": {"despeckle": 5,          # median radius, px, at 2048
             "posterize": 6,          # value bands (0 = off)
             "posterize_strength": 0.6,
             "feature_percentile": 3, # darkest N% of the SOURCE are features
             "feature_max_val": 0.22, # ...but never brighter than this
             "feature_set_val": 0.05, # re-stamped this dark after smoothing
             "feature_sat_scale": 0.4,
             "sat_ceiling": 0.8,
             "output_size": 1024}

`"finish": {}` for a species opts out of every default.

The tool also prints, per output, the share of chromatic pixels sitting in the
meadow's own hue band (TERRAIN_HUE_BAND). That number is the numeric half of
"a creature on grass must separate at 30% thumbnail size": a ground-dwelling
species whose body is 60% grass-hue is camouflage, however good the portrait
looks on a neutral card.

Run from the repo root:  python3 tools/repaint_creature_textures.py [species...]
No args = every species present in the spec file. Idempotent -- output is a
pure function of (source texture, spec). `--only vivid` (or `--only shiny`)
regenerates one colourway, which is how a presentation pass avoids rewriting
110MB of rare-variant textures nobody's change touched.

Species whose textures are embedded in the .glb rather than shipped as
sibling PNGs (bramblebun, mudsnout, trailpup, veridian as of OF28) are
handled by extracting the glb's embedded images first -- a .glb is a JSON
chunk plus a BIN chunk, and its images sit in the BIN at documented offsets.
Extraction writes `<species>_extracted_base_color.png` (etc.) next to the
glb, then the same repaint applies. creature_body.gd swaps textures via
material override either way, so the glb itself is NEVER modified (no new
meshes, no re-import churn).
"""
import collections
import json
import os
import struct
import sys

from PIL import Image, ImageFilter
import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from creature_overlays import apply_overlays  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "data", "creatures", "shiny_colourways.json")
CREATURES = os.path.join(ROOT, "assets", "creatures", "tetherbound")

## The meadow's own hue, measured off shipped frames rather than off
## palette.json's board value: the grass in `shots/band3/*.png` sits at hue
## 134-155 and the canopy at 98. A creature body inside this band separates
## from the ground by value alone, and value is the first thing distance,
## shadow and overcast weather take away.
TERRAIN_HUE_BAND = (80.0, 175.0)


def load_spec():
    with open(SPEC_PATH) as f:
        spec = json.load(f)
    return {k: v for k, v in spec.get("species", {}).items() if not k.startswith("_")}


def find_textures(species):
    """Return {kind: path} for kind in (base_color, emissive). Extracts from
    the glb when no sibling PNG exists."""
    models = os.path.join(CREATURES, species, "models")
    out = {}
    for kind in ("base_color", "emissive"):
        direct = [f for f in os.listdir(models)
                  if f.endswith(f"{kind}.png") and "_shiny" not in f
                  and "_vivid" not in f and "extracted" not in f]
        if direct:
            out[kind] = os.path.join(models, sorted(direct)[0])
    if out:
        return out
    return extract_from_glb(species, models)


def extract_from_glb(species, models):
    """Pull embedded images out of the species glb. Heuristic: the largest
    image is the albedo; an image whose name/mime mentions emissive wins that
    slot, else the albedo doubles as the emissive source (matching how these
    assets use one painted map for both)."""
    glbs = [f for f in os.listdir(models) if f.endswith(".glb")]
    if not glbs:
        raise SystemExit(f"{species}: no textures and no glb found")
    path = os.path.join(models, glbs[0])
    with open(path, "rb") as f:
        data = f.read()
    magic, _version, _length = struct.unpack_from("<III", data, 0)
    assert magic == 0x46546C67, f"{path} is not a glb"
    offset = 12
    gltf = None
    binary = None
    while offset < len(data):
        chunk_len, chunk_type = struct.unpack_from("<II", data, offset)
        chunk = data[offset + 8: offset + 8 + chunk_len]
        if chunk_type == 0x4E4F534A:
            gltf = json.loads(chunk)
        elif chunk_type == 0x004E4942:
            binary = chunk
        offset += 8 + chunk_len
    images = []
    for image in gltf.get("images", []):
        view = gltf["bufferViews"][image["bufferView"]]
        start = view.get("byteOffset", 0)
        blob = binary[start: start + view["byteLength"]]
        images.append((image.get("name", ""), blob))
    if not images:
        raise SystemExit(f"{species}: glb has no embedded images")
    # Materials tell us which texture index is emissive, when present.
    emissive_index = None
    base_index = None
    for mat in gltf.get("materials", []):
        pbr = mat.get("pbrMetallicRoughness", {})
        if "baseColorTexture" in pbr:
            base_index = gltf["textures"][pbr["baseColorTexture"]["index"]].get("source")
        if "emissiveTexture" in mat:
            emissive_index = gltf["textures"][mat["emissiveTexture"]["index"]].get("source")
    if base_index is None:
        base_index = max(range(len(images)), key=lambda i: len(images[i][1]))
    out = {}
    base_path = os.path.join(models, f"{species}_extracted_base_color.png")
    with open(base_path, "wb") as f:
        f.write(images[base_index][1])
    out["base_color"] = base_path
    if emissive_index is not None and emissive_index != base_index:
        em_path = os.path.join(models, f"{species}_extracted_emissive.png")
        with open(em_path, "wb") as f:
            f.write(images[emissive_index][1])
        out["emissive"] = em_path
    else:
        out["emissive"] = base_path
    return out


def rgb_to_hsv(arr):
    """Vectorised RGB[0..1] -> HSV (h in degrees)."""
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
    h = (h / 6.0) % 1.0 * 360.0
    return h, s, v


def hsv_to_rgb(h, s, v):
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


def rule_mask(rule, h, s, v):
    match = rule.get("match", {})
    mask = np.ones_like(h, dtype=bool)
    if "hue" in match:
        lo, hi = match["hue"]
        if lo <= hi:
            mask &= (h >= lo) & (h <= hi)
        else:  # wrapping band, e.g. [330, 30]
            mask &= (h >= lo) | (h <= hi)
    if "sat_min" in match:
        mask &= s >= match["sat_min"]
    if "sat_max" in match:
        mask &= s <= match["sat_max"]
    if "val_min" in match:
        mask &= v >= match["val_min"]
    if "val_max" in match:
        mask &= v <= match["val_max"]
    return mask


def finish_pass(rgb, source_v, finish):
    """Speckle -> zones, and the darkest features re-stamped on top.

    `rgb` is the repainted image, float 0..1, HxWx3. `source_v` is the value
    channel of the ORIGINAL texture -- features are found there rather than in
    the repaint, because a rule that sets an absolute value would otherwise
    erase its own species' eyes before this pass could protect them.
    """
    if not finish:
        return rgb

    height, width, _ = rgb.shape
    scale = width / 2048.0

    # Which pixels are features: the darkest N% of the source, but never
    # anything the eye would read as merely shaded. A percentile rather than a
    # fixed threshold because a charcoal badger and a cream rabbit do not share
    # a "dark" -- a fixed cut turned the badger entirely into eye.
    feature = None
    pct = float(finish.get("feature_percentile", 0) or 0)
    if pct > 0:
        cut = min(float(np.percentile(source_v, pct)),
                  float(finish.get("feature_max_val", 0.22)))
        feature = source_v <= cut

    # Despeckle. A median filter, not a blur: a blur smears the flecks into
    # muddy haze at the same frequency, where a median deletes anything
    # smaller than its window and leaves painted edges where they were.
    radius = int(round(float(finish.get("despeckle", 0)) * scale))
    if radius >= 1:
        size = radius * 2 + 1
        img = Image.fromarray((np.clip(rgb, 0, 1) * 255).astype(np.uint8), "RGB")
        img = img.filter(ImageFilter.MedianFilter(size=min(size, 9)))
        rgb = np.asarray(img).astype(np.float64) / 255.0

    h, s, v = rgb_to_hsv(rgb)

    # Bounded colour zones. Quantising VALUE (never hue) is what turns a
    # photoreal gradient into the flat banded read the reference frames have,
    # while leaving the painted colour regions exactly where the artist put
    # them. Blended rather than hard-applied so the result is a stylised
    # surface, not a topographic map.
    bands = int(finish.get("posterize", 0) or 0)
    if bands > 1:
        strength = float(finish.get("posterize_strength", 0.65))
        quantised = np.round(v * (bands - 1)) / (bands - 1)
        v = v * (1.0 - strength) + quantised * strength

    ceiling = finish.get("sat_ceiling")
    if ceiling is not None:
        s = np.minimum(s, float(ceiling))

    if feature is not None:
        v = np.where(feature, float(finish.get("feature_set_val", 0.05)), v)
        s = np.where(feature, s * float(finish.get("feature_sat_scale", 0.4)), s)

    return hsv_to_rgb(h, np.clip(s, 0, 1), np.clip(v, 0, 1))


def terrain_share(rgb):
    """Share of chromatic pixels sitting in the meadow's own hue band."""
    h, s, _v = rgb_to_hsv(rgb)
    chromatic = s > 0.18
    if not chromatic.any():
        return 0.0
    lo, hi = TERRAIN_HUE_BAND
    return float(((h >= lo) & (h <= hi) & chromatic).sum() / chromatic.sum())


def repaint(src_path, rules, dst_path, finish=None, species=None, overlays=None):
    img = Image.open(src_path).convert("RGBA")
    arr = np.asarray(img).astype(np.float64) / 255.0
    h, s, v = rgb_to_hsv(arr)
    new_h, new_s, new_v = h.copy(), s.copy(), v.copy()
    claimed = np.zeros_like(h, dtype=bool)
    for rule in rules:
        mask = rule_mask(rule, h, s, v) & ~claimed
        claimed |= mask
        if "set_hue" in rule:
            new_h = np.where(mask, float(rule["set_hue"]), new_h)
        if "hue_shift" in rule:
            new_h = np.where(mask, (h + float(rule["hue_shift"])) % 360.0, new_h)
        if rule.get("set_sat") is not None:
            new_s = np.where(mask, float(rule["set_sat"]), new_s)
        if "sat_scale" in rule:
            new_s = np.where(mask, np.clip(s * float(rule["sat_scale"]), 0, 1), new_s)
        if rule.get("set_val") is not None:
            new_v = np.where(mask, float(rule["set_val"]), new_v)
        if "val_scale" in rule:
            new_v = np.where(mask, np.clip(v * float(rule["val_scale"]), 0, 1), new_v)
    rgb = hsv_to_rgb(new_h, np.clip(new_s, 0, 1), np.clip(new_v, 0, 1))
    rgb = finish_pass(rgb, v, finish or {})
    out = np.concatenate([np.clip(rgb, 0, 1), arr[..., 3:4]], axis=-1)
    image = Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA")

    # Downsample BEFORE the overlays, not after. It is also the cheapest
    # despeckle there is -- four source texels averaged into one -- and it takes
    # the checked-in colourway set from ~110MB to a fraction of that, which
    # matters because every one of these is a tracked binary in a repo that
    # already carries 619MB of art. Overlays then composite at the shipped
    # resolution against an anatomy map rasterised to match, so a leaf edge is
    # as crisp as the output allows instead of being softened by a resample it
    # never needed to survive.
    size = int((finish or {}).get("output_size", 0) or 0)
    if size and size < image.width:
        image = image.resize((size, size), Image.LANCZOS)

    notes = []
    if overlays and species:
        arr2 = np.asarray(image).astype(np.float64) / 255.0
        painted, notes = apply_overlays(arr2[..., :3], species, overlays, image.width)
        merged = np.concatenate([painted, arr2[..., 3:4]], axis=-1)
        image = Image.fromarray((np.clip(merged, 0, 1) * 255).astype(np.uint8), "RGBA")

    share = terrain_share(np.asarray(image).astype(np.float64)[..., :3] / 255.0)
    image.save(dst_path, optimize=True)
    return dst_path, share, notes


def variant_path(src_path, suffix):
    stem, ext = os.path.splitext(src_path)
    return f"{stem}_{suffix}{ext}"


def main():
    spec = load_spec()
    with open(SPEC_PATH) as f:
        default_finish = json.load(f).get("_finish_default", {})
    argv = list(sys.argv[1:])
    only = None
    if "--only" in argv:
        index = argv.index("--only")
        only = argv[index + 1]
        del argv[index:index + 2]
    wanted = argv or sorted(spec.keys())
    for species in wanted:
        if species not in spec:
            print(f"skip {species}: no colourway in spec")
            continue
        textures = find_textures(species)
        # Two colourways per species: `rules` -> *_shiny (the rare variant) and
        # `vivid_rules` -> *_vivid (OF28's other half, the ordinary creature
        # repainted off naturalistic mud toward the mystical palette the owner
        # asked for). A species with no vivid_rules simply keeps its shipped
        # base texture.
        finish = dict(default_finish)
        if "finish" in spec[species]:
            override = spec[species]["finish"]
            finish = dict(finish, **override) if override else {}
        # Three colourways per species: `rules` -> *_shiny (the rare variant),
        # `vivid_rules` -> *_vivid (the ORDINARY creature, OF28's repaint off
        # naturalistic mud toward the board's palette) and, new in
        # CREATURE-IDENTITY-2, `alpha_rules` -> *_alpha, the cluster leader
        # WILD-ECOLOGY already spawns bigger and stronger but which looked
        # exactly like its neighbours. An alpha with no rules of its own
        # inherits the vivid ones, so a species can declare only the overlay
        # difference (heavier plates, storm-blue tips) and nothing else.
        for suffix, key in (("shiny", "rules"), ("vivid", "vivid_rules"),
                            ("alpha", "alpha_rules")):
            if only and suffix != only:
                continue
            rules = spec[species].get(key)
            if not rules and suffix == "alpha" and spec[species].get("overlays_alpha"):
                rules = spec[species].get("vivid_rules")
            if not rules:
                continue
            # The identity layer (board: leaf ears, moss carpets, greened
            # antler tips) belongs to the ANIMAL, not to one colourway, so every
            # colourway gets it; `overlays_<suffix>` then adds or replaces what
            # is specific to that variant.
            #
            # "or replaces" is what this comment always claimed and what the
            # concatenation below never did: a variant entry reusing a base
            # entry's `id` REPLACES it, and only a genuinely new id appends.
            # Without this a rare variant that recolours the animal's existing
            # growth gets BOTH -- trailpup's shiny came back carrying green moss
            # AND orange moss at once, because `ember_growth` appended alongside
            # `moss_saddle` instead of standing in for it. Matching ids also
            # means the replacement inherits the seed, since creature_overlays
            # seeds its noise from (species, id): the rare's growth then lands on
            # exactly the patches the ordinary's does, which is what makes it
            # read as the same plant in a different season rather than as a
            # second, differently-shaped plant.
            overlays = collections.OrderedDict(
                (o["id"], o) for o in spec[species].get("overlays", []))
            for entry in spec[species].get("overlays_%s" % suffix, []):
                overlays[entry["id"]] = entry
            overlays = list(overlays.values())
            done = {}
            for kind, src in textures.items():
                if src in done:  # emissive may share the base image
                    dst, share = done[src]
                else:
                    # A species whose emissive is its OWN image (veridian) can
                    # carry overlays that exist only in the glow -- which is how
                    # the legendary's crown separates from a green meadow at a
                    # hundred metres without repainting its hide green again
                    # (BACKLOG VERIDIAN-HIDE). Where emissive and albedo are the
                    # same file this list is simply never reached.
                    extra = spec[species].get("overlays_emissive", []) \
                        if kind == "emissive" else []
                    dst, share, notes = repaint(
                        src, rules, variant_path(src, suffix), finish,
                        species=species, overlays=overlays + list(extra))
                    done[src] = (dst, share)
                    for note in notes:
                        print("   overlay: %s" % note)
                print("%s: %s -> %s (%.0f%% of chromatic pixels in the terrain hue band)"
                      % (species, kind, os.path.relpath(dst, ROOT), share * 100))


if __name__ == "__main__":
    main()
