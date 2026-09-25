"""Draft a colour-blocked retexture style reference for bramblebun_redesign.
Source: the species' own saved front reference (assets/creatures/tetherbound/bramblebun_redesign/reference/front.png),
used as layout/shape guide only; every surface colour is replaced by a flat palette block with soft form shading.
"""
import colorsys, collections, sys
from PIL import Image, ImageFilter
SRC='/home/user/tetherbound/assets/creatures/tetherbound/bramblebun_redesign/reference/front.png'
OUT=sys.argv[1] if len(sys.argv)>1 else 'ref/bramblebun_style_ref_front.png'
N=512
src=Image.open(SRC).convert('RGB').resize((N,N),Image.LANCZOS)
sm=src.filter(ImageFilter.MedianFilter(5))
px=sm.load()
hsv=[[colorsys.rgb_to_hsv(*(c/255 for c in px[x,y])) for x in range(N)] for y in range(N)]
# background flood fill from border
bg=[[False]*N for _ in range(N)]
dq=collections.deque()
def isbg(x,y):
    h,s,v=hsv[y][x]; return v>0.80 and s<0.16
for i in range(N):
    for (x,y) in ((i,0),(i,N-1),(0,i),(N-1,i)):
        if isbg(x,y) and not bg[y][x]: bg[y][x]=True; dq.append((x,y))
while dq:
    x,y=dq.popleft()
    for dx,dy in ((1,0),(-1,0),(0,1),(0,-1)):
        a,b=x+dx,y+dy
        if 0<=a<N and 0<=b<N and not bg[b][a] and isbg(a,b):
            bg[b][a]=True; dq.append((a,b))
# spatial priors (coords in 512 space; source 1024 /2)
def in_ell(x,y,cx,cy,rx,ry): return ((x-cx)/rx)**2+((y-cy)/ry)**2<=1
def head(x,y): return in_ell(x,y,235,245,95,80)
def body(x,y): return in_ell(x,y,250,390,125,115) or (y>300 and 140<x<370)
def earzone(x,y):
    # left ear runs ~ (110,30)->(190,190); right ear ~ (410,30)->(300,190)
    def near(x,y,x0,y0,x1,y1,w):
        vx,vy=x1-x0,y1-y0; t=max(0,min(1,((x-x0)*vx+(y-y0)*vy)/(vx*vx+vy*vy)))
        px_,py_=x0+t*vx,y0+t*vy; return (x-px_)**2+(y-py_)**2<=w*w
    return near(x,y,115,30,190,185,36) or near(x,y,410,30,300,185,36)
def face_dark_zone(x,y): return in_ell(x,y,235,250,80,50)
PAL={
 'coat':(18,0.64,0.66),     # warm russet chestnut
 'cream':(38,0.12,0.95),    # chest, muzzle, paws
 'pink':(355,0.35,0.90),    # inner ear
 'antler':(30,0.58,0.42),   # warm bark-gold twig antlers
 'moss':(98,0.52,0.52),    # deep leaf-green mantle accents
 'dark':(15,0.40,0.13),
 'nose':(350,0.45,0.45),     # eyes, nose line
}
def modefilter(cls,r):
    out=[[None]*N for _ in range(N)]
    for y in range(N):
        for x in range(N):
            if cls[y][x] is None: continue
            cnt=collections.Counter()
            for b in range(max(0,y-r),min(N,y+r+1)):
                for a in range(max(0,x-r),min(N,x+r+1)):
                    if cls[b][a] is not None: cnt[cls[b][a]]+=1
            c=cnt.most_common(1)[0][0]
            out[y][x]='dark' if cls[y][x]=='dark' and cnt['dark']>=3 else c
    return out
def eyes(x,y): return in_ell(x,y,192,233,15,20) or in_ell(x,y,265,233,15,20)
def nose(x,y): return in_ell(x,y,220,258,10,6)
def muzzle(x,y): return in_ell(x,y,222,274,36,17) or in_ell(x,y,222,290,16,8)
def nosedot(x,y): return in_ell(x,y,221,263,8,5)
def chest(x,y): return in_ell(x,y,232,340,92,62)
LEAVES=[(150,315,20,11,-40),(160,345,18,10,-70),(172,292,16,9,-20),(318,318,20,11,40),(312,348,18,10,70),(300,292,16,9,20),(222,168,14,8,-30),(250,166,14,8,30)]
import math
def leaf(x,y):
    for cx,cy,a,b,ang in LEAVES:
        t=math.radians(ang); dx,dy=x-cx,y-cy
        u=dx*math.cos(t)+dy*math.sin(t); w=-dx*math.sin(t)+dy*math.cos(t)
        if (u/a)**2+(w/b)**2<=1: return True
    return False
cls=[[None]*N for _ in range(N)]
for y in range(N):
    for x in range(N):
        if bg[y][x]: continue
        h,s,v=hsv[y][x]; hd=h*360
        if nosedot(x,y): c='nose'
        elif eyes(x,y) and v<0.42: c='dark'
        elif muzzle(x,y): c='cream'
        elif in_ell(x,y,232,348,68,42): c='cream'
        elif chest(x,y) and s<0.40 and v>0.70: c='cream'
        elif y>=440 and s<0.40 and v>0.75: c='cream'
        elif (hd<=28 or hd>=330) and s>=0.28 and v>0.45 and earzone(x,y) and y<190: c='pink'
        elif earzone(x,y) or head(x,y) or body(x,y): c='coat'
        else: c='antler'
        cls[y][x]=c
cls=modefilter(cls,3)
for y in range(N):
    for x in range(N):
        c=cls[y][x]
        if c is None: continue
        if c=='coat' and leaf(x,y): cls[y][x]='moss'
        if c=='coat' and (in_ell(x,y,190,472,22,9) or in_ell(x,y,282,472,22,9)): cls[y][x]='cream'
# soft luminance for form shading
L=src.convert('L').filter(ImageFilter.GaussianBlur(7)).load()
sums=collections.defaultdict(float); cnts=collections.Counter()
for y in range(N):
    for x in range(N):
        c=cls[y][x]
        if c: sums[c]+=L[x,y]; cnts[c]+=1
mean={c:sums[c]/cnts[c] for c in cnts}
out=Image.new('RGB',(N,N),(238,238,236)); op=out.load()
for y in range(N):
    for x in range(N):
        c=cls[y][x]
        if not c: continue
        h,s,v=PAL[c]
        f=1.0 if c in ('dark','nose') else max(0.80,min(1.12,1.0+0.35*(L[x,y]-mean[c])/255*2))
        r,g,b=colorsys.hsv_to_rgb(h/360,s,min(1,v*f))
        op[x,y]=(int(r*255),int(g*255),int(b*255))
# eye highlights: brightest small spot near each eye centroid
for cx0 in (0,1):
    pts=[(x,y) for y in range(200,300) for x in (range(150,235) if cx0==0 else range(235,320)) if cls[y][x]=='dark']
    if pts:
        mx=sum(p[0] for p in pts)/len(pts); my=sum(p[1] for p in pts)/len(pts)
        for dy in range(-3,3):
            for dx in range(-3,3):
                if dx*dx+dy*dy<=5: op[int(mx-4+dx),int(my-5+dy)]=(250,250,250)
out=out.filter(ImageFilter.SMOOTH).resize((1024,1024),Image.LANCZOS)
out.save(OUT)
cc=Counter=collections.Counter(c for row in cls for c in row if c)
print(OUT, dict(cc))
