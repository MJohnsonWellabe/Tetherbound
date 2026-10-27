"""dog3 Terrapup r4 (CLOSE-OUT, 27 Oct 2026; owner: "Terrapup is supposed to be a
large dog, not a badger").

GPU CO8 (tb/gpu-pass 41b922661): dog3 r1 lost -1.82 to the shipping badger, read
as an orange coat with a strapped-on plate pad. The coordinator's brief: grow
smaller overlapping plates out of the fur along the spine, with no pad
outline, on a desaturated chestnut coat. Texture only, on the same Meshy r1
retexture (r1_base_color.png, task ids in provenance.jsonl):

1. The r1 plate pad (found the same way grade_retex.py finds it) is filled
   back in with fur: each pad texel copies the coat from the flank just below
   it on the body (nearest coat texel, in model space, to a point dropped down
   the side), so real fur strands continue over where the pad was.
2. The coat moves to a desaturated chestnut (hue 24-29, saturation at most
   0.42, value x0.86); the cream muzzle, chest and paws, eyes and nose keep
   theirs.
3. Small stone plates grow along the spine in model space (anatomy map
   positions, so they cross UV seams unbroken): a centre row and two staggered
   side rows from rump to withers, each an ellipse longer along the body,
   overlapping like shingles toward the tail, with a dark crevice edge, fur
   strands over the rim and a soft contact shadow, so they read grown out of
   the coat rather than worn on it.
4. The normal map is flattened over the same filled pad region, so the pad's
   relief outline goes with its paint (dog3_normal_source.png keeps the Meshy
   normal it starts from).
Mesh, rig, UVs and clips are untouched. Deterministic (seeded).

    python3 assets/creatures/tetherbound/terrapup/candidate_dog3/retex/grade_r4.py [--preview out.png]
"""
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy.spatial import cKDTree

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
sys.path.insert(0, HERE)
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)
import grade_retex as R1  # noqa: E402  (the r1 plate detection)
from creature_anatomy_maps import build as build_anatomy  # noqa: E402

SOURCE = os.path.join(HERE, "r1_base_color.png")
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_terrapup_dog3.glb")
JPG = os.path.join(MODELS, "creature_terrapup_dog3_Image_0.jpg")
NORMAL_PNG = os.path.join(MODELS, "creature_terrapup_dog3_normal.png")
NORMAL_SOURCE = os.path.join(HERE, "dog3_normal_source.png")  # the Meshy normal, before flattening
ANATOMY_KEY = "terrapup/candidate_dog3"
SEED = 1027
EXTENT = np.array([1.221, 3.2, 4.896])  # the GLB's bind-pose box (metres)
PAD_GROW_PX = 16
PAD_REMNANT_PX = 44  # cool-hued rim remnants this close to the pad are filled too
PAD_DROP_M = 0.55  # fur is copied from this far down the flank
COAT_HUE = (24.0, 29.0)
COAT_SAT_MAX = 0.42
COAT_VAL_SCALE = 0.86
SPINE_Z = (0.24, 0.63)  # rump to withers, as fractions of body length
PLATE_STEP_M = 0.27  # spacing along the spine
PLATE_LEN_M = 0.34  # half-lengths of each ellipse (along the body / across it)
PLATE_WID_M = 0.22
SIDE_OFFSET_M = 0.26  # the two side rows, staggered half a step
STONE = (0x6E / 255.0, 0x6A / 255.0, 0x5E / 255.0)
CREVICE = (0x3A / 255.0, 0x36 / 255.0, 0x2F / 255.0)
SHADOW = (0x2A / 255.0, 0x20 / 255.0, 0x18 / 255.0)


def _plate_pad(rgb):
    """The r1 plate mask, exactly as grade_retex.grade() builds it."""
    from scipy import ndimage as nd
    h, s, v = T._hsv(rgb)
    cool = (h >= R1.PLATE_HUE[0]) & (h < R1.PLATE_HUE[1]) & (s >= R1.PLATE_SAT_MIN) & (v <= R1.PLATE_VAL_MAX)
    mean = nd.uniform_filter(v, 7)
    spread = np.sqrt(np.maximum(nd.uniform_filter(v * v, 7) - mean * mean, 0))
    rim = nd.binary_opening(cool & (spread > R1.PLATE_RIM_DETAIL))
    near = nd.binary_dilation(rim, structure=R1._disk(R1.PLATE_REACH_PX))
    interior = ((h < R1.INTERIOR["hue_max"]) & (s < R1.INTERIOR["sat_max"]) & (v < R1.INTERIOR["val_max"])
                & near & (spread > R1.PLATE_RIM_DETAIL * 0.66))
    plate = nd.binary_fill_holes(nd.binary_closing(rim | interior, structure=R1._disk(3)))
    plate = nd.binary_opening(plate, structure=R1._disk(2))
    labels, count = nd.label(plate)
    sizes = nd.sum(plate, labels, range(1, count + 1))
    plate = np.isin(labels, 1 + np.nonzero(sizes >= R1.PLATE_MIN_PX)[0])
    # the flat blue-grey fill wedges too, so no blue-grey survives
    fill = cool & ~plate
    return plate | fill


