"""Author SOURCE models and byte-preservation checks; never executes GD/Godot."""
from pathlib import Path
import json,math,re,hashlib,gzip
P=Path(__file__).resolve().parent;W=P.parents[4];checks=[]
def check(name,condition):
 assert condition,name
 checks.append(name)
def sha(data):return hashlib.sha256(data).hexdigest()
def dist(a,b):return math.hypot(a[0]-b[0],a[1]-b[1])
def project(p,a,b):
 dx,dy=b[0]-a[0],b[1]-a[1];n=dx*dx+dy*dy
 t=max(0.,min(1.,((p[0]-a[0])*dx+(p[1]-a[1])*dy)/n))
 return [a[0]+t*dx,a[1]+t*dy]
def road_slice(road,start,goal):
 if len(road)<2 or len(road)>64 or not all(math.isfinite(v) for p in road+[start,goal] for v in p):return []
 lengths=[0.];first=last=None;best_first=best_last=math.inf;first_arc=last_arc=0.
 for i,(a,b) in enumerate(zip(road,road[1:])):
  length=dist(a,b)
  if length<=1e-5 or length>180:return []
  f,l=project(start,a,b),project(goal,a,b)
  if dist(start,f)**2<best_first:best_first=dist(start,f)**2;first=f;first_arc=lengths[i]+dist(a,f)
  if dist(goal,l)**2<best_last:best_last=dist(goal,l)**2;last=l;last_arc=lengths[i]+dist(a,l)
  lengths.append(lengths[-1]+length)
 if dist(start,first)>180 or dist(goal,last)>180:return []
 result=[first];ids=range(len(road)) if last_arc>=first_arc else range(len(road)-1,-1,-1)
 for i in ids:
  if min(first_arc,last_arc)+1e-5<lengths[i]<max(first_arc,last_arc)-1e-5:result.append(road[i])
 if dist(result[-1],last)>1e-5:result.append(last)
 return result
def reach(walk,sprint,scale,momentum,ceiling,delta):
 if not all(math.isfinite(v) for v in [walk,sprint,scale,momentum,ceiling,delta]) or walk<=0 or sprint<walk or scale<=0 or momentum<0 or ceiling<=0 or delta<=0:return math.nan
 speed=max(max(walk,sprint)*scale,momentum)
 return min(speed,ceiling)*delta if math.isfinite(speed) else math.nan
def bodies(source):
 starts=list(re.finditer(r'^(?:static )?func (\w+)\(',source,re.M));result={}
 for i,m in enumerate(starts):
  end=starts[i+1].start() if i+1<len(starts) else len(source)
  lines=source[m.start():end].splitlines()
  while lines and (not lines[-1].startswith('\t') or lines[-1].lstrip().startswith('#')):lines.pop()
  result[m.group(1)]='\n'.join(lines)
 return result
paths=['tests/helpers/opening_geometry_navigator.gd','tests/helpers/gate_a_npc_gather_segment.gd','tests/test_gate_a_npc_gather_segment_contract.gd']
old={n:(P/'originals'/n).read_text() for n in paths};new={n:(P/'proposal'/n).read_text() for n in paths}
allowed={paths[0]:{'reset','walk_to','_production_heading','_choose_route'},paths[1]:{'_enter_through','_walk_toward','_prove_movement_resumed'}}
for n in paths:
 check('working matches frozen proposal '+n,(W/n).read_bytes()==(P/'proposal'/n).read_bytes())
 if n in allowed:
  before,after=bodies(old[n]),bodies(new[n])
  for name,body in before.items():
   if name not in allowed[n]:check('byte-preserved function '+name,after[name]==body)
