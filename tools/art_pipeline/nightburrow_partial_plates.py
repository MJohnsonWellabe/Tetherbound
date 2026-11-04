#!/usr/bin/env python3
"""F36#56 Nightburrow: partial plates (flag `creatures_ralph_nightburrow_partial_plates`, OFF).

Judges (ralph/reports/LANES/CREATURES-RALPH/v1/b7 and v1/b15): the yellow and
purple plates cover almost the whole back and sides -- close to the full-body
overgrowth the owner's 1 Nov creature rule forbids -- a busy surface at small
size, and the plates swallow the face and outline. The rule allows PARTIAL
natural plates on the spine, head or shoulders.

This repaints the live Nightburrow coat (the aspect repaint after the enabled
`creatures_f36_coat_lift_2` grade) so that:
  * stone plates stay only along the spine and over the shoulders;
  * every other plate, and all of the yellow moss bed under the plates,
    becomes the creature's own brown fur (hue/saturation of the coat's fur,
    value carried from the texel's own shading so the fur keeps a clump
    texture, with a little model-space value noise so it is not a flat fill);
  * the head and face are not touched.

Plates are found by 3D anatomy, never by UV position (the islands are
scattered): tools/creature_anatomy_maps.py rasterises the mesh's own UVs into
per-texel model-space position, stone texels inside the back zone are grouped
into individual plates by 3D connectivity, and each plate is kept or removed
as a whole by its centroid, so no plate is cut in half.

Writes a NEW file beside the shipped textures; nothing shipped is overwritten:
  creature_burrowback_nat1024_Image_0_nightburrow_partial_plates.png

  python3 tools/art_pipeline/nightburrow_partial_plates.py [--debug <png>]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
sys.path.insert(0, os.path.join(ROOT, "tools"))
from creature_anatomy_maps import build as build_anatomy  # noqa: E402
from creature_overlays import _rgb_to_hsv, _value_noise_3d, _smoothstep  # noqa: E402

SOURCE = "burrowback/candidate_nat1024"
MODELS = os.path.join(ROOT, "assets", "creatures", "tetherbound", SOURCE, "models")
LIVE = os.path.join(MODELS, "creature_burrowback_nat1024_Image_0_nightburrow_coat_lift.png")
OUT = os.path.join(MODELS, "creature_burrowback_nat1024_Image_0_nightburrow_partial_plates.png")
## The live violet glow map (aspect emissive) and its trimmed sibling: glow
## that sat in the moss between the removed plates would float on bare fur,
## so inside the back zone it survives only next to the kept plates (cracks
## along the spine row); the eyes, face mask and tail glow are untouched.
GLOW = os.path.join(MODELS, "creature_burrowback_nat1024_Image_0_emissive_nightburrow.png")
GLOW_OUT = os.path.join(MODELS, "creature_burrowback_nat1024_Image_0_emissive_nightburrow_partial_plates.png")
GLOW_NEAR_KEPT_PX = 8
## Repainted fur: a little darker than the coat median (a lit flat plate top
## otherwise reads lighter than the fur around it), fine stretched strokes,
## and a share of the coat's own charcoal patches (CHARCOAL = h, s, v, the
## coat's dark-marking median measured on the live texture).
FUR_VALUE_SCALE = 0.88
STROKE_STRETCH = 0.35
STROKE_FREQ = 38.0
STROKE_AMPLITUDE = 0.22
PATCH_FREQ = 5.0
PATCH_CUT = 0.62
CHARCOAL = (264.0, 0.06, 0.20)
## Texels of a removed plate's footprint that are not stone (its dark crack
## glyphs and edge shadow) are repainted too, out to this many texels.
FOOTPRINT_PX = 3

## Back zone (unit model box: y up, z fore/aft with the head at z = 1). The
## plate shell sits on the upper body between the hips and the neck; the head
## (z > 0.78, which takes in the ears and the grey cheek stripes) and the
## tail are outside it and never repainted.
ZONE = {"y_min": 0.50, "z_min": 0.08, "z_max": 0.78}
## The nape strip between the ears (ears sit at lateral 0.50 and beyond).
NAPE = {"y_min": 0.75, "z_max": 0.83, "lateral_max": 0.30}
NAPE_CRUMBS = {"z_min": 0.72, "y_min": 0.70, "lateral_max": 0.45}
## Stone: grey (low saturation) texels; moss: the yellow-olive bed.
STONE_SAT_MAX = 0.22
STONE_VAL_MIN = 0.25
MOSS_HUE = (40.0, 100.0)
MOSS_SAT_MIN = 0.25
## Plate grouping: model-space voxel edge in metres.
VOXEL_M = 0.015
MIN_PLATE_TEXELS = 40
## A kept plate is a real stone (the smallest is about 1,300 texels at 1024);
## anything under this is crust or crumbs and is repainted with the bed.
KEEP_MIN_TEXELS = 600
## Plates kept: the spine row (centroid within SPINE_LATERAL of the midline,
## lateral = |x - 0.5| * 2, from SPINE_Z_MIN forward), plus the pair of
## plates on top of the shoulders (centroid z >= SHOULDER_Z_MIN, lateral under
## SHOULDER_LATERAL and high on the body). Measured on this mesh (1024 map,
## 1.5 cm voxels): the spine row is one connected chain at lateral 0.10,
## z 0.36-0.75; the shoulder pair sits at z 0.67-0.68, lateral 0.46/0.58,
## height 0.81-0.84. The flank rows (lateral 0.45-0.77 further back) and the
## hip plates (z 0.31-0.34) are removed.
SPINE_LATERAL = 0.20
SPINE_Z_MIN = 0.30
## Crumbs at the nape (centroids z 0.77-0.79, a few hundred texels each) read
## as crusty debris beside the ears, not as plates; they go.
SPINE_Z_MAX = 0.76
SHOULDER_Z_MIN = 0.62
SHOULDER_LATERAL = 0.62
SHOULDER_Y_MIN = 0.78
## A kept plate keeps a thin stone rim around its texels (texel dilation), so
## its edge is not repainted brown.
KEEP_DILATE_PX = 2


def _dilate(mask, radius):
    out = mask.copy()
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            if dx * dx + dy * dy > radius * radius:
                continue
            out |= np.roll(np.roll(mask, dy, axis=0), dx, axis=1)
    return out


def _label_points(cells):
    """26-connected components of occupied voxel cells ((N, 3) ints).

    Union-find over the unique occupied cells; returns one label per input row.
    """
    uniq, inverse = np.unique(cells, axis=0, return_inverse=True)
    inverse = inverse.ravel()
    span = uniq.max(axis=0) + 3
    keys = ((uniq[:, 0] + 1) * span[1] + (uniq[:, 1] + 1)) * span[2] + (uniq[:, 2] + 1)
    order = np.argsort(keys)
    sorted_keys = keys[order]
    parent = np.arange(len(uniq))

    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]
            i = parent[i]
        return i

    for dx in (-1, 0, 1):
        for dy in (-1, 0, 1):
            for dz in (-1, 0, 1):
                if (dx, dy, dz) <= (0, 0, 0):
                    continue
                nk = ((uniq[:, 0] + 1 + dx) * span[1] + (uniq[:, 1] + 1 + dy)) * span[2] + (uniq[:, 2] + 1 + dz)
                pos = np.searchsorted(sorted_keys, nk)
                pos = np.minimum(pos, len(sorted_keys) - 1)
                hit = sorted_keys[pos] == nk
                for a, b in zip(np.nonzero(hit)[0], order[pos[hit]]):
                    ra, rb = find(a), find(b)
                    if ra != rb:
                        parent[max(ra, rb)] = min(ra, rb)
    roots = np.array([find(i) for i in range(len(uniq))])
    return roots[inverse] + 1


def build(debug_path=""):
    anatomy, _ = build_anatomy(SOURCE, size=1024)
    unit, valid = anatomy["unit"], anatomy["valid"]
    live = np.asarray(Image.open(LIVE).convert("RGBA")).astype(np.float64) / 255.0
    rgb = live[..., :3]
    h, s, v = _rgb_to_hsv(rgb)

    lateral = np.abs(unit[..., 0] - 0.5) * 2.0
    zone = (valid & (unit[..., 1] > ZONE["y_min"]) & (unit[..., 2] > ZONE["z_min"])
            & (unit[..., 2] < ZONE["z_max"]))
    # The nape: the moss bed runs on up the top of the neck between the ears.
    zone |= (valid & (unit[..., 2] < NAPE["z_max"]) & (unit[..., 2] > ZONE["z_min"])
             & (unit[..., 1] > NAPE["y_min"]) & (lateral < NAPE["lateral_max"]))
    stone = zone & (s < STONE_SAT_MAX) & (v > STONE_VAL_MIN)
    moss = zone & (h >= MOSS_HUE[0]) & (h < MOSS_HUE[1]) & (s > MOSS_SAT_MIN)
    fur = valid & (h < 40.0) & (s >= STONE_SAT_MAX) & ~zone

    # Group stone texels into plates by 3D connectivity.
    gltf_extent = _model_extent()
    pos_m = unit * gltf_extent
    grid = np.floor(pos_m / VOXEL_M).astype(np.int64)
    texel_label = np.zeros(valid.shape, dtype=np.int64)
    texel_label[stone] = _label_points(grid[stone])

    keep = np.zeros(valid.shape, dtype=bool)
    plates_total, plates_kept = 0, 0
    for lab in np.unique(texel_label[stone]):
        sel = texel_label == lab
        n = int(sel.sum())
        if n < MIN_PLATE_TEXELS:
            continue
        plates_total += 1
        cz = float(unit[..., 2][sel].mean())
        cl = float(lateral[sel].mean())
        cy = float(unit[..., 1][sel].mean())
        spine = cl < SPINE_LATERAL and SPINE_Z_MIN <= cz <= SPINE_Z_MAX
        shoulder = cz >= SHOULDER_Z_MIN and cl < SHOULDER_LATERAL and cy >= SHOULDER_Y_MIN
        if (spine or shoulder) and n >= KEEP_MIN_TEXELS:
            # The spine row is one connected chain that runs on into the
            # nape's crumbs; those texels (z past SPINE_Z_MAX) are trimmed.
            if spine and not shoulder:
                sel = sel & (unit[..., 2] <= SPINE_Z_MAX)
            keep |= sel
            plates_kept += 1
    kept_stone = keep.copy()
    keep = _dilate(keep, KEEP_DILATE_PX) & zone
    removed = stone & ~keep

    # Removed plates and the whole moss bed become fur. Dark charcoal fur
    # (grey but below STONE_VAL_MIN) is the coat's own marking and stays.
    footprint = _dilate(removed, FOOTPRINT_PX) & zone & ~keep & (s < STONE_SAT_MAX)
    # The nape carries pale tan crumbs (the moss bed's crust: hue 29-41,
    # saturation 0.2-0.42, value 0.46-0.56) that read as debris by the ears.
    crumbs = (valid & (unit[..., 2] > NAPE_CRUMBS["z_min"]) & (unit[..., 2] < NAPE["z_max"])
              & (unit[..., 1] > NAPE_CRUMBS["y_min"]) & (lateral < NAPE_CRUMBS["lateral_max"])
              & (h >= 25.0) & (h < 50.0) & (s >= 0.18) & (s < 0.45) & (v > 0.42))
    repaint = (zone & ~keep & (stone | moss | footprint)) | (crumbs & ~keep)

    fur_h = float(np.median(h[fur]))
    fur_s = float(np.median(s[fur]))
    fur_v = float(np.median(v[fur]))
    fur_v_lo, fur_v_hi = np.percentile(v[fur], [10, 90])
    # Value: the texel's own shading relative to its class, mapped into the
    # fur's own range, so crevices stay dark and lumps keep their form.
    rel = np.zeros_like(v)
    for cls in (stone & repaint, moss & repaint):
        if cls.any():
            med = max(float(np.median(v[cls])), 1e-3)
            rel[cls] = v[cls] / med
    noise = _value_noise_3d(unit, 9.0, 5602, 3)
    # Crack glyphs and edge shadow (neither stone nor moss) take the fur's own
    # darker clump value rather than their near-black, so no outline survives.
    rel[repaint & ~stone & ~moss] = 0.8
    rel[repaint & crumbs] = 1.0
    # Fur strokes: fine model-space noise stretched along the body (z), so a
    # removed plate's flat top reads as a fur clump rather than a brown tile.
    stretched = unit * np.array([1.0, 1.0, STROKE_STRETCH])
    strokes = _value_noise_3d(stretched, STROKE_FREQ, 5603, 2)
    new_v = fur_v * FUR_VALUE_SCALE * rel ** 0.5 * (0.85 + 0.3 * noise) \
        * (1.0 + STROKE_AMPLITUDE * (strokes - 0.5) * 2.0)
    new_v = np.clip(new_v, fur_v_lo * 0.6, fur_v_hi)
    new_h = fur_h + (noise - 0.5) * 8.0
    new_s = np.clip(fur_s * (0.9 + 0.2 * noise), 0.0, 1.0)
    new_rgb = _hsv_to_rgb(new_h, new_s, new_v)
    # The coat's own charcoal patches, continued over the old plate bed in
    # large soft clumps (same hue family as the fur's dark markings).
    patches = _value_noise_3d(unit, PATCH_FREQ, 5604, 2)
    pw = _smoothstep(PATCH_CUT - 0.04, PATCH_CUT + 0.04, patches)[..., None]
    char = _hsv_to_rgb(np.full_like(h, CHARCOAL[0]), np.full_like(h, CHARCOAL[1]),
                       np.clip(CHARCOAL[2] * (0.85 + 0.3 * strokes), 0, 1))
    new_rgb = new_rgb * (1.0 - pw) + char * pw

    # Soft edge: feather the repaint mask a couple of texels against kept stone.
    w = repaint.astype(np.float64)
    w = np.asarray(Image.fromarray((w * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(1.0))) / 255.0
    w = np.maximum(w, repaint.astype(np.float64))
    out = rgb * (1.0 - w[..., None]) + new_rgb * w[..., None]
    out_img = np.concatenate([out, live[..., 3:4]], axis=-1)
    Image.fromarray((np.clip(out_img, 0, 1) * 255).round().astype(np.uint8), "RGBA").save(OUT, optimize=True)

    glow = np.asarray(Image.open(GLOW).convert("RGBA")).astype(np.float64) / 255.0
    near_kept = _dilate(kept_stone, GLOW_NEAR_KEPT_PX)
    cut = (zone & ~near_kept).astype(np.float64)
    cut = np.maximum(cut, np.asarray(Image.fromarray((cut * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(1.5))) / 255.0 * zone)
    glow_out = glow.copy()
    glow_out[..., :3] *= (1.0 - cut)[..., None]
    Image.fromarray((np.clip(glow_out, 0, 1) * 255).round().astype(np.uint8), "RGBA").save(GLOW_OUT, optimize=True)

    stats = {
        "plates": plates_total, "kept": plates_kept,
        "stone_share_before": float(stone.sum() / valid.sum()),
        "stone_share_after": float((keep & stone).sum() / valid.sum()),
        "moss_share_before": float(moss.sum() / valid.sum()),
        "glow_sum_before": float(glow[..., :3].sum()),
        "glow_sum_after": float(glow_out[..., :3].sum()),
        "fur": [round(fur_h, 1), round(fur_s, 3), round(fur_v, 3)],
    }
    if debug_path:
        dbg = np.zeros(valid.shape + (3,))
        dbg[valid] = (0.35, 0.35, 0.35)
        dbg[zone] = (0.45, 0.25, 0.25)
        dbg[valid & ~zone & (s < STONE_SAT_MAX) & (v > STONE_VAL_MIN)] = (0.1, 0.8, 0.2)
        dbg[repaint] = (0.9, 0.5, 0.1)
        dbg[keep & stone] = (0.1, 0.4, 1.0)
        Image.fromarray((dbg * 255).astype(np.uint8)).save(debug_path)
    return stats


def _model_extent():
    from creature_anatomy_maps import read_glb, mesh_arrays
    glb = os.path.join(MODELS, "creature_burrowback_nat1024.glb")
    gltf, binary = read_glb(glb)
    pos, _n, _uv, _t = mesh_arrays(gltf, binary)
    return (pos.max(axis=0) - pos.min(axis=0)).astype(np.float64)


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


if __name__ == "__main__":
    dbg = ""
    if "--debug" in sys.argv:
        dbg = sys.argv[sys.argv.index("--debug") + 1]
    print(build(dbg))
