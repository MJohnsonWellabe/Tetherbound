import json
R='/home/user/Tetherbound/'
p=R+'data/config/trainer_aftermath.json'
d=json.load(open(p)); S=d['visual_candidate_sites']
S['relay_officer_dell']['pieces']=[x for x in S['relay_officer_dell']['pieces'] if x.get('model')!='toppled_tether_banner']
for pc in S['relay_officer_dell']['pieces']:
    if pc.get('model')=='tether_pylon': pc['after']={'finish':'pylon_dead','finish_tint':'#4a4f55'}
for s in ['captain_riverwatch','captain_field','captain_ridge']:
    S[s]['stand_down']={'offset':[14.0,0.0],'turn_deg':90.0}
open(p,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
q=R+'data/config/tether_relay.json'
t0=open(q).read()
open(q,'w').write(t0.replace('"inset_finish": "tether"','"inset_finish": "stone"'))
t=R+'data/config/terrain_playground.json'
d=json.load(open(t)); d['textures'][0]['candidate']['enabled']=True
open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
print('applied r24')
