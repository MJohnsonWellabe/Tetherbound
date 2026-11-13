#!/usr/bin/env python3
"""BEINGS-OFFICER-FACES (F41#8, F41#18): distinct hair for Officer Maren and Officer Nysa.

Judges (G-below6-uniform-cloth-c673 and G-below6-staticub-fur-dialogue-c673, 3/3):
Lieutenant Sera and Officer Maren share one face, coat and portrait (both wear
officer_b); Officer Nysa shows Lieutenant Varga's male face and portrait (both
wear officer_a). Ask: separate them by face, or hair and coat colour.

Installed cast only, identity-preserving texture variants (no new mesh, no Meshy):
- Maren keeps officer_b; her hair goes chestnut-honey.
- Nysa moves to a copy of officer_b (a female face, so she no longer wears
  Varga's face) with ash-silver hair, so she is not a second Sera either.
Hair is chosen by position on the model (top 16% of its height, from the
model's own UVs, tools/creature_anatomy_maps.py) and the plum hair hue; face
skin, coat, collar and eyes keep their pixels. Shading is kept: each texel's
value is scaled, not replaced. The portraits get the same recolour of the plate
the game shows for officer_b today (hair = plum hue in the top 62% of the plate).

Writes:
  assets/characters/officer_b/officer_b_lod0_texture_0_vis1_maren.png
  assets/characters/npc_identity/stormwood_nysa/nysa_lod0.glb  (officer_b copy, embedded atlas recoloured)
  assets/ui/portraits/npc_identity_stormwood_maren.png
  assets/ui/portraits/npc_identity_stormwood_nysa.png

    python3 ralph/reports/LANES/BEINGS-OFFICER-FACES/derive_officer_hair.py
    python3 ralph/reports/LANES/BEINGS-OFFICER-FACES/derive_officer_hair.py --nysa-neutral
      (Nysa keeps her officer_a face; hair and plate only)
"""
import io
import json
import os
import shutil
import struct
import sys

import numpy as np
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "..", ".."))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import creature_anatomy_maps as A  # noqa: E402

OB = "assets/characters/officer_b/"
GLB = OB + "officer_b_lod0.glb"
VIS1 = OB + "officer_b_lod0_texture_0_vis1.png"
PLATE = "assets/ui/portraits/officer_b.png"
LOOKS = {
    # name: (target hue deg, target saturation, value scale)
    "maren": (38.0, 0.52, 2.0),
    "nysa": (215.0, 0.07, 2.05),
}
HAIR_TOP = 0.84
FACE_CENTRE = (0.42, 0.41)
FACE_RADII = (0.13, 0.17)


def hsv_arrays(image):
    hsv = np.asarray(image.convert("HSV")).astype(np.float64) / 255.0
    return hsv[..., 0] * 360.0, hsv[..., 1], hsv[..., 2]


def plum(h, s, v):
    return ((h > 280.0) | (h < 15.0)) & (s > 0.18) & (v > 0.10) & (v < 0.78)


def recolour(image, mask, look):
    hue, sat, vscale = look
    hsv = np.asarray(image.convert("HSV")).astype(np.float64)
    hsv[..., 0] = np.where(mask, hue / 360.0 * 255.0, hsv[..., 0])
    hsv[..., 1] = np.where(mask, sat * 255.0, hsv[..., 1])
    hsv[..., 2] = np.where(mask, np.clip(hsv[..., 2] * vscale, 0, 255), hsv[..., 2])
    return Image.fromarray(hsv.astype(np.uint8), "HSV").convert("RGB")


def hair_mask(size):
    gltf, binary = A.read_glb(os.path.join(ROOT, GLB))
    pos, nrm, uv, tris = A.mesh_arrays(gltf, binary)
    pos_map, nrm_map, valid = A.rasterise(pos, nrm, uv, tris, size)
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    unit = (pos_map - lo) / np.maximum(hi - lo, 1e-6)
    nrm_map = nrm_map / np.maximum(np.linalg.norm(nrm_map, axis=-1, keepdims=True), 1e-9)
    # The front of the face below the fringe (lips, eyes) keeps its pixels.
    face = (np.abs(unit[..., 0] - 0.5) < 0.14) & (nrm_map[..., 2] > 0.45) & (unit[..., 1] < 0.93)
    return (valid > 0) & (unit[..., 1] > HAIR_TOP) & ~face


