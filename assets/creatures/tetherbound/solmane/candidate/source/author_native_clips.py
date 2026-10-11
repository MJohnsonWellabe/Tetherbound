"""Solmane neutral cycles and explicit pose roles, with world-axis keys.

Blender --background --python this.py -- rigged.glb output.glb
Root-owned bake only. The source support guard is not native contact acceptance.
"""
import bpy, math, sys, json
from pathlib import Path
from mathutils import Vector,Quaternion
repose=json.loads(Path(__file__).with_name('terminal_repose.json').read_text())
a=sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
for obj in list(bpy.data.objects):
 if obj.type=='MESH' and not obj.vertex_groups:bpy.data.objects.remove(obj,do_unlink=True)
bpy.context.scene.render.fps=24
rig.animation_data_create()
for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
bases={b.name:b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}
def reset():
 for b in rig.pose.bones:
  b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion((1,0,0),0);b.location=(0,0,0)
def rotate(name,degrees,axis=(1,0,0)):
 basis=bases[name];rig.pose.bones[name].rotation_quaternion=basis.inverted()@Quaternion(Vector(axis),math.radians(degrees))@basis
def low():
 graph=bpy.context.evaluated_depsgraph_get();result=math.inf
 for o in bpy.data.objects:
  if o.type!='MESH' or not o.vertex_groups:continue
  e=o.evaluated_get(graph);m=e.to_mesh();result=min(result,min((e.matrix_world@v.co).z for v in m.vertices));e.to_mesh_clear()
 return result
def verify_repose_support():
 # A bake-time guard, not a visual/physical acceptance result. A crown, feather
 # or distal foot touching the floor cannot substitute for both torso regions.
 gaps={name:math.inf for name in repose['support_bones']}
 patches={name:0 for name in gaps}
 graph=bpy.context.evaluated_depsgraph_get()
 for obj in bpy.data.objects:
  if obj.type!='MESH' or not obj.vertex_groups:continue
  evaluated=obj.evaluated_get(graph);mesh=evaluated.to_mesh()
  try:
   if len(mesh.vertices)!=len(obj.data.vertices):
    raise RuntimeError('Repose support requires unchanged skin vertex indexing')
   for source,posed in zip(obj.data.vertices,mesh.vertices):
    if not source.groups:continue
    owner=obj.vertex_groups[max(source.groups,key=lambda group:group.weight).group].name
    if owner in gaps:
     height=(evaluated.matrix_world@posed.co).z
     gaps[owner]=min(gaps[owner],height)
     if -0.005<=height<=repose['authoring_support_gap_limit_m']:patches[owner]+=1
  finally:evaluated.to_mesh_clear()
 for name,gap in gaps.items():
  if not -0.005<=gap<=repose['authoring_support_gap_limit_m'] or patches[name]<repose['minimum_support_vertices']:
   raise RuntimeError(f'{name} lacks terminal body support: {gap:.4f} m, {patches[name]} vertices; no export')
 print('Source repose support (native acceptance still pending):',gaps)

for role,frames,loop in [('idle',72,True),('walk',40,True),('run',26,True),('attack',24,False),('charged',42,False),('hit',12,False),('faint',36,False),('rest',36,False),('swim',40,True),('fly_grip',48,True),('ride',72,True)]:
 action=bpy.data.actions.new(role);rig.animation_data.action=action
 for f in sorted(set(range(0,frames+1,2))|{frames}):
  bpy.context.scene.frame_set(f)
  reset();t=f/frames;wave=math.sin(t*2*math.pi)
  if role in ['idle','ride']:
   rotate('spine',.7*wave);rotate('head',1.2*wave);rotate('tail_2',4*wave,(0,0,1))
  if role in ['walk','run','swim']:
   amplitude={'walk':17,'run':28,'swim':24}[role]
   for prefix in ['front','rear']:
    for side in ['l','r']:
     phase=math.pi if (prefix,side) in [('front','r'),('rear','l')] else 0
     swing=math.sin(t*2*math.pi+phase)
     rotate(prefix+'_upper_'+side,amplitude*swing)
     bend=-18*max(0,-swing)
     rotate(prefix+'_lower_'+side,bend)
     rotate(prefix+'_foot_'+side,-amplitude*swing-bend)
   rotate('head',-2*wave)
  if role in ['attack','charged']:
   pulse=math.sin(math.pi*min(1,t/.65)) if t<.65 else 0
   for side in ['l','r']:
    rotate('front_upper_'+side,-30*pulse);rotate('front_lower_'+side,25*pulse)
   rotate('head',-10*pulse);rotate('spine',-4*pulse)
  if role=='hit':
   pulse=math.sin(math.pi*t);rotate('head',12*pulse);rotate('spine',6*pulse,(0,0,1))
  rotate('tail_3',5*wave,(0,0,1))
  if role=='fly_grip':
   for prefix in ['front','rear']:
    for side in ['l','r']:
     rotate(prefix+'_upper_'+side,-30);rotate(prefix+'_lower_'+side,55)
  for side,sign in [('l',-1),('r',1)]:
   beat=16*wave if role=='fly_grip' else 2*wave if role in ['idle','ride','swim'] else 0
   rotate('wing_'+side+'_1',sign*beat,(0,1,0));rotate('wing_'+side+'_2',sign*beat*.35,(0,1,0))
  if role in ['faint','rest']:
   # Replace every inherited control: neither the old roll nor tail oscillation
   # may survive into the supported terminal hold. Other clips are unchanged.
   reset()
   phase=min(1,t/repose['settle_fraction']) if role=='faint' else 1
   phase=phase*phase*(3-2*phase)
   for name,degrees,axis in repose['rotations']:
    rotate(name,degrees*phase,axis)
  bpy.context.view_layer.update()
  # Floor correction follows articulated support; it is not the support test.
  root=rig.pose.bones['root'];root.location=bases['root'].inverted()@Vector((0,0,-low()))
  bpy.context.view_layer.update()
  if role in ['faint','rest'] and f==frames:verify_repose_support()
  for b in rig.pose.bones:
   b.keyframe_insert('rotation_quaternion',frame=f)
   if b.name=='root':b.keyframe_insert('location',frame=f)
 for curve in action.fcurves:
  for key in curve.keyframe_points:key.interpolation='LINEAR'
 action.use_fake_user=True
 track=rig.animation_data.nla_tracks.new();track.name=role;track.mute=True;track.strips.new(role,1,action)
 rig.animation_data.action=None
reset();bpy.context.scene.frame_set(0)
for track in rig.animation_data.nla_tracks:track.mute=False
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=a[1],export_format='GLB',export_yup=True,export_skins=True,export_animations=True,export_animation_mode='NLA_TRACKS')
