import json,sys,re
R='/home/user/Tetherbound/'
p=R+'data/config/trainer_aftermath.json'
d=json.load(open(p))
S=d['visual_candidate_sites']
def drop_banner(site):
    S[site]['pieces']=[x for x in S[site]['pieces'] if x.get('model')!='toppled_tether_banner']
for s in ['relay_officer_dell','captain_riverwatch','captain_ridge']:
    drop_banner(s)
for pc in S['relay_officer_dell']['pieces']:
    if pc.get('model')=='tether_pylon':
        pc['after']={'finish':'pylon_dead','finish_tint':'#4a4f55'}
for s in ['captain_riverwatch','captain_field','captain_ridge']:
    S[s]['stand_down']={'offset':[14.0,0.0],'turn_deg':90.0}
S['captain_field']['pieces']=[x for x in S['captain_field']['pieces'] if not (x.get('smoke_wisp',{}).get('top_m')==5.0)]
S['captain_field']['sigil_stone']=dict(S['captain_field'].get('sigil_stone',{}),sigil_height=1.35,scale=0.95)
S['_r23']='F04#6 r23 candidate: one beat per site; no repeated fallen banner (Dell, Riverwatch, Ridge); the spent Dell pylon tinted dark; beaten captains step 14 m aside off the road; Field drops the tall billboard smoke and lifts its sigil off the ground.'
open(p,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
q=R+'data/config/tether_relay.json'
t=open(q).read().replace('"inset_finish": "tether"','"inset_finish": "stone"')
open(q,'w').write(t)
print('applied r23')
