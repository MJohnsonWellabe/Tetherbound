"""Build the reference-backed bare Meadowhart skin and six grounded clips.

Run in Blender: --background --python this_file -- [source.glb] [output_dir]
Default source is the Meshy task download recorded in models/provenance.json.
This operates only on Meadowhart; common rig/animation authoring stays unchanged.
"""
import json, math, pathlib, sys
import bpy
from mathutils import Vector

ROOT = pathlib.Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT/'tools/art_pipeline/blender'))
import rig_quadruped as rq
import animate_quadruped as aq

args = sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
source = pathlib.Path(args[0]).resolve() if args else ROOT/'assets_raw/meadowhart_bare/a/model.glb'
out = pathlib.Path(args[1]).resolve() if len(args)>1 else ROOT/'assets_raw/meadowhart_bare/build'
out.mkdir(parents=True, exist_ok=True)
rq.load(source)
body = rq.join_and_normalise()
body.name = 'MeadowhartBareBody'
# Preserve the textured surface and UV seams; no voxel reconstruction.
tris = sum(len(p.vertices)-2 for p in body.data.polygons)
if tris > 30000:
    modifier = body.modifiers.new('TriangleBudget', 'DECIMATE')
    modifier.ratio = 28000 / tris
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.modifier_apply(modifier=modifier.name)
body.data.validate(verbose=True)
for material in body.data.materials:
    if not material or not material.use_nodes:
        continue
    for node in material.node_tree.nodes:
        if node.type == 'BSDF_PRINCIPLED':
            for channel,value in (('Roughness',0.96),('Metallic',0.0)):
                for link in list(node.inputs[channel].links):
                    material.node_tree.links.remove(link)
                node.inputs[channel].default_value=value
        elif node.type == 'NORMAL_MAP':
            node.inputs['Strength'].default_value=0.22
legs = rq.find_legs(body)
rig = rq.build_armature(body, legs)
# Lift the back/upper legs into the established physical saddle seat while
# retaining ground, full antler height and the reference's slender outline.
# Warp the rest skeleton with the skin before weighting, never move the rider.
low,high=rq.bounds(body)
height=high.z-low.z
def saddle_fit(z):
    t=max(0.0,min(1.0,(z-low.z)/height))
    return z + height * 0.065 * math.sin(math.pi*t)
for vertex in body.data.vertices:
    vertex.co.z=saddle_fit(vertex.co.z)
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for bone in rig.data.edit_bones:
    bone.head.z=saddle_fit(bone.head.z)
    bone.tail.z=saddle_fit(bone.tail.z)
bpy.ops.object.mode_set(mode='OBJECT')
rq.skin(body, rig)
repaired = rq.repair_unweighted(body)
bpy.context.view_layer.objects.active=body
bpy.ops.object.vertex_group_limit_total(limit=4)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)
report = rq.weight_report(body)
if report['unweighted_vertices']:
    raise SystemExit('Unweighted vertices: candidate rejected')
report['repaired_vertices'] = repaired
report['legs'] = {k:list(v) for k,v in legs.items()}
report['bounds'] = [list(v) for v in rq.bounds(body)]

def hoofbeat(rig, frames):
    # A short forehoof lift and stamp. The hindquarters support the animal;
    # avoid the old digger's whole-torso fold at attack anticipation.
    for f,amount in ((0,0),(8,1),(13,0.8),(16,0.15),(frames,0)):
        aq.key(rig, 'pelvis', f, euler=(5*amount,0,0))
        aq.key(rig, 'spine', f, euler=(-5*amount,0,0))
        aq.key(rig, 'neck', f, euler=(28*amount,0,0))
        aq.key(rig, 'head', f, euler=(12*amount,0,0))
        for side in ('l','r'):
            aq.key(rig, 'front_upper_'+side, f, euler=(-32*amount,0,0))
            aq.key(rig, 'front_lower_'+side, f, euler=(48*amount,0,0))

def faint(rig, frames):
    # Root local Z is horizontal; local Y would spin around world up.
    for f,amount in ((0,0),(12,.18),(frames,1)):
        aq.key(rig, 'root', f, euler=(0,0,78*amount))
        aq.key(rig, 'neck', f, euler=(-12*amount,0,0))
        aq.key(rig, 'head', f, euler=(10*amount,0,0))
        for leg in aq.QUAD_LEGS:
            aq.key(rig, leg, f, euler=(25*amount,0,0))
            aq.key(rig, aq.QUAD_LOWER[leg], f, euler=(-40*amount,0,0))

def idle(rig, frames):
    for frame in range(0,frames+1,6):
        t=frame/frames*2*math.pi
        aq.key(rig,'spine',frame,euler=(0.8*math.sin(t),0,0))
        aq.key(rig,'head',frame,euler=(1.4*math.sin(t+0.7),0,2*math.sin(t)))
        aq.key(rig,'tail_1',frame,euler=(0,0,4*math.sin(t+1)))
        aq.key(rig,'tail_2',frame,euler=(0,0,3*math.sin(t+1.6)))

def hit(rig, frames):
    for frame,amount in ((0,0),(3,1),(frames,0)):
        aq.key(rig,'spine',frame,euler=(-4*amount,0,2*amount))
        aq.key(rig,'head',frame,euler=(-6*amount,0,4*amount))
        aq.key(rig,'pelvis',frame,euler=(-2*amount,0,0))

aq.author_idle = idle
aq.author_hit = hit
aq.author_attack = hoofbeat
aq.author_faint = faint
bpy.context.scene.render.fps = aq.FPS
for name,(frames,looping) in aq.CLIPS.items():
    aq.author(rig,name,frames,looping)

# Bake vertical ground contact against the evaluated skin, in each action.
# The runtime still owns horizontal movement. Record corrections for review.
tracks = list(rig.animation_data.nla_tracks)
for track in tracks:
    track.mute = True
report['clips'] = {}
root_bone = rig.pose.bones['root']
up_in_root = root_bone.bone.matrix_local.to_3x3().inverted() @ Vector((0,0,1))
for name,(frames,looping) in aq.CLIPS.items():
    aq.clear_pose(rig)
    action = bpy.data.actions[name]
    rig.animation_data.action = action
    corrections=[]
    for frame in range(0,frames+1):
        bpy.context.scene.frame_set(frame)
        root_bone.location=(0,0,0)
        bpy.context.view_layer.update()
        evaluated = body.evaluated_get(bpy.context.evaluated_depsgraph_get())
        mesh=evaluated.to_mesh()
        lowest=min((evaluated.matrix_world @ v.co).z for v in mesh.vertices)
        evaluated.to_mesh_clear()
        root_bone.location=up_in_root * -lowest
        root_bone.keyframe_insert('location',frame=frame)
        corrections.append(round(-lowest,5))
    report['clips'][name]={'frames':frames,'ground_correction_range':[min(corrections),max(corrections)]}
rig.animation_data.action=None
for track in tracks:
    track.mute=False
aq.clear_pose(rig)
bpy.context.scene.frame_set(0)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(out/'animated.glb'),export_format='GLB',
    export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_yup=True)
(out/'rig_report.json').write_text(json.dumps(report,indent=2))
print(json.dumps(report,indent=2))
