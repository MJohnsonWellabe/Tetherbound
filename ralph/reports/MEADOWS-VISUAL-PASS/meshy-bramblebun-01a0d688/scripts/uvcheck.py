import json,struct
def load(p):
    b=open(p,'rb').read(); l=struct.unpack('<I',b[12:16])[0]; j=json.loads(b[20:20+l]); return j,b[20+l+8:]
def acc(j,bn,i):
    a=j['accessors'][i]; bv=j['bufferViews'][a['bufferView']]
    n={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]; off=bv.get('byteOffset',0)+a.get('byteOffset',0)
    fmt={5126:'f',5125:'I',5123:'H'}[a['componentType']]; sz=struct.calcsize(fmt); stride=bv.get('byteStride',n*sz)
    return [struct.unpack_from('<'+fmt*n,bn,off+k*stride) for k in range(a['count'])]
A,ab=load('/home/user/tetherbound/assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb')
B,bb=load('candidate/model.glb')
pa=A['meshes'][0]['primitives'][0]; pb=B['meshes'][0]['primitives'][0]
va=acc(A,ab,pa['attributes']['POSITION']); vb=acc(B,bb,pb['attributes']['POSITION'])
ua=acc(A,ab,pa['attributes']['TEXCOORD_0']); ub=acc(B,bb,pb['attributes']['TEXCOORD_0'])
ia=acc(A,ab,pa['indices']); ib=acc(B,bb,pb['indices'])
bbox=lambda v:[(min(p[k] for p in v),max(p[k] for p in v)) for k in range(3)]
print('bbox orig',bbox(va)); print('bbox cand',bbox(vb))
print('uv range orig',bbox([u+(0,) for u in ua])[:2],'cand',bbox([u+(0,) for u in ub])[:2])
# compare per-triangle-corner UVs
d=[abs(ua[x[0]][k]-ub[y[0]][k]) for x,y in zip(ia,ib) for k in (0,1)]
print('corner uv max diff',max(d),'mean',sum(d)/len(d), 'frac>1e-3', sum(1 for q in d if q>1e-3)/len(d))
# node transforms
print('cand nodes',[ (n.get('name'),n.get('rotation'),n.get('scale'),n.get('translation')) for n in B['nodes']])
print('orig mesh node',[ (n.get('name'),n.get('rotation'),n.get('scale'),n.get('translation')) for n in A['nodes'] if 'mesh' in n])
