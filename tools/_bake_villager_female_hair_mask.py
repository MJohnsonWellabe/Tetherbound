#!/usr/bin/env python3
"""Bake the painted-hair mask for the villager_female rig.

N04-DIALOGUE-PORTRAITS, 2026-09-05. Writes
`assets/characters/villager_female/villager_female_lod0_hair_mask.png`, the
`detail_mask` `character_model.gd::_apply_hair` lays over the rig's ONE body
material so a villager's hair colour lands on the hair painted onto the head
(the fringe, the cap, the sides -- what a player sees from the front), not only
on the separated `hair_ponytail` mesh at the nape.

How the mask is found, so it can be re-baked if the rig or its texture changes:

  1. The rig's body mesh (`char1`) and the ponytail mesh both sample the same
     2048x2048 `texture_0`, an auto-unwrapped atlas of scattered islands. Every
     triangle whose three vertices are skinned to the head bones (`Head`,
     `head_end`, `headfront`, weight > 0.5) is rasterised in UV space, and so is
     every ponytail triangle. That is the HEAD REGION: hair, face, ears, neck.
  2. Inside that region a texel is HAIR when it is dark and warm-brown
     (luma < 70, R >= G >= B, R - B > 8): the painted hair is near-black brown
     (median luma 23) and skin is pink (luma > 100), so the two do not overlap.
  3. Connected components under 1500 texels are dropped. Those are pupils,
     lashes and eyebrows -- dark, warm, inside the head region, and not hair.
  4. The kept texels get a value, not just a bit: clamp(luma / 28, 0, 1) ^ 0.7.
     `StandardMaterial3D` mixes `detail_albedo` over the body texture by this
     value, so a crevice the painter darkened stays darker in the new colour
     and the hair keeps its painted shading instead of flattening to a swatch.
  5. The mask is then DILATED into the atlas gutters -- the empty texels
     between UV islands -- by up to GUTTER_DILATION texels of grey dilation,
     never onto a texel any island of the body mesh actually uses. Without
     this, bilinear and mip sampling at the edge of every hair island blends
     toward the mask's zero in the gutter and the painted dark brown shows
     through as a lattice of one-texel seams across the head in the world
     (the plate, sampled close up at mip 0, hid it). The albedo itself is
     already dilated into those gutters by whatever authored it, which is
     why the ORIGINAL hair shows no seams; the mask has to be dilated the
     same way to follow it.

Run from the repo root with numpy, Pillow and scipy installed:

    python3 tools/_bake_villager_female_hair_mask.py

Prints the texel counts it used; the bake is deterministic.
"""
import json
import os
import struct
import sys

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RIG_DIR = os.path.join(ROOT, "assets", "characters", "villager_female")
GLB = os.path.join(RIG_DIR, "villager_female_lod0.glb")
TEXTURE = os.path.join(RIG_DIR, "villager_female_lod0_texture_0.png")
OUT = os.path.join(RIG_DIR, "villager_female_lod0_hair_mask.png")

HEAD_BONES = ("head", "head_end", "headfront")
HEAD_WEIGHT = 0.5
HAIR_LUMA_MAX = 70.0
HAIR_MIN_WARMTH = 8
MIN_COMPONENT_TEXELS = 1500
SHADE_REFERENCE_LUMA = 28.0
SHADE_GAMMA = 0.7
GUTTER_DILATION = 12


def load_glb(path):
    data = open(path, "rb").read()
    json_len = struct.unpack("<I", data[12:16])[0]
    doc = json.loads(data[20:20 + json_len])
    bin_off = 20 + json_len
    bin_len = struct.unpack("<I", data[bin_off:bin_off + 4])[0]
    return doc, data[bin_off + 8:bin_off + 8 + bin_len]


def accessor(doc, blob, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    offset = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    dtype = {5120: "i1", 5121: "u1", 5122: "i2", 5123: "u2", 5125: "u4", 5126: "f4"}[acc["componentType"]]
    width = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}[acc["type"]]
    stride = view.get("byteStride", 0)
    item = np.dtype(dtype).itemsize * width
    if stride and stride != item:
        return np.array([np.frombuffer(blob, dtype=dtype, count=width, offset=offset + k * stride)
                         for k in range(acc["count"])])
    return np.frombuffer(blob, dtype=dtype, count=acc["count"] * width, offset=offset).reshape(acc["count"], width)


def rasterise(doc, blob, mesh, size, head_only, head_joint_indices):
    prim = mesh["primitives"][0]
    attrs = prim["attributes"]
    uv = accessor(doc, blob, attrs["TEXCOORD_0"])
    tris = accessor(doc, blob, prim["indices"]).ravel().reshape(-1, 3)
    if head_only:
        joints = accessor(doc, blob, attrs["JOINTS_0"])
        weights = accessor(doc, blob, attrs["WEIGHTS_0"])
        head_weight = np.zeros(len(uv))
        for column in range(4):
            head_weight += np.where(np.isin(joints[:, column], head_joint_indices), weights[:, column], 0.0)
        tris = tris[(head_weight[tris] > HEAD_WEIGHT).all(axis=1)]
    canvas = Image.new("L", size, 0)
    draw = ImageDraw.Draw(canvas)
    w, h = size
    for tri in tris:
        draw.polygon([(float(uv[i, 0] * w), float(uv[i, 1] * h)) for i in tri], fill=255)
    return np.array(canvas) > 0


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
    region = rasterise(doc, blob, meshes["char1"], size, True, head_joints)
    region |= rasterise(doc, blob, meshes["hair_ponytail"], size, False, head_joints)
    # Every texel any triangle of the body or ponytail uses, head or not: the
    # dilation below may only ever grow into what is left (the gutters).
    used = rasterise(doc, blob, meshes["char1"], size, False, head_joints)
    used |= rasterise(doc, blob, meshes["hair_ponytail"], size, False, head_joints)

    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    luma = 0.299 * r + 0.587 * g + 0.114 * b
    hair_like = (luma < HAIR_LUMA_MAX) & (r >= g) & (g >= b) & ((r - b) > HAIR_MIN_WARMTH)
    candidate = region & hair_like
    labels, count = ndimage.label(candidate)
    sizes = ndimage.sum(candidate, labels, range(1, count + 1))
    kept = np.isin(labels, np.where(sizes >= MIN_COMPONENT_TEXELS)[0] + 1)

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
          % (region.sum(), candidate.sum(), kept.sum(), int((sizes >= MIN_COMPONENT_TEXELS).sum()),
             float(mask[kept].mean()), dilated))
    print("wrote", os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
