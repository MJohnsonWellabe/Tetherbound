import collections, io, json, struct
from pathlib import Path
import numpy as np
from PIL import Image

def read_glb(path):
    data=Path(path).read_bytes()
    assert struct.unpack_from('<III',data)==(0x46546c67,2,len(data))
    n,kind=struct.unpack_from('<II',data,12); assert kind==0x4e4f534a
    g=json.loads(data[20:20+n]); k=20+n
    size,kind=struct.unpack_from('<II',data,k); assert kind==0x004e4942
    return g,data[k+8:k+8+size]

def accessor(g,b,i):
    a=g['accessors'][i]; assert 'sparse' not in a
    v=g['bufferViews'][a['bufferView']]
    d={5121:'u1',5123:'<u2',5125:'<u4',5126:'<f4'}[a['componentType']]
    k={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}[a['type']]; sz=np.dtype(d).itemsize
    x=np.ndarray((a['count'],k),dtype=d,buffer=b,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',k*sz),sz)).copy()
    if a.get('normalized') and a['componentType']!=5126:x=x/np.iinfo(np.dtype(d)).max
    return x

def single_primitive(g,b):
    assert len(g['meshes'])==1 and len(g['meshes'][0]['primitives'])==1
    p=g['meshes'][0]['primitives'][0]; assert p.get('mode',4)==4
    a=p['attributes']; pos=accessor(g,b,a['POSITION']); uv=accessor(g,b,a['TEXCOORD_0'])
    idx=accessor(g,b,p['indices']).reshape(-1,3).astype(int) if 'indices' in p else np.arange(len(pos)).reshape(-1,3)
    return p,pos,uv,idx

def uv_triangles(g,b):
    p,pos,uv,idx=single_primitive(g,b)
    # Original-UV retexture may reorder vertices and normalize coordinates;
    # only its albedo is used, never its geometry, rig or materials.
    q=np.rint(uv*100000).astype(np.int64)
    return collections.Counter(tuple(sorted(tuple(q[v]) for v in tri)) for tri in idx)

def albedo(g,b,p):
    m=p.get('material',0); t=g['materials'][m]['pbrMetallicRoughness']['baseColorTexture']['index']
    i=g['textures'][t]['source']; v=g['bufferViews'][g['images'][i]['bufferView']]
    raw=b[v.get('byteOffset',0):v.get('byteOffset',0)+v['byteLength']]
    return Image.open(io.BytesIO(raw)).convert('RGBA'),m,t,i

def write_glb(path,g,binary):
    binary=bytearray(binary); binary.extend(b'\0'*((-len(binary))%4)); g['buffers'][0]['byteLength']=len(binary)
    js=json.dumps(g,separators=(',',':')).encode();js+=b' '*((-len(js))%4)
    Path(path).write_bytes(struct.pack('<III',0x46546c67,2,12+8+len(js)+8+len(binary))+struct.pack('<II',len(js),0x4e4f534a)+js+struct.pack('<II',len(binary),0x004e4942)+binary)