check('all original nine regression cases byte-preserved',(P/'proposal'/paths[2]).read_bytes().startswith((P/'originals'/paths[2]).read_bytes()))
check('four meaningful added cases',len(re.findall(r'^func test_',new[paths[2]],re.M))==len(re.findall(r'^func test_',old[paths[2]],re.M))+4)
nav=new[paths[0]];segment=new[paths[1]]
constants=['CONTACTS','CONTACT_EPS','MAX_QUERIES_FRAME','MAX_QUERIES_LIFETIME','MAX_REQUESTS','FRAME_QUERY_US','MAX_CHOICES','MAX_PLANS','MAX_EDGE','THRESHOLD_RADIUS']
for name in constants:
 def line(source):return re.search(r'^const '+name+r'\s*:?=.*$',source,re.M).group()
 check('original constant '+name,line(nav)==line(old[paths[0]]))
for text in ['if _stalled > 90:','_retry_at += STALL_FRAMES','_deadline = began + maxi(0, FRAME_QUERY_US - _pre_observe_us)']:
 check('original stall/retry/combined cap '+text,text in nav and text in old[paths[0]])
check('same number of native motion calls',nav.count('_motion(')==old[paths[0]].count('_motion('))
check('no new collision query API',all(nav.count(token)==old[paths[0]].count(token) for token in ['body_test_motion(','intersect_shape(','cast_motion(','intersect_ray(','collide_shape(','get_rest_info(']))
check('no pose writes added',len(re.findall(r'(?:global_position|global_transform|position|transform)\s*=',nav))==len(re.findall(r'(?:global_position|global_transform|position|transform)\s*=',old[paths[0]])))
resume=bodies(segment)['_prove_movement_resumed'];old_resume=bodies(old[paths[1]])['_prove_movement_resumed']
for text in ['for _i in 120:','for _i in 22:','for _i in 4:',').length() >= 0.3:']:
 check('original resume budget/threshold '+text,text in resume and text in old_resume)
check('resume uses guarded real input requests','_nav.push_once(requested)' in resume and '_nav.push_once(Vector3.ZERO)' in resume)
check('resume has no unobserved raw axis calls','_send_axis(' not in resume)
check('resume failures remain terminal',resume.count('_nav.refused()')==2 and resume.count('return false')==old_resume.count('return false')+2)
enter=bodies(segment)['_enter_through']
check('original standoff target900frames1m','door.global_position + outward * DOOR_STANDOFF, 900, 1.0, "", false, hints' in enter)
for text in ['_walk_to_and_activate(prompt, 1200)','for _i in 45:','_walk_toward(step, 600, 0.7)']:
 check('original door budget '+text,text in enter and text in bodies(old[paths[1]])['_enter_through'])
