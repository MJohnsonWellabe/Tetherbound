"""Fit Galewisp's inspected Meshy-6 biped; preserve UV loops and textures.
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
# Raw tail tips were below the foot soles: lift the tail, ground to the feet.
sole=min(v.co.z for v in body.data.vertices if v.co.y<.04 and abs(v.co.x)<.25 and v.co.z<.25)
tailverts=[v for v in body.data.vertices if v.co.y>.12 and v.co.z<.50]
tail_lift=max(0,sole+.008-min(v.co.z for v in tailverts))
for v in tailverts:
 t=max(0,min(1,(v.co.y-.12)/.10));v.co.z+=tail_lift*t*t*(3-2*t)
floor=min(v.co.z for v in body.data.vertices)
new_height=max(v.co.z for v in body.data.vertices)-floor
for v in body.data.vertices:v.co.z=(v.co.z-floor)/new_height;v.co.x/=new_height;v.co.y/=new_height
bm=bmesh.new();bm.from_mesh(body.data)
bmesh.ops.remove_doubles(bm,verts=bm.verts,dist=.00004)
bm.to_mesh(body.data);bm.free()
for o in list(bpy.data.objects):
 if o.type=='MESH' and o!=body:bpy.data.objects.remove(o,do_unlink=True)
bpy.ops.object.armature_add(enter_editmode=True);rig=bpy.context.object;rig.name='GalewispNativeRig'
eb=rig.data.edit_bones
for b in list(eb):eb.remove(b)
def bone(n,h,t,parent=None):
 b=eb.new(n);b.head=h;b.tail=t;b.roll=0
 if parent:b.parent=eb[parent]
bone('root',(0,0,0),(0,0,.12))
bone('pelvis',(0,-.04,.28),(0,-.055,.42),'root')
bone('spine',(0,-.055,.42),(0,-.075,.57),'pelvis')
bone('neck',(0,-.075,.57),(0,-.13,.68),'spine')
bone('head',(0,-.13,.68),(0,-.15,.85),'neck')
bone('tail_1',(0,.04,.30),(0,.25,.19),'pelvis')
bone('tail_2',(0,.25,.19),(0,.45,.12),'tail_1')
for side,sign in [('l',-1),('r',1)]:
 bone('leg_upper_'+side,(sign*.08,-.04,.28),(sign*.09,-.04,.14),'pelvis')
 bone('leg_lower_'+side,(sign*.09,-.04,.14),(sign*.115,-.08,.045),'leg_upper_'+side)
 bone('foot_'+side,(sign*.115,-.08,.045),(sign*.12,-.20,.015),'leg_lower_'+side)
 bone('wing_upper_'+side,(sign*.10,-.05,.57),(sign*.28,-.04,.61),'spine')
 bone('wing_lower_'+side,(sign*.28,-.04,.61),(sign*.43,-.03,.47),'wing_upper_'+side)
 bone('wing_tip_'+side,(sign*.43,-.03,.47),(sign*.58,-.02,.25),'wing_lower_'+side)
bpy.ops.object.mode_set(mode='OBJECT')
groups={b.name:body.vertex_groups.new(name=b.name) for b in rig.data.bones}
def s(a,b,x):
 t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
weights=[]
for v in body.data.vertices:
 x,y,z=v.co;side='l' if x<0 else 'r'
 head=s(.60,.72,z);tail=s(.11,.20,y)*(1-s(.46,.56,z));tip=s(.24,.35,y)
 torso=s(.30,.46,z)
 w={'head':head,'tail_1':tail*(1-tip),'tail_2':tail*tip,
 'spine':(1-head)*(1-tail)*torso,'pelvis':(1-head)*(1-tail)*(1-torso)}
 wing=s(.11,.20,abs(x))*(1-head)*(1-tail)
 leg=(1-s(.23,.34,z))*(1-tail)*(1-wing)
 for k in w:w[k]*=1-max(wing,leg)
 elbow=s(.25,.34,abs(x));wrist=s(.40,.49,abs(x))
 knee=s(.10,.17,z);ankle=1-s(.035,.075,z)
 w['wing_upper_'+side]=wing*(1-elbow)
 w['wing_lower_'+side]=wing*elbow*(1-wrist)
 w['wing_tip_'+side]=wing*elbow*wrist
 w['leg_upper_'+side]=leg*knee
 w['leg_lower_'+side]=leg*(1-knee)*(1-ankle)
 w['foot_'+side]=leg*(1-knee)*ankle
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
for v in body.data.vertices:v.co*=3.25
bpy.context.view_layer.objects.active=rig;bpy.ops.object.mode_set(mode='EDIT')
for b in rig.data.edit_bones:b.head*=3.25;b.tail*=3.25
bpy.ops.object.mode_set(mode='OBJECT')
for o in bpy.data.objects:o.select_set(o in (body,rig))
bpy.ops.export_scene.gltf(filepath=a[1],export_format='GLB',use_selection=True,export_yup=True,export_skins=True,export_animations=False)
Path(a[2]).write_text(json.dumps({'height_m':3.25,'bones':len(groups),'vertices':len(body.data.vertices),'unweighted_vertices':sum(not v.groups for v in body.data.vertices),'tail_tip_lift_raw_m':tail_lift*H,'foot_sole_raw_m':sole*H,'candidate_enabled':False},indent=2))
