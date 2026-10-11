"""Fulgocobra asset preparation: corrected joints and anatomical skin ownership.

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
# Legless asymmetric open coil measured from front, side and top views.
# Each coil joint follows the body centreline; no quadruped donor or invented feet.
body.data.validate(verbose=True)
coil=[(-.42,-.23,.14),(-.65,-.18,.12),(-.67,.02,.12),(-.45,.10,.12),
      (-.15,-.02,.12),(.15,.08,.12),(.25,.33,.12),(-.10,.50,.12),
      (.20,.65,.12),(.55,.64,.12),(.73,.77,.11),(.53,.97,.10),(.20,1.08,.11)]
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object; rig.name='FulgocobraNativeRig'
eb=rig.data.edit_bones
for b in list(eb): eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.13))
bone('pelvis',(-.42,-.23,.14),(-.40,-.27,.30),'root')
bone('spine',(-.40,-.27,.30),(-.40,-.38,.56),'pelvis')
bone('neck',(-.40,-.38,.56),(-.40,-.58,.84),'spine')
bone('head',(-.40,-.58,.84),(-.40,-.94,.90),'neck')
bone('hood_l',(-.43,-.40,.61),(-.75,-.36,.72),'neck')
bone('hood_r',(-.37,-.40,.61),(-.06,-.36,.72),'neck')
for i,(h,t) in enumerate(zip(coil[:-1],coil[1:])):
 bone('coil_'+str(i+1),h,t,'pelvis' if i==0 else 'coil_'+str(i))
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
 head=s(.80,.89,z)*(1-s(-.65,-.48,y))
 neck=s(.47,.65,z)*(1-head)
 spine=s(.23,.42,z)*(1-head-neck)
 w={'head':head,'neck':neck,'spine':spine}
 low_body=max(0,1-head-neck-spine)
 distances=[distance_segment(v.co,a,b) for a,b in zip(coil[:-1],coil[1:])]
 nearest=sorted(range(len(distances)),key=distances.__getitem__)[:2]
 scores=[1/max(.025,distances[i])**4 for i in nearest];total=sum(scores)
 for i,score in zip(nearest,scores):w['coil_'+str(i+1)]=low_body*score/total
 # The broad hood belongs to the neck; small edge controls do not drive the face.
 hood=s(.09,.22,abs(x+.40))*s(.35,.51,z)*(1-head)
 for k in w:w[k]*=1-hood
 w['hood_l' if x<-.40 else 'hood_r']=hood
 weights.append(w)
# Spatially local surface diffusion smooths transition edges while preserving
# protected head and hood ownership and avoiding broad transfer between adjacent coil loops.
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
# Scales, fangs and throat plates are dielectric; retain albedo/normal/roughness maps.
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
# Export at the established 5.20 m size; never shrink the installed creature.
scale=5.20/H
for v in body.data.vertices:v.co*=scale
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=scale;b.tail*=scale
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (rig,body))
bpy.ops.export_scene.gltf(filepath=args[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(args[2]).write_text(json.dumps({'height_m':5.20,'bones':len(groups),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'vertices':len(body.data.vertices),'method':'measured_joint_anatomical_regions_local_surface_diffusion','candidate_enabled':False},indent=2))
