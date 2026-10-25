"""dog3 Terrapup retexture grade (25 Oct 2026; owner: "Terrapup should be a
dog"). The coordinator's Meshy /retexture of the rigged dog3 mesh (tb/meshy-1024
b959ba072, task ids in provenance.jsonl, enable_original_uv) gave a readable
dog with stone plates, but the coat is orange (hue 27, saturation 0.81: inside
the reserved red band) and the plates are blue-grey pads that read as a pack
strapped on. This grades r1 toward the retexture spec
(ralph/reports/CREATURES/close-1024/dog3-retex-spec on tb/creatures):
- the coat moves to chestnut brown (#7A4E2E shading to #5A3920) at hue 27-31
  and saturation at most 0.54, so no texel stays in the reserved red band;
- the plates (blue-grey rims with their dark interiors) move to matte, warm
  earth-grey stone (#6E6A5E, crevices #3E3B34) with sparse lichen flecks;
- fur (#6A4428) grows over each plate rim, a dark contact shadow (#2A2018)
  sits under every plate, and broken moss clumps creep from the plates into
  the coat, so the plates read as grown out of the dog, not worn by it;
- the cream muzzle, chest and paws, the eyes and the nose are kept.
It writes the graded image into the model's embedded Image_0 and the
extracted image beside it, so the mesh, rig, UVs and clips are untouched. The
noise is seeded, so a re-run gives the same bytes. Needs numpy, Pillow and scipy.

    python3 assets/creatures/tetherbound/terrapup/candidate_dog3/retex/grade_retex.py [--source r3] [--preview out.png]

r3 (task 01a1754c, tb/meshy-1024 6c63dfa6d) asked Meshy for small separate
stones ringed by coat. Its stones are already grey-brown (hue about 50,
saturation 0.16) with no blue-grey rims, so `--source r3` also seeds the plate
mask from textured grey stone texels; the coat grade is the same.
"""
import io
import os
import sys

import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage as nd

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools", "art_pipeline"))
import shift_reserved_red as T  # noqa: E402  (HSV helpers and GLB writer)

SOURCES = {"r1": "r1_base_color.png", "r3": "r3_base_color.png"}
STONE = {"hue": (40.0, 100.0), "sat_max": 0.3, "val": (0.2, 0.65)}  # r3 only
MODELS = os.path.join(HERE, "..", "models")
GLB = os.path.join(MODELS, "creature_terrapup_dog3.glb")
JPG = os.path.join(MODELS, "creature_terrapup_dog3_Image_0.jpg")
SEED = 1025
# Measured on r1: coat hue 27 / sat 0.81 / value 0.56 (p10 0.41); cream 30 /
# 0.23 / 0.59; plate rims blue-grey (hue 150-260, value about 0.27).
COAT_SAT_MIN = 0.3
COAT_HUE = 27.5
COAT_HUE_SPREAD = 0.3
COAT_SAT_SCALE = 0.67
COAT_SAT_MAX = 0.54  # the reserved band starts at saturation 0.55
COAT_VAL_SCALE = 0.86
PLATE_HUE = (150.0, 260.0)
PLATE_SAT_MIN = 0.06
PLATE_VAL_MAX = 0.75
PLATE_RIM_DETAIL = 0.03  # local value spread: textured rims, not the flat fill wedges
PLATE_REACH_PX = 20  # dark plate interiors lie within this of a rim
INTERIOR = {"hue_max": 40.0, "sat_max": 0.72, "val_max": 0.42}
PLATE_MIN_PX = 150
PLATE_TO_HUE = 48.0
PLATE_SAT = 0.13
PLATE_VAL = (0.16, 0.52)  # value range the plate texels are remapped into (#6E6A5E about 0.43)
FILL_HUE = 36.0  # the flat blue-grey fill wedges (underside) warm to a dull earth-brown
FILL_SAT = 0.12
FILL_VAL_SCALE = 0.9
LICHEN = (0x7E / 255.0, 0x84 / 255.0, 0x56 / 255.0)
LICHEN_SHARE = 0.06
FUR_RIM = (0x6A / 255.0, 0x44 / 255.0, 0x28 / 255.0)
FUR_IN_PX = 5
SHADOW = (0x2A / 255.0, 0x20 / 255.0, 0x18 / 255.0)
SHADOW_OUT_PX = 7
SHADOW_ALPHA = 0.7
MOSS = ((0x55 / 255.0, 0x62 / 255.0, 0x32 / 255.0), (0x6C / 255.0, 0x7A / 255.0, 0x3C / 255.0))
MOSS_REACH_PX = 26
MOSS_SHARE = 0.4
MOSS_ALPHA = 0.8


def _disk(r):
    return np.add.outer(np.arange(-r, r + 1) ** 2, np.arange(-r, r + 1) ** 2) <= r * r


def _mask_img(m):
    return Image.fromarray((m * 255).astype(np.uint8), "L")


def _grow(m, px):
    return nd.binary_dilation(m, structure=_disk(px))


def _shrink(m, px):
    return nd.binary_erosion(m, structure=_disk(px))


def _soft(m, radius):
    return np.asarray(_mask_img(m).filter(ImageFilter.GaussianBlur(radius))).astype(np.float64) / 255.0


