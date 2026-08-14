"""Round-2 Galewisp: give the tail plume its mass back.

    blender --background --python tools/art_pipeline/blender/fix2_galewisp.py \
            -- <rigged.glb> --out <out.glb>

Round 1's fix cut the ground-dragging tail to 0.6x; the in-engine gate
critique says it went too far: "the tail plume is missing or vestigial...
visibly changes the character's outline from any rear or side angle — exactly
the angles the player sees most while following a creature." Re-inflate the rear
overhang and sweep it up into the concept's plume. Run on the rigged mesh —
weights are per-vertex and ride along with position edits.
"""
import math, pathlib, sys
import bpy
from mathutils import Matrix, Vector

TAIL_SCALE = 1.55
TAIL_RAISE = 14.0
TAIL_START = 0.10

def argv(): return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
def option(a, n, d=None): return a[a.index(n) + 1] if n in a else d

args = argv()
model = pathlib.Path(args[0]).resolve()
out = pathlib.Path(option(args, "--out", model.with_name("fixed2.glb"))).resolve()

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(model))
bodies = [o for o in bpy.data.objects if o.type == "MESH" and o.vertex_groups]
if not bodies:
    raise SystemExit("no skinned mesh")
body = bodies[0]

low = Vector((math.inf,) * 3); high = Vector((-math.inf,) * 3)
for c in body.bound_box:
    p = body.matrix_world @ Vector(c)
    low = Vector(map(min, low, p)); high = Vector(map(max, high, p))
size = high - low
band_top = low.z + size.z * 0.30
mid_y = (low.y + high.y) / 2
rear_foot_y = max((body.matrix_world @ v.co).y for v in body.data.vertices
                  if (body.matrix_world @ v.co).z < band_top
                  and mid_y < (body.matrix_world @ v.co).y < low.y + size.y * 0.62)
root_y = rear_foot_y + (high.y - rear_foot_y) * TAIL_START
root_z = low.z + size.z * 0.45
pivot = Vector((0.0, root_y, root_z))

def smooth(t): t = max(0.0, min(1.0, t)); return t * t * (3 - 2 * t)

touched = 0
inv = body.matrix_world.inverted()
for v in body.data.vertices:
    p = body.matrix_world @ v.co
    if p.y <= root_y: continue
    w = smooth((p.y - root_y) / (high.y - root_y + 1e-9))
    axis = Vector((0.0, p.y, root_z))
    p = axis + (p - axis) * (1.0 + (TAIL_SCALE - 1.0) * w)
    rot = Matrix.Rotation(math.radians(TAIL_RAISE) * w, 4, "X")
    p = pivot + rot @ (p - pivot)
    v.co = inv @ p
    touched += 1
body.data.update()
out.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB",
                          export_skins=True, export_animations=True, export_yup=True)
print(f"  tail: {touched} verts re-inflated {TAIL_SCALE}x, +{TAIL_RAISE} deg")
print(f"-> {out}")
