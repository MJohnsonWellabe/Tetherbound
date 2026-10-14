import pathlib,json,struct,hashlib,math
import numpy as np
base=pathlib.Path('D:/tetherbound/source');repo=pathlib.Path('D:/tetherbound/codex-takeover-visual')
path=base/'assets/characters/trainer/trainer_lod0.glb';raw=path.read_bytes();n=struct.unpack_from('<I',raw,12)[0];d=json.loads(raw[20:20+n]);buf=raw[28+n:]
def acc(doc,data,index):
 a=doc['accessors'][index];v=doc['bufferViews'][a['bufferView']];dt=np.dtype({5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]);k={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}[a['type']]
 return np.ndarray((a['count'],k),dtype=dt,buffer=data,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',k*dt.itemsize),dt.itemsize)).copy()
def mat(node):
 if 'matrix' in node:return np.array(node['matrix']).reshape(4,4).T
 x,y,z,w=node.get('rotation',[0,0,0,1]);q=np.array([[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],[2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],[2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]])
 m=np.eye(4);m[:3,:3]=q@np.diag(node.get('scale',[1,1,1]));m[:3,3]=node.get('translation',[0,0,0]);return m
def worlds(nodes):
 out={}
 def visit(i,parent):
  out[i]=parent@mat(nodes[i])
  for c in nodes[i].get('children',[]):visit(c,out[i])
 for i in d['scenes'][d.get('scene',0)]['nodes']:visit(i,np.eye(4))
 return out
rest=worlds(d['nodes']);nodes=json.loads(json.dumps(d['nodes']));anim=next(a for a in d['animations'] if a['name']=='idle')
for ch in anim['channels']:
 s=anim['samplers'][ch['sampler']];assert s.get('interpolation','LINEAR') in ['LINEAR','STEP'];times=acc(d,buf,s['input']).reshape(-1);vals=acc(d,buf,s['output']);j=max(0,min(len(times)-2,int(np.searchsorted(times,.2)-1)));t=float(np.clip((.2-times[j])/(times[j+1]-times[j]),0,1));a=vals[j].astype(float);b=vals[j+1].astype(float)
 if s.get('interpolation')=='STEP':value=a
 elif ch['target']['path']=='rotation':
  a/=np.linalg.norm(a);b/=np.linalg.norm(b);dot=float(a@b)
  if dot<0:b=-b;dot=-dot
  if dot>.9995:value=a+t*(b-a);value/=np.linalg.norm(value)
  else:angle=math.acos(np.clip(dot,-1,1));value=(math.sin((1-t)*angle)*a+math.sin(t*angle)*b)/math.sin(angle)
 else:value=a*(1-t)+b*t
 nodes[ch['target']['node']][ch['target']['path']]=value.tolist()
posed=worlds(nodes);skin=d['skins'][0];ib=acc(d,buf,skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1);p=d['meshes'][0]['primitives'][0]['attributes'];positions=acc(d,buf,p['POSITION']);verts=np.c_[positions,np.ones(len(positions))];joints=acc(d,buf,p['JOINTS_0']);weights=acc(d,buf,p['WEIGHTS_0']);assert np.max(abs(weights.sum(axis=1)-1))<.001
def skinned(ws):
 bones=np.array([ws[j]@ib[i] for i,j in enumerate(skin['joints'])]);out=np.zeros_like(verts)
 for k in range(4):out+=np.einsum('nij,nj->ni',bones[joints[:,k]],verts)*weights[:,k,None]
 return out[:,:3]
rv=skinned(rest);pv=skinned(posed);fit=1.8/(rv[:,1].max()-rv[:,1].min());sole=float((pv[:,1].min()-rv[:,1].min())*fit)
floorpath=base/'assets/buildings/quaternius_medieval/Floor_UnevenBrick.gltf';fd=json.loads(floorpath.read_text());fb=(floorpath.parent/fd['buffers'][0]['uri']).read_bytes();assert fd['nodes']==[{'mesh':0,'name':'Floor_UnevenBrick'}]
fp=fd['meshes'][0]['primitives'][0];fv=acc(fd,fb,fp['attributes']['POSITION']);fi=acc(fd,fb,fp['indices']).reshape(-1,3)
prefab=json.loads((repo/'data/config/building_prefabs.json').read_text())['prefabs']['crossing_hall_shell'];floors=[m for m in prefab['modules'] if m['module']=='Floor_UnevenBrick'];cam=json.loads((repo/'tools/visual_judge/camera_sets/F17-6.json').read_text());rows=[]
def surface_height(x,z):
 hits=[]
 for tile in floors:
  assert tile.get('yaw_deg',0)==0
  at=np.array(tile['at']);local=np.array([x,z])-at[[0,2]]
  for ids in fi:
   tri=fv[ids];xz=tri[:,[0,2]];m=np.column_stack((xz[1]-xz[0],xz[2]-xz[0]))
   if abs(np.linalg.det(m))<1e-10:continue
   u,v=np.linalg.solve(m,local-xz[0])
   if u>=-1e-6 and v>=-1e-6 and u+v<=1+1e-6:hits.append(float(tri[0,1]+u*(tri[1,1]-tri[0,1])+v*(tri[2,1]-tri[0,1])+at[1]-.05))
 assert hits,'No Hall floor triangle under station'
 return max(hits)
for view in cam['views']:
 if view['id'].startswith('hall-approach'):continue
 x,y,z=view['player'];floor=surface_height(-(z-14),x-107)
 rows.append({'view':view['id'],'old_player_y':y,'rendered_floor_y':floor,'idle_sole_relative_to_player_y':sole,'old_idle_sole_gap_m':y+sole-floor,'corrected_player_y_for_idle_contact':floor-sole})
out={'scope':'CPU glTF skinning/idle0.2s and actual Hall floor triangle audit; native confirmation required','trainer_glb_sha256':hashlib.sha256(raw).hexdigest(),'fit_height_m':1.8,'bind_min_y':float(rv[:,1].min()),'bind_max_y':float(rv[:,1].max()),'fit_scale':float(fit),'idle_sole_offset_m':sole,'collider_bottom_relative_to_player':0.0,'hall_floor_collider_top_world_y':.01,'fixture_model_physics_disabled_before_first_tick':True,'views':rows}
target=pathlib.Path('D:/tetherbound/.artifacts/visual-takeover/hall-trainer-contact-cpu.json');target.write_text(json.dumps(out,indent=2)+'\n');print(json.dumps(out,indent=2))
