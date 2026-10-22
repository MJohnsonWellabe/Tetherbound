"""Voltarach Meshy-1022 candidate: a round-bodied spider rig and its gameplay clips.

Run in Blender with -- raw-Meshy.glb output.glb report.json.
Body = the vertices inside the measured carapace radius; every vertex outside
it belongs to the nearest of the leg columns found as peaks of the angular
histogram of outlying vertices (no other creature's numbers). Each leg is one
bone from the carapace rim to its tip, so a leg can lift (hit) and curl in
(faint). Clips: idle, scuttle, front-leg strike, the held rear-back hit, and the
judged "dead bug" faint: rolled onto its back with the legs curled in.
Exported at the installed 4.25 m (never smaller).
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector, Quaternion
root = Path(__file__).resolve().parents[6]
sys.path.insert(0, str(root / 'tools/art_pipeline/blender'))
import rig_quadruped as quad
import cleanup_mesh as cleanup

TARGET_HEIGHT = 4.25
args = sys.argv[sys.argv.index('--') + 1:]
quad.load(Path(args[0]))
body = quad.join_and_normalise()
cleanup.decimate_to(body, 28000)
for o in list(bpy.data.objects):
    if o != body:
        bpy.data.objects.remove(o, do_unlink=True)
vs = body.data.vertices
H = max(v.co.z for v in vs)
for v in vs:
    v.co /= H
body.data.update(); bpy.context.view_layer.update()


def s(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


# Carapace: the upper body's horizontal extent sets the leg radius.
top = [v.co for v in vs if v.co.z > .55]
cx = sum(p.x for p in top) / len(top); cy = sum(p.y for p in top) / len(top)
R = sorted(math.hypot(p.x - cx, p.y - cy) for p in top)[int(len(top) * .9)]
outer = [v.co for v in vs if math.hypot(v.co.x - cx, v.co.y - cy) > R * 1.05 and v.co.z < .6]
bins = [0] * 72
for p in outer:
    bins[int((math.atan2(p.y - cy, p.x - cx) + math.pi) / (2 * math.pi) * 72) % 72] += 1
sm = [sum(bins[(i + k) % 72] for k in (-1, 0, 1)) for i in range(72)]
peaks = [i for i in range(72) if sm[i] >= max(sm[(i - 1) % 72], sm[(i + 1) % 72]) and sm[i] > max(sm) * .25]
merged = []
for i in peaks:
    if not merged or min(abs(i - j) % 72 for j in merged) > 3:
        merged.append(i)
angles = [(i + .5) / 72 * 2 * math.pi - math.pi for i in merged]
legs = {}
for n, a in enumerate(angles):
    pts = [p for p in outer if abs((math.atan2(p.y - cy, p.x - cx) - a + math.pi) % (2 * math.pi) - math.pi) < .3]
    tip = max(pts, key=lambda p: math.hypot(p.x - cx, p.y - cy))
    rim = Vector((cx + R * math.cos(a), cy + R * math.sin(a), sum(p.z for p in pts) / len(pts) + .1))
    legs['leg_%d' % n] = (a, rim, tip)
c_body = Vector((cx, cy, sum(p.z for p in top) / len(top)))
bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object; rig.name = 'VoltarachMeshy1022Rig'
eb = rig.data.edit_bones
for b in list(eb):
    eb.remove(b)


def bone(n, h, t, parent=None):
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
    if parent:
        b.parent = eb[parent]


bone('root', (cx, cy, 0), (cx, cy, .1))
bone('body', (cx, cy, .25), c_body + Vector((0, 0, .2)), 'root')
for name, (a, rim, tip) in legs.items():
    bone(name, rim, tip, 'body')
bpy.ops.object.mode_set(mode='OBJECT')
groups = {b.name: body.vertex_groups.new(name=b.name) for b in rig.data.bones}
weights = []
for v in vs:
    p = v.co; d = math.hypot(p.x - cx, p.y - cy)
    leg = s(R * .9, R * 1.1, d) * (1 - s(.55, .7, p.z))
    ang = math.atan2(p.y - cy, p.x - cx)
    near = min(legs, key=lambda k: abs((ang - legs[k][0] + math.pi) % (2 * math.pi) - math.pi))
    weights.append({'body': 1 - leg, near: leg})
adj = [set() for _ in vs]
for e in body.data.edges:
    a, b = e.vertices; adj[a].add(b); adj[b].add(a)
for _ in range(3):
    nxt = []
    for i, w in enumerate(weights):
        nb = [j for j in adj[i] if (vs[j].co - vs[i].co).length < .05]
        if not nb:
            nxt.append(w); continue
        keys = set(w) | set(k for j in nb for k in weights[j])
        nxt.append({k: .8 * w.get(k, 0) + .2 * sum(weights[j].get(k, 0) for j in nb) / len(nb) for k in keys})
    weights = nxt
for v, w in zip(vs, weights):
    sel = sorted(((k, x) for k, x in w.items() if x > .001), key=lambda kv: -kv[1])[:4]; total = sum(x for _, x in sel) or 1
    for k, x in sel:
        groups[k].add([v.index], x / total, 'REPLACE')
body.parent = rig
body.modifiers.new('NativeSkin', 'ARMATURE').object = rig
for v in vs:
    v.co *= TARGET_HEIGHT
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:
    b.head *= TARGET_HEIGHT; b.tail *= TARGET_HEIGHT
bpy.ops.object.mode_set(mode='OBJECT')

bpy.context.scene.render.fps = 24
rig.animation_data_create()
bases = {b.name: b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}


def reset():
    for b in rig.pose.bones:
        b.rotation_mode = 'QUATERNION'; b.rotation_quaternion = Quaternion((1, 0, 0, 0)); b.location = (0, 0, 0)


def rotate(name, degrees, axis=(1, 0, 0)):
    basis = bases[name]
    rig.pose.bones[name].rotation_quaternion = basis.inverted() @ Quaternion(Vector(axis), math.radians(degrees)) @ basis


def lift(name, degrees):
    """Raise (+) or curl down/in (-) a leg about the horizontal axis across it."""
    a = legs[name][0]
    rotate(name, degrees, (-math.sin(a), math.cos(a), 0))


def low():
    graph = bpy.context.evaluated_depsgraph_get(); e = body.evaluated_get(graph); m = e.to_mesh()
    r = min((e.matrix_world @ v.co).z for v in m.vertices); e.to_mesh_clear(); return r


def tip_z(name, deg):
    reset(); lift(name, deg); bpy.context.view_layer.update()
    z = (rig.matrix_world @ rig.pose.bones[name].tail).z; reset(); bpy.context.view_layer.update(); return z


k0 = next(iter(legs))
UP = 1 if tip_z(k0, 10) > tip_z(k0, -10) else -1
front = sorted(legs, key=lambda k: legs[k][2].y)[:2]   # facing -Y
for role, frames in [('idle', 72), ('walk', 32), ('run', 20), ('attack', 24), ('hit', 12), ('faint', 36)]:
    action = bpy.data.actions.new(role); rig.animation_data.action = action
    for f in sorted(set(range(0, frames + 1, 2)) | {frames}):
        bpy.context.scene.frame_set(f); reset(); t = f / frames; wave = math.sin(t * 2 * math.pi)
        if role == 'idle':
            rotate('body', 1.5 * wave)
        if role in ('walk', 'run'):
            amp = 14 if role == 'walk' else 22
            for n, k in enumerate(legs):
                lift(k, UP * amp * max(0, math.sin(t * 2 * math.pi + n * math.pi)))
        if role == 'attack':
            pulse = math.sin(math.pi * min(1, t / .6)) if t < .6 else 0
            for k in front:
                lift(k, UP * 45 * pulse)
            rotate('body', -8 * pulse)
        if role == 'hit':
            e = min(1, t / .12); e = e * e * (3 - 2 * e)
            r = max(0, min(1, (t - .5) / .47)); e *= 1 - r * r * (3 - 2 * r)
            # b5/b6: hit read as standing; rear the carapace and throw every leg up.
            rotate('body', 26 * e)
            for k in legs:
                lift(k, UP * (70 if k in front else 30) * e)
        if role == 'faint':
            # b4 judges: the flip stood the spider on end at faint mid; finish it by .4.
            ph = min(1, t / .4); ph = ph * ph * (3 - 2 * ph)
            rotate('root', 165 * ph, (0, 1, 0))
            for k in legs:
                lift(k, -UP * 70 * ph)
        bpy.context.view_layer.update()
        rig.pose.bones['root'].location = bases['root'].inverted() @ Vector((0, 0, -low()))
        bpy.context.view_layer.update()
        for b in rig.pose.bones:
            b.keyframe_insert('rotation_quaternion', frame=f)
            if b.name == 'root':
                b.keyframe_insert('location', frame=f)
    for c in action.fcurves:
        for kp in c.keyframe_points:
            kp.interpolation = 'LINEAR'
    action.use_fake_user = True
    tr = rig.animation_data.nla_tracks.new(); tr.name = role; tr.mute = True; tr.strips.new(role, 1, action)
    rig.animation_data.action = None
reset(); bpy.context.scene.frame_set(0)
for tr in rig.animation_data.nla_tracks:
    tr.mute = False
for o in bpy.data.objects:
    o.select_set(o in (rig, body))
Path(args[1]).parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=args[1], export_format='GLB', use_selection=True, export_yup=True,
                          export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS')
lo, hi = quad.bounds(body)
Path(args[2]).write_text(json.dumps({'height_m': round(hi.z - lo.z, 3), 'length_m': round(hi.y - lo.y, 3),
                                     'width_m': round(hi.x - lo.x, 3), 'legs_found': len(legs), 'carapace_radius_norm': round(R, 3),
                                     'method': 'carapace_radius_angular_leg_columns_local_surface_diffusion',
                                     'candidate_enabled': False}, indent=2))
print('REPORT legs', len(legs))
