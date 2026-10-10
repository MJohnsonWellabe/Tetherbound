"""Voltarach asset preparation: corrected joints and anatomical skin ownership.

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
# Eight complete legs measured from front/side/overhead source views.
# Four pairs, three articulated controls per leg, no quadruped donor.
body.data.validate(verbose=True)
limbs=[((.29,-.85,.42),(.66,-1.00,.74),(.70,-1.55,.08),(.69,-1.65,.01)),
       ((.40,-.60,.44),(1.02,-.87,.88),(1.20,-1.24,.10),(1.24,-1.32,.02)),
       ((.43,-.18,.44),(1.08,-.12,.94),(1.52,-.18,.08),(1.61,-.22,.015)),
       ((.33,.10,.43),(.91,.55,.92),(1.20,.99,.07),(1.28,1.04,.015))]
segments={}
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object; rig.name='VoltarachNativeRig'
eb=rig.data.edit_bones
for b in list(eb): eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.13))
bone('abdomen',(0,.15,.39),(0,1.40,.40),'root')
bone('thorax',(0,.02,.40),(0,-.65,.40),'root')
bone('head',(0,-.65,.40),(0,-1.02,.36),'thorax')
for pair,points in enumerate(limbs,1):
 for side,sign in [('l',-1),('r',1)]:
  mirrored=[(x*sign,y,z) for x,y,z in points]
  parent='thorax'
  for joint,(h,t) in enumerate(zip(mirrored[:-1],mirrored[1:]),1):
   name='leg_'+str(pair)+'_'+side+'_'+str(joint)
   bone(name,h,t,parent);segments[name]=(h,t);parent=name
bpy.ops.object.mode_set(mode='OBJECT')
for vg in list(body.vertex_groups):body.vertex_groups.remove(vg)
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
def distance_segment(v,a,b):
 a,b=Vector(a),Vector(b);delta=b-a
 q=max(0,min(1,(v-a).dot(delta)/delta.length_squared))
 return (v-(a+delta*q)).length
weights=[]
core={'abdomen':((0,.15,.39),(0,1.40,.40)),
      'thorax':((0,.02,.40),(0,-.65,.40)),
      'head':((0,-.65,.40),(0,-1.02,.36))}
for v in body.data.vertices:
 x,y,z=v.co
 body_region=1-s(.29,.49,abs(x))
 # The entire central rear abdomen stays on the abdominal control.
 if y>.28 and abs(x)<.49:body_region=max(body_region,1-s(.39,.52,abs(x)))
 nearest=sorted(core,key=lambda k:distance_segment(v.co,*core[k]))[:2]
 values={k:1/max(.035,distance_segment(v.co,*core[k]))**4 for k in nearest};total=sum(values.values())
 w={k:body_region*value/total for k,value in values.items()}
 nearest=sorted(segments,key=lambda k:distance_segment(v.co,*segments[k]))[:2]
 values={k:1/max(.025,distance_segment(v.co,*segments[k]))**4 for k in nearest};total=sum(values.values())
 for k,value in values.items():w[k]=(1-body_region)*value/total
 weights.append(w)
# Spatially local surface diffusion smooths transition edges while preserving
# protected central carapace ownership and avoiding broad transfer between adjacent legs.
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
# Carapace, leg plates and mouthparts are dielectric; retain albedo/normal/roughness maps.
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
# Export at the established 4.25 m size; never shrink the installed creature.
scale=4.25/H
for v in body.data.vertices:v.co*=scale
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=scale;b.tail*=scale
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (rig,body))
bpy.ops.export_scene.gltf(filepath=args[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(args[2]).write_text(json.dumps({'height_m':4.25,'bones':len(groups),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'vertices':len(body.data.vertices),'method':'measured_joint_anatomical_regions_local_surface_diffusion','candidate_enabled':False},indent=2))