def _blobs(shape, rng, radius, share):
    """Broken clumps: blurred white noise thresholded at the given share."""
    noise = rng.random(shape)
    img = Image.fromarray((noise * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(radius))
    field = np.asarray(img).astype(np.float64)
    return field >= np.percentile(field, 100.0 * (1.0 - share))


def _blend(rgb, colour, alpha):
    a = alpha[..., None]
    return rgb * (1.0 - a) + np.asarray(colour)[None, None, :] * a


def grade(rgb, stone_seed=False):
    rng = np.random.default_rng(SEED)
    h, s, v = T._hsv(rgb)
    cool = (h >= PLATE_HUE[0]) & (h < PLATE_HUE[1]) & (s >= PLATE_SAT_MIN) & (v <= PLATE_VAL_MAX)
    mean = nd.uniform_filter(v, 7)
    spread = np.sqrt(np.maximum(nd.uniform_filter(v * v, 7) - mean * mean, 0))
    seed = cool
    if stone_seed:
        seed = seed | ((h >= STONE["hue"][0]) & (h <= STONE["hue"][1]) & (s <= STONE["sat_max"])
                       & (v >= STONE["val"][0]) & (v <= STONE["val"][1]))
    rim = nd.binary_opening(seed & (spread > PLATE_RIM_DETAIL))
    # Each plate's dark, textured interior sits inside its blue-grey rim.
    near = nd.binary_dilation(rim, structure=_disk(PLATE_REACH_PX))
    interior = ((h < INTERIOR["hue_max"]) & (s < INTERIOR["sat_max"]) & (v < INTERIOR["val_max"])
                & near & (spread > PLATE_RIM_DETAIL * 0.66))
    plate = nd.binary_fill_holes(nd.binary_closing(rim | interior, structure=_disk(3)))
    plate = nd.binary_opening(plate, structure=_disk(2))
    labels, count = nd.label(plate)
    sizes = nd.sum(plate, labels, range(1, count + 1))
    plate = np.isin(labels, 1 + np.nonzero(sizes >= PLATE_MIN_PX)[0])
    coat = (h < 50.0) & (s >= COAT_SAT_MIN) & ~plate
    out_h, out_s, out_v = h.copy(), s.copy(), v.copy()
    out_h[coat] = COAT_HUE + (h[coat] - 27.0) * COAT_HUE_SPREAD
    out_h[coat] = np.clip(out_h[coat], 27.0, 31.0)
    out_s[coat] = np.minimum(s[coat] * COAT_SAT_SCALE, COAT_SAT_MAX)
    out_v[coat] = v[coat] * COAT_VAL_SCALE
    # Stone: one warm earth-grey, the source's light/dark structure kept as
    # the crevices and faces.
    pv = v[plate]
    lo, hi = np.percentile(pv, 3), np.percentile(pv, 97)
    out_h[plate] = PLATE_TO_HUE
    out_s[plate] = PLATE_SAT
    fill = cool & ~plate
    out_h[fill] = FILL_HUE
    out_s[fill] = np.minimum(s[fill], FILL_SAT)
    out_v[fill] = v[fill] * FILL_VAL_SCALE
    out_v[plate] = PLATE_VAL[0] + np.clip((pv - lo) / max(hi - lo, 1e-6), 0, 1) * (PLATE_VAL[1] - PLATE_VAL[0])
    out = T._rgb(out_h, out_s, out_v)
    lichen = plate & _blobs(h.shape, rng, 1.2, LICHEN_SHARE)
    out = _blend(out, LICHEN, lichen * 0.6)
    # Contact shadow just outside each plate, strongest at the rim.
    ring_out = _grow(plate, SHADOW_OUT_PX) & ~plate
    shade = np.clip(_soft(plate, SHADOW_OUT_PX * 0.6) * 2.0, 0, 1) * ring_out
    out = _blend(out, SHADOW, shade * SHADOW_ALPHA)
    # Fur over the rim: ragged coat-coloured strands across the plate edge.
    ring_in = plate & ~_shrink(plate, FUR_IN_PX)
    strands = _blobs(h.shape, rng, 1.0, 0.45)
    fur = ring_in & strands
    out = _blend(out, FUR_RIM, _soft(fur, 0.8) * 0.7)
    # Moss creeping from the plates into the coat, as broken clumps.
    reach = _grow(plate, MOSS_REACH_PX) & ~_grow(plate, 2) & coat
    near = _soft(plate, MOSS_REACH_PX * 0.5)
    clumps = reach & _blobs(h.shape, rng, 3.0, MOSS_SHARE) & (near > 0.04)
    tint = np.where(_blobs(h.shape, rng, 2.0, 0.5), 1.0, 0.0)[..., None]
    moss = np.asarray(MOSS[0])[None, None, :] * (1 - tint) + np.asarray(MOSS[1])[None, None, :] * tint
    a = (clumps * np.clip(near * 3.0, 0, 1) * MOSS_ALPHA)[..., None]
    lum = (out.mean(-1, keepdims=True) / max(out[coat].mean(), 1e-6)).clip(0.6, 1.3)
    out = out * (1 - a) + moss * lum * a
    print("coat %.1f%%, plate %.1f%%, fur rim %.2f%%, shadow %.2f%%, moss %.2f%%" % (
        coat.mean() * 100, plate.mean() * 100, fur.mean() * 100, ring_out.mean() * 100, clumps.mean() * 100))
    return np.clip(out, 0, 1)


def main():
    tag = sys.argv[sys.argv.index("--source") + 1] if "--source" in sys.argv else "r1"
    rgb = np.asarray(Image.open(os.path.join(HERE, SOURCES[tag])).convert("RGB")).astype(np.float64) / 255.0
    out = grade(rgb, stone_seed=(tag == "r3"))
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
    T._write_glb(GLB, gltf, views)
    print("graded into", os.path.relpath(GLB, ROOT))


if __name__ == "__main__":
    main()
