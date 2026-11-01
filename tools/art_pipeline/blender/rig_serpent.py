"""Serpent remake rig (1 Nov 2026): a raised body over a grounded coil.

    blender --background --python tools/art_pipeline/blender/rig_serpent.py -- \
        raw.glb out.glb report.json '{"species":"fulgocobra","height":5.2}'

For the two owner-rule serpents (Aquaryn, Fulgocobra), whose Meshy poses stand a
raised neck and hood over a coil on the ground. No installed rig fits a legless
body: rig_quadruped needs four leg columns and rig_bird two feet. The raised
column is measured, not guessed: horizontal slices above `coil` (fraction of
height) are walked from the top down, each slice's centroid taken from the
points nearest the previous one, so the chain follows the neck even when the
coil passes beside it. Five chain bones (spine_1..spine_4, head) run along those
centroids; the coil below stays on the root (blended over a short band), so it
reads planted while the column sways, strikes, recoils and folds.

Clips (gameplay roles of both species): idle, walk, run, attack, hit, faint.
Every frame grounds the lowest evaluated vertex, as dog3's clip author does.
Mesh preparation is the quadruped one (rig_quadruped.join_and_normalise,
strip_ground_patch.auto, cleanup_mesh.decimate_to).
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector, Quaternion
root_dir = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(root_dir / 'tools/art_pipeline/blender'))
import rig_quadruped as quad
import cleanup_mesh as cleanup
import strip_ground_patch as patch

args = sys.argv[sys.argv.index('--') + 1:]
P = json.loads(args[3])
HEIGHT = float(P['height'])
COIL = float(P.get('coil', .30))
quad.load(Path(args[0]))
body = quad.join_and_normalise()
patch_report = patch.auto(body)
cleanup.decimate_to(body, int(P.get('tris', 28000)))
for o in list(bpy.data.objects):
    if o != body:
        bpy.data.objects.remove(o, do_unlink=True)
vs = body.data.vertices
H = max(v.co.z for v in vs)
for v in vs:
    v.co /= H
body.data.update()


def s(a, b, x):
    t = max(0.0, min(1.0, (x - a) / (b - a)))
    return t * t * (3 - 2 * t)


# Walk the column from the top down.
pts = [v.co.copy() for v in vs]
N = 14
cents = []
prev = None
for i in range(N):
    z1 = 1.0 - i * (1.0 - COIL) / N
    z0 = z1 - (1.0 - COIL) / N
    sl = [p for p in pts if z0 <= p.z < z1]
    if prev is not None and sl:
        sl.sort(key=lambda p: (p.x - prev.x) ** 2 + (p.y - prev.y) ** 2)
        sl = sl[:max(8, len(sl) // 2)]
    if not sl:
        continue
    c = sum(sl, Vector()) / len(sl)
    c.z = (z0 + z1) / 2
    cents.append(c); prev = c
cents.reverse()                       # bottom (coil top) -> crown
top = max(pts, key=lambda p: p.z)
head_pts = [p for p in pts if p.z > .85]
nose = min(head_pts, key=lambda p: p.y)   # glTF front is -Y
base = Vector((cents[0].x, cents[0].y, COIL * .8))
idx = [0, len(cents) // 4, len(cents) // 2, (3 * len(cents)) // 4, len(cents) - 1]
joints = [base] + [cents[i] for i in idx[1:]] + [Vector((nose.x, nose.y, cents[-1].z))]

bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object
rig.name = P['species'].capitalize() + 'SerpentRig'
eb = rig.data.edit_bones
for b in list(eb):
    eb.remove(b)
names = ['spine_1', 'spine_2', 'spine_3', 'spine_4', 'head']
r = eb.new('root'); r.head = (base.x, base.y, 0); r.tail = (base.x, base.y, .1)
parent = 'root'
for n, a, b in zip(names, joints[:-1], joints[1:]):
    e = eb.new(n); e.head = a; e.tail = b if (b - a).length > 1e-3 else a + Vector((0, 0, .05))
    e.parent = eb[parent]; parent = n
bpy.ops.object.mode_set(mode='OBJECT')

# Weights: the coil on the root; the column by height along the chain.
zs = [j.z for j in joints]
groups = {b.name: body.vertex_groups.new(name=b.name) for b in rig.data.bones}
for v in vs:
    p = v.co
    lift = s(COIL * .75, COIL * 1.05, p.z)
    w = {'root': 1 - lift}
    for k, n in enumerate(names):
        lo, hi = zs[k], zs[k + 1]
        span = max(hi - lo, 1e-3)
        a = s(lo - .3 * span, lo + .3 * span, p.z)
        b = 1 - s(hi - .3 * span, hi + .3 * span, p.z) if n != 'head' else 1.0
        w[n] = lift * a * b
    tot = sum(w.values()) or 1.0
    for n, x in sorted(w.items(), key=lambda t: -t[1])[:4]:
        if x / tot > .001:
            groups[n].add([v.index], x / tot, 'REPLACE')
body.parent = rig
mod = body.modifiers.new('SerpentSkin', 'ARMATURE'); mod.object = rig
for v in vs:
    v.co *= HEIGHT
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:
    b.head *= HEIGHT; b.tail *= HEIGHT
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.update()

# Clips.
bpy.context.scene.render.fps = 24
rig.animation_data_create()
bases = {b.name: b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}


def head_y(name, deg):
    b = rig.pose.bones[name]; b.rotation_mode = 'QUATERNION'
    b.rotation_quaternion = bases[name].inverted() @ Quaternion(Vector((1, 0, 0)), math.radians(deg)) @ bases[name]
    bpy.context.view_layer.update(); y = (rig.matrix_world @ rig.pose.bones['head'].tail).y
    b.rotation_quaternion = Quaternion((1, 0, 0, 0)); bpy.context.view_layer.update(); return y


FWD = 1 if head_y('spine_2', 10) < head_y('spine_2', -10) else -1   # +FWD pitches the head forward (-Y)


def reset():
    for b in rig.pose.bones:
        b.rotation_mode = 'QUATERNION'; b.rotation_quaternion = Quaternion((1, 0, 0, 0)); b.location = (0, 0, 0)


def turn(name, parts):
    q = Quaternion((1, 0, 0, 0))
    for deg, axis in parts:
        q = Quaternion(Vector(axis), math.radians(deg)) @ q
    rig.pose.bones[name].rotation_quaternion = bases[name].inverted() @ q @ bases[name]


def low():
    graph = bpy.context.evaluated_depsgraph_get(); e = body.evaluated_get(graph); m = e.to_mesh()
    z = min((e.matrix_world @ v.co).z for v in m.vertices); e.to_mesh_clear(); return z


X, Z = (1, 0, 0), (0, 0, 1)
for role, frames, loop in [('idle', 72, True), ('walk', 40, True), ('run', 26, True), ('attack', 24, False),
                           ('hit', 12, False), ('faint', 36, False)]:
    action = bpy.data.actions.new(role); rig.animation_data.action = action
    for f in sorted(set(range(0, frames + 1, 2)) | {frames}):
        bpy.context.scene.frame_set(f); reset(); t = f / frames; wave = math.sin(t * 2 * math.pi)
        if role == 'idle':
            for k, n in enumerate(names):
                turn(n, [(2.5 * math.sin(t * 2 * math.pi + k * .7), Z), (FWD * 1.2 * wave, X)])
        if role in ('walk', 'run'):
            amp = 6 if role == 'walk' else 10
            for k, n in enumerate(names):
                turn(n, [(amp * math.sin(t * 2 * math.pi - k * .9), Z), (FWD * (3 if role == 'run' else 1.5), X)])
        if role == 'attack':
            # Coil back, then strike forward and recover.
            back = math.sin(math.pi * min(1, t / .35)) if t < .35 else 0
            strike = math.sin(math.pi * (t - .35) / .45) if .35 <= t < .8 else 0
            for k, n in enumerate(names[1:], 1):
                turn(n, [(FWD * (-10 * back + 16 * strike) * (k / 3), X)])
        if role == 'hit':
            e = min(1, t / .25); e = e * e * (3 - 2 * e)
            rr = max(0, min(1, (t - .5) / .5)); e *= 1 - rr * rr * (3 - 2 * rr)
            for k, n in enumerate(names[1:], 1):
                turn(n, [(-FWD * 14 * e, X), (10 * e, Z)])
        if role == 'faint':
            ph = min(1, t / .8); ph = ph * ph * (3 - 2 * ph)
            for k, n in enumerate(names):
                turn(n, [(FWD * (32 if k < 3 else 18) * ph, X), (8 * ph, Z)])
        bpy.context.view_layer.update()
        rb = rig.pose.bones['root']; rb.location = bases['root'].inverted() @ Vector((0, 0, -low()))
        bpy.context.view_layer.update()
        for b in rig.pose.bones:
            b.keyframe_insert('rotation_quaternion', frame=f)
            if b.name == 'root':
                b.keyframe_insert('location', frame=f)
    for c in action.fcurves:
        for k in c.keyframe_points:
            k.interpolation = 'LINEAR'
    action.use_fake_user = True
    tr = rig.animation_data.nla_tracks.new(); tr.name = role; tr.mute = True; tr.strips.new(role, 1, action)
    rig.animation_data.action = None
reset(); bpy.context.scene.frame_set(0)
for tr in rig.animation_data.nla_tracks:
    tr.mute = False
for o in bpy.data.objects:
    o.select_set(o in (rig, body))
bpy.ops.export_scene.gltf(filepath=args[1], export_format='GLB', use_selection=True, export_yup=True,
                          export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS')
rep = quad.weight_report(body)
lo, hi = quad.bounds(body)
rep.update({'height_m': round(hi.z - lo.z, 4), 'triangles': sum(len(p.vertices) - 2 for p in body.data.polygons),
            'bones': len(groups), 'chain_joints_normalised': [[round(c, 3) for c in j] for j in joints],
            'coil_fraction': COIL, 'ground_patch': patch_report, 'params': P,
            'method': 'measured_column_chain_coil_on_root', 'candidate_enabled': False})
Path(args[2]).write_text(json.dumps(rep, indent=2))
print('REPORT', json.dumps({k: v for k, v in rep.items() if k != 'per_bone'}))
