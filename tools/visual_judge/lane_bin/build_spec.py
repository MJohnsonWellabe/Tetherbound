# build_spec.py <base_arm> <cand_arm> <rows_csv> <outdir> : per-row 2x2 sheets (640x360 tiles) + spec.json
import json,sys,glob,os
from PIL import Image
R='/home/user/Tetherbound/'; base,cand,rows,out=sys.argv[1:5]; rows=rows.split(',')
os.makedirs(out+'/sides',exist_ok=True)
d=json.load(open(R+'ralph/reports/VISUAL/item-scores/job.json'))
bs=d['biomes']; bs=bs.values() if isinstance(bs,dict) else bs
items={it['board_row']:it for bi in bs for it in (bi['items'] if isinstance(bi,dict) else bi)}
LAUNCH={}
def launch_of(arm,fid):
    if arm not in LAUNCH:
        LAUNCH[arm]={}
        try:
            for n,l in enumerate(open(f'{R}.artifacts/vl/{arm}/plan.jsonl'),1):
                for f in json.loads(l)['frames']: LAUNCH[arm].setdefault(f,str(n))
        except FileNotFoundError: pass
    return LAUNCH[arm].get(fid,'*')
def find(arm,fid):
    d=launch_of(arm,fid)
    names=[fid]
    if '__' in fid: names.append(fid.split('__',1)[1])           # meadows__exploration_hud -> exploration_hud
    if '__catching__' in fid: names.append(fid.split('__catching__',1)[1])
    if fid.count('__') >= 2: names.append(fid.split('__',2)[2])
    for n in names:
        h=glob.glob(f'{R}.artifacts/vl/{arm}/{d}/{n}.jpg')+glob.glob(f'{R}.artifacts/vl/{arm}/{d}/{n}.png')
        if h: return h[0]
    return None
def sheet(paths,dst):
    n=len(paths); W,H=(1280,720) if n==1 else (640,360); cols=2 if n>1 else 1; rws=(n+1)//2 if n>1 else 1
    im=Image.new('RGB',(W*cols,H*rws),(30,30,30))
    for i,p in enumerate(paths): im.paste(Image.open(p).convert('RGB').resize((W,H)),((i%cols)*W,(i//cols)*H))
    im.save(dst,quality=88)
spec=[];missing=[]
BIOME={'F38':'Meadows','F39':'Tidewake','F40':'Cloudreach','F41':'Stormwood','F13':'Tidewake','F22':'named fights'}
for r in rows:
    it=items[r]; fids=[f['id'] for f in it['frames']]
    pa=[(f,find(base,f),find(cand,f)) for f in fids]; ok=[(f,a,b) for f,a,b in pa if a and b]
    missing+= [f'{r}:{f}' for f,a,b in pa if not (a and b)]
    if not ok: continue
    sa=f"{out}/sides/{r.replace('#','_')}_a.jpg"; sb=f"{out}/sides/{r.replace('#','_')}_b.jpg"
    sheet([a for _,a,_ in ok],sa); sheet([b for _,_,b in ok],sb)
    spec.append({'label':r,'a':sa,'b':sb,'brief':f"{len(ok)} in-game frame{'s' if len(ok)>1 else ''} ({BIOME.get(r.split('#')[0],'')}) for one catalogue subject: {it['subject']}. Judge that subject as the game's real look - identity and read at a glance, silhouette, palette, lighting and fit with the key art and its chapter board.",'defects':[it['defect']]})
json.dump(spec,open(out+'/spec.json','w'),indent=1); print(len(spec),'sets; missing',missing)
