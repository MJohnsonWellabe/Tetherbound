import json, subprocess
from pathlib import Path
from PIL import Image, ImageDraw

root=Path(__file__).resolve().parent
repo=root.parents[4]
raw=subprocess.check_output(['git','-C',str(repo),'show','8181ab0802a9d961ef31738e3f58c430ce8dd09a:assets/buildings/quaternius_castle/WallEntranceBricks.obj']).decode()
verts=[]; faces=[]; material=''
for line in raw.splitlines():
    bits=line.split()
    if not bits: continue
    if bits[0]=='v': verts.append(list(map(float,bits[1:4])))
    if bits[0]=='usemtl': material=bits[1]
    if bits[0]=='f': faces.append(([int(s.split('/')[0])-1 for s in bits[1:]],material))
lo=[min(v[i] for v in verts) for i in range(3)]
hi=[max(v[i] for v in verts) for i in range(3)]
factor=4/(hi[1]-lo[1]); cx=(lo[0]+hi[0])/2; cz=(lo[2]+hi[2])/2
world=[[(v[0]-cx)*factor,(v[1]-lo[1])*factor,(v[2]-cz)*factor] for v in verts]
def proposal(p):
    x,y,z=p; t=max(0,min(1,(y-2.65)/1.35))
    return [x*(1+t*(4.6/((hi[0]-lo[0])*factor)-1)),y+t,z*(1+t*(1.9/((hi[2]-lo[2])*factor)-1))]
image=Image.new('RGB',(1200,680),'#101923'); d=ImageDraw.Draw(image)
d.text((30,22),'CROWN ARCH / SOURCE-DERIVED REFERENCE / NOT A NATIVE RENDER',fill='#ffffff')
d.text((30,45),'Baseline 8181ab08 / installed WallEntranceBricks. Preserve everything below Y=2.65 m.',fill='#c3ced5')
for index,(label,points,axis) in enumerate([('SHIPPING FRONT',world,0),('PROPOSED FRONT',[proposal(p) for p in world],0),('SHIPPING FLANK',world,2),('PROPOSED FLANK',[proposal(p) for p in world],2)]):
    ox=155+index*295; oy=550; scale=72
    d.text((ox-105,95),label,fill='#ffffff')
    for ids,mat in faces:
        xy=[(ox+points[i][axis]*scale,oy-points[i][1]*scale) for i in ids]
        d.polygon(xy,outline='#72d5e1' if mat=='DarkRock' else '#879b9f')
    d.line((ox-125,oy,ox+125,oy),fill='#8c9d88',width=2)
    y=oy-2.65*scale
    d.line((ox-125,y,ox+125,y),fill='#e1b777',width=1)
    d.text((ox-120,572),'amber = unchanged lower boundary',fill='#e1b777')
d.text((30,615),'Proposal: upper crown 5.0 m high, up to 4.6 m wide / 1.9 m deep; opening and travel axis unchanged.',fill='#ffffff')
d.text((30,638),'Paving: full 9 x 9 m support surface remains visible; staggered stone courses replace the single blank slab.',fill='#c3ced5')
image.save(root/'reference-draft.png')
