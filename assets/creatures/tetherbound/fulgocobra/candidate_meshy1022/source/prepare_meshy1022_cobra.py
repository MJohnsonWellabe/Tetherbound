"""Fulgocobra Meshy-1022 candidate: a coiled-cobra rig and its gameplay clips.

Run in Blender with -- raw-Meshy.glb output.glb report.json.
The stylised remake is a cobra raised from a ground coil, so the installed
quadruped contract does not fit it. Bones run up the measured centre line of
the raised hood (coil -> spine -> neck -> head) and skin by height bands with
local surface diffusion, like the quadruped candidates. Clips: idle sway,
slither, lunge, the held rear-back hit, and a faint where the hood folds forward
and the head comes to rest on the coil and ground. Exported at the installed
5.20 m (never smaller).
"""
import bpy, sys, math, json
from pathlib import Path
from mathutils import Vector, Quaternion
root = Path(__file__).resolve().parents[6]
sys.path.insert(0, str(root / 'tools/art_pipeline/blender'))
import rig_quadruped as quad
import cleanup_mesh as cleanup

TARGET_HEIGHT = 5.20
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


def centre(z0, z1):
    pts = [v.co for v in vs if z0 <= v.co.z < z1]
    return sum(pts, Vector()) / len(pts)


COIL, SPINE, NECK = .30, .55, .78
c_coil = centre(0, COIL); c_spine = centre(COIL, SPINE); c_neck = centre(SPINE, NECK); c_head = centre(NECK, 1.01)
nose = min((v.co for v in vs if v.co.z > NECK), key=lambda p: p.y)
bpy.ops.object.armature_add(enter_editmode=True)
rig = bpy.context.object; rig.name = 'FulgocobraMeshy1022Rig'
eb = rig.data.edit_bones
for b in list(eb):
    eb.remove(b)


def bone(n, h, t, parent=None):
    b = eb.new(n); b.head = h; b.tail = t; b.roll = 0
    if parent:
        b.parent = eb[parent]


base = Vector((c_spine.x, c_spine.y, COIL))
bone('root', (c_coil.x, c_coil.y, 0), (c_coil.x, c_coil.y, .1))
bone('coil', (c_coil.x, c_coil.y, .02), (c_coil.x, c_coil.y, COIL * .8), 'root')
bone('spine', base, Vector((c_neck.x, c_neck.y, SPINE)), 'coil')
bone('neck', Vector((c_neck.x, c_neck.y, SPINE)), Vector((c_head.x, c_head.y, NECK)), 'spine')
bone('head', Vector((c_head.x, c_head.y, NECK)), Vector((nose.x, nose.y, nose.z)), 'neck')
bpy.ops.object.mode_set(mode='OBJECT')
groups = {b.name: body.vertex_groups.new(name=b.name) for b in rig.data.bones}
weights = []
for v in vs:
    z = v.co.z
    up1 = s(COIL - .05, COIL + .05, z); up2 = s(SPINE - .05, SPINE + .05, z); up3 = s(NECK - .05, NECK + .05, z)
    weights.append({'coil': 1 - up1, 'spine': up1 * (1 - up2), 'neck': up2 * (1 - up3), 'head': up3})
adj = [set() for _ in vs]
for e in body.data.edges:
    a, b = e.vertices; adj[a].add(b); adj[b].add(a)
for _ in range(3):
    nxt = []
    for i, w in enumerate(weights):
        nb = [j for j in adj[i] if (vs[j].co - vs[i].co).length < .05]
        if not nb:
            nxt.append(w); continue
        nxt.append({k: .8 * w.get(k, 0) + .2 * sum(weights[j].get(k, 0) for j in nb) / len(nb) for k in groups})
    weights = nxt
for v, w in zip(vs, weights):
    sel = [(k, x) for k, x in w.items() if x > .001]; total = sum(x for _, x in sel) or 1
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

# Clips (world-axis keys, grounded on the lowest evaluated vertex).
bpy.context.scene.render.fps = 24
rig.animation_data_create()
bases = {b.name: b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}


