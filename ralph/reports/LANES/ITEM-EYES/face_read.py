"""Fulgocobra / Mirejaw face read (LANE-KIT, 7 Nov 2026; F36 roster rows 5.78 / 5.84).
  python3 face_read.py <species> <radius_m> <lift_gamma> <emission_gain> [front|top] [emission_map_suffix]
Judges: "near-black heads; the hood/head merges with the backdrop and the face is
lost"; a whole-body value lift was flat (b25). This touches the face only: every
triangle with a vertex within <radius_m> of the head joint's bind origin (the
live remake GLB, unchanged) is rasterised into a UV mask (feathered); inside it
the albedo gets a midtone gamma lift (hue kept) and the remake's own emission
map (eyes, spots, hood lines) is multiplied by <emission_gain>. Writes
creature_<sp>_owner1101_Image_0_face.png and ..._arc_emission_face.png next to
the originals. Nothing outside the head mask changes.
"""
import json, struct, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sp, R, GAMMA, GAIN = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])
base = f"assets/creatures/tetherbound/{sp}/candidate_owner1101/models/creature_{sp}_owner1101"
data = open(base + ".glb", "rb").read()
jl = struct.unpack("<I", data[12:16])[0]
gl = json.loads(data[20:20 + jl]); off = 20 + jl + 8
CT = {5126: np.float32, 5121: np.uint8, 5123: np.uint16, 5125: np.uint32}
NC = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4, "MAT4": 16}
def acc(i):
    a = gl["accessors"][i]; bv = gl["bufferViews"][a["bufferView"]]
    s = off + bv.get("byteOffset", 0) + a.get("byteOffset", 0); dt = np.dtype(CT[a["componentType"]]); n = NC[a["type"]]
    return np.frombuffer(data[s:s + a["count"] * dt.itemsize * n], dtype=dt).reshape(a["count"], n)
pr = gl["meshes"][0]["primitives"][0]
pos = acc(pr["attributes"]["POSITION"]).astype(float)
uv = acc(pr["attributes"]["TEXCOORD_0"]).astype(float)
idx = acc(pr["indices"]).reshape(-1, 3)
skin = gl["skins"][0]
ibm = acc(skin["inverseBindMatrices"]).reshape(-1, 4, 4).transpose(0, 2, 1).astype(float)
names = [gl["nodes"][i]["name"] for i in skin["joints"]]
head = np.linalg.inv(ibm[names.index("head")])[:3, 3]
# "front": the head is the frontmost <radius_m> of the body along +Z (Mirejaw:
# its rig's head joint sits ~2 m behind the mesh snout, like the other dog3 rigs).
mode = sys.argv[5] if len(sys.argv) > 5 else ""
if mode == "front":
    near = pos[:, 2] > pos[:, 2].max() - R
elif mode == "top":  # Fulgocobra: the raised head is the top <radius_m> of the 5.2 m body
    near = pos[:, 1] > pos[:, 1].max() - R
else:
    near = np.linalg.norm(pos - head, axis=1) < R
tris = idx[near[idx].any(1)]
alb = Image.open(base + "_Image_0.jpg").convert("RGB")
W, H = alb.size
mask = Image.new("L", (W, H), 0); dr = ImageDraw.Draw(mask)
for t in tris:
    dr.polygon([(uv[k, 0] * W, uv[k, 1] * H) for k in t], fill=255)
mask = mask.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(2))
m = np.asarray(mask).astype(float)[..., None] / 255.0
a = np.asarray(alb).astype(float) / 255.0
lifted = a ** GAMMA
Image.fromarray((np.clip(a * (1 - m) + lifted * m, 0, 1) * 255).astype(np.uint8)).save(base + "_Image_0_face.png")
# The live emission map: the GLB's arc_emission, or for Fulgocobra the ON
# creatures_ralph_fulgocobra_goldvein coat's map (later coat flags replace it).
em_name = sys.argv[6] if len(sys.argv) > 6 else "arc_emission"
em = np.asarray(Image.open(base + "_" + em_name + ".png").convert("RGB")).astype(float)
if em.shape[:2] != (H, W):
    m2 = np.asarray(mask.resize((em.shape[1], em.shape[0]))).astype(float)[..., None] / 255.0
else:
    m2 = m
Image.fromarray(np.clip(em * (1 + (GAIN - 1) * m2), 0, 255).astype(np.uint8)).save(base + "_" + em_name + "_face.png")
print(sp, "head", head.round(2), "tris", len(tris), "mask frac %.4f" % (m.mean()), "emission px in mask", int(((em.sum(2) > 60) & (m2[..., 0] > 0.5)).sum()))
