"""Galecrest confirm-only repair: retain installed geometry, skin, UVs and six clips.

Blender --background --python this.py -- installed.glb candidate.glb
Adds charged/rest/swim/fly_grip/ride without rebuilding the accepted bird.
"""
import bpy,sys,math
from mathutils import Vector,Quaternion
a=sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
bpy.context.scene.render.fps=24
tracks=rig.animation_data.nla_tracks
original={t.name:t.strips[0].action for t in tracks}
assert set(original)=={'idle','walk','run','attack','hit','faint'}
for track in tracks:track.mute=True
rig.animation_data.action=None
bases={b.name:b.bone.matrix_local.to_quaternion() for b in rig.pose.bones}
def reset():
 for b in rig.pose.bones:
  b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion((1,0,0),0);b.location=(0,0,0);b.scale=(1,1,1)
def rotate(name,degrees,axis=(1,0,0)):
 basis=bases[name];rig.pose.bones[name].rotation_quaternion=basis.inverted()@Quaternion(Vector(axis),math.radians(degrees))@basis
def low():
 graph=bpy.context.evaluated_depsgraph_get();result=math.inf
 for o in bpy.data.objects:
  if o.type!='MESH' or not o.vertex_groups:continue
  e=o.evaluated_get(graph);m=e.to_mesh();result=min(result,min((e.matrix_world@v.co).z for v in m.vertices));e.to_mesh_clear()
 return result
def track_action(role,action):
 action.use_fake_user=True
 track=tracks.new();track.name=role;track.mute=True;track.strips.new(role,1,action)
 rig.animation_data.action=None
# Retain the existing attack's poses; give the charged anticipation a longer span.
charged=original['attack'].copy();charged.name='charged'
lo,hi=charged.frame_range;ratio=42/(hi-lo)
for curve in charged.fcurves:
 for key in curve.keyframe_points:
  key.co.x=1+(key.co.x-lo)*ratio
  key.handle_left.x=1+(key.handle_left.x-lo)*ratio
  key.handle_right.x=1+(key.handle_right.x-lo)*ratio
track_action('charged',charged)
# A dedicated rest action holds the installed flank pose, rather than a runtime roll.
reset();rig.animation_data.action=original['faint']
bpy.context.scene.frame_set(int(original['faint'].frame_range[1]));bpy.context.view_layer.update()
terminal={b.name:(b.rotation_quaternion.copy() if b.rotation_mode=='QUATERNION' else b.rotation_euler.to_quaternion(),b.location.copy(),b.scale.copy()) for b in rig.pose.bones}
rig.animation_data.action=None
for role,frames in [('rest',36),('swim',40),('fly_grip',48),('ride',72)]:
 action=bpy.data.actions.new(role);rig.animation_data.action=action
 for f in sorted(set(range(0,frames+1,2))|{frames}):
  bpy.context.scene.frame_set(f);reset();wave=math.sin(f/frames*2*math.pi)
  if role=='rest':
   for b in rig.pose.bones:
    q,p,s=terminal[b.name];b.rotation_quaternion=q;b.location=p;b.scale=s
  else:
   rotate('root',55 if role=='swim' else 25 if role=='fly_grip' else 15)
   rotate('head',-2*wave);rotate('tail_2',3*wave,(0,0,1))
   for side,sign in [('l',-1),('r',1)]:
    rotate('wing_upper_'+side,-sign*(9+12*wave),(0,1,0))
    rotate('wing_fore_'+side,-sign*5*wave,(0,1,0))
    rotate('leg_upper_'+side,-25+(5*wave*sign if role=='swim' else 0))
    rotate('leg_lower_'+side,40);rotate('foot_'+side,-20)
  bpy.context.view_layer.update()
  rig.pose.bones['root'].location+=bases['root'].inverted()@Vector((0,0,-low()))
  bpy.context.view_layer.update()
  for b in rig.pose.bones:
   b.keyframe_insert('rotation_quaternion',frame=f)
   b.keyframe_insert('location',frame=f)
   b.keyframe_insert('scale',frame=f)
 for curve in action.fcurves:
  for key in curve.keyframe_points:key.interpolation='LINEAR'
 track_action(role,action)
reset();bpy.context.scene.frame_set(0)
for track in tracks:track.mute=False
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=a[1],export_format='GLB',export_yup=True,export_skins=True,export_animations=True,export_animation_mode='NLA_TRACKS')
