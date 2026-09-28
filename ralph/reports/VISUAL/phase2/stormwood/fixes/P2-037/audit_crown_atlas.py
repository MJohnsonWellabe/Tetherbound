import hashlib,json,pathlib
import numpy as np
from PIL import Image
root=pathlib.Path.cwd();family=root/'assets/environment/stylized_nature'
paths=[family/'Leaves_TwistedTree_C.png',family/'derived/Leaves_NormalTree_C_desat55.png']
alphas=[np.asarray(Image.open(p).convert('RGBA'))[:,:,3] for p in paths]
samples=[]
for i in range(12):
 for j in range(12-i):
  a=(i+1/3)/12;b=(j+1/3)/12
  samples.append([a,b,1-a-b])
weights=np.array(samples)
records=[]
for name in ['TwistedTree_2','TwistedTree_4']:
 path=family/(name+'.gltf');g=json.loads(path.read_text());buffers=[(family/x['uri']).read_bytes() for x in g['buffers']]
 def accessor(index):
  a=g['accessors'][index];v=g['bufferViews'][a['bufferView']]
  dt={5126:'<f4',5123:'<u2',5125:'<u4',5121:'u1'}[a['componentType']]
  count={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]
  width=np.dtype(dt).itemsize*count
  return np.ndarray((a['count'],count),dtype=dt,buffer=buffers[v['buffer']],offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',width),np.dtype(dt).itemsize)).copy()
 totals=np.zeros(4);triangles=0
 for mesh in g['meshes']:
  for prim in mesh['primitives']:
   if g['materials'][prim['material']]['name']!='Leaves_TwistedTree':continue
   uv=accessor(prim['attributes']['TEXCOORD_0']);positions=accessor(prim['attributes']['POSITION']);ids=accessor(prim['indices']).reshape(-1,3)
   vertices=positions[ids];areas=np.linalg.norm(np.cross(vertices[:,1]-vertices[:,0],vertices[:,2]-vertices[:,0]),axis=1)*.5
   points=np.einsum('sc,tcd->tsd',weights,uv[ids])%1
   masks=[]
   for alpha in alphas:
    y=np.minimum((points[:,:,1]*alpha.shape[0]).astype(int),alpha.shape[0]-1);x=np.minimum((points[:,:,0]*alpha.shape[1]).astype(int),alpha.shape[1]-1)
    masks.append(alpha[y,x]>51)
   correct,swapped=masks
   for k,mask in enumerate([correct,swapped,correct&~swapped,~correct&swapped]):totals[k]+=(mask.mean(axis=1)*areas).sum()
   triangles+=len(ids)
 records.append({'model':name,'leaf_triangles':triangles,'sample_points_per_triangle':len(weights),'authored_opaque_area':float(totals[0]),'substituted_opaque_area':float(totals[1]),'authored_leaf_area_lost_fraction':float(totals[2]/totals[0]),'substituted_opaque_area_outside_authored_mask_fraction':float(totals[3]/totals[1])})
result={'method':'Deterministic 78 barycentric samples per actual leaf triangle, weighted by model-space triangle area; nearest alpha threshold >0.2. Diagnostic source UV/alpha pairing, not screen coverage or a visual acceptance result.','textures':[{'path':str(p.relative_to(root)).replace('\\','/'),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths],'models':records}
out=root/'ralph/reports/VISUAL/phase2/stormwood/fixes/P2-037/crown-atlas-audit.json';out.write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps(records,indent=2))
