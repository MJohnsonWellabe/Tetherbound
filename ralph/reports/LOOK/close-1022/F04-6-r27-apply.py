import json
exec(open('ralph/reports/LOOK/close-1022/F04-6-r26-apply.py').read().split("t=R+'data/config/terrain_presentation.json'")[0])
t=R+'data/config/terrain_presentation.json'
d=json.load(open(t))
d['texture_candidates']['grass_v2']['enabled']=True; d['texture_candidates']['soil']['enabled']=True
open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
print('applied r27')
