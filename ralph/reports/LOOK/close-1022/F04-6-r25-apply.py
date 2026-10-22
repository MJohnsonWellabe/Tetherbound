import json,sys
R='/home/user/Tetherbound/'
aniso = '--aniso' in sys.argv
p=R+'data/config/trainer_aftermath.json'
d=json.load(open(p)); S=d['visual_candidate_sites']
S['relay_officer_dell']['pieces']=[x for x in S['relay_officer_dell']['pieces'] if x.get('model')!='toppled_tether_banner']
for pc in S['relay_officer_dell']['pieces']:
    if pc.get('model')=='tether_pylon': pc['after']={'finish':'pylon_dead','finish_tint':'#4a4f55'}
for s in ['captain_riverwatch','captain_field','captain_ridge']:
    S[s]['stand_down']={'offset':[14.0,0.0],'turn_deg':90.0}
def swap(site, piece):
    S[site]['pieces']=[x for x in S[site]['pieces'] if x.get('model')!='toppled_tether_banner']+[piece]
swap('captain_riverwatch',{'model':'riverwatch_toll_boom','dir':'res://assets/props/meshy-1022/riverwatch_toll_boom','offset':[3.4,0.6],'scale':3.16,'yaw_deg':-30.0,'sink_m':-0.89,'state':'after'})
swap('captain_ridge',{'model':'ridge_toppled_brazier','dir':'res://assets/props/meshy-1022/ridge_toppled_brazier','offset':[2.0,0.8],'scale':1.37,'yaw_deg':70.0,'sink_m':-0.73,'state':'after'})
open(p,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
q=R+'data/config/tether_relay.json'
t0=open(q).read()
t1=t0.replace('"inset_finish": "tether"','"inset_finish": "stone",\n      "hero": {"enabled": true, "scene": "res://assets/props/meshy-1022/relay_gatehouse_arch/relay_gatehouse_arch.glb"}')
assert t1!=t0
open(q,'w').write(t1); json.loads(t1)
t=R+'data/config/terrain_presentation.json'
d=json.load(open(t)); d['texture_candidates']['grass']['enabled']=True
open(t,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
if aniso:
    a=R+'data/config/art.json'; s=open(a).read()
    old='''      "shadow_quality": "Low",
      "draw_distance": "Near"
    },'''
    assert s.count(old)==1
    s=s.replace(old,'''      "shadow_quality": "Low",
      "draw_distance": "Near",
      "anisotropic_filtering_level": 4,
      "texture_mipmap_bias": -0.5
    },'''); open(a,'w').write(s); json.loads(s)
print('applied r25', 'aniso' if aniso else '')