def plate_mask(plate):
    h, s, v = hsv_arrays(plate)
    height, width = plate.size[1], plate.size[0]
    rows = np.arange(height)[:, None] / height
    cols = np.arange(width)[None, :] / width
    # The face (eyes, lips) keeps its pixels: an ellipse over the face of this plate.
    face = ((cols - FACE_CENTRE[0]) / FACE_RADII[0]) ** 2 + ((rows - FACE_CENTRE[1]) / FACE_RADII[1]) ** 2 < 1.0
    return plum(h, s, v) & (rows < 0.62) & ~face


def replace_embedded_png(src, dst, png_bytes):
    data = open(src, "rb").read()
    json_len = struct.unpack("<I", data[12:16])[0]
    gltf = json.loads(data[20:20 + json_len])
    off = 20 + json_len
    bin_len = struct.unpack("<I", data[off:off + 4])[0]
    binary = data[off + 8:off + 8 + bin_len]
    images = gltf.get("images", [])
    if len(images) != 1 or "bufferView" not in images[0]:
        raise SystemExit("expected one embedded image in %s" % src)
    target = images[0]["bufferView"]
    out = bytearray()
    for index, view in enumerate(gltf["bufferViews"]):
        chunk = png_bytes if index == target else binary[view.get("byteOffset", 0):view.get("byteOffset", 0) + view["byteLength"]]
        while len(out) % 4:
            out.append(0)
        view["byteOffset"] = len(out)
        view["byteLength"] = len(chunk)
        out += chunk
    while len(out) % 4:
        out.append(0)
    gltf["buffers"][0]["byteLength"] = len(out)
    js = json.dumps(gltf, separators=(",", ":")).encode()
    js += b" " * ((4 - len(js) % 4) % 4)
    total = 12 + 8 + len(js) + 8 + len(out)
    with open(dst, "wb") as f:
        f.write(struct.pack("<III", 0x46546C67, 2, total))
        f.write(struct.pack("<II", len(js), 0x4E4F534A) + js)
        f.write(struct.pack("<II", len(out), 0x004E4942) + bytes(out))


def main():
    vis1 = Image.open(os.path.join(ROOT, VIS1)).convert("RGB")
    h, s, v = hsv_arrays(vis1)
    mask = hair_mask(vis1.size[0]) & plum(h, s, v)
    print("hair texels: %.2f%% of the atlas" % (100.0 * mask.mean()))
    plate = Image.open(os.path.join(ROOT, PLATE)).convert("RGB")
    pmask = plate_mask(plate)
    print("plate hair pixels: %.2f%%" % (100.0 * pmask.mean()))
    maren = recolour(vis1, mask, LOOKS["maren"])
    maren.save(os.path.join(ROOT, OB + "officer_b_lod0_texture_0_vis1_maren.png"))
    recolour(plate, pmask, LOOKS["maren"]).save(os.path.join(ROOT, "assets/ui/portraits/npc_identity_stormwood_maren.png"))
    nysa = recolour(vis1, mask, LOOKS["nysa"])
    folder = os.path.join(ROOT, "assets/characters/npc_identity/stormwood_nysa")
    os.makedirs(folder, exist_ok=True)
    buffer = io.BytesIO()
    nysa.save(buffer, format="PNG", optimize=True)
    replace_embedded_png(os.path.join(ROOT, GLB), os.path.join(folder, "nysa_lod0.glb"), buffer.getvalue())
    recolour(plate, pmask, LOOKS["nysa"]).save(os.path.join(ROOT, "assets/ui/portraits/npc_identity_stormwood_nysa.png"))


