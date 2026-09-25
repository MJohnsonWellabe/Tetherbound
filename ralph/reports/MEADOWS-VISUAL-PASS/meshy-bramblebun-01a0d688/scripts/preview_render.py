"""Texture-validation preview only (NOT an approval render): software rasterizer drawing the SHIPPED
bramblebun_redesign mesh with its own UVs, textured by (a) the shipped vivid albedo and (b) the Meshy candidate albedo."""
import sys, math, struct, json
from PIL import Image
sys.path.insert(0,'.')
from uvcheck import load, acc
A,ab=load('/home/user/tetherbound/assets/creatures/tetherbound/bramblebun_redesign/models/creature_bramblebun_redesign_lod0.glb')
p=A['meshes'][0]['primitives'][0]
V=acc(A,ab,p['attributes']['POSITION']); UV=acc(A,ab,p['attributes']['TEXCOORD_0']); I=[i[0] for i in acc(A,ab,p['indices'])]
tris=[(I[k],I[k+1],I[k+2]) for k in range(0,len(I),3)]
def render(texpath, yaw_deg, S=420, flipv=False):
    tex=Image.open(texpath).convert('RGB'); TW,TH=tex.size; tp=tex.load()
    c,s=math.cos(math.radians(yaw_deg)),math.sin(math.radians(yaw_deg))
    P=[(x*c+z*s, y, -x*s+z*c) for x,y,z in V]   # rotate about Y; camera looks down -Z from +Z
    scale=S/2.0/1.05; cy=0.86
    scr=[(S/2+px*scale, S/2-(py-cy)*scale, pz) for px,py,pz in P]
    zb=[-1e9]*(S*S); img=Image.new('RGB',(S,S),(46,50,56)); ip=img.load()
    L=(0.35,0.6,0.72); ln=math.sqrt(sum(q*q for q in L)); L=tuple(q/ln for q in L)
    for a,b,d in tris:
        (x0,y0,z0),(x1,y1,z1),(x2,y2,z2)=scr[a],scr[b],scr[d]
        area=(x1-x0)*(y2-y0)-(x2-x0)*(y1-y0)
        if abs(area)<1e-9: continue
        # face normal in rotated space for lambert (double-sided)
        A3,B3,C3=P[a],P[b],P[d]
        ux,uy,uz=B3[0]-A3[0],B3[1]-A3[1],B3[2]-A3[2]; vx,vy,vz=C3[0]-A3[0],C3[1]-A3[1],C3[2]-A3[2]
        nx,ny,nz=uy*vz-uz*vy,uz*vx-ux*vz,ux*vy-uy*vx; nl=math.sqrt(nx*nx+ny*ny+nz*nz) or 1
        if nz<0: nx,ny,nz=-nx,-ny,-nz
        sh=0.45+0.6*max(0,(nx*L[0]+ny*L[1]+nz*L[2])/nl)
        minx=max(0,int(min(x0,x1,x2))); maxx=min(S-1,int(max(x0,x1,x2))+1)
        miny=max(0,int(min(y0,y1,y2))); maxy=min(S-1,int(max(y0,y1,y2))+1)
        ua,ub,ud=UV[a],UV[b],UV[d]
        for py in range(miny,maxy+1):
            for px in range(minx,maxx+1):
                fx,fy=px+0.5,py+0.5
                w0=((x1-fx)*(y2-fy)-(x2-fx)*(y1-fy))/area
                w1=((x2-fx)*(y0-fy)-(x0-fx)*(y2-fy))/area
                w2=1-w0-w1
                if w0<0 or w1<0 or w2<0: continue
                z=w0*z0+w1*z1+w2*z2; k=py*S+px
                if z<=zb[k]: continue
                zb[k]=z
                u=w0*ua[0]+w1*ub[0]+w2*ud[0]; v=w0*ua[1]+w1*ub[1]+w2*ud[1]
                r,g,bb=tp[min(TW-1,max(0,int(u*TW))),min(TH-1,max(0,int(v*TH)))]
                ip[px,py]=(min(255,int(r*sh)),min(255,int(g*sh)),min(255,int(bb*sh)))
    return img
if __name__=='__main__':
    tex,yaw,out=sys.argv[1],float(sys.argv[2]),sys.argv[3]
    render(tex,yaw).save(out)
