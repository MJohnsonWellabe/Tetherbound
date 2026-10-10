"""Meadowhart neutral cycles and explicit pose roles, with world-axis keys.

Blender --background --python this.py -- rigged.glb output.glb
All vertices are evaluated for floor correction; this is pose evidence only.
"""
import bpy, math, sys
from mathutils import Vector,Quaternion
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
for role,frames,loop in [('idle',72,True),('walk',40,True),('run',26,True),('attack',24,False),('charged',42,False),('hit',12,False),('faint',36,False),('rest',36,False),('swim',40,True),('fly_grip',48,True),('ride',72,True)]:
 action=bpy.data.actions.new(role);rig.animation_data.action=action
 for f in sorted(set(range(0,frames+1,2))|{frames}):
  bpy.context.scene.frame_set(f)
  reset();t=f/frames;wave=math.sin(t*2*math.pi)
  if role in ['idle','ride']:
   rotate('neck',.5*wave);rotate('spine',.7*wave);rotate('head',1.2*wave);rotate('tail_2',4*wave,(0,0,1))
  if role in ['walk','run','swim']:
   amplitude={'walk':17,'run':28,'swim':24}[role]
   for prefix in ['front','rear']:
    for side in ['l','r']:
     phase=math.pi if (prefix,side) in [('front','r'),('rear','l')] else 0
     swing=math.sin(t*2*math.pi+phase)
     rotate(prefix+'_upper_'+side,amplitude*swing)
     rotate(prefix+'_lower_'+side,-18*max(0,-swing))
     rotate(prefix+'_foot_'+side,-amplitude*swing+18*max(0,-swing))
   rotate('head',-2*wave)
  if role in ['attack','charged']:
   pulse=math.sin(math.pi*min(1,t/.65)) if t<.65 else 0
   for side in ['l','r']:
    rotate('front_upper_'+side,-30*pulse);rotate('front_lower_'+side,25*pulse)
   rotate('head',-10*pulse);rotate('spine',-4*pulse)
  if role=='hit':
   pulse=math.sin(math.pi*t);rotate('head',12*pulse);rotate('spine',6*pulse,(0,0,1))
  if role in ['faint','rest']:
   phase=min(1,t/.8);phase=phase*phase*(3-2*phase)
   rotate('root',90*phase,(0,1,0));rotate('head',12*phase)
   for prefix in ['front','rear']:
    for side in ['l','r']:
     rotate(prefix+'_upper_'+side,45*phase);rotate(prefix+'_lower_'+side,-65*phase)
  if role=='fly_grip':
   for prefix in ['front','rear']:
    for side in ['l','r']:
     rotate(prefix+'_upper_'+side,-30);rotate(prefix+'_lower_'+side,55)
  bpy.context.view_layer.update()
  # Ground the lowest evaluated surface, never change the body/world position.
  root=rig.pose.bones['root'];root.location=bases['root'].inverted()@Vector((0,0,-low()))
  bpy.context.view_layer.update()
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
