"""AbyssalGuardian asset preparation: corrected joints and anatomical skin ownership.

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
# Four rounded paddles measured in front/side/overhead views, no invented legs.
body.data.validate(verbose=True)
fins={'front':((.14,-.83,.18),(.50,-.89,.10),(.90,-.99,.03)),
      'rear':((.14,-.13,.21),(.43,.09,.10),(.72,.22,.035))}
segments={}
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object; rig.name='AbyssalGuardianNativeRig'
eb=rig.data.edit_bones
for b in list(eb): eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.13))
bone('pelvis',(0,.04,.20),(0,-.40,.20),'root')
bone('spine',(0,-.40,.20),(0,-.87,.22),'pelvis')
bone('neck_lower',(0,-.87,.22),(0,-1.00,.56),'spine')
bone('neck_upper',(0,-1.00,.56),(0,-1.03,.89),'neck_lower')
bone('head',(0,-1.03,.89),(0,-1.37,.92),'neck_upper')
tail=[(0,.04,.20),(0,.35,.25),(0,.65,.43),(0,.95,.39),(0,1.42,.10)]
for i,(h,t) in enumerate(zip(tail[:-1],tail[1:]),1):bone('tail_'+str(i),h,t,'pelvis' if i==1 else 'tail_'+str(i-1))
for kind,points in fins.items():
 for side,sign in [('l',-1),('r',1)]:
  points=[(x*sign,y,z) for x,y,z in points];parent='spine' if kind=='front' else 'pelvis'
  for i,(h,t) in enumerate(zip(points[:-1],points[1:]),1):
   name=kind+'_flipper_'+side+'_'+str(i);bone(name,h,t,parent);segments[name]=(h,t);parent=name
bpy.ops.object.mode_set(mode='OBJECT')
for vg in list(body.vertex_groups):body.vertex_groups.remove(vg)
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
def distance_segment(v,a,b):
 a,b=Vector(a),Vector(b);delta=b-a
 q=max(0,min(1,(v-a).dot(delta)/delta.length_squared))
 return (v-(a+delta*q)).length
weights=[]
for v in body.data.vertices:
 x,y,z=v.co
 head=s(.86,.94,z)*(1-s(-1.10,-.95,y))
 upper=s(.52,.70,z)*(1-head)*(1-s(-.96,-.70,y))
 lower=s(.20,.40,z)*(1-head-upper)*(1-s(-.80,-.62,y))
 tail_region=s(-.04,.30,y)*(1-s(.07,.14,abs(x)))
 remaining=max(0,1-head-upper-lower);rear=s(-.38,-.05,y)
 w={'head':head,'neck_upper':upper,'neck_lower':lower,'spine':remaining*(1-tail_region)*(1-rear),'pelvis':remaining*(1-tail_region)*rear}
 nearest=sorted(range(4),key=lambda i:distance_segment(v.co,tail[i],tail[i+1]))[:2]
 scores=[1/max(.025,distance_segment(v.co,tail[i],tail[i+1]))**4 for i in nearest];total=sum(scores)
 for i,score in zip(nearest,scores):w['tail_'+str(i+1)]=remaining*tail_region*score/total
 fin=s(.10,.22,abs(x))*(1-s(.28,.45,z))
 for k in w:w[k]*=1-fin
 nearest=sorted(segments,key=lambda k:distance_segment(v.co,*segments[k]))[:2]
 scores={k:1/max(.025,distance_segment(v.co,*segments[k]))**4 for k in nearest};total=sum(scores.values())
 for k,score in scores.items():w[k]=fin*score/total
 weights.append(w)
# Spatially local surface diffusion smooths transition edges while preserving
# protected neck/head ownership and avoiding broad transfer between separate paddles.
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
# Scales, underside and connected dorsal crest are dielectric; retain albedo/normal/roughness maps.
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
# Export at the established 7.20 m size; never shrink the installed creature.
scale=7.20/H
for v in body.data.vertices:v.co*=scale
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=scale;b.tail*=scale
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (rig,body))
bpy.ops.export_scene.gltf(filepath=args[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(args[2]).write_text(json.dumps({'height_m':7.20,'bones':len(groups),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'vertices':len(body.data.vertices),'method':'measured_joint_anatomical_regions_local_surface_diffusion','candidate_enabled':False},indent=2))
