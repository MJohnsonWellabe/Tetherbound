"""AbyssalGuardian neutral cycles and explicit pose roles, with world-axis keys.

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
   rotate('neck_upper',.8*wave,(0,0,1));rotate('head',.6*wave)
  if role in ['walk','run','swim','fly_grip']:
   amplitude={'walk':3,'run':5,'swim':14,'fly_grip':5}[role]
   for kind in ['front','rear']:
    for side,sign in [('l',-1),('r',1)]:
     offset=math.pi if kind=='rear' else 0;pulse=math.sin(t*2*math.pi+offset)
     rotate(kind+'_flipper_'+side+'_1',sign*amplitude*pulse,(0,1,0))
     rotate(kind+'_flipper_'+side+'_2',sign*amplitude*.4*pulse,(0,1,0))
   for i in range(1,5):rotate('tail_'+str(i),3*math.sin(t*2*math.pi-i*.5),(0,0,1))
  if role in ['attack','charged']:
   pulse=math.sin(math.pi*min(1,t/.65)) if t<.65 else 0
   rotate('neck_lower',-8*pulse);rotate('neck_upper',-12*pulse);rotate('head',10*pulse)
  if role=='hit':
   pulse=math.sin(math.pi*t);rotate('neck_upper',10*pulse);rotate('head',6*pulse)
  if role in ['faint','rest']:
   phase=min(1,t/.8);phase=phase*phase*(3-2*phase) if role=='faint' else 1
   # Belly-down aquatic settling: no quadruped roll or fabricated foot folding.
   rotate('neck_lower',(55 if role=='faint' else 30)*phase)
   rotate('neck_upper',(35 if role=='faint' else 32)*phase)
   rotate('head',10*phase)
   for kind in ['front','rear']:
    for side,sign in [('l',-1),('r',1)]:rotate(kind+'_flipper_'+side+'_1',sign*8*phase,(0,0,1))
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