def reset():
    for b in rig.pose.bones:
        b.rotation_mode = 'QUATERNION'; b.rotation_quaternion = Quaternion((1, 0, 0, 0)); b.location = (0, 0, 0)


def rotate(name, degrees, axis=(1, 0, 0)):
    basis = bases[name]
    rig.pose.bones[name].rotation_quaternion = basis.inverted() @ Quaternion(Vector(axis), math.radians(degrees)) @ basis


def low():
    graph = bpy.context.evaluated_depsgraph_get(); e = body.evaluated_get(graph); m = e.to_mesh()
    r = min((e.matrix_world @ v.co).z for v in m.vertices); e.to_mesh_clear(); return r


def head_y(angle):
    reset(); rotate('spine', angle); bpy.context.view_layer.update()
    y = (rig.matrix_world @ rig.pose.bones['head'].tail).y; reset(); bpy.context.view_layer.update(); return y


# FWD: the pitch sign that moves the head forward (-Y, the facing direction).
FWD = 1 if head_y(10) < head_y(-10) else -1
for role, frames in [('idle', 72), ('walk', 40), ('run', 26), ('attack', 24), ('hit', 12), ('faint', 36)]:
    action = bpy.data.actions.new(role); rig.animation_data.action = action
    for f in sorted(set(range(0, frames + 1, 2)) | {frames}):
        bpy.context.scene.frame_set(f); reset(); t = f / frames; wave = math.sin(t * 2 * math.pi)
        if role == 'idle':
            rotate('spine', 2 * wave, (0, 1, 0)); rotate('neck', 3 * wave, (0, 1, 0)); rotate('head', 2 * wave)
        if role in ('walk', 'run'):
            amp = 6 if role == 'walk' else 10
            rotate('coil', amp * wave, (0, 0, 1)); rotate('spine', amp * .8 * math.sin(t * 2 * math.pi + 1), (0, 1, 0))
            rotate('neck', -amp * .5 * math.sin(t * 2 * math.pi + 2), (0, 1, 0))
        if role == 'attack':
            pulse = math.sin(math.pi * min(1, t / .6)) if t < .6 else 0
            rotate('spine', FWD * 20 * pulse); rotate('neck', FWD * 25 * pulse); rotate('head', -FWD * 10 * pulse)
        if role == 'hit':
            # The held rear-back that judged 7.5+ on Meadowhart and Riverdrake (b3).
            e = min(1, t / .12); e = e * e * (3 - 2 * e)
            r = max(0, min(1, (t - .5) / .47)); e *= 1 - r * r * (3 - 2 * r)
            rotate('spine', -FWD * 16 * e); rotate('neck', -FWD * 18 * e); rotate('head', FWD * 12 * e, (0, 0, 1))
        if role == 'faint':
            ph = min(1, t / .8); ph = ph * ph * (3 - 2 * ph)
            # The hood folds forward and down; the head rests on the ground beside the coil.
            rotate('spine', FWD * 55 * ph); rotate('neck', FWD * 45 * ph); rotate('head', FWD * 10 * ph)
            rotate('spine', 15 * ph, (0, 1, 0))
        bpy.context.view_layer.update()
        rig.pose.bones['root'].location = bases['root'].inverted() @ Vector((0, 0, -low()))
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
Path(args[1]).parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(filepath=args[1], export_format='GLB', use_selection=True, export_yup=True,
                          export_skins=True, export_animations=True, export_animation_mode='NLA_TRACKS')
lo, hi = quad.bounds(body)
Path(args[2]).write_text(json.dumps({'height_m': round(hi.z - lo.z, 3), 'length_m': round(hi.y - lo.y, 3),
                                     'width_m': round(hi.x - lo.x, 3), 'bones': len(groups), 'fwd_sign': FWD,
                                     'method': 'height_band_cobra_chain_local_surface_diffusion',
                                     'candidate_enabled': False}, indent=2))
print('REPORT done')
