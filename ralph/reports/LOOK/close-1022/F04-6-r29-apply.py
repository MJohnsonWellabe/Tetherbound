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
        w.update({'top_m':6.0,'alpha':0.65,'top_size_m':2.6,'base_size_m':0.6,'fade':0.8})
open(p,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
m=R+'data/config/meadows_look.json'
d=json.load(open(m))
d['environment'].update({'fog_colour':'#9cb7d3','fog_density':0.001,'adjustment_contrast':1.1,'adjustment_saturation':1.08})
d['sun']={'energy':1.5,'colour':'#ffe8c4','pitch_deg':-38.0}
open(m,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
print('applied r29')
