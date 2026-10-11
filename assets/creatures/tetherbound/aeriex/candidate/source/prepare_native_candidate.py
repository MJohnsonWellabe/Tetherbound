"""Aeriex asset preparation: corrected joints and anatomical skin ownership.

Run in Blender with -- preserved-Meshy-model.glb output.glb report.json.
Raw Meshy-6 geometry is normalized before fitting; no automatic heat or cross-creature donor.
"""
import bpy, bmesh, sys, math, json
from pathlib import Path
from mathutils import Vector
args=sys.argv[sys.argv.index('--')+1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=args[0])
body=max((o for o in bpy.data.objects if o.type=='MESH'),key=lambda o:len(o.data.vertices))
old=[o for o in bpy.data.objects if o.type=='ARMATURE']
for mod in list(body.modifiers): body.modifiers.remove(mod)
body.parent=None
bpy.context.view_layer.objects.active=body
body.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
vs=body.data.vertices
lo=Vector(tuple(min(v.co[i] for v in vs) for i in range(3)))
hi=Vector(tuple(max(v.co[i] for v in vs) for i in range(3)))
offset=Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z))
H=hi.z-lo.z
for v in vs:v.co=(v.co+offset)/H
for o in old: bpy.data.objects.remove(o,do_unlink=True)
for o in list(bpy.data.objects):
 if o.type=='MESH' and o!=body: bpy.data.objects.remove(o,do_unlink=True)
bm=bmesh.new(); bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=0.00008)
bm.to_mesh(body.data); bm.free()
body.data.calc_loop_triangles()
if len(body.data.loop_triangles)>29500:
 dec=body.modifiers.new('TriangleBudget','DECIMATE');dec.ratio=29400/len(body.data.loop_triangles)
 bpy.context.view_layer.objects.active=body;bpy.ops.object.modifier_apply(modifier=dec.name)
H=max(v.co.z for v in body.data.vertices)
def s(a,b,x):
 t=max(0,min(1,(x-a)/(b-a))); return t*t*(3-2*t)
# Legless serpent body and two measured three-segment wings; no invented feet.
body.data.validate(verbose=True)
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object; rig.name='AeriexNativeRig'
eb=rig.data.edit_bones
for b in list(eb): eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.13))
bone('pelvis',(0,-.15,.12),(0,-.24,.30),'root')
bone('spine',(0,-.24,.30),(0,-.32,.54),'pelvis')
bone('neck',(0,-.32,.54),(0,-.40,.77),'spine')
bone('head',(0,-.40,.77),(0,-.46,.91),'neck')
bone('tail_1',(0,-.04,.11),(0,.19,.10),'pelvis')
bone('tail_2',(0,.19,.10),(0,.39,.16),'tail_1')
bone('tail_3',(0,.39,.16),(0,.59,.12),'tail_2')
for side,sign in [('l',-1),('r',1)]:
 bone('wing_upper_'+side,(sign*.10,-.24,.40),(sign*.34,-.23,.48),'spine')
 bone('wing_lower_'+side,(sign*.34,-.23,.48),(sign*.57,-.20,.57),'wing_upper_'+side)
 bone('wing_tip_'+side,(sign*.57,-.20,.57),(sign*.80,-.15,.65),'wing_lower_'+side)
bpy.ops.object.mode_set(mode='OBJECT')
for vg in list(body.vertex_groups):body.vertex_groups.remove(vg)
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
weights=[]
for v in body.data.vertices:
 x,y,z=v.co
 head=s(.76,.85,z)
 neck=s(.50,.72,z)*(1-head)
 tail=s(-.04,.15,y)*(1-s(.25,.36,z))
 torso=s(.19,.36,z)
 t2=s(.15,.29,y);t3=s(.36,.51,y)
 w={'head':head,'neck':neck,'spine':(1-head-neck)*(1-tail)*torso,
    'pelvis':(1-head-neck)*(1-tail)*(1-torso),
    'tail_1':tail*(1-t2),'tail_2':tail*t2*(1-t3),'tail_3':tail*t3}
 # Low rear tail plumes remain tail-owned. Shoulder weights feather into torso.
 wing=s(.10,.22,abs(x))*s(.23,.34,z)*(1-head)*(1-tail)
 for k in w:w[k]*=1-wing
 side='l' if x<0 else 'r';elbow=s(.29,.40,abs(x));wrist=s(.52,.64,abs(x))
 w['wing_upper_'+side]=wing*(1-elbow)
 w['wing_lower_'+side]=wing*elbow*(1-wrist)
 w['wing_tip_'+side]=wing*elbow*wrist
 weights.append(w)
# Spatially local surface diffusion smooths transition edges while preserving
# protected head and wing-root ownership and avoiding transfer between wings and low tail feathers.
adj=[set() for _ in body.data.vertices]
for e in body.data.edges:
 a,b=e.vertices;adj[a].add(b);adj[b].add(a)
for _ in range(3):
 nxt=[]
 for i,w in enumerate(weights):
  neighbours=[j for j in adj[i] if (body.data.vertices[j].co-body.data.vertices[i].co).length<.06]
  if not neighbours:nxt.append(w);continue
  out={}
  for name in groups:
   value=.8*w.get(name,0)+.2*sum(weights[j].get(name,0) for j in neighbours)/len(neighbours)
   if value>.0005:out[name]=value
  nxt.append(out)
 weights=nxt
for v,w in zip(body.data.vertices,weights):
 selected=sorted(w.items(),key=lambda x:x[1],reverse=True)[:4]; total=sum(value for _,value in selected)
 for name,value in selected:
  if value>0:groups[name].add([v.index],value/total,'REPLACE')
# Feathers, beak and skin are dielectric; retain albedo/normal/roughness maps.
for material in body.data.materials:
 if not material.use_nodes:continue
 for node in material.node_tree.nodes:
  if node.type!='BSDF_PRINCIPLED':continue
  for name in ['Metallic','Emission Color','Emission Strength']:
   socket=node.inputs.get(name)
   if socket is None:continue
   for link in list(socket.links):material.node_tree.links.remove(link)
   socket.default_value=(0,0,0,1) if name=='Emission Color' else 0
body.parent=rig
mod=body.modifiers.new('NativeSkin','ARMATURE');mod.object=rig
# Export at the established 4.00 m size; never shrink the installed creature.
scale=4.00/H
for v in body.data.vertices:v.co*=scale
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=scale;b.tail*=scale
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (rig,body))
bpy.ops.export_scene.gltf(filepath=args[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(args[2]).write_text(json.dumps({'height_m':4.00,'bones':len(groups),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'vertices':len(body.data.vertices),'method':'measured_joint_anatomical_regions_local_surface_diffusion','candidate_enabled':False},indent=2))
