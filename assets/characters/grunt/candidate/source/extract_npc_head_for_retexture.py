"""Produce a static head input with installed UVs; never modify the source.
python extract_npc_head_for_retexture.py body.glb head.glb report.json
"""
import copy,json,struct,sys
from pathlib import Path
import numpy as np
def load(p):
 b=Path(p).read_bytes();n=struct.unpack_from('<I',b,12)[0];j=json.loads(b[20:20+n]);k=20+n;s=struct.unpack_from('<I',b,k)[0];return j,b[k+8:k+8+s]
def acc(j,b,i):
 a=j['accessors'][i];assert 'sparse' not in a;v=j['bufferViews'][a['bufferView']];d={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']];k={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']];sz=np.dtype(d).itemsize
 x=np.ndarray((a['count'],k),dtype=d,buffer=b,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',k*sz),sz)).copy()
 if a.get('normalized') and a['componentType']!=5126:x=x/np.iinfo(np.dtype(d)).max
 return x
source,dest,report=map(Path,sys.argv[1:4]);r,rb=load(source);assert len(r['meshes'])==1 and len(r['meshes'][0]['primitives'])==1
p=r['meshes'][0]['primitives'][0];a=p['attributes'];pos=acc(r,rb,a['POSITION']);joints=acc(r,rb,a['JOINTS_0']);weights=acc(r,rb,a['WEIGHTS_0']);s=r['skins'][0]
head_joint=next(i for i,n in enumerate(s['joints']) if r['nodes'][n]['name']=='Head');hw=(weights*(joints==head_joint)).sum(axis=1)
idx=acc(r,rb,p['indices']).reshape(-1,3);height=pos[:,1].max()-pos[:,1].min();selected=(hw>.05)&(pos[:,1]>pos[:,1].min()+.72*height)
chosen=idx[selected[idx].any(axis=1)];used=np.unique(chosen);mapping=np.full(len(pos),-1,dtype=np.int64);mapping[used]=np.arange(len(used));newidx=mapping[chosen]
assert len(chosen)>0 and newidx.min()>=0
g={'asset':{'version':'2.0','generator':'Tetherbound installed-head UV-preserving extraction'},'buffers':[{'byteLength':0}],'bufferViews':[],'accessors':[],'materials':copy.deepcopy(r['materials']),'images':[],'textures':copy.deepcopy(r.get('textures',[])),'samplers':copy.deepcopy(r.get('samplers',[])),'nodes':[{'name':'InstalledHeadInput','mesh':0}],'meshes':[{'name':'InstalledHeadInput','primitives':[]}],'scenes':[{'nodes':[0]}],'scene':0}
if r.get('extensionsUsed'):g['extensionsUsed']=r['extensionsUsed']
binary=bytearray()
def add(x,ctype,typ,target=None):
 x=np.ascontiguousarray(x);binary.extend(b'\0'*((-len(binary))%4));v={'buffer':0,'byteOffset':len(binary),'byteLength':x.nbytes};binary.extend(x.tobytes())
 if target:v['target']=target
 vi=len(g['bufferViews']);g['bufferViews'].append(v);z={'bufferView':vi,'componentType':ctype,'count':len(x),'type':typ}
 if typ=='VEC3':z['min']=x.min(axis=0).tolist();z['max']=x.max(axis=0).tolist()
 ai=len(g['accessors']);g['accessors'].append(z);return ai
attrs={};lower=float(pos[used,1].min())
for key,i in a.items():
 if key in ['JOINTS_0','WEIGHTS_0']:continue
 x=acc(r,rb,i)[used].astype('<f4');typ=r['accessors'][i]['type']
 if key=='POSITION':x[:,1]-=lower
 attrs[key]=add(x,5126,typ,34962)
g['meshes'][0]['primitives'].append({'attributes':attrs,'indices':add(newidx.reshape(-1).astype('<u4'),5125,'SCALAR',34963),'material':p.get('material',0)})
for image in r.get('images',[]):
 x=copy.deepcopy(image);assert 'bufferView' in x;v=r['bufferViews'][x['bufferView']];off=v.get('byteOffset',0);binary.extend(b'\0'*((-len(binary))%4));view={'buffer':0,'byteOffset':len(binary),'byteLength':v['byteLength']};binary.extend(rb[off:off+v['byteLength']]);x['bufferView']=len(g['bufferViews']);g['bufferViews'].append(view);g['images'].append(x)
binary.extend(b'\0'*((-len(binary))%4));g['buffers'][0]['byteLength']=len(binary);js=json.dumps(g,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
dest.write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary)
report.write_text(json.dumps({'source':source.name,'selected_triangles':len(chosen),'selected_vertices':len(used),'installed_uvs_retained':True,'source_body_unmodified':True,'scope':'Static isolated head service input only, not a new humanoid or an integration asset','vertical_translation_m':-lower,'original_body_height_m':float(height)},indent=2)+'\n')
print('Extracted installed head with original UVs; source untouched:',len(chosen),'triangles')
