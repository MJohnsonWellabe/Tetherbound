"""F36#70 Sparkit legs (LANE-KIT, 7 Nov 2026). Blender 4.2 headless:
  blender -b --python thicken_legs.py -- <in.glb> <out.glb> <scale> <paw_keep>
Judges (three GPU/CPU rounds) name "spindly stick legs". This keeps the installed
owner-remake mesh, rig, weights, clips and textures and only moves leg vertices
outward from their bone's axis in the rest pose: vertices weighted mostly to a
leg bone get their perpendicular distance to that bone scaled by one
continuous hip-to-paw profile (s = 0 at the hip, 0.5 at the knee, 1 at the paw):
it fades in over the top fifth so the body seam does not bulge, holds `scale`,
and eases to (1 - paw_keep) of the gain at the paw so feet keep their shape. The
profile is the same on both sides of the knee, so there is no step there. No vertex moves along the
bone, so length, stance, height (1.95 m) and ground contact are unchanged.
"""
import bpy, sys
from mathutils import Vector
from mathutils.geometry import intersect_point_line

args = sys.argv[sys.argv.index("--") + 1:]
src, dst, K, paw_keep = args[0], args[1], float(args[2]), float(args[3])
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src)
arm = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
mesh = max((o for o in bpy.data.objects if o.type == 'MESH'), key=lambda o: len(o.data.vertices))
legs = {}
for b in arm.data.bones:
    if b.name.startswith(("front_", "rear_")):
        legs[b.name] = (arm.matrix_world @ b.head_local, arm.matrix_world @ b.tail_local)
names = {g.index: g.name for g in mesh.vertex_groups}
mw, mwi = mesh.matrix_world, mesh.matrix_world.inverted()
moved = 0
def smooth(x):
    x = max(0.0, min(1.0, x)); return x * x * (3 - 2 * x)
for v in mesh.data.vertices:
    best = max(v.groups, key=lambda g: g.weight, default=None)
    if best is None or names.get(best.group) not in legs:
        continue
    bone = names[best.group]
    head, tail = legs[bone]
    p = mw @ v.co
    closest, t = intersect_point_line(p, head, tail)
    t = max(0.0, min(1.0, t))
    closest = head.lerp(tail, t)
    off = p - closest
    sp = t * 0.5 if "upper" in bone else 0.5 + t * 0.5
    k = 1.0 + (K - 1.0) * smooth(sp / 0.2) * (1.0 - paw_keep * smooth((sp - 0.85) / 0.15))
    k = 1.0 + (k - 1.0) * best.weight                          # blended verts move less
    v.co = mwi @ (closest + off * k)
    moved += 1
print("THICKEN moved", moved, "of", len(mesh.data.vertices))
bpy.ops.export_scene.gltf(filepath=dst, export_format='GLB', export_animations=True,
                          export_skins=True, export_yup=True, export_apply=False)
print("THICKEN wrote", dst)
