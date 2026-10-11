"""Tanglevolt asset preparation: corrected joints and anatomical skin ownership.

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
body.data.validate(clean_customdata=False);body.data.update()
H=max(v.co.z for v in body.data.vertices)
def s(a,b,x):
 t=max(0,min(1,(x-a)/(b-a))); return t*t*(3-2*t)
# Four paw columns retain the existing mesh's diagonal stance. Joint heights
# are measured within the visible limbs, rather than from the sole centroid.
feet={'front_l':(-.275,-.68),'front_r':(.265,-.62),
      'rear_l':(-.30,.16),'rear_r':(.27,.47)}
bpy.ops.object.armature_add(enter_editmode=True)
rig=bpy.context.object; rig.name='TanglevoltNativeRig'
eb=rig.data.edit_bones
for b in list(eb): eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.13))
bone('pelvis',(0,.29,.63),(0,-.05,.67),'root')
bone('spine',(0,-.05,.67),(0,-.45,.71),'pelvis')
bone('neck',(0,-.45,.71),(0,-.75,.73),'spine')
bone('head',(0,-.75,.73),(0,-1.06,.65),'neck')
bone('tail_1',(0,.62,.58),(0,.79,.47),'pelvis')
bone('tail_2',(0,.79,.47),(0,.97,.36),'tail_1')
bone('tail_3',(0,.97,.36),(0,1.13,.27),'tail_2')
for key,(x,y) in feet.items():
 prefix,side=key.split('_');upper=prefix+'_upper_'+side;lower=prefix+'_lower_'+side
 knee=(x,y+(.075 if prefix=='front' else .095),.27)
 ankle=(x,y+.04,.047)
 bone(upper,(x*.77,y+(.22 if prefix=='front' else -.16),.66),knee,'spine' if prefix=='front' else 'pelvis')
 bone(lower,knee,ankle,upper)
 bone(prefix+'_foot_'+side,ankle,(x,y-.06,.017),lower)
bpy.ops.object.mode_set(mode='OBJECT')
for vg in list(body.vertex_groups):body.vertex_groups.remove(vg)
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
weights=[]
for v in body.data.vertices:
 x,y,z=v.co
 head=s(.47,.68,z)*(1-s(-.79,-.52,y))
 neck=s(.46,.67,z)*(1-s(-.52,-.28,y))*(1-head)
 tail=s(.57,.77,y)*(1-s(.17,.28,abs(x)))
 rear=s(-.04,.22,y)
 t2=s(.77,.94,y);t3=s(.98,1.11,y)
 w={'head':head,'neck':neck,'spine':(1-head-neck)*(1-tail)*(1-rear),
    'pelvis':(1-head-neck)*(1-tail)*rear,'tail_1':tail*(1-t2),'tail_2':tail*t2*(1-t3),'tail_3':tail*t3}
 key=min(feet,key=lambda k:(x-feet[k][0])**2+(y-feet[k][1])**2)
 fx,fy=feet[key];distance=math.hypot(x-fx,y-fy)
 leg=(1-s(.36,.60,z))*(1-s(.11,.25,distance))
 leg=max(leg,(1-s(.22,.35,z))*(1-s(.17,.29,distance)))
 for k in w:w[k]*=1-leg
 prefix,side=key.split('_');upper=s(.22,.34,z);foot=1-s(.045,.10,z)
 w[prefix+'_upper_'+side]=leg*upper
 w[prefix+'_lower_'+side]=leg*(1-upper)*(1-foot)
 w[prefix+'_foot_'+side]=leg*(1-upper)*foot
 weights.append(w)
# Spatially local surface diffusion smooths transition edges while preserving
# protected head/shell ownership and avoiding cross-leg donor transfer.
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
# Fur, tusks and earth plates are dielectric; retain albedo/normal/roughness maps.
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
# Export at the established 3.40 m size; never shrink the installed creature.
scale=3.40/H
for v in body.data.vertices:v.co*=scale
bpy.context.view_layer.objects.active=rig
bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=scale;b.tail*=scale
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (rig,body))
bpy.ops.export_scene.gltf(filepath=args[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(args[2]).write_text(json.dumps({'height_m':3.40,'bones':len(groups),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'vertices':len(body.data.vertices),'method':'measured_joint_anatomical_regions_local_surface_diffusion','candidate_enabled':False},indent=2))
