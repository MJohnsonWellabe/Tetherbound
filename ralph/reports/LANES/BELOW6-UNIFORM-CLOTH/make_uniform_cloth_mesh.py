"""F41#18 Stormwood uniforms (LANE-BELOW6, 13 Nov 2026): garment mask from the mesh.

Coordinator's idea after the colour-selection passes failed (NOT-SENT.md): the uniform bodies are
skinned, so each triangle's dominant bone says what it is. Triangles dominated by a garment bone
(hips, legs, feet, spine, shoulders, upper arms) are rasterised into UV space as the garment mask;
head, neck, forearm and hand triangles are left out, which covers hair, face and bare skin.

Inputs per body: <key>_lod0.glb (read only: UVs, joints, weights) and the live body texture.
Outputs: <texture>_cloth2.png
  - inside the garment mask, dark pixels (the cloth) are lifted to a mid value with a cool slate
    cast, fold detail kept; bright pixels there (skin at a short sleeve, emblems, buckles) are kept;
  - triangles dominated by a shoulder bone get a brass band (the rank accent), sized by the
    mesh itself;
  - everything outside the mask is untouched.
The .glb files are not modified. Nothing is red.
"""
import hashlib
import json
import struct
import sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter

BODIES = [
    ("assets/characters/grunt_c/grunt_c_lod0.glb", "assets/characters/grunt_c/grunt_c_lod0_texture_0_vis1.png"),
    ("assets/characters/officer_a/officer_a_lod0.glb", "assets/characters/officer_a/officer_a_lod0_texture_0_vis1.png"),
    ("assets/characters/former_tether_member/former_tether_member_lod0.glb",
        "assets/characters/former_tether_member/former_tether_member_lod0_texture_0.png"),
]
GARMENT = ("Hips", "UpLeg", "Leg", "Foot", "Toe", "Spine", "Shoulder", "LeftArm", "RightArm")
SKIN = ("ForeArm", "Hand", "neck", "Head", "head")
SLATE = np.array([0.60, 0.63, 0.70], dtype=np.float32)
BRASS = np.array([0.80, 0.60, 0.24], dtype=np.float32)
COMPONENT = {5120: "b", 5121: "B", 5122: "h", 5123: "H", 5125: "I", 5126: "f"}
COUNT = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def read_glb(path):
    with open(path, "rb") as handle:
        handle.read(12)
        size, _ = struct.unpack("<II", handle.read(8))
        doc = json.loads(handle.read(size))
        size, _ = struct.unpack("<II", handle.read(8))
        return doc, handle.read(size)


def accessor(doc, blob, index):
    acc = doc["accessors"][index]
    view = doc["bufferViews"][acc["bufferView"]]
    kind = np.dtype(COMPONENT[acc["componentType"]])
    width = COUNT[acc["type"]]
    start = view.get("byteOffset", 0) + acc.get("byteOffset", 0)
    stride = view.get("byteStride", 0) or kind.itemsize * width
    raw = np.frombuffer(blob, dtype=np.uint8, count=stride * acc["count"], offset=start)
    rows = np.lib.stride_tricks.as_strided(raw, (acc["count"], kind.itemsize * width), (stride, 1))
    return np.frombuffer(rows.tobytes(), dtype=kind).reshape(acc["count"], width)


def classify(name):
    if any(part in name for part in SKIN):
        return "skin"
    if "Shoulder" in name:
        return "shoulder"
    return "garment" if any(part in name for part in GARMENT) else "skin"


probe_only = "--probe" in sys.argv
for glb, texture in BODIES:
    doc, blob = read_glb(glb)
    prim = doc["meshes"][0]["primitives"][0]
    uv = accessor(doc, blob, prim["attributes"]["TEXCOORD_0"]).astype(np.float32)
    joints = accessor(doc, blob, prim["attributes"]["JOINTS_0"]).astype(np.int64)
    weights = accessor(doc, blob, prim["attributes"]["WEIGHTS_0"]).astype(np.float32)
    indices = accessor(doc, blob, prim["indices"]).reshape(-1, 3)
    names = [doc["nodes"][node].get("name", "") for node in doc["skins"][0]["joints"]]
    bone_count = len(names)
    src = Image.open(texture).convert("RGB")
    size = src.size[0]
    garment_img = Image.new("L", src.size, 0)
    brass_img = Image.new("L", src.size, 0)
    draw_g, draw_b = ImageDraw.Draw(garment_img), ImageDraw.Draw(brass_img)
    tally = {"garment": 0, "shoulder": 0, "skin": 0}
    blended = 0
    for tri in indices:
        total = np.zeros(bone_count, dtype=np.float32)
        for vertex in tri:
            np.add.at(total, joints[vertex], weights[vertex])
        dominant = int(total.argmax())
        if total[dominant] / max(total.sum(), 1e-6) < 0.5:
            blended += 1
        kind = classify(names[dominant])
        tally[kind] += 1
        if kind == "skin":
            continue
        polygon = [(float(uv[v][0]) * size, float(uv[v][1]) * size) for v in tri]
        draw_g.polygon(polygon, fill=255)
        if kind == "shoulder":
            draw_b.polygon(polygon, fill=255)
    print(glb.split("/")[-1], "triangles", len(indices), tally, "under-half dominant %.1f%%" % (100.0 * blended / len(indices)))
    if probe_only:
        garment_img.save(texture[:-4] + "_garment_mask_probe.png")
        continue
    rgb = np.asarray(src, dtype=np.float32) / 255.0
    val = rgb.max(-1)
    garment = np.asarray(garment_img, dtype=np.float32) / 255.0
    cloth = garment * np.clip((0.5 - val) / 0.12, 0.0, 1.0)
    cloth = np.asarray(Image.fromarray((cloth * 255).astype(np.uint8), "L").filter(ImageFilter.GaussianBlur(1.5)),
        dtype=np.float32) / 255.0
    detail = np.asarray(src.convert("L").filter(ImageFilter.UnsharpMask(radius=4, percent=100, threshold=0)),
        dtype=np.float32) / 255.0
    lifted = np.clip(0.17 + val * 1.05 + (detail - rgb.mean(-1)) * 0.35, 0.08, 0.6)
    target = SLATE[None, None, :] * (lifted / SLATE.mean())[..., None]
    out = rgb * (1 - cloth[..., None]) + target * cloth[..., None]
    brass = np.asarray(brass_img.filter(ImageFilter.GaussianBlur(1.0)), dtype=np.float32) / 255.0
    shade = np.clip(0.75 + (detail - 0.5) * 0.8, 0.55, 1.1)
    out = out * (1 - brass[..., None]) + (BRASS[None, None, :] * shade[..., None]) * brass[..., None]
    dst = texture[:-4] + "_cloth2.png"
    Image.fromarray((np.clip(out, 0, 1) * 255).astype(np.uint8), "RGB").save(dst)
    print("  src sha256", hashlib.sha256(open(texture, "rb").read()).hexdigest()[:16],
        "garment %.2f cloth %.2f brass %.3f" % (garment.mean(), (cloth > 0.5).mean(), (brass > 0.5).mean()))
