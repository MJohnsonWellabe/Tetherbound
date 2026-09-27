"""Minimal read-only glTF 2.0 skin evaluator for attack-contact diagnostics."""
import csv, hashlib, json, pathlib, struct
import numpy as np

DTYPES = {5120:'i1',5121:'u1',5122:'<i2',5123:'<u2',5125:'<u4',5126:'<f4'}
WIDTHS = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}

def matrix(t, q, s):
    x,y,z,w = q / np.linalg.norm(q)
    m=np.eye(4)
    m[:3,:3]=np.array([[1-2*(y*y+z*z),2*(x*y-z*w),2*(x*z+y*w)],
                      [2*(x*y+z*w),1-2*(x*x+z*z),2*(y*z-x*w)],
                      [2*(x*z-y*w),2*(y*z+x*w),1-2*(x*x+y*y)]]) * s
    m[:3,3]=t
    return m

def slerp(a,b,f):
    a=a/np.linalg.norm(a); b=b/np.linalg.norm(b); dot=float(a@b)
    if dot<0: b=-b; dot=-dot
    if dot>.9995:
        q=a+(b-a)*f; return q/np.linalg.norm(q)
    angle=np.arccos(np.clip(dot,-1,1))
    return (np.sin((1-f)*angle)*a+np.sin(f*angle)*b)/np.sin(angle)

class Model:
    def __init__(self,path):
        raw=path.read_bytes(); self.sha=hashlib.sha256(raw).hexdigest(); off=12
        while off<len(raw):
            length,kind=struct.unpack_from('<II',raw,off); chunk=raw[off+8:off+8+length]; off+=8+length
            if kind==0x4e4f534a:self.d=json.loads(chunk)
            elif kind==0x004e4942:self.bin=chunk
        self.nodes=self.d['nodes']; self.parent={c:i for i,n in enumerate(self.nodes) for c in n.get('children',[])}
        self.base=[{k:np.array(n.get(k,default),dtype=float) for k,default in [('translation',[0,0,0]),('rotation',[0,0,0,1]),('scale',[1,1,1])]} for n in self.nodes]
        assert not any('matrix' in n for n in self.nodes), 'matrix nodes need explicit handling'
        self.clips={a['name']:a for a in self.d['animations']}
        self.parts=[]
        for i,n in enumerate(self.nodes):
            if 'mesh' not in n:continue
            assert 'skin' in n
            skin=self.d['skins'][n['skin']]; joints=skin['joints']
            inv=self.acc(skin['inverseBindMatrices']).reshape(-1,4,4).transpose(0,2,1)
            for p in self.d['meshes'][n['mesh']]['primitives']:
                a=p['attributes']; pos=self.acc(a['POSITION']); w=self.acc(a['WEIGHTS_0']); j=self.acc(a['JOINTS_0']).astype(int)
                assert 'JOINTS_1' not in a and not p.get('targets')
                self.parts.append((pos,w,j,joints,inv))
        self.names=np.array([self.nodes[joints[x]]['name'] for pos,w,j,joints,inv in self.parts for x in j[np.arange(len(j)),w.argmax(axis=1)]])
        self.rest=self.pose(None,0)
        self.floor=float(self.rest[:,1].min()); self.height=float(np.ptp(self.rest[:,1]))
        self.group={name:np.where(np.char.startswith(self.names,prefix))[0] for name,prefix in [('head','head'),('neck','neck'),('front','front_'),('rear','rear_'),('tail','tail_'),('spine','spine'),('pelvis','pelvis')]}

    def acc(self,index):
        a=self.d['accessors'][index]; assert 'sparse' not in a
        v=self.d['bufferViews'][a['bufferView']]; dtype=np.dtype(DTYPES[a['componentType']]); width=WIDTHS[a['type']]
        ar=np.ndarray((a['count'],width),dtype=dtype,buffer=self.bin,offset=v.get('byteOffset',0)+a.get('byteOffset',0),strides=(v.get('byteStride',width*dtype.itemsize),dtype.itemsize)).copy()
        if a.get('normalized'):
            maxv=np.iinfo(dtype).max; ar=np.maximum(ar.astype(float)/maxv,-1)
        return ar

    def pose(self,clip,time,freeze=(),rot_scale=None):
        trs=[{k:v.copy() for k,v in n.items()} for n in self.base]
        if clip is not None:
            a=self.clips[clip]
            for c in a['channels']:
                i=c['target']['node']; prop=c['target']['path']
                if self.nodes[i]['name'] in freeze:continue
                s=a['samplers'][c['sampler']]; ts=self.acc(s['input'])[:,0]; vs=self.acc(s['output'])
                interp=s.get('interpolation','LINEAR'); assert interp in ['LINEAR','STEP']
                if time<=ts[0]:v=vs[0]
                elif time>=ts[-1]:v=vs[-1]
                else:
                    hi=np.searchsorted(ts,time);lo=hi-1;f=float((time-ts[lo])/(ts[hi]-ts[lo]))
                    v=vs[lo] if interp=='STEP' else slerp(vs[lo],vs[hi],f) if prop=='rotation' else vs[lo]*(1-f)+vs[hi]*f
                if prop=='rotation' and rot_scale and self.nodes[i]['name'] in rot_scale:
                    v=slerp(self.base[i]['rotation'],v,rot_scale[self.nodes[i]['name']])
                trs[i][prop]=v
        glob={}
        def global_m(i):
            if i not in glob:
                n=trs[i];m=matrix(n['translation'],n['rotation'],n['scale'])
                glob[i]=global_m(self.parent[i])@m if i in self.parent else m
            return glob[i]
        verts=[]
        for pos,w,j,joints,inv in self.parts:
            mats=np.array([global_m(i) for i in joints])@inv
            p4=np.column_stack((pos,np.ones(len(pos))))
            v=np.einsum('nvij,nj->nvi',mats[j],p4)
            verts.append(np.einsum('nvi,nv->ni',v,w)[:,:3])
        self.globals=glob
        return np.concatenate(verts)

    def stats(self,verts,fit):
        y=(verts[:,1]-self.floor)*fit;i=int(y.argmin())
        stats={'minimum_m':float(y[i]),'lowest_vertex':i,'lowest_dominant_bone':str(self.names[i]),'below_minus_1cm_vertices':int((y<-.01).sum())}
        for name,idx in self.group.items():
            if len(idx): stats[name+'_min_m']=float(y[idx].min())
        return stats