check('provisional path bounded by original8choices','provisional_path.size() > MAX_CHOICES' in nav)
check('metadata hint applies only to current Mira','get_meta("village_role", "")) == "mira_shop"' in enter)
check('native heading uses configured speeds and cached momentum',all(t in bodies(nav)['_production_heading'] for t in ['get("_walk_speed")','get("_sprint_speed")','vitals.call("move_speed_scale")','_body.velocity.x','_body.velocity.z']))
check('120 ceiling remains actual movement validation','var speed_cap: float = float(_body.get("_max_speed"))' in bodies(nav)['_production_observe'])
check('live relief distinct from prospective tangent','wall_heading(along, opposing, _production_hint_source == &"live_pre")' in nav)
movement=json.loads((W/'data/config/movement.json').read_bytes())['locomotion']
ordinary=reach(movement['walk_speed'],movement['sprint_speed'],1,5,movement['max_speed'],1/60)
check('actual ordinary preview143mm not2m',abs(ordinary-8.6/60)<1e-12 and ordinary<.15)
check('actual cached momentum retained',abs(reach(5,8.6,1,12,120,1/60)-.2)<1e-12)
check('actual scale retained',abs(reach(5,8.6,.8,0,120,1/60)-6.88/60)<1e-12)
for args in [(5,8.6,math.inf,0,120,1/60),(5,8.6,1,-1,120,1/60),(5,4,1,0,120,1/60),(5,8.6,1,0,120,0)]:check('invalid preview refused '+str(args),math.isnan(reach(*args)))
observations=json.loads((P/'ci6172/failed-observations.json').read_bytes())
cap_case=next(i['observation'] for i in observations if i['observation']['refusal']=='actual production contact observation cap')
opposing=cap_case['provisional_steering']['wall_normal']
east=next(c['normal'] for c in cap_case['live_contacts'] if c['normal'][0]<-.9)
along=[-opposing[2],0,opposing[0]]
old_heading=cap_case['provisional_steering']['heading']
check('actual prospective bias points into actual east wall',sum(a*b for a,b in zip(old_heading,east))<-.24)
check('source prospective tangent avoids opposite-wall shove',sum(a*b for a,b in zip(along,east))==0 and math.isclose(math.hypot(*[along[0],along[2]]),1))
check('live original relief retained',.25/math.sqrt(1+.25**2)>.24)
terrain=json.loads((W/'data/config/terrain_playground.json').read_bytes())
road=next(r['points'] for r in terrain['paths']['routes'] if r.get('label')=='Practice Meadow')
check('painted road exact original bends',road==[[20,14],[20,-12],[20,-18],[20,-26],[14.6,-31],[21,-37.5],[30,-40]])
village=json.loads((W/'data/config/village.json').read_bytes());prefabs=json.loads((W/'data/config/building_prefabs.json').read_bytes())['prefabs']
shop=next(s for s in village['structures'] if s.get('id')=='mira_shop');step=next(s for s in village['structures'] if s.get('id')=='mira_shop_threshold')
check('Mira and threshold actual current metadata',shop['at']==[26,2] and shop['yaw_deg']==0 and step['at']==[27,7.9] and step['yaw_deg']==0)
check('Village metadata bound29of64',len(village['structures'])==29)
check('actual doorstep full4x.1x2',prefabs['doorstep']['colliders'][0]['size']==[4,.1,2])
check('actual installed door remains1x0x3',prefabs['cottage_a']['door']['at']==[1,0,3])
check('same recipe wall returns and lintel',len(prefabs['cottage_a']['colliders'])==7)
check('forward slice order',road_slice([[0,0],[4,0],[8,0],[10,0]],[1,1],[9,1])==[[1,0],[4,0],[8,0],[9,0]])
check('reverse slice order',road_slice([[0,0],[4,0],[8,0],[10,0]],[9,1],[1,1])==[[9,0],[8,0],[4,0],[1,0]])
for rr,a,b in [([[0,0],[math.inf,0]],[0,0],[1,1]),(road,[math.inf,0],[0,0]),(road,[1000,1000],[0,0])]:check('malformed/distant slice refused '+str(a),not road_slice(rr,a,b))
starts=json.loads((P/'ci6172/first-observations.json').read_bytes())
models=[]
def model(start,path):
 at=list(start);v=[0.,0.];index=0;rows=[];dt=1/60;goal=[27,7.6]
 for frame in range(1,901):
  if dist(at,goal)<=1:break
  while index<len(path) and dist(at,path[index])<=.25:index+=1
  aim=path[index] if index<len(path) else goal
  length=dist(at,aim);wanted=[(aim[i]-at[i])/length*5 for i in range(2)]
  change=dist(v,wanted);fraction=min(1,42*dt/change) if change else 0
  v=[v[i]+(wanted[i]-v[i])*fraction for i in range(2)];at=[at[i]+v[i]*dt for i in range(2)]
  rows.append([frame,*at])
 arrived=dist(at,goal)<=1
 # Original5 neutral settle frames. Friction is38, with no pose write.
 for frame in range(5):
  speed=math.hypot(*v);factor=max(0,1-38*dt/speed) if speed else 0
  v=[x*factor for x in v];at=[at[i]+v[i]*dt for i in range(2)];rows.append([len(rows)+1,*at])
 return {'kind':'ideal planar SOURCE model, no terrain/contact/floor/activation proof','frames_walk':len(rows)-5,
  'original900_budget_reached':arrived,'after_original5_settle_xz':at,'rows':rows}
