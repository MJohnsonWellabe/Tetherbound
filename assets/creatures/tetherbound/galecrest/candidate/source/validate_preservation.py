import json,struct,collections,sys
from pathlib import Path
root=Path('C:/CodexTemp/tetherbound-native-service');out=Path('C:/CodexTemp/native-service-artifacts/galecrest')
def read(path):
 b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);k=20+n;size=struct.unpack_from('<I',b,k)[0];binary=b[k+8:k+8+size]
 def values(i):
  a=g['accessors'][i];v=g['bufferViews'][a['bufferView']];typ={'SCALAR':1,'VEC3':3}[a['type']];fmt={5126:'f',5125:'I',5123:'H',5121:'B'}[a['componentType']];width=struct.calcsize('<'+fmt)*typ
  stride=v.get('byteStride',width);start=v.get('byteOffset',0)+a.get('byteOffset',0)
  return [struct.unpack_from('<'+fmt*typ,binary,start+j*stride) for j in range(a['count'])]
 points=set();tris=0
 for mesh in g['meshes']:
  for p in mesh['primitives']:
   points.update(tuple(round(x,5) for x in xyz) for xyz in values(p['attributes']['POSITION']))
   tris+=g['accessors'][p['indices']]['count']//3
 clips={a['name']:max(values(s['input'])[-1][0] for s in a['samplers']) for a in g['animations']}
 return g,points,tris,clips
source=Path(sys.argv[1]) if len(sys.argv)>1 else root/'assets/creatures/tetherbound/galecrest/models/creature_galecrest_lod0.glb'
candidate=Path(sys.argv[2]) if len(sys.argv)>2 else out/'animated-confirm.glb'
a,pa,ta,ca=read(source)
b,pb,tb,cb=read(candidate)
assert pa==pb,'Neutral geometry changed'
for key in ['nodes','meshes','skins','materials','textures','images','samplers','scenes']:
 assert a.get(key)==b.get(key),('Original GLB object changed',key)
assert a['accessors']==b['accessors'][:len(a['accessors'])]
assert a['bufferViews']==b['bufferViews'][:len(a['bufferViews'])]
assert a['animations']==b['animations'][:len(a['animations'])]
assert ta==tb,'Triangle count changed'
assert set(cb)=={'idle','walk','run','attack','charged','hit','faint','rest','swim','fly_grip','ride'}
for clip,duration in ca.items():assert abs(duration-cb[clip])<.0001,(clip,duration,cb[clip])
assert len(a['skins'][0]['joints'])==len(b['skins'][0]['joints'])==19
r={'triangles_before':ta,'triangles_after':tb,'neutral_position_set_preserved':True,'mesh_skin_uv_materials_preserved':True,'bones':19,'original_six_clip_data_and_durations_preserved':True,'clips':list(cb),'new_meshy_submissions':0,'candidate_enabled':False}
if len(sys.argv)==1:(out/'preservation-report.json').write_text(json.dumps(r,indent=2)+'\n')
print(json.dumps(r))
