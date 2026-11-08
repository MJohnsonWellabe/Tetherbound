import json, math
import numpy as np
d=json.load(open('.artifacts/warrens/feas.json'))
T=np.array(d['terrain']); B=np.array(d['bank'])          # rows iz (-40..100), cols ix (-70..70), step 2 m, local
xs=np.arange(-70,71)*2.0; zs=np.arange(-40,101)*2.0
X,Z=np.meshgrid(xs,zs)
ox,oy,oz=d['origin']; th=math.radians(d['yaw_deg']); c,s=math.cos(th),math.sin(th)
def to_local(wx,wz):
    dx,dz=wx-ox,wz-oz
    return dx*c - dz*s, dx*s + dz*c
clear=d['clearance']
surf=T+B  # current bank surface (local y)
req=np.full(T.shape,-1e9)
print('floor_y(world)',d['floor_y'],'origin_y',oy,'mouth_outer_z',d['mouth_outer_z'])
for b in d['bumps']:
    m=(np.abs(X-b['cx'])<=b['hx'])&(np.abs(Z-b['cz'])<=b['hz'])
    need=b['top']+clear
    print(b['id'],'box x %.1f±%.1f z %.1f±%.1f top %.2f need %.2f  current bank min over box %.2f'%(b['cx'],b['hx'],b['cz'],b['hz'],b['top'],need,surf[m].min()))
    req[m]=np.maximum(req[m],need)
ring={'burrowback cluster (-372,2605) r10':(-372,2605,10),'cluster 2049 (-427,2590) r14':(-427,2590,14),'cluster (-316,2650)':(-316,2650,0),
'pickup mushroom (-374,2592)':(-374,2592,0),'pickup candy (-350,2654)':(-350,2654,0),'harvest (-342.2,2645)':(-342.2,2645,0),'prop (-351,2611.8)':(-351,2611.8,0)}
ri=np.argwhere(req>-1e8)
for slope_deg in (35,40):
    k=math.tan(math.radians(slope_deg))
    H=np.full(T.shape,-1e9)
    for (i,j) in ri:
        dist=np.hypot(X-X[i,j],Z-Z[i,j])
        H=np.maximum(H,req[i,j]-k*dist)
    cover=H-T   # >0 means mound above ground
    foot=cover>0.05
    print('\n== slope %d deg: footprint %.0f m2 (current bank footprint %.0f m2)'%(slope_deg,foot.sum()*4,(B>0.05).sum()*4))
    for name,(wx,wz,r) in ring.items():
        lx,lz=to_local(wx,wz)
        ii=int(round(lz/2))+40; jj=int(round(lx/2))+70
        if not(0<=ii<T.shape[0] and 0<=jj<T.shape[1]): print(name,'outside grid'); continue
        dist_edge=np.min(np.hypot(X[foot]-lx,Z[foot]-lz)) if foot.any() else 1e9
        inside=foot[ii,jj]
        print('  %-36s local (%6.1f,%6.1f) mound-ground %+6.2f m  %s  dist to footprint edge %.1f m%s'%(name,lx,lz,cover[ii,jj],'COVERED' if inside else 'clear  ',dist_edge,'  (cluster r %d)'%r if r else ''))
    np.save('.artifacts/warrens/foot_%d.npy'%slope_deg,foot)
np.save('.artifacts/warrens/curfoot.npy',B>0.05)

print('\n######## corrected: requirement = live Bank plateau cells (surface >= need), mouth excluded')
req2=np.full(T.shape,-1e9)
for b in d['bumps']:
    if b['id']=='mouth': continue
    need=b['top']+clear
    m=(np.abs(X-b['cx'])<=b['hx'])&(np.abs(Z-b['cz'])<=b['hz'])&(surf>=need)
    req2[m]=np.maximum(req2[m],need)
ri=np.argwhere(req2>-1e8)
print('required cells',len(ri))
results={}
for slope_deg in (35,40,45):
    k=math.tan(math.radians(slope_deg))
    H=np.full(T.shape,-1e9)
    for (i,j) in ri:
        H=np.maximum(H,req2[i,j]-k*np.hypot(X-X[i,j],Z-Z[i,j]))
    cover=H-T; foot=cover>0.05
    print('\n== slope %d deg: footprint %.0f m2'%(slope_deg,foot.sum()*4))
    for name,(wx,wz,r) in ring.items():
        lx,lz=to_local(wx,wz); ii=int(round(lz/2))+40; jj=int(round(lx/2))+70
        cv=cover[ii,jj]
        if cv>0.05:
            msg='COVERED by %.1f m -> horizontal shortfall ~%.1f m'%(cv,cv/k)
        else:
            free=~foot
            dd=np.min(np.hypot(X[foot]-lx,Z[foot]-lz))
            msg='clear, margin %.1f m to footprint edge'%dd
        print('  %-36s local (%6.1f,%6.1f) %s%s'%(name,lx,lz,msg,' (cluster r %d)'%r if r else ''))
    results[slope_deg]=foot
np.save('.artifacts/warrens/foot2_40.npy',results[40])
# plot 40 deg
from PIL import Image, ImageDraw
sc=3; Wd=T.shape[1]*sc; Hd=T.shape[0]*sc
img=Image.new('RGB',(Wd,Hd),(235,240,230)); dr=ImageDraw.Draw(img)
cur=B>0.05
for (ii,jj),v in np.ndenumerate(results[40]):
    col=None
    if v and cur[ii,jj]: col=(120,90,60)
    elif v: col=(200,150,90)
    elif cur[ii,jj]: col=(90,90,140)
    if col: dr.rectangle([jj*sc,(T.shape[0]-1-ii)*sc,jj*sc+sc-1,(T.shape[0]-1-ii)*sc+sc-1],fill=col)
for (i,j) in ri:
    dr.point((j*sc+1,(T.shape[0]-1-i)*sc+1),fill=(30,30,30))
for name,(wx,wz,r) in ring.items():
    lx,lz=to_local(wx,wz); px=(lx/2+70)*sc; py=(T.shape[0]-1-(lz/2+40))*sc
    rr=max(4,r/2*sc)
    dr.ellipse([px-rr,py-rr,px+rr,py+rr],outline=(200,0,0),width=2); dr.text((px+6,py-6),name.split(' (')[0],fill=(150,0,0))
mz=(T.shape[0]-1-(0/2+40))*sc; dr.line([(70*sc-20,mz),(70*sc+20,mz)],fill=(0,0,0),width=2); dr.text((70*sc+24,mz-6),'mouth (local z=0)',fill=(0,0,0))
dr.text((6,6),'Warrens v2 feasibility, 40 deg mound (local frame, 2 m cells). brown=mound∩current Bank, tan=mound only, blue=current Bank only, dots=required cover, red=exterior ring',fill=(0,0,0))
img.save('.artifacts/warrens/feas_40.png')
