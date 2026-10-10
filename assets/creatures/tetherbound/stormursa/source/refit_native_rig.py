"""Author the measured-paw rest skeleton and anatomical skin regions for Stormursa."""
import pathlib,sys,json
import bpy,math
from mathutils import Matrix
root=pathlib.Path(__file__).resolve().parents[5];sys.path.insert(0,str(root/'tools/art_pipeline/blender'))
import rig_quadruped as author
args=author.argv_after_double_dash();src=pathlib.Path(args[0]);out=pathlib.Path(author.option(args,'--out'))
author.load(src)
old=next(o for o in bpy.data.objects if o.type=='ARMATURE');old.animation_data_clear()
for bone in old.pose.bones:bone.matrix_basis=Matrix.Identity(4)
body=next(o for o in bpy.data.objects if o.type=='MESH' and o.vertex_groups)
for stray in list(bpy.data.objects):
 if stray.type=='MESH' and stray!=body:bpy.data.objects.remove(stray,do_unlink=True)
world=body.matrix_world.copy();body.parent=None;body.matrix_world=world
for modifier in list(body.modifiers):
 if modifier.type=='ARMATURE':body.modifiers.remove(modifier)
bpy.context.view_layer.objects.active=body;bpy.ops.object.select_all(action='DESELECT');body.select_set(True);bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
legs=author.find_legs(body);new=author.build_armature(body,legs)
# Bear knees sit halfway down the leg, rather than at the low-band paw centroid.
bpy.context.view_layer.objects.active=new;bpy.ops.object.mode_set(mode='EDIT')
spine_z=max(b.head.z for b in new.data.edit_bones if b.name=='spine')
for prefix in ['front','rear']:
 for side in ['l','r']:
  upper=new.data.edit_bones[prefix+'_upper_'+side];lower=new.data.edit_bones[prefix+'_lower_'+side]
  upper.tail.z=spine_z*.48;lower.head=upper.tail
bpy.ops.object.mode_set(mode='OBJECT')
# Asset-specific continuous regions keep paw vertices on their own limb.
# The inherited cub heat map smeared the far foreleg across the adult chest.
for group in list(body.vertex_groups):body.vertex_groups.remove(group)
groups={name:body.vertex_groups.new(name=name) for name in new.data.bones.keys()}
front_y=(legs['front_l'].y+legs['front_r'].y)/2
rear_y=(legs['rear_l'].y+legs['rear_r'].y)/2
mid_y=(front_y+rear_y)/2
head_end=front_y-.30
neck_start=front_y-.08
low,high=author.bounds(body)
def smooth(a,b,value):
 t=max(0.,min(1.,(value-a)/(b-a)));return t*t*(3-2*t)
for vertex in body.data.vertices:
 p=body.matrix_world @ vertex.co
 if p.y<head_end:
  head=smooth(head_end-.22,head_end,p.y);weights={'head':1-head,'neck':head}
 elif p.y<neck_start:
  spine=smooth(head_end,neck_start,p.y);weights={'neck':1-spine,'spine':spine}
 else:
  pelvis=smooth(front_y,rear_y,p.y);weights={'spine':1-pelvis,'pelvis':pelvis}
 tail=smooth(high.y-.16,high.y-.03,p.y)*(1-smooth(.10,.24,abs(p.x)))
 if tail>0:weights={k:v*(1-tail) for k,v in weights.items()};weights['tail_1']=tail
 leg_key=min(legs,key=lambda name:(p.x-legs[name].x)**2+(p.y-legs[name].y)**2)
 col=legs[leg_key];distance=math.hypot(p.x-col.x,p.y-col.y)
 influence=(1-smooth(.20,.43,distance))*(1-smooth(spine_z*.68,spine_z*1.12,p.z))
 prefix,side=leg_key.split('_');knee=spine_z*.48
 lower=1-smooth(knee-.12,knee+.12,p.z)
 weights={k:v*(1-influence) for k,v in weights.items()}
 weights[prefix+'_upper_'+side]=influence*(1-lower);weights[prefix+'_lower_'+side]=influence*lower
 significant=sorted(((k,v) for k,v in weights.items() if v>1e-5),key=lambda pair:pair[1],reverse=True)[:4]
 total=sum(v for k,v in significant)
 for name,weight in significant:groups[name].add([vertex.index],weight/total,'REPLACE')
modifier=body.modifiers.new('Armature','ARMATURE');modifier.object=new;body.parent=new
bpy.data.objects.remove(old,do_unlink=True);new.name='Armature'
for action in list(bpy.data.actions):bpy.data.actions.remove(action)
report=author.weight_report(body);report['legs_found_at']={k:list(v) for k,v in legs.items()};report['method']='Stormursa measured-paw skeleton and continuous anatomical skin regions; inherited Staticub layout'
out.parent.mkdir(parents=True,exist_ok=True);bpy.ops.object.select_all(action='SELECT');bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',export_skins=True,export_animations=False,export_yup=True)
(out.parent/'refit-report.json').write_text(json.dumps(report,indent=2));print('Refitted rig:',out)