for item in starts:
 xyz=item['observation']['player'];start=[xyz[0],xyz[2]]
 path=road_slice(road,start,[20,6.3])+[[27,6.65]]
 check('bounded source route job'+str(item['job']),len(path)<=8 and dist(path[-2],[20,6.3])<1e-10)
 check('source bend return job'+str(item['job']),[14.6,-31] in path)
 length=dist(start,path[0])+sum(dist(a,b) for a,b in zip(path,path[1:]))
 m=model(start,path);m.update({'job':item['job'],'source_start_xz':start,'path_xz':path,'source_planar_length':length})
 check('ideal route inside original900 job'+str(item['job']),m['original900_budget_reached'] and m['frames_walk']<=900)
 # FULL and CONT also have initial records on identical declared routes;
 # every model remains source-only, including successes from those records.
 check('ideal settled lip side job'+str(item['job']),m['after_original5_settle_xz'][1]<6.69)
 models.append(m)
expanded=.4000000059604645+.0010000000474974513
lip_clearance=math.hypot(.35,.25-.04)-expanded
check('full upright capsule clears low box with40mm Zreserve',lip_clearance>.007)
check('source endpoint inside original1m standoff',dist([27,6.65],[27,7.6])<1)
check('same original900 budget not raised',all(m['frames_walk']<=900 for m in models))
for name,meta in json.loads((P/'ci6172/raw-provenance.json').read_bytes()).items():
 raw=gzip.decompress((P/'ci6172'/ (name+'.gz')).read_bytes());check('byte-exact raw CI '+name,len(raw)==meta['bytes'] and sha(raw)==meta['sha256'])
failed=json.loads((P/'ci6172/failed-observations.json').read_bytes())
check('all four latest original route failures retained',len(failed)==4)
check('actual Mira contact count10of8 retained',any(i['observation']['slide_point_counts']==[2,4,4] for i in failed))
check('actual missing grounded state retained',any(not i['observation']['on_floor'] for i in failed))
check('actual Bram PRE raw vector retained',any(i['job']==110511919635 and i['observation']['live_state_phase']=='pre' for i in failed))
for tag,rawname,expected in [('unit','unit-tests.log.gz','9db2bf37cca08e4e498d331755334d33544ec1ccb3176492885c5c2090f67523'),('tree','tree-smoke.log.gz','16fcbd180067148e87c60a9aeaecbcf77eb8eb2a42b1f93b914f030e4273c0f1')]:
 check('actual earned tree '+tag+' raw preserved',sha(gzip.decompress((P/'tree-passed'/rawname).read_bytes()))==expected)
 check('actual earned tree '+tag+' exit0',json.loads((P/'tree-passed'/ (tag+'-result.json')).read_bytes())['exit']==0)
for name,expected in json.loads((P/'unchanged-paths.json').read_bytes()).items():check('unchanged '+name,sha((W/name).read_bytes())==expected)
report={'scope':'AUTHOR SOURCE ONLY; all new GD/native opening work UNRUN; F17#4 OPEN; R9 HOLD','checks':len(checks),'passed':checks,
 'ordinary_preview_reach':ordinary,'old_safety_ceiling_preview':120/60,'full_capsule_lip_clearance_with40mm_Ztracking':lip_clearance,
 'models':models,'actual_native':'Retained CI6170 PREBox+POSTTerrain and CI6172 Bram PRE /Mira contact-cap /CORE lost-floor+camp-overlap failures. Tree original native PASS separately, never opening acceptance.'}
(P/'source-results.json').write_bytes((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({k:v for k,v in report.items() if k not in ['passed','models']},indent=2))
print('ideal SOURCE models',[(m['job'],m['frames_walk'],m['source_planar_length'],m['after_original5_settle_xz']) for m in models])
