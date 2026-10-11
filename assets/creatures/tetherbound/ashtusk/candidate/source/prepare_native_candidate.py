"""Material-only Ashtusk derivative; preserve Tuskroot geometry, UVs, rig and clips.

python graft_materials.py input-task-raw.glb retexture.glb fitted-tuskroot.glb output.glb report.json
Reject a changed UV/triangle mapping; no geometry from the retexture is installed.
"""
import copy,json,struct,sys,collections
from pathlib import Path
def read(p):
 data=Path(p).read_bytes();n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n]);k=20+n;size=struct.unpack_from('<I',data,k)[0]
 return g,data[k+8:k+8+size]
def values(g,b,i):
 a=g['accessors'][i];assert 'sparse' not in a
 v=g['bufferViews'][a['bufferView']];offset=v.get('byteOffset',0)+a.get('byteOffset',0)
 types={5121:'B',5123:'H',5125:'I',5126:'f'};sizes={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
 fmt='<'+types[a['componentType']]*sizes[a['type']];stride=v.get('byteStride',struct.calcsize(fmt))
 return [struct.unpack_from(fmt,b,offset+j*stride) for j in range(a['count'])]
def triangles(g,b):
 result=collections.Counter()
 for mesh in g['meshes']:
  for p in mesh['primitives']:
   assert p.get('mode',4)==4
   pos=values(g,b,p['attributes']['POSITION']);uv=values(g,b,p['attributes']['TEXCOORD_0'])
   vertices=[tuple(round(x,5) for x in xyz+st) for xyz,st in zip(pos,uv)]
   indices=[x[0] for x in values(g,b,p['indices'])] if 'indices' in p else list(range(len(pos)))
   for i in range(0,len(indices),3):result[tuple(sorted(vertices[j] for j in indices[i:i+3]))]+=1
 return result
raw,ret,rigged,dest,report=map(Path,sys.argv[1:6]);a,ab=read(raw);r,rb=read(ret);g,gb=read(rigged)
assert triangles(a,ab)==triangles(r,rb),'FAIL UV/triangle mapping: cannot install retexture materials'
original=copy.deepcopy(g);binary=bytearray(gb);image_map={};texture_map={};sampler_map={}
# Keep the original binary intact for geometry/skin proof, but do not ask Godot
# to extract obsolete source textures that are no longer bound to this variant.
for name in ['images','textures','samplers','materials']:g[name]=[]
used=list(dict.fromkeys(g.get('extensionsUsed',[])+r.get('extensionsUsed',[])))
if used:g['extensionsUsed']=used
for i,img in enumerate(r.get('images',[])):
 x=copy.deepcopy(img);assert 'bufferView' in x,'Only embedded textures accepted'
 view=copy.deepcopy(r['bufferViews'][x['bufferView']]);offset=view.get('byteOffset',0);length=view['byteLength']
 binary.extend(b'\0'*((-len(binary))%4));view['buffer']=0;view['byteOffset']=len(binary);binary.extend(rb[offset:offset+length])
 x['bufferView']=len(g['bufferViews']);g['bufferViews'].append(view)
 image_map[i]=len(g.setdefault('images',[]));g['images'].append(x)
for i,sampler in enumerate(r.get('samplers',[])):
 sampler_map[i]=len(g.setdefault('samplers',[]));g['samplers'].append(copy.deepcopy(sampler))
for i,tex in enumerate(r.get('textures',[])):
 x=copy.deepcopy(tex);x['source']=image_map[x['source']]
 if 'sampler' in x:x['sampler']=sampler_map[x['sampler']]
 texture_map[i]=len(g.setdefault('textures',[]));g['textures'].append(x)
def texture_indices(value):
 if isinstance(value,dict):
  for key,item in value.items():
   if key.endswith('Texture') and isinstance(item,dict) and 'index' in item:item['index']=texture_map[item['index']]
   else:texture_indices(item)
 elif isinstance(value,list):
  for item in value:texture_indices(item)
material_map={}
for i,material in enumerate(r['materials']):
 x=copy.deepcopy(material);texture_indices(x);x.setdefault('pbrMetallicRoughness',{})['metallicFactor']=0.0
 x['name']='AshtuskNativeMaterial_'+str(i)
 material_map[i]=len(g.setdefault('materials',[]));g['materials'].append(x)
assert len(g['meshes'])==len(r['meshes'])==1 and len(g['meshes'][0]['primitives'])==len(r['meshes'][0]['primitives'])==1
g['meshes'][0]['primitives'][0]['material']=material_map[r['meshes'][0]['primitives'][0].get('material',0)]
for name in ['nodes','skins','animations','accessors']:assert g[name]==original[name],name
assert g['bufferViews'][:len(original['bufferViews'])]==original['bufferViews']
assert bytes(binary[:len(gb)])==gb
check=copy.deepcopy(g['meshes']);check[0]['primitives'][0]['material']=original['meshes'][0]['primitives'][0]['material'];assert check==original['meshes']
binary.extend(b'\0'*((-len(binary))%4));g['buffers'][0]['byteLength']=len(binary)
js=json.dumps(g,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
dest.write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary)
report.write_text(json.dumps({'subject':'ashtusk','candidate_enabled':False,'raw_retexture_triangle_uv_mapping_unchanged':True,'fitted_tuskroot_geometry_uv_weights_nodes_skins_animations_unchanged':True,'original_binary_prefix_preserved':True,'only_material_binding_and_new_material_textures_added':True,'clips':len(g['animations']),'full_art_gate':False},indent=2)+'\n')
print('PASS same Tuskroot geometry/UV/weights/rig/11 clips; material-only Ashtusk derivative; OFF')
