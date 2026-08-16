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

Run from the repo root:  python3 tools/repaint_creature_textures.py [species...]
No args = every species present in the spec file. Idempotent -- output is a
pure function of (source texture, spec).

Species whose textures are embedded in the .glb rather than shipped as
sibling PNGs (bramblebun, mudsnout, trailpup, veridian as of OF28) are
handled by extracting the glb's embedded images first -- a .glb is a JSON
chunk plus a BIN chunk, and its images sit in the BIN at documented offsets.
Extraction writes `<species>_extracted_base_color.png` (etc.) next to the
glb, then the same repaint applies. creature_body.gd swaps textures via
material override either way, so the glb itself is NEVER modified (no new
meshes, no re-import churn).
"""
import json
import os
import struct
import sys

from PIL import Image
import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPEC_PATH = os.path.join(ROOT, "data", "creatures", "shiny_colourways.json")
CREATURES = os.path.join(ROOT, "assets", "creatures", "tetherbound")


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


def repaint(src_path, rules, dst_path):
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
    out = np.concatenate([rgb, arr[..., 3:4]], axis=-1)
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGBA").save(dst_path)
    return dst_path


def variant_path(src_path, suffix):
    stem, ext = os.path.splitext(src_path)
    return f"{stem}_{suffix}{ext}"


def main():
    spec = load_spec()
    wanted = sys.argv[1:] or sorted(spec.keys())
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
        for suffix, key in (("shiny", "rules"), ("vivid", "vivid_rules")):
            rules = spec[species].get(key)
            if not rules:
                continue
            done = {}
            for kind, src in textures.items():
                if src in done:  # emissive may share the base image
                    dst = done[src]
                else:
                    dst = repaint(src, rules, variant_path(src, suffix))
                    done[src] = dst
                print(f"{species}: {kind} -> {os.path.relpath(dst, ROOT)}")


if __name__ == "__main__":
    main()
