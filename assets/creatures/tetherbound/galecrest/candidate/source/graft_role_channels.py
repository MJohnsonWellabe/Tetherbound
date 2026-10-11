"""Append authored role channels to the installed GLB; preserve all original payloads."""
import copy,json,struct,sys
from pathlib import Path
def read(p):
 b=Path(p).read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);k=20+n;size=struct.unpack_from('<I',b,k)[0];return g,b[k+8:k+8+size]
src,authored,dest=map(Path,sys.argv[1:4]);a,original=read(src);b,bb=read(authored);binary=bytearray(original)
names={n['name']:i for i,n in enumerate(a['nodes'])};node_map={}
for i,n in enumerate(b['nodes']):
 if n.get('name') not in names:continue
 j=names[n['name']];node_map[i]=j
 for field,default in [('translation',[0,0,0]),('rotation',[0,0,0,1]),('scale',[1,1,1])]:
  assert max(abs(x-y) for x,y in zip(n.get(field,default),a['nodes'][j].get(field,default)))<.00001,(n['name'],field)
accessors={};views={}
def accessor(i):
 if i in accessors:return accessors[i]
 x=copy.deepcopy(b['accessors'][i]);assert 'sparse' not in x;v=x['bufferView']
 if v not in views:
  view=copy.deepcopy(b['bufferViews'][v]);start=view.get('byteOffset',0);length=view['byteLength'];binary.extend(b'\0'*((-len(binary))%4));view['byteOffset']=len(binary);view['buffer']=0;binary.extend(bb[start:start+length]);views[v]=len(a['bufferViews']);a['bufferViews'].append(view)
 x['bufferView']=views[v];accessors[i]=len(a['accessors']);a['accessors'].append(x);return accessors[i]
roles={'charged','rest','swim','fly_grip','ride'}
for animation in b['animations']:
 if animation['name'] not in roles:continue
 x=copy.deepcopy(animation)
 for channel in x['channels']:channel['target']['node']=node_map[channel['target']['node']]
 for sampler in x['samplers']:
  sampler['input']=accessor(sampler['input']);sampler['output']=accessor(sampler['output'])
 a['animations'].append(x)
assert len(a['animations'])==11
binary.extend(b'\0'*((-len(binary))%4));a['buffers'][0]['byteLength']=len(binary)
js=json.dumps(a,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
out=struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary
dest.write_bytes(out);print('Preserved original GLB payload; appended five role animations')
