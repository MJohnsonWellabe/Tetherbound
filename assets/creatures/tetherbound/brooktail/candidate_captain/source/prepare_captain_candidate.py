"""Captain's Brooktail (F22#4 Riverwatch boss variant): measured joints and anatomical skin regions.

Run in Blender with -- raw-Meshy-multiview.glb output.glb report.json.
Copy of ../../../staticub/candidate_regen/source/prepare_regen_candidate.py (itself
from the Stormursa v3 / Burrowback multiview scripts: leg line aligned to the rig
forward axis, measured leg columns, anatomical regions, local surface diffusion; no
automatic heat or donor), with three otter-specific changes:

1. The broad paddle tail lies on the ground behind the body for almost half the
   length, so rig_quadruped.find_legs (quadrants split on the whole mesh's midline)
   would count it as rear legs. The tail start is measured first (where the
   cross-section narrows and drops below the back line) and legs are measured
   only ahead of it; front and rear pairs split at the largest gap in the foot band.
2. The head is held high directly above the front legs, so Staticub's "forward of
   the front legs" head rule would hand the chest and the front of the forelegs to
   the head. Here the head is the volume above the measured chin line in the front
   of the body, and the neck/chest band below it blends into the neck bone.
3. Tail bones follow the measured tail centreline on the ground rather than a
   straight line from the pelvis.

Harness, sash, brass buckle and forearm rope wraps are surface detail on the chest
and lower forelegs: the chest band is driven by spine/neck (no clip animates the
neck, so it moves as one piece), the rope wraps by the rigid lower-leg bones.
Exported at the installed Brooktail catalogue height (2.10 m, species.json
placeholder.height); boss size is the trainer member row's body_scale in game.
Never shrinks (trainer 1.80 m).
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector
root = Path(__file__).resolve().parents[6]
sys.path.insert(0, str(root / 'tools/art_pipeline/blender'))
import rig_quadruped as quad
import cleanup_mesh as cleanup

SPECIES = 'brooktail'
TARGET_HEIGHT = 2.10     # installed species placeholder.height; never smaller
DECIMATE_TRIS = 28000
SPINE_FRACTION = 0.62    # spine height as a fraction of the measured back top
FOOT_BAND = 0.25         # rig_quadruped.LEG_BAND

args = sys.argv[sys.argv.index('--') + 1:]
quad.load(Path(args[0]))
body = quad.join_and_normalise()          # one mesh, welded, centred, on z=0, facing -Y


def slices(points, lo_y, hi_y, n=48):
    out = []
    for i in range(n):
        y0 = lo_y + (hi_y - lo_y) * i / n; y1 = lo_y + (hi_y - lo_y) * (i + 1) / n
        sl = [p for p in points if y0 <= p.y < y1]
        out.append(((y0 + y1) / 2, sl))
    return out


def tail_start_y(points):
    """First slice behind the middle where the body narrows to a tail below the back line."""
    lo_y = min(p.y for p in points); hi_y = max(p.y for p in points)
    H = max(p.z for p in points)
    sl = slices(points, lo_y, hi_y)
    width = max((max(p.x for p in s) - min(p.x for p in s)) for _, s in sl if s)
    for y, s in sl:
        if y < (lo_y + hi_y) / 2 - .1 * (hi_y - lo_y) or not s:
            continue
        w = max(p.x for p in s) - min(p.x for p in s)
        if w < .6 * width and max(p.z for p in s) < .6 * H:
            return y - .5 * (hi_y - lo_y) / 48
    raise SystemExit('no tail found behind the body')


def find_legs_ahead_of(points, limit_y):
    H = max(p.z for p in points)
    band = sorted((p for p in points if p.z <= FOOT_BAND * H and p.y < limit_y), key=lambda p: p.y)
    gaps = [(band[i + 1].y - band[i].y, i) for i in range(len(band) - 1)]
    _, at = max(gaps)
    split = (band[at].y + band[at + 1].y) / 2
    mid_x = 0.0
    legs = {}
    for key in ('front_l', 'front_r', 'rear_l', 'rear_r'):
        front = key.startswith('front'); left = key.endswith('_l')
        pts = [p for p in band if (p.y < split) == front and (p.x < mid_x) == left]
        if not pts:
            raise SystemExit('no vertices in the %s leg quadrant' % key)
        legs[key] = sum(pts, Vector()) / len(pts)
    return legs, split


pts0 = [body.matrix_world @ v.co for v in body.data.vertices]
legs0, _ = find_legs_ahead_of(pts0, tail_start_y(pts0))
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
body.data.update(); bpy.context.view_layer.update()
lo, hi = quad.bounds(body)
L = hi.y - lo.y
P = [v.co.copy() for v in vs]


def s(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


tail_y = tail_start_y(P)
legs, leg_split = find_legs_ahead_of(P, tail_y)
front_y = (legs['front_l'].y + legs['front_r'].y) / 2
rear_y = (legs['rear_l'].y + legs['rear_r'].y) / 2
mid_y = (front_y + rear_y) / 2
half_gap = min(abs(legs['front_l'].x - legs['front_r'].x), abs(legs['rear_l'].x - legs['rear_r'].x),
               abs(front_y - rear_y)) / 2
torso = [p for p in P if leg_split < p.y < tail_y and abs(p.x) < half_gap]
back_top = max(p.z for p in torso)
spine_z = back_top * SPINE_FRACTION
knee_z = spine_z * .48
nose_y0 = min(p.y for p in P)
# Underside of the muzzle: the head starts here. The chest front sits directly
# below the chin, so only the front 4% of the length and points above the
# shoulder band count (measured 0.70 of height on the centreline profile).
snout = [p for p in P if p.y < nose_y0 + .04 * L and p.z > spine_z * 1.2]
chin_z = min(p.z for p in snout)
front_end = leg_split                     # nothing behind the leg gap is head or neck


def head_weight(p):
    return s(chin_z - .03, chin_z + .03, p.z) * (1 - s(front_end - .04 * L, front_end + .02 * L, p.y))


def neck_weight(p):
    # Throat/chest band between the shoulder line and the chin, ahead of the leg gap.
    return s(spine_z * .95, spine_z * 1.2, p.z) * (1 - s(front_end - .06 * L, front_end, p.y))


head_pts = [p for p in P if head_weight(p) > .6]
c_head = sum(head_pts, Vector()) / len(head_pts)
nose_y = min(p.y for p in head_pts)


def centre_at(y, width=.025 * L):
    sl = [p for p in P if abs(p.y - y) < width]
    return sum(sl, Vector()) / len(sl)


tail_tip_y = hi.y - .03 * L
tail_base = centre_at(tail_y)
tail_root = centre_at(tail_y + .45 * (tail_tip_y - tail_y))
tail_tip = centre_at(tail_tip_y)

bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object
rig.name = 'BrooktailCaptainRig'
eb = rig.data.edit_bones
for b in list(eb):
    eb.remove(b)


def bone(n, h, t, parent=None):
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
    if parent:
        b.parent = eb[parent]


chest = Vector((0, front_y, spine_z * 1.04))
pelvis = Vector((0, rear_y, spine_z))
head_base = Vector((0, front_y + (c_head.y - front_y) * .5, chin_z))
bone('root', (0, mid_y, 0), (0, mid_y, .13))
bone('pelvis', pelvis, (0, mid_y, spine_z * 1.02), 'root')
bone('spine', (0, mid_y, spine_z * 1.02), chest, 'pelvis')
bone('neck', chest, head_base, 'spine')
bone('head', head_base, (0, nose_y + (c_head.y - nose_y) * .2, c_head.z), 'neck')
bone('tail_1', Vector((0, tail_base.y, tail_base.z)), Vector((0, tail_root.y, tail_root.z)), 'pelvis')
bone('tail_2', Vector((0, tail_root.y, tail_root.z)), Vector((0, tail_tip.y, tail_tip.z)), 'tail_1')
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
for p in P:
    head = head_weight(p)
    neck = neck_weight(p) * (1 - head)
    pelvis_w = s(front_y, rear_y, p.y)
    tail = s(tail_y - .02 * L, tail_y + .04 * L, p.y)
    body_share = (1 - head - neck) * (1 - tail)
    w = {'spine': (1 - pelvis_w) * body_share, 'pelvis': pelvis_w * body_share, 'head': head, 'neck': neck * (1 - tail)}
    tail_split = s(tail_root.y - .03 * L, tail_root.y + .03 * L, p.y)
    w['tail_1'] = tail * (1 - tail_split); w['tail_2'] = tail * tail_split
    if p.y < tail_y + .02 * L:
        key = min(legs, key=lambda k: (p.x - legs[k].x) ** 2 + (p.y - legs[k].y) ** 2)
        col = legs[key]; distance = math.hypot(p.x - col.x, p.y - col.y)
        leg = (1 - s(half_gap * .55, half_gap * 1.05, distance)) * (1 - s(spine_z * .68, spine_z * 1.05, p.z))
        leg *= (1 - head) * (1 - tail)
        w = {k: x * (1 - leg) for k, x in w.items()}
        prefix, side = key.split('_'); upper = s(knee_z - .04, knee_z + .04, p.z)
        w[prefix + '_upper_' + side] = leg * upper
        w[prefix + '_lower_' + side] = leg * (1 - upper)
    weights.append(w)
adj = [set() for _ in vs]
for e in body.data.edges:
    a, b = e.vertices; adj[a].add(b); adj[b].add(a)
for _ in range(3):
    nxt = []
    for i, w in enumerate(weights):
        nb = [j for j in adj[i] if (P[j] - P[i]).length < .06]
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
               'leg_split_y_normalised': round(leg_split, 4), 'tail_start_y_normalised': round(tail_y, 4),
               'tail_length_m': round((hi.y - tail_y) * TARGET_HEIGHT, 4),
               'back_top_normalised': round(back_top, 4), 'chin_z_normalised': round(chin_z, 4),
               'method': 'brooktail_captain_from_staticub_regen_leg_line_aligned_tail_excluded_leg_columns_chin_line_head_anatomical_regions_local_surface_diffusion', 'candidate_enabled': False})
Path(args[2]).write_text(json.dumps(report, indent=2))
print('REPORT', json.dumps({k: v for k, v in report.items() if k != 'per_bone'}))
