# F38#6 (LANE-MS, 7 Nov 2026): reskin of the installed Meshy rare-candy pickup.
# Source: assets/props/meshy-1020/candy_pickup_set/model_candy_rare/candy_rare.glb
# (Meshy task 01a15c3f-dc02-777b-8150-fd9f2cd2d9e0). Geometry is unchanged; only
# the base-colour texels of the cloth (faces in the lower CLOTH_FRAC of the
# model's height) that are pale and unsaturated move to a deep blue velvet,
# keeping their shading. The gold trim and the sweets keep their colours.
#   blender -b --python candy_rare_cloth_r1.py -- <repo root>
import bpy, sys, os, colorsys
import numpy as np

ROOT = sys.argv[sys.argv.index("--") + 1]
SRC = os.path.join(ROOT, "assets/props/meshy-1020/candy_pickup_set/model_candy_rare/candy_rare.glb")
OUT_DIR = os.path.join(ROOT, "assets/props/meshy-1020/candy_pickup_set/model_candy_rare_cloth_r1")
CLOTH_FRAC = 0.47          # lower share of the model height that is cloth
SAT_MAX = 0.42             # pale cream texels only (gold trim is saturated)
VAL_MIN = 0.45
VELVET = np.array([0.105, 0.215, 0.36])   # #1b375c deep blue, not red
os.makedirs(OUT_DIR, exist_ok=True)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
obj = [o for o in bpy.data.objects if o.type == "MESH"][0]
me = obj.data
zs = [(obj.matrix_world @ v.co).z for v in me.vertices]
z0, z1 = min(zs), max(zs)
cut = z0 + CLOTH_FRAC * (z1 - z0)

img = bpy.data.images["Image_0"]
w, h = img.size
px = np.array(img.pixels[:], dtype=np.float32).reshape(h, w, 4)
mask = np.zeros((h, w), dtype=bool)
uv = me.uv_layers.active.data
mask = np.zeros((h, w), dtype=bool)   # row 0 = bottom (Blender pixel order)
def fill_tri(a, b, c):
    xs = (a[0], b[0], c[0]); ys = (a[1], b[1], c[1])
    x0, x1 = max(int(min(xs)), 0), min(int(max(xs)) + 1, w - 1)
    y0, y1 = max(int(min(ys)), 0), min(int(max(ys)) + 1, h - 1)
    if x1 < x0 or y1 < y0:
        return
    gx, gy = np.meshgrid(np.arange(x0, x1 + 1) + 0.5, np.arange(y0, y1 + 1) + 0.5)
    d = (b[1] - c[1]) * (a[0] - c[0]) + (c[0] - b[0]) * (a[1] - c[1])
    if abs(d) < 1e-9:
        return
    l1 = ((b[1] - c[1]) * (gx - c[0]) + (c[0] - b[0]) * (gy - c[1])) / d
    l2 = ((c[1] - a[1]) * (gx - c[0]) + (a[0] - c[0]) * (gy - c[1])) / d
    inside = (l1 >= -0.02) & (l2 >= -0.02) & (1.0 - l1 - l2 >= -0.02)
    mask[y0:y1 + 1, x0:x1 + 1] |= inside
for poly in me.polygons:
    cz = sum((obj.matrix_world @ me.vertices[i].co).z for i in poly.vertices) / len(poly.vertices)
    if cz > cut:
        continue
    pts = [(uv[li].uv[0] * w, uv[li].uv[1] * h) for li in poly.loop_indices]
    for k in range(1, len(pts) - 1):
        fill_tri(pts[0], pts[k], pts[k + 1])
rgb = px[:, :, :3]
mx = rgb.max(axis=2); mn = rgb.min(axis=2)
sat = np.where(mx > 1e-4, (mx - mn) / np.maximum(mx, 1e-4), 0.0)
sel = mask & (sat < SAT_MAX) & (mx > VAL_MIN)
lum = (0.3 * rgb[:, :, 0] + 0.59 * rgb[:, :, 1] + 0.11 * rgb[:, :, 2])
shade = np.clip(lum / max(np.percentile(lum[sel], 90), 1e-3), 0.55, 1.15)
rgb[sel] = VELVET[None, :] * shade[sel][:, None] * 1.25
px[:, :, :3] = rgb
img.pixels[:] = px.ravel()
print("cloth texels recoloured:", int(sel.sum()), "of mask", int(mask.sum()))
new_name = "candy_rare_cloth_r1_base"
img.name = new_name
img.filepath_raw = os.path.join(OUT_DIR, new_name + ".png")
img.file_format = "PNG"
img.save()
# The glTF importer packs its images; re-load the edited PNG so the exporter
# writes the recoloured texels, not the original packed bytes.
img.unpack(method="REMOVE") if img.packed_file else None
img.filepath = img.filepath_raw
img.source = "FILE"
img.reload()
img.pack()
bpy.ops.export_scene.gltf(filepath=os.path.join(OUT_DIR, "candy_rare_cloth_r1.glb"),
    export_format="GLB", export_image_format="AUTO")
print("wrote", OUT_DIR)
