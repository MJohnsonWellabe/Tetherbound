"""Fit Ripplet's inspected Meshy-6 biped; preserve UV loops and textures.
Blender --background --python this.py -- raw.glb rigged.glb report.json
"""
import bpy,bmesh,sys,json
from pathlib import Path
from mathutils import Vector
a=sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=a[0])
body=max((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:len(o.data.vertices))
bpy.context.view_layer.objects.active=body;body.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
lo=Vector(tuple(min(v.co[i] for v in body.data.vertices) for i in range(3)))
hi=Vector(tuple(max(v.co[i] for v in body.data.vertices) for i in range(3)))
H=hi.z-lo.z;offset=Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z))
for v in body.data.vertices:v.co=(v.co+offset)/H
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.00004)
bm.to_mesh(body.data);bm.free()
for o in list(bpy.data.objects):
 if o.type=='MESH' and o!=body:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.object.armature_add(enter_editmode=True);rig=bpy.context.object;rig.name='RippletNativeRig'
eb=rig.data.edit_bones
for b in list(eb):eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.12))
bone('pelvis',(0,-.04,.24),(0,-.07,.39),'root')
bone('spine',(0,-.07,.39),(0,-.09,.54),'pelvis')
bone('neck',(0,-.09,.54),(0,-.13,.67),'spine')
bone('head',(0,-.13,.67),(0,-.17,.83),'neck')
bone('tail_1',(0,.02,.24),(0,.21,.17),'pelvis')
bone('tail_2',(0,.21,.17),(0,.35,.44),'tail_1')
for side,sign in [('l',-1),('r',1)]:
 bone('leg_upper_'+side,(sign*.11,-.04,.24),(sign*.12,-.08,.12),'pelvis')
 bone('leg_lower_'+side,(sign*.12,-.08,.12),(sign*.12,-.18,.025),'leg_upper_'+side)
 bone('arm_'+side,(sign*.105,-.09,.51),(sign*.15,-.14,.39),'spine')
 bone('forearm_'+side,(sign*.15,-.14,.39),(sign*.13,-.24,.30),'arm_'+side)
bpy.ops.object.mode_set(mode='OBJECT')
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
def s(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
weights=[]
for v in body.data.vertices:
 x,y,z=v.co;side='l' if x<0 else 'r'
 head=s(.56,.68,z);tail=s(.08,.18,y)*(1-s(.50,.60,z));tip=s(.20,.31,y)
 torso=s(.27,.44,z)
 w={'head':head,'tail_1':tail*(1-tip),'tail_2':tail*tip,
 'spine':(1-head)*(1-tail)*torso,'pelvis':(1-head)*(1-tail)*(1-torso)}
 arm=s(.08,.13,abs(x))*s(.27,.32,z)*(1-s(.49,.57,z))*(1-s(-.11,-.03,y))
 leg=(1-s(.20,.31,z))*(1-tail)
 for k in w:w[k]*=1-max(arm,leg)
 elbow=s(.36,.43,z);knee=s(.08,.15,z)
 w['arm_'+side]=arm*elbow;w['forearm_'+side]=arm*(1-elbow)
 w['leg_upper_'+side]=leg*knee;w['leg_lower_'+side]=leg*(1-knee)
 weights.append(w)
adj=[set() for _ in body.data.vertices]
for e in body.data.edges:
 i,j=e.vertices;adj[i].add(j);adj[j].add(i)
for _ in range(3):
 nxt=[]
 for i,w in enumerate(weights):
  near=[j for j in adj[i] if (body.data.vertices[i].co-body.data.vertices[j].co).length<.025]
  if not near:nxt.append(w);continue
  nxt.append({k:.8*w.get(k,0)+.2*sum(weights[j].get(k,0) for j in near)/len(near) for k in groups})
 weights=nxt
for v,w in zip(body.data.vertices,weights):
 selected=sorted(w.items(),key=lambda p:p[1],reverse=True)[:4];total=sum(q for _,q in selected)
 if total<=0:selected=[('pelvis',1)];total=1
 for name,value in selected:groups[name].add([v.index],value/total,'REPLACE')
body.parent=rig;mod=body.modifiers.new('NativeSkin','ARMATURE');mod.object=rig
for v in body.data.vertices:v.co*=3.6
bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=3.6;b.tail*=3.6
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (body,rig))
bpy.ops.export_scene.gltf(filepath=a[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(a[2]).write_text(json.dumps({'height_m':3.6,'bones':len(groups),'vertices':len(body.data.vertices),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'filament_cleanup':'Not applied: regenerated cheek markings are flush; no hanging rods in inspected front/side/reverse','candidate_enabled':False},indent=2))
