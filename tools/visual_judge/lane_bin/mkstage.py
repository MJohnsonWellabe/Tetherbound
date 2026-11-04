# mkstage.py <batch> <label> <species> <base_dir> <cand_dir> <defect> [roles: hit,faint] -> appends one stage set to <batch>/k/spec.json
import json,sys,os
from PIL import Image
b,label,sp,bd,cd,defect=sys.argv[1:7]
J=f'/tmp/claude-0/work/judge/{b}/k'; os.makedirs(J+'/sides',exist_ok=True)
frames=['hit-050','hit-100','faint-050','faint-100']
def sheet(d,dst):
    ims=[Image.open(f'{d}/{sp}-{f}.png').convert('RGB') for f in frames]
    W,H=ims[0].size; im=Image.new('RGB',(W*2,H*2))
    for i,x in enumerate(ims): im.paste(x,((i%2)*W,(i//2)*H))
    im.save(dst,quality=88)
a=f'{J}/sides/{sp}_a.jpg'; bb=f'{J}/sides/{sp}_b.jpg'; sheet(bd,a); sheet(cd,bb)
p=J+'/spec.json'; spec=json.load(open(p)) if os.path.exists(p) else []
spec.append({'label':label,'a':a,'b':bb,'brief':"One creature on a neutral stage beside a 1.80 m human ruler: hit react mid, hit react end, faint mid, faint end. Judge the creature's model, material and poses as the game's real look - identity, silhouette, surface and elemental finish, hurt and faint read without a label and stay grounded, scale against the ruler.",'defects':[defect]})
json.dump(spec,open(p,'w'),indent=1); print(len(spec),'stage sets')
