#!/usr/bin/env python3
"""Bake the painted-hair mask for the villager_male rig.

N14-ROUTED-FOLLOWUPS, 2026-09-05, on N04-DIALOGUE-PORTRAITS's routed finding.
Writes `assets/characters/villager_male/villager_male_lod0_hair_mask.png`, the
`detail_mask` `character_model.gd::_recolour_painted_hair` lays over the rig's
body material so a villager's hair colour lands on the hair painted onto the
head.

N04 built this technique for `villager_female` and scoped itself to that rig.
Five NPCs on the male rig -- Oskar, Bram, Kell, the Quarry Foreman and Coll --
still share one undifferentiated plate and one undifferentiated head in the
world, and `art.json`'s `villager_keeper` block records the two things already
tried and reverted for it: a whole-body tint ("looks stupid", owner playtest)
and a per-material belt pouch (rendered in the wrong place).

**This rig has no separated hair mesh, and it does not need one.** That is worth
stating because N04's report flagged the opposite as a real possibility ("the
male rig has no separable hair and no mask") and because
`villager_keeper`'s own comment says "villager_male has no separable hair mesh
(NP7 only cut one for villager_female)". Both are true about the MESH, and both
are beside the point for this technique: the mask is a region of the TEXTURE,
found by skinning and colour, not a mesh to be cut. Measured on the real rig
before writing this file: the head-bone-skinned UV islands cover 425,806 texels
of `texture_0`, and inside them the same colour key N04 used separates cleanly
into hair islands and face islands (the tunic, which is the same warm brown
family as the hair and would defeat a colour test applied to the whole atlas, is
outside the head region and never considered).

Everything else is N04's method, unchanged, and its own script's docstring is
the reference for WHY each step is there -- read
`tools/_bake_villager_female_hair_mask.py` first. The pure helpers (`load_glb`,
`accessor`, `rasterise`) are imported from it rather than copied, so the two
rigs cannot drift in how they read a GLB.

The thresholds are N04's, and they are reused because they were MEASURED to fit
rather than assumed to: the male rig's painted hair sits at luma p05 13 /
median 25 / p95 46 against the female's 10 / 23 / 44 -- the same paint, the same
distribution -- so `HAIR_LUMA_MAX` 70 and `SHADE_REFERENCE_LUMA` 36 transfer
without retuning. If a future rig's paint does NOT match, re-measure before
copying these numbers again.

Two differences from the female bake, both forced by the rig:

  * There is no `hair_ponytail` mesh to add to the region or to the used-texel
    set. The region is `char1`'s head-skinned triangles alone.
  * `char1` and `trousers` are separate materials on separate textures
    (`texture_0` and `trousers_tex`), so only `char1` contributes to `used` --
    the gutter dilation must not be told that trousers texels are occupied in
    an atlas the trousers never sample.

Run from the repo root with numpy, Pillow and scipy installed:

    python3 tools/_bake_villager_male_hair_mask.py

Prints the texel counts it used; the bake is deterministic.
"""
import importlib.util
import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG_DIR = os.path.join(ROOT, "assets", "characters", "villager_male")
GLB = os.path.join(RIG_DIR, "villager_male_lod0.glb")
TEXTURE = os.path.join(RIG_DIR, "villager_male_lod0_texture_0.png")
OUT = os.path.join(RIG_DIR, "villager_male_lod0_hair_mask.png")

# The female bake's own module, imported for its GLB readers so the two rigs
# read a glTF the same way. Its module-level constants describe the FEMALE rig
# and are deliberately NOT reused as a group -- each one below is restated here
# so this file can be read on its own and retuned without touching that one.
_FEMALE = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "_bake_villager_female_hair_mask.py")
_spec = importlib.util.spec_from_file_location("_bake_villager_female_hair_mask", _FEMALE)
_female = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_female)
load_glb = _female.load_glb
rasterise = _female.rasterise

HEAD_BONES = ("head", "head_end", "headfront")
HAIR_LUMA_MAX = 70.0
HAIR_MIN_WARMTH = 8
HAIR_MIN_RED_OVER_GREEN = 5
MIN_COMPONENT_TEXELS = 1500
MIN_ISLAND_FRACTION = 0.5
SHADE_REFERENCE_LUMA = 36.0
SHADE_GAMMA = 0.85
GUTTER_DILATION = 12


def main():
    doc, blob = load_glb(GLB)
    joint_names = [doc["nodes"][k]["name"] for k in doc["skins"][0]["joints"]]
    head_joints = [i for i, name in enumerate(joint_names) if name.lower() in HEAD_BONES]
    if not head_joints:
        sys.exit("no head bones in %s (joints: %s)" % (GLB, joint_names))
    texture = Image.open(TEXTURE).convert("RGB")
    rgb = np.array(texture).astype(np.float64)
    size = texture.size

    meshes = {m["name"]: m for m in doc["meshes"]}
    if "char1" not in meshes:
        sys.exit("no `char1` mesh in %s (meshes: %s)" % (GLB, list(meshes)))
    region = rasterise(doc, blob, meshes["char1"], size, True, head_joints)
    # `trousers` is a separate material on a separate texture, so it owns none
    # of THIS atlas: only char1's triangles may mark a texel as occupied.
    used = rasterise(doc, blob, meshes["char1"], size, False, head_joints)

    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    hair_like = ((luma < HAIR_LUMA_MAX) & (r >= g) & (g >= b)
                 & ((r - b) > HAIR_MIN_WARMTH) & ((r - g) > HAIR_MIN_RED_OVER_GREEN))
    candidate = region & hair_like
    labels, count = ndimage.label(candidate)
    sizes = ndimage.sum(candidate, labels, range(1, count + 1))
    island_labels, island_count = ndimage.label(region)
    island_sizes = ndimage.sum(region, island_labels, range(1, island_count + 1))
    keep_ids = []
    for index in range(count):
        if sizes[index] >= MIN_COMPONENT_TEXELS:
            keep_ids.append(index + 1)
            continue
        component = labels == index + 1
        island = np.bincount(island_labels[component]).argmax()
        if island > 0 and sizes[index] / island_sizes[island - 1] >= MIN_ISLAND_FRACTION:
            keep_ids.append(index + 1)
    kept = np.isin(labels, keep_ids)
    if not kept.any():
        sys.exit("no hair component survived the filters; do not ship an empty mask")

    shade = np.clip(luma / SHADE_REFERENCE_LUMA, 0.0, 1.0) ** SHADE_GAMMA
    mask = np.where(kept, shade, 0.0)
    gutter = ~used
    grown = mask.copy()
    for _ in range(GUTTER_DILATION):
        wider = ndimage.grey_dilation(grown, size=(3, 3))
        grown = np.where(gutter, np.maximum(grown, wider), grown)
    dilated = int(((grown > 0) & ~kept).sum())
    mask = grown
    Image.fromarray((mask * 255.0 + 0.5).astype(np.uint8), "L").save(OUT, optimize=True)
    print("head region %d texels, hair candidates %d, kept %d in %d components; mean mask value over hair %.2f; "
          "dilated %d gutter texels"
          % (region.sum(), candidate.sum(), kept.sum(), len(keep_ids), float(mask[kept].mean()), dilated))
    print("wrote", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
