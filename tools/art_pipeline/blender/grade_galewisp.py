"""Grade Galewisp: warm the creams, mute the blues, keep the gold.

    blender --background --python tools/art_pipeline/blender/grade_galewisp.py \
            -- <animated.glb> --out <graded.glb>

The gate critique: "the in-engine model is stark white with saturated, glossy
ice-cyan ears and wings, so at gameplay distance it reads as an Ice-type
sprite, not a wind-fox." Sheet 03's palette is warm cream/beige down, MUTED
slate-blue feathers, gold accents. Two hue-targeted moves: blown whites blend
toward warm cream, and saturated cyans desaturate-and-darken toward slate.
Gold/tan pixels are guarded — they are the accents the critique missed.
"""
import pathlib, sys
import bpy
import numpy as np

ROUGHNESS_FLOOR = 0.78
CREAM = np.array((0.90, 0.84, 0.72), dtype=np.float32)
CREAM_BLEND = 0.45
SLATE = np.array((0.42, 0.55, 0.66), dtype=np.float32)
SLATE_BLEND = 0.60

def argv(): return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def option(a, n, d=None): return a[a.index(n) + 1] if n in a else d

def rgb_to_hsv(rgb):
    maxc = rgb.max(axis=-1); minc = rgb.min(axis=-1)
    value = maxc; delta = maxc - minc
    sat = np.where(maxc > 1e-6, delta / np.maximum(maxc, 1e-6), 0.0)
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    hue = np.zeros_like(maxc); mask = delta > 1e-6
    rm = mask & (maxc == r); gm = mask & (maxc == g) & ~rm; bm = mask & ~rm & ~gm
    hue[rm] = ((g - b)[rm] / delta[rm]) % 6
    hue[gm] = ((b - r)[gm] / delta[gm]) + 2
    hue[bm] = ((r - g)[bm] / delta[bm]) + 4
    return hue * 60.0, sat, value

def grade(image):
    px = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    rgb = px[:, :3].copy()
    hue, sat, val = rgb_to_hsv(rgb)
    gold = (hue > 25) & (hue < 70) & (sat > 0.18)          # guarded
    white = (sat < 0.12) & (val > 0.72) & ~gold
    shading = np.clip(val[..., None] / 0.95, 0, 1)
    rgb[white] = rgb[white] * (1 - CREAM_BLEND) + CREAM * shading[white] * CREAM_BLEND
    cyan = (hue > 150) & (hue < 235) & (sat > 0.15) & ~gold
    rgb[cyan] = rgb[cyan] * (1 - SLATE_BLEND) + SLATE * shading[cyan] * SLATE_BLEND
    px[:, :3] = np.clip(rgb, 0, 1)
    image.pixels[:] = px.reshape(-1).tolist()
    image.pack()

def matte(image):
    px = np.array(image.pixels[:], dtype=np.float32).reshape(-1, 4)
    px[:, 1] = np.maximum(px[:, 1], ROUGHNESS_FLOOR); px[:, 2] = 0.0
    image.pixels[:] = px.reshape(-1).tolist()
    image.pack()

args = argv()
model = pathlib.Path(args[0]).resolve()
out = pathlib.Path(option(args, "--out", model.with_name("graded.glb"))).resolve()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(model))
for mat in bpy.data.materials:
    if not mat.use_nodes: continue
    for node in mat.node_tree.nodes:
        if node.type != "TEX_IMAGE" or node.image is None: continue
        feeds = {l.to_node.type for o in node.outputs for l in o.links}
        if "NORMAL_MAP" in feeds: continue
        if node.image.colorspace_settings.name == "sRGB":
            grade(node.image); print(f"  graded: {node.image.name}")
        else:
            matte(node.image); print(f"  matted: {node.image.name}")
    for node in mat.node_tree.nodes:
        if node.type == "BSDF_PRINCIPLED":
            node.inputs["Metallic"].default_value = 0.0
            node.inputs["Specular IOR Level"].default_value = 0.25
out.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                          export_animations=True, export_animation_mode="NLA_TRACKS",
                          export_skins=True, export_yup=True)
print(f"-> {out}")
