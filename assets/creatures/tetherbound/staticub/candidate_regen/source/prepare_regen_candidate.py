"""Staticub cub-proportions regen candidate: aligned, measured joints and anatomical skin regions.

Run in Blender with -- raw-Meshy-multiview.glb output.glb report.json.
Copy of ../../../stormursa/source/v3/prepare_v3_candidate.py, itself a copy of ../../../burrowback/candidate_multiview/source/prepare_multiview_candidate.py
(measured leg columns, anatomical regions, local surface diffusion; no automatic
heat or donor) with the Stormursa v2 alignment:
the front-to-rear leg line is rotated onto the rig forward axis (-Y) before the
skeleton is built, and the residual leg-line angle and head-centre offset are
reported (v1 shipped 36 degrees off its rig forward). Bear knees sit halfway
down the leg. The game target is the installed Staticub 3.25 m standing
height (never shrinks; trainer 1.80 m).
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector
root = Path(__file__).resolve().parents[6]
sys.path.insert(0, str(root / 'tools/art_pipeline/blender'))
import rig_quadruped as quad
import cleanup_mesh as cleanup

SPECIES = 'staticub'
TARGET_HEIGHT = 3.25     # installed species height; never smaller
DECIMATE_TRIS = 28000
SPINE_FRACTION = 0.62    # spine height as a fraction of the measured back top
EAR_Z = 9.0              # no ear bones: above the normalised body, so no ear region
HEAD_RISE = 1.05         # head region starts this multiple of back-top height

args = sys.argv[sys.argv.index('--') + 1:]
quad.load(Path(args[0]))
body = quad.join_and_normalise()          # one mesh, welded, centred, on z=0, facing -Y
# v2 alignment: put the measured front-to-rear leg line on the rig forward axis.
legs0 = quad.find_legs(body)
f0 = (legs0['front_l'] + legs0['front_r']) / 2; r0 = (legs0['rear_l'] + legs0['rear_r']) / 2
align = math.atan2((r0 - f0).x, (r0 - f0).y)
bpy.context.view_layer.objects.active = body
body.rotation_euler.z = align; bpy.ops.object.transform_apply(rotation=True)
lo0, hi0 = quad.bounds(body)
body.location = Vector((-(lo0.x + hi0.x) / 2, -(lo0.y + hi0.y) / 2, -lo0.z)); bpy.ops.object.transform_apply(location=True)
cleanup.decimate_to(body, DECIMATE_TRIS)
for o in list(bpy.data.objects):
    if o != body:
        bpy.data.objects.remove(o, do_unlink=True)
vs = body.data.vertices
H = max(v.co.z for v in vs)
for v in vs:
    v.co /= H                             # normalised height 1 for the region rules
body.data.update(); bpy.context.view_layer.update()   # refresh bound_box for quad.bounds
lo, hi = quad.bounds(body)
L = hi.y - lo.y


def s(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


legs = quad.find_legs(body)
front_y = (legs['front_l'].y + legs['front_r'].y) / 2
rear_y = (legs['rear_l'].y + legs['rear_r'].y) / 2
mid_y = (front_y + rear_y) / 2
half_gap = min(abs(legs['front_l'].x - legs['front_r'].x), abs(legs['rear_l'].x - legs['rear_r'].x),
               abs(front_y - rear_y)) / 2
# Rear half of the torso: the head and ears never overhang it.
torso = [v.co for v in vs if mid_y < v.co.y < rear_y - .1 * (rear_y - front_y)
         and abs(v.co.x) < half_gap and v.co.z < EAR_Z]
back_top = max(p.z for p in torso)
spine_z = back_top * SPINE_FRACTION
knee_z = spine_z * .48
fore = [v.co for v in vs if v.co.y < front_y and v.co.z < EAR_Z]
head_top = max(p.z for p in fore)
raised_head = head_top > back_top * 1.1


def head_weight(p):
    forward = (1 - s(front_y - .10 * L, front_y + .02 * L, p.y)) * s(knee_z, spine_z * 1.05, p.z)
    up = 0.0
    if raised_head:
        up = s(back_top * HEAD_RISE, back_top * (HEAD_RISE + .18), p.z) * (1 - s(front_y + .05 * L, front_y + .22 * L, p.y))
    return max(forward, up)


head_pts = [v.co for v in vs if head_weight(v.co) > .6 and v.co.z < EAR_Z]
c_head = sum(head_pts, Vector()) / len(head_pts)
nose_y = min(p.y for p in head_pts)
tail_pts = [v.co for v in vs if v.co.y > hi.y - .05 * L]
c_tail = sum(tail_pts, Vector()) / len(tail_pts)
ear_info = {}
for side, sign in (('l', -1), ('r', 1)):
    pts = [v.co for v in vs if v.co.z > EAR_Z and sign * v.co.x > 0]
    if pts:
        base = [p for p in pts if p.z < EAR_Z + .05] or pts
        top = max(p.z for p in pts)
        tip = [p for p in pts if p.z > top - .05]
        ear_info[side] = (sum(base, Vector()) / len(base), sum(tip, Vector()) / len(tip))

bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object
rig.name = SPECIES.capitalize() + 'RegenRig'
eb = rig.data.edit_bones
for b in list(eb):
    eb.remove(b)


def bone(n, h, t, parent=None):
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
    if parent:
        b.parent = eb[parent]


chest = Vector((0, front_y, spine_z * 1.04))
pelvis = Vector((0, rear_y, spine_z))
head_base = Vector((0, front_y + (c_head.y - front_y) * .5, spine_z + (c_head.z - spine_z) * .7))
bone('root', (0, mid_y, 0), (0, mid_y, .13))
bone('pelvis', pelvis, (0, mid_y, spine_z * 1.02), 'root')
bone('spine', (0, mid_y, spine_z * 1.02), chest, 'pelvis')
bone('neck', chest, head_base, 'spine')
bone('head', head_base, (0, nose_y + (c_head.y - nose_y) * .2, c_head.z), 'neck')
tail_root = pelvis.lerp(Vector((0, c_tail.y, c_tail.z)), .5)
bone('tail_1', pelvis, tail_root, 'pelvis')
bone('tail_2', tail_root, (0, c_tail.y, c_tail.z), 'tail_1')
for side, (base, tip) in ear_info.items():
    bone('ear_' + side, base, tip, 'head')
for key, col in legs.items():
    prefix, side = key.split('_')
    upper = prefix + '_upper_' + side; lower = prefix + '_lower_' + side
    knee = (col.x, col.y + (.02 if prefix == 'front' else -.02), knee_z)
    bone(upper, (col.x * .88, col.y, spine_z * .95), knee, 'spine' if prefix == 'front' else 'pelvis')
    bone(lower, knee, (col.x, col.y - .015, .02), upper)
bpy.ops.object.mode_set(mode='OBJECT')

for vg in list(body.vertex_groups):
    body.vertex_groups.remove(vg)
groups = {b.name: body.vertex_groups.new(name=b.name) for b in rig.data.bones}
weights = []
for v in vs:
    p = v.co
    head = head_weight(p)
    neck = s(c_head.y, front_y, p.y) * .6   # rear of the head region blends into the neck
    pelvis_w = s(front_y, rear_y, p.y)
    tail = s(rear_y + .35 * (hi.y - rear_y), rear_y + .6 * (hi.y - rear_y), p.y) * (1 - s(half_gap * .6, half_gap * 1.1, abs(p.x)))
    tail *= s(knee_z * .5, knee_z, p.z)
    w = {'spine': (1 - pelvis_w) * (1 - head) * (1 - tail), 'pelvis': pelvis_w * (1 - head) * (1 - tail),
         'head': head * (1 - neck), 'neck': head * neck}
    tail_split = s(tail_root.y - .02 * L, tail_root.y + .04 * L, p.y)
    w['tail_1'] = tail * (1 - tail_split); w['tail_2'] = tail * tail_split
    if ear_info:
        ear = s(EAR_Z, EAR_Z + .06, p.z)
        if ear > 0:
            w = {k: x * (1 - ear) for k, x in w.items()}
            w['ear_l' if p.x < 0 else 'ear_r'] = ear
    key = min(legs, key=lambda k: (p.x - legs[k].x) ** 2 + (p.y - legs[k].y) ** 2)
    col = legs[key]; distance = math.hypot(p.x - col.x, p.y - col.y)
    leg = (1 - s(half_gap * .55, half_gap * 1.05, distance)) * (1 - s(spine_z * .68, spine_z * 1.05, p.z))
    leg *= (1 - head)
    w = {k: x * (1 - leg) for k, x in w.items()}
    prefix, side = key.split('_'); upper = s(knee_z - .04, knee_z + .04, p.z)
    w[prefix + '_upper_' + side] = leg * upper
    w[prefix + '_lower_' + side] = leg * (1 - upper)
    weights.append(w)
# Spatially local surface diffusion, as in the precedent: smooths transition
# edges without cross-leg donor transfer.
adj = [set() for _ in vs]
for e in body.data.edges:
    a, b = e.vertices; adj[a].add(b); adj[b].add(a)
for _ in range(3):
    nxt = []
    for i, w in enumerate(weights):
        nb = [j for j in adj[i] if (vs[j].co - vs[i].co).length < .06]
        if not nb:
            nxt.append(w); continue
        out = {}
        for name in groups:
            value = .8 * w.get(name, 0) + .2 * sum(weights[j].get(name, 0) for j in nb) / len(nb)
            if value > .0005:
                out[name] = value
        nxt.append(out)
    weights = nxt
for v, w in zip(vs, weights):
    sel = sorted(w.items(), key=lambda x: x[1], reverse=True)[:4]; total = sum(x for _, x in sel)
    if total <= 0:
        sel = [('spine', 1.0)]; total = 1.0
    for name, value in sel:
        if value > 0:
            groups[name].add([v.index], value / total, 'REPLACE')
body.parent = rig
mod = body.modifiers.new('NativeSkin', 'ARMATURE'); mod.object = rig
# Export at the established installed height; never shrink the creature.
for v in vs:
    v.co *= TARGET_HEIGHT
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:
    b.head *= TARGET_HEIGHT; b.tail *= TARGET_HEIGHT
bpy.ops.object.mode_set(mode='OBJECT')
lo2, hi2 = quad.bounds(body)
for o in bpy.data.objects:
    o.select_set(o in (rig, body))
Path(args[1]).parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=args[1], export_format='GLB', use_selection=True, export_yup=True,
                          export_skins=True, export_animations=False)
report = quad.weight_report(body)
fl = (legs['front_l'] + legs['front_r']) / 2; rl = (legs['rear_l'] + legs['rear_r']) / 2
report.update({'align_applied_deg': round(math.degrees(align), 3),
               'residual_leg_line_deg': round(math.degrees(math.atan2((rl - fl).x, (rl - fl).y)), 3),
               'head_centre_x_normalised': round(c_head.x, 4), 'nose_y_normalised': round(nose_y, 4),
               'head_yaw_from_rig_forward_deg': round(math.degrees(math.atan2(c_head.x, front_y - c_head.y)), 3),
               'height_m': round(hi2.z - lo2.z, 4), 'length_m': round(hi2.y - lo2.y, 4), 'width_m': round(hi2.x - lo2.x, 4),
               'triangles': sum(len(p.vertices) - 2 for p in body.data.polygons), 'bones': len(groups),
               'legs_found_at_normalised': {k: [round(c, 4) for c in v] for k, v in legs.items()},
               'back_top_normalised': round(back_top, 4), 'raised_head': raised_head, 'ears': sorted(ear_info),
               'method': 'staticub_regen_from_stormursa_v3_leg_line_aligned_measured_leg_columns_anatomical_regions_local_surface_diffusion', 'candidate_enabled': False})
Path(args[2]).write_text(json.dumps(report, indent=2))
print('REPORT', json.dumps({k: v for k, v in report.items() if k != 'per_bone'}))
