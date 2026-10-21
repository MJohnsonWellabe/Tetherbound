"""Measure that the Staticub regen candidate's legs and neck actually deform.

Copy of ../../../stormursa/source/v3/check_v3_deformation.py.

Run in Blender with -- rigged.glb report.json.
For each tested bone, rotate it 30 degrees about the world X axis at its head
(the same basis conjugation as author_native_clips.py) and compare each strongly
weighted (>0.9) vertex of its distal region with the rigid-rotation displacement
it should have. A ratio near 1 means the skin follows the bone; v1-style
failure reads near 0. Also records clip-frame displacements per region.
"""
import bpy, math, sys, json, statistics
from mathutils import Vector, Quaternion, Matrix
a = sys.argv[sys.argv.index('--') + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
rig = next(o for o in bpy.data.objects if o.type == 'ARMATURE')
body = max((o for o in bpy.data.objects if o.type == 'MESH' and o.vertex_groups), key=lambda o: len(o.data.vertices))
if rig.animation_data:
    rig.animation_data.action = None
    for t in rig.animation_data.nla_tracks: t.mute = True
bases = {b.name: b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}
names = {g.index: g.name for g in body.vertex_groups}
def dominant(v):
    best = max(v.groups, key=lambda g: g.weight, default=None)
    return (names[best.group], best.weight) if best else (None, 0)
def reset():
    for b in rig.pose.bones:
        b.rotation_mode = 'QUATERNION'; b.rotation_quaternion = Quaternion((1, 0, 0, 0)); b.location = (0, 0, 0)
def evaluated():
    bpy.context.view_layer.update()
    g = bpy.context.evaluated_depsgraph_get(); e = body.evaluated_get(g); m = e.to_mesh()
    pts = [e.matrix_world @ v.co for v in m.vertices]; e.to_mesh_clear(); return pts
reset(); rest = evaluated()
TESTS = {'front_upper_l': 'front_lower_l', 'front_upper_r': 'front_lower_r', 'rear_upper_l': 'rear_lower_l',
         'rear_upper_r': 'rear_lower_r', 'neck': 'head', 'head': 'head'}
ANGLE = math.radians(30)
out = {'rotation_deg': 30, 'tests': {}}
for bone, region in TESTS.items():
    reset()
    rig.pose.bones[bone].rotation_quaternion = bases[bone].inverted() @ Quaternion(Vector((1, 0, 0)), ANGLE) @ bases[bone]
    posed = evaluated()
    pivot = rig.matrix_world @ rig.data.bones[bone].head_local
    rot = Matrix.Rotation(ANGLE, 3, 'X')
    ratios = []; moved = 0; idx = []
    for i, v in enumerate(body.data.vertices):
        n, w = dominant(v)
        if n == region and w > .9:
            idx.append(i)
            expect = (rot @ (rest[i] - pivot) + pivot - rest[i]).length
            actual = (posed[i] - rest[i]).length
            if expect > 1e-3: ratios.append(actual / expect)
            if actual > .05: moved += 1
    out['tests'][bone] = {'region': region, 'vertices': len(idx), 'median_follow_ratio': round(statistics.median(ratios), 3) if ratios else None,
                          'moved_over_5cm': moved}
# Clip extremes: max region displacement over each clip relative to rest.
clips = {}
if rig.animation_data:
    for track in rig.animation_data.nla_tracks:
        for t in rig.animation_data.nla_tracks: t.mute = (t != track)
        strip = track.strips[0]; best = {}
        reset()
        for f in range(int(strip.frame_start), int(strip.frame_end) + 1, 3):
            bpy.context.scene.frame_set(f); pts = evaluated()
            for i, v in enumerate(body.data.vertices):
                n, w = dominant(v)
                if w > .6: best[n] = max(best.get(n, 0), (pts[i] - rest[i]).length)
        clips[track.name] = {k: round(x, 3) for k, x in sorted(best.items())}
        track.mute = True
out['clip_max_region_displacement_m'] = clips
json.dump(out, open(a[1], 'w'), indent=2)
print('DEFORM', json.dumps(out['tests']))