if __name__ == "__main__" and "--nysa-neutral" not in sys.argv:
    main()


# --- Gender-neutral Nysa option (coordinator, 13 Nov 2026) -----------------
# Nysa keeps her current officer_a face; only her hair and plate change, so
# she separates from Varga without the game stating her gender. Built on the
# judged uniform-cloth texture (character_body_flags.json below6_uniform_cloth),
# so the variant keeps that cloth. Varga's hair is near-black, so hair here is
# the dark texels in the top 14% of the model, front of the face excluded.
OA = "assets/characters/officer_a/"
OA_GLB = OA + "officer_a_lod0.glb"
OA_CLOTH = OA + "officer_a_lod0_texture_0_vis1_cloth2.png"
OA_PLATE = "assets/ui/portraits/officer_a.png"
OA_HAIR_TOP = 0.83
OA_FACE_CENTRE = (0.46, 0.29)
OA_FACE_RADII = (0.09, 0.10)
OA_EYES_CENTRE = (0.47, 0.205)
OA_EYES_RADII = (0.12, 0.045)
NYSA_NEUTRAL = (215.0, 0.06, 3.2)


def officer_a_hair_mask(size, image):
    gltf, binary = A.read_glb(os.path.join(ROOT, OA_GLB))
    pos, nrm, uv, tris = A.mesh_arrays(gltf, binary)
    pos_map, nrm_map, valid = A.rasterise(pos, nrm, uv, tris, size)
    lo, hi = pos.min(axis=0), pos.max(axis=0)
    unit = (pos_map - lo) / np.maximum(hi - lo, 1e-6)
    nrm_map = nrm_map / np.maximum(np.linalg.norm(nrm_map, axis=-1, keepdims=True), 1e-9)
    # The eyes and brows at the very front keep their pixels. Known limit: the
    # forelock over the forehead falls inside this box and stays near-black.
    face = (np.abs(unit[..., 0] - 0.5) < 0.085) & (nrm_map[..., 2] > 0.6) & (unit[..., 1] < 0.945)
    _, _, v = hsv_arrays(image)
    return (valid > 0) & (unit[..., 1] > OA_HAIR_TOP) & ~face & (v < 0.34)


def officer_a_plate_mask(plate):
    _, _, v = hsv_arrays(plate)
    height, width = plate.size[1], plate.size[0]
    rows = np.arange(height)[:, None] / height
    cols = np.arange(width)[None, :] / width
    face = ((cols - OA_FACE_CENTRE[0]) / OA_FACE_RADII[0]) ** 2 + ((rows - OA_FACE_CENTRE[1]) / OA_FACE_RADII[1]) ** 2 < 1.0
    eyes = ((cols - OA_EYES_CENTRE[0]) / OA_EYES_RADII[0]) ** 2 + ((rows - OA_EYES_CENTRE[1]) / OA_EYES_RADII[1]) ** 2 < 1.0
    return (v < 0.25) & (rows < 0.24) & ~face & ~eyes


def nysa_neutral():
    cloth = Image.open(os.path.join(ROOT, OA_CLOTH)).convert("RGB")
    mask = officer_a_hair_mask(cloth.size[0], cloth)
    print("nysa (neutral) hair texels: %.2f%%" % (100.0 * mask.mean()))
    recolour(cloth, mask, NYSA_NEUTRAL).save(os.path.join(ROOT, OA + "officer_a_lod0_texture_0_vis1_cloth2_nysa.png"))
    plate = Image.open(os.path.join(ROOT, OA_PLATE)).convert("RGB")
    pmask = officer_a_plate_mask(plate)
    print("nysa (neutral) plate hair pixels: %.2f%%" % (100.0 * pmask.mean()))
    recolour(plate, pmask, NYSA_NEUTRAL).save(os.path.join(ROOT, "assets/ui/portraits/npc_identity_stormwood_nysa_hair.png"))


if __name__ == "__main__" and "--nysa-neutral" in sys.argv:
    nysa_neutral()
