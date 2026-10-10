"""Author Stormursa-specific clips on the inherited Staticub quadruped rig.
Reuse standing/gait/hit clips; replace the cub strike and faint endpoints.
All transformations remain in place, with faint grounded by evaluated vertices.
"""
import math,pathlib,sys
import bpy
from mathutils import Vector, Quaternion
root=pathlib.Path(__file__).resolve().parents[5]
sys.path.insert(0,str(root/'tools/art_pipeline/blender'))
import animate_quadruped as anim
args=anim.argv_after_double_dash();source=pathlib.Path(args[0]);out=pathlib.Path(anim.option(args,'--out'))
rig=anim.load(source);bpy.context.scene.render.fps=24
for obj in list(bpy.data.objects):
 if obj.type=='MESH' and not obj.vertex_groups:bpy.data.objects.remove(obj,do_unlink=True)
rig.animation_data_create()
# A heavy bear uses shorter leg arcs than the starter's neutral trot.
_original_gait=anim.author_gait
def _bear_gait(rig,frames,swing,bob,lean):return _original_gait(rig,frames,swing=swing*.5,bob=bob*.6,lean=lean*.5)
anim.author_gait=_bear_gait
for name,frames,loop in [('idle',72,True),('walk',40,True),('run',26,True),('hit',12,False)]:anim.author(rig,name,frames,loop)
replace=['attack','charged','faint','swim','fly_grip','ride']
for track in list(rig.animation_data.nla_tracks):
 if any(track.name==role or track.name.startswith(role+'_') for role in replace):rig.animation_data.nla_tracks.remove(track)
for action in list(bpy.data.actions):
 if any(action.name==role or action.name.startswith(role+'_') for role in replace):bpy.data.actions.remove(action)
for track in rig.animation_data.nla_tracks:track.mute=True
def frame_low():
 graph=bpy.context.evaluated_depsgraph_get();low=float('inf')
 for obj in bpy.data.objects:
  if obj.type!='MESH' or not obj.vertex_groups:continue
  evaluated=obj.evaluated_get(graph);mesh=evaluated.to_mesh()
  low=min(low,min((evaluated.matrix_world @ v.co).z for v in mesh.vertices));evaluated.to_mesh_clear()
 return low
def key(bone,frame,degrees=(0,0,0),location=None):anim.key(rig,bone,frame,euler=degrees,location=location)
for role,frames,loop in [('attack',24,False),('charged',42,False),('faint',36,False),('swim',40,True),('fly_grip',48,True),('ride',72,True)]:
 anim.clear_pose(rig);action=bpy.data.actions.new(role);rig.animation_data.action=action
 for name in rig.pose.bones.keys():
  if role!='faint' or name!='root':key(name,0)
 if role in ['attack','charged']:
  wind=10 if role=='attack' else 20;impact=14 if role=='attack' else 27
  key('neck',wind,(-8,0,0));key('head',wind,(-8,0,0));key('spine',wind,(-4,0,0))
  key('neck',impact,(12,0,0));key('head',impact,(14,0,0));key('spine',impact,(4,0,0))
  for side in ['l','r']:
   key('front_upper_'+side,wind,(-8 if role=='attack' else -18,0,0));key('front_lower_'+side,wind,(12,0,0))
   key('front_upper_'+side,impact,(10 if role=='attack' else 18,0,0));key('front_lower_'+side,impact,(-8,0,0))
  for name in rig.pose.bones.keys():key(name,frames)
 elif role=='faint':
  bone=rig.pose.bones['root'];bone.rotation_mode='QUATERNION'
  basis=bone.bone.matrix_local.to_3x3()
  local_axis=(basis.inverted() @ Vector((0,1,0))).normalized()
  bone.rotation_quaternion=Quaternion(local_axis,0);bone.keyframe_insert('rotation_quaternion',frame=0)
  bone.location=Vector((0,0,0));bone.keyframe_insert('location',frame=0)
  for f,phase in [(10,.2),(24,.7),(36,1.)]:
   bone.rotation_quaternion=Quaternion(local_axis,0);bone.keyframe_insert('rotation_quaternion',frame=f)
   bone.location=Vector((0,0,0));bone.keyframe_insert('location',frame=f)
   key('neck',f,(16*phase,0,0));key('head',f,(30*phase,0,0));key('spine',f,(8*phase,0,0))
   for prefix in ['front','rear']:
    for side in ['l','r']:
     key(prefix+'_upper_'+side,f,(45*phase,0,0));key(prefix+'_lower_'+side,f,(-75*phase,0,0))
   bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
   low=frame_low();bone.location+=basis.inverted() @ Vector((0,0,-low));bone.keyframe_insert('location',frame=f)
 elif role=='swim':
  for f in range(0,frames+1,5):
   for prefix,offset in [('front',0),('rear',math.pi)]:
    for side,side_offset in [('l',0),('r',math.pi)]:
     wave=math.sin(2*math.pi*f/frames+offset+side_offset)
     key(prefix+'_upper_'+side,f,(18*wave,0,0));key(prefix+'_lower_'+side,f,(8+10*max(0,-wave),0,0))
   key('head',f,(-6+2*math.sin(2*math.pi*f/frames),0,0))
 elif role=='fly_grip':
  for f in [0,frames//2,frames]:
   for prefix in ['front','rear']:
    for side in ['l','r']:
     key(prefix+'_upper_'+side,f,(-28,0,0));key(prefix+'_lower_'+side,f,(52,0,0))
   key('head',f,(8,0,0))
 elif role=='ride':
  for f in [0,frames//2,frames]:
   key('spine',f,(1.5 if f==frames//2 else 0,0,0));key('head',f,(-1 if f==frames//2 else 0,0,0))
 action.use_fake_user=True;track=rig.animation_data.nla_tracks.new();track.name=role;track.mute=True;track.strips.new(role,1,action);rig.animation_data.action=None
anim.clear_pose(rig);rig.pose.bones['root'].rotation_mode='QUATERNION';rig.pose.bones['root'].rotation_quaternion=Quaternion((1,0,0),0);bpy.context.scene.frame_set(0)
for track in rig.animation_data.nla_tracks:track.mute=False
out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_animations=True,export_animation_mode='NLA_TRACKS',export_skins=True,export_yup=True)
print('Stormursa native clips exported:',out)
