import json
R='/home/user/Tetherbound/'
exec(open(R+'ralph/reports/LOOK/close-1022/F04-6-r26-apply.py').read().split("t=R+'data/config/terrain_presentation.json'")[0])
t=R+'data/config/terrain_presentation.json'
d=json.load(open(t)); d['texture_candidates']['grass_v2']['enabled']=True; d['texture_candidates']['soil']['enabled']=True
open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
v=R+'data/config/vegetation_presentation.json'
d=json.load(open(v)); d['candidate']['enabled']=True
open(v,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
p=R+'data/config/trainer_aftermath.json'
d=json.load(open(p)); S=d['visual_candidate_sites']
for pc in S['captain_field']['pieces']:
    w=pc.get('smoke_wisp')
    if w and w.get('top_m')==5.0:
        w.update({'top_m':6.0,'alpha':0.5,'top_size_m':2.2,'base_size_m':0.5,'fade':0.85})
S['captain_ridge']['sigil_stone']=dict(S['captain_ridge'].get('sigil_stone',{}),model='rock_tallA',dir='res://assets/environment/nature',scale=2.0,sigil_height=1.3,sigil_out_m=0.7)
open(p,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
print('applied r28')