def _spine(points):
    """Top-centre ridge of the back: per slice along the body, the highest
    surface point near the midline."""
    ridge = []
    for z in np.linspace(SPINE_Z[0], SPINE_Z[1], 40) * EXTENT[2]:
        sl = points[(np.abs(points[:, 2] - z) < 0.04) & (np.abs(points[:, 0] - EXTENT[0] / 2) < 0.12)]
        if len(sl):
            ridge.append(sl[np.argmax(sl[:, 1])])
    return np.asarray(ridge)


def grade(rgb):
    rng = np.random.default_rng(SEED)
    size = rgb.shape[0]
    anatomy, _cache = build_anatomy(ANATOMY_KEY, size=size)
    valid = anatomy["valid"]
    pos = anatomy["unit"].astype(np.float64) * EXTENT
    h, s, v = T._hsv(rgb)
    pad = _plate_pad(rgb)
    pad_grown = np.asarray(Image.fromarray((pad * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(2 * PAD_GROW_PX + 1))) > 127
    # the old pad's blue-grey rims and dark outlines leave remnants just past
    # the detected mask; any cool-hued or near-black texel near the pad goes too
    near_pad = np.asarray(Image.fromarray((pad * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(2 * PAD_REMNANT_PX + 1))) > 127
    remnant = near_pad & (((h >= 150.0) & (h < 330.0)) | (v < 0.3) | ((s < 0.22) & (v < 0.55)))
    pad_grown = pad_grown | (np.asarray(Image.fromarray((remnant * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(5))) > 127)
    coat = valid & (h < 50.0) & (s >= R1.COAT_SAT_MIN) & ~pad_grown
    # 1. pad -> fur from the flank below
    out = rgb.copy()
    fill_idx = np.nonzero(valid & pad_grown)
    coat_idx = np.nonzero(coat)
    tree = cKDTree(pos[coat_idx])
    target = pos[fill_idx] - np.array([0.0, PAD_DROP_M, 0.0])
    _, nearest = tree.query(target)
    out[fill_idx] = rgb[coat_idx[0][nearest], coat_idx[1][nearest]]
    blend = np.asarray(Image.fromarray((pad_grown * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(3))).astype(np.float64)[..., None] / 255.0
    out = rgb * (1 - blend) + out * blend
    # 2. desaturated chestnut coat (after the fill, so the filled fur matches)
    h, s, v = T._hsv(out)
    fur = (h < 50.0) & (s >= R1.COAT_SAT_MIN)  # the whole atlas, as r1 did: gutters bleed into mip levels
    oh, os_, ov = h.copy(), s.copy(), v.copy()
    oh[fur] = np.clip(COAT_HUE[0] + (h[fur] - 22.0) * 0.4, *COAT_HUE)
    os_[fur] = np.minimum(s[fur] * 0.62, COAT_SAT_MAX)
    ov[fur] = v[fur] * COAT_VAL_SCALE
    out = T._rgb(oh, os_, ov)
    # 3. grown plates along the spine
    points = pos[valid]
    ridge = _spine(points)
    length = np.cumsum(np.r_[0, np.linalg.norm(np.diff(ridge, axis=0), axis=1)])
    centres = []
    for row, lateral, phase in ((0, 0.0, 0.0), (1, -SIDE_OFFSET_M, 0.5), (2, SIDE_OFFSET_M, 0.5)):
        for d in np.arange(PLATE_STEP_M * phase, length[-1], PLATE_STEP_M):
            i = np.searchsorted(length, d).clip(1, len(ridge) - 1)
            c = ridge[i]
            fwd = ridge[i] - ridge[i - 1]
            fwd /= max(np.linalg.norm(fwd), 1e-6)
            c = c + np.array([lateral, -abs(lateral) * 0.55, 0.0])
            scale = 1.0 - 0.25 * abs(lateral) / SIDE_OFFSET_M + rng.uniform(-0.08, 0.08)
            centres.append((c, fwd, scale, d))
    # tail-most first, so plates nearer the head overlap them (shingles)
    centres.sort(key=lambda t: t[3])
    tree_all = cKDTree(pos[valid])
    plate_map = np.zeros(valid.shape)
    shade_map = np.zeros(valid.shape)
    crevice_map = np.zeros(valid.shape)
    shadow_map = np.zeros(valid.shape)
    vi = np.nonzero(valid)
    for c, fwd, scale, _d in centres:
        reach = PLATE_LEN_M * scale * 1.6
        idx = tree_all.query_ball_point(c, reach)
        if not idx:
            continue
        idx = np.asarray(idx)
        rel = pos[vi[0][idx], vi[1][idx]] - c
        along = rel @ fwd
        across = np.linalg.norm(rel - np.outer(along, fwd), axis=1)
        r = np.sqrt((along / (PLATE_LEN_M * scale)) ** 2 + (across / (PLATE_WID_M * scale)) ** 2)
        inside = r < 1.0
        ys, xs = vi[0][idx], vi[1][idx]
        # shingle: a later (head-ward) plate replaces what it covers
        plate_map[ys[inside], xs[inside]] = 1.0
        # lighter toward the plate's head-ward edge, darker at the tail edge
        shade_map[ys[inside], xs[inside]] = 0.85 + 0.25 * np.clip(along[inside] / (PLATE_LEN_M * scale), -1, 1)
        crevice_map[ys[inside], xs[inside]] = np.clip((r[inside] - 0.78) / 0.22, 0, 1)
        ring = (r >= 1.0) & (r < 1.35)
        shadow_map[ys[ring], xs[ring]] = np.maximum(shadow_map[ys[ring], xs[ring]], 1.0 - (r[ring] - 1.0) / 0.35)
    noise = np.asarray(Image.fromarray((rng.random(valid.shape) * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(1.5))).astype(np.float64) / 255.0
    stone = np.asarray(STONE)[None, None, :] * (shade_map * (0.85 + 0.3 * noise))[..., None]
    stone = stone * (1 - crevice_map[..., None]) + np.asarray(CREVICE)[None, None, :] * crevice_map[..., None]
    # fur strands over the rim: ragged edge from noise
    strands = (noise > 0.55).astype(np.float64)
    soft_plate = np.asarray(Image.fromarray((plate_map * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(1.0))).astype(np.float64) / 255.0
    edge = soft_plate * (1 - np.clip(soft_plate * 2 - 1, 0, 1))
    alpha = np.clip(soft_plate - edge * strands * 0.9, 0, 1)
    sh = np.asarray(Image.fromarray((shadow_map * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(2.0))).astype(np.float64) / 255.0 * 0.55 * (1 - plate_map)
    out = out * (1 - sh[..., None]) + np.asarray(SHADOW)[None, None, :] * sh[..., None]
    out = out * (1 - alpha[..., None]) + stone * alpha[..., None]
    print("pad filled %.1f%%, plates %d covering %.2f%% of the surface" % (
        (valid & pad_grown).mean() * 100, len(centres), plate_map[valid].mean() * 100))
    return np.clip(out, 0, 1), blend[..., 0]


def main():
    rgb = np.asarray(Image.open(SOURCE).convert("RGB")).astype(np.float64) / 255.0
    out, pad_soft = grade(rgb)
    h, s, v = T._hsv(out)
    signed = np.where(h > 180.0, h - 360.0, h)
    red = (signed >= -15.0) & (signed <= 26.0) & (s >= 0.55) & (v >= 0.12)
    print("reserved red band texels: %.3f%%" % (red.mean() * 100))
    image = Image.fromarray((out * 255 + 0.5).astype(np.uint8), "RGB")
    if "--preview" in sys.argv:
        image.save(sys.argv[sys.argv.index("--preview") + 1])
        return
    buf = io.BytesIO()
    image.save(buf, "JPEG", quality=92)
    data = buf.getvalue()
    open(JPG, "wb").write(data)
    gltf, views = T._read_glb(GLB)
    target = next(i for i in gltf["images"] if i.get("name") == "Image_0")
    views[target["bufferView"]] = data
    target["mimeType"] = "image/jpeg"
    # The pad's raised outline is also in the normal map: flatten it there,
    # so no relief line is left where the pad was.
    normal_entry = next(i for i in gltf["images"] if i.get("name") == "normal")
    if not os.path.exists(NORMAL_SOURCE):
        open(NORMAL_SOURCE, "wb").write(views[normal_entry["bufferView"]])
    nrm = Image.open(NORMAL_SOURCE).convert("RGB")
    flat_w = np.asarray(Image.fromarray((pad_soft * 255).astype(np.uint8)).resize(nrm.size, Image.BILINEAR)).astype(np.float64)[..., None] / 255.0
    n = np.asarray(nrm).astype(np.float64)
    n = n * (1 - flat_w) + np.array([128.0, 128.0, 255.0])[None, None, :] * flat_w
    nbuf = io.BytesIO()
    Image.fromarray(np.clip(n + 0.5, 0, 255).astype(np.uint8), "RGB").save(nbuf, "PNG", optimize=True)
    views[normal_entry["bufferView"]] = nbuf.getvalue()
    open(NORMAL_PNG, "wb").write(nbuf.getvalue())
    T._write_glb(GLB, gltf, views)
    print("graded into", os.path.relpath(GLB, ROOT))


if __name__ == "__main__":
    main()
