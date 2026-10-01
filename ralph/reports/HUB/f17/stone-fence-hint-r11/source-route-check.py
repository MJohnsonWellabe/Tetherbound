"""R11 author source/closed-fence audit only. No Godot/native acceptance."""
from pathlib import Path
import hashlib,json,math,re
P=Path(__file__).resolve().parent
ROOT=P.parents[4]
H=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
def check(name,ok,detail=None):checks.append({'name':name,'passed':bool(ok),'detail':detail})
def read(n):return (P/n).read_text(encoding='utf-8').replace('\r\n','\n')
def functions(source):
    lines = source.splitlines()
    result = {}
    for i, line in enumerate(lines):
        match = re.match(r'(?:static )?func (\w+)\(', line)
        if not match:
            continue
        j = i + 1
        while j < len(lines) and (not lines[j] or lines[j].startswith('\t')):
            j += 1
        result[match[1]] = '\n'.join(lines[i:j]).rstrip()
    return result

def sub(a,b): return (a[0]-b[0], a[1]-b[1])

def dot(a,b): return a[0]*b[0]+a[1]*b[1]

def cross(a,b): return a[0]*b[1]-a[1]*b[0]

def point_segment(p,a,b):
    ab=sub(b,a); t=max(0,min(1,dot(sub(p,a),ab)/dot(ab,ab)))
    return math.dist(p,(a[0]+t*ab[0],a[1]+t*ab[1]))

def intersects(a,b,c,d):
    ab=sub(b,a); cd=sub(d,c); denom=cross(ab,cd)
    if abs(denom)<1e-10: return False
    t=cross(sub(c,a),cd)/denom; u=cross(sub(c,a),ab)/denom
    return 0<=t<=1 and 0<=u<=1

def segment_distance(a,b,c,d):
    return 0 if intersects(a,b,c,d) else min(point_segment(a,c,d),point_segment(b,c,d),point_segment(c,a,b),point_segment(d,a,b))

def contains(poly,p):
    inside=False
    for a,b in zip(poly,poly[1:]+poly[:1]):
        if (a[1]>p[1]) != (b[1]>p[1]) and p[0] < (b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]: inside=not inside
    return inside

def path_clearance(path, poly):
    if any(contains(poly,p) for p in path): return 0
    return min(segment_distance(a,b,c,d) for a,b in zip(path,path[1:]) for c,d in zip(poly,poly[1:]+poly[:1]))

m=json.loads(read('manifest.json'))
for n,e in m['files'].items():
 b=(P/n).read_bytes();check('frozen '+n,len(b)==e['bytes'] and H(b)==e['sha256'])
for n,pin in m['unchanged_hub_sha256'].items():check('unchanged live '+n,H((ROOT/n).read_bytes())==pin)
g,t=m['changed_paths'];old,new=read('originals/'+g),read('proposal/'+g);of,nf=functions(old),functions(new)
for n in m['changed_paths']:
 check('ROOT executed original '+n,(P/'originals'/n).read_bytes()==(P/'root-actual'/n).read_bytes())
 check('live proposal '+n,(P/'proposal'/n).read_bytes()==(ROOT/n).read_bytes())
check('only gather function changed',[k for k in of if of[k]!=nf.get(k)]==['_gather_authored_node'])
check('one pure bounded hint added',set(nf)-set(of)=={'stone_road_hint'})
for k in of:
 if k!='_gather_authored_node':check('unchanged earned function '+k,of[k]==nf[k])
code=lambda s:'\n'.join(x for x in s.splitlines() if x.strip() and not x.lstrip().startswith('#'))
func=nf['_gather_authored_node'];a=func.index('\tif item_id == "stone":');z=func.index('\tif not await _walk_toward(',a)
check('entire gathering actions/assertions exact',code(func[:a]+func[z:])==code(of['_gather_authored_node']))
check('one original1800/1.55 walk; wood prefix exact',func.count('_walk_toward(')==1 and 'node.global_position, 1800, 1.55, road, item_id == "wood"' in func)
check('same actual position and selected goal',all(x in func[a:z] for x in ['_player.global_position.x','node.global_position.x','VILLAGE_BOUNDARY.outline(VILLAGE_BOUNDARY.load_config())']))
check('no fixed resource/gate coordinates in routing function','Vector2(36' not in func and 'Vector2(47' not in func and 'Vector2(-8' not in func)
check('only existing authored meadow road','road = "Practice Meadow"' in func[a:z] and 'StoneRoadHint.INVALID' in func[a:z])
check('bounded hint no native/input/pose work',not any(x in nf['stone_road_hint'] for x in ['Physics','Input.','await ','global_','_motion(','_drive','reset(']) and 'outline.size() > 64' in nf['stone_road_hint'])
check('malformed validation before polygon work',nf['stone_road_hint'].index('outline[index].is_finite()')<nf['stone_road_hint'].index('Geometry2D.is_point_in_polygon'))
check('crossing and buffered parallel hints',all(x in nf['stone_road_hint'] for x in ['segment_intersects_segment','get_closest_point_to_segment','gap <= clearance','StoneRoadHint.MEADOW']))
ot,nt=functions(read('originals/'+t)),functions(read('proposal/'+t))
for k in ot:check('existing contract unchanged '+k,ot[k]==nt[k])
check('two geometry regression tests added',len(set(nt)-set(ot))==2)
receipts=[];raws=[];observations=[]
for folder in ['earned-opening-bbe43027409c','earned-opening-857bc75d65e1']:
 d=json.loads(read('prior-failure/'+folder+'/receipt.json'));raw=read('prior-failure/'+folder+'/native.log');receipts.append(d);raws.append(raw)
 check('failed exact sourceclosure '+folder,d['source_before']==d['source_after'] and not d['campaign_result']['requested_prefix_passed'] and d['campaign_result']['checkpoints']==[] and d['campaign_result']['resume']=={})
 check('same actual gate/key/sourcecount '+folder,all(x in raw for x in ['world_seed override=4','RoadGate/Interactable target_position=(38.72, -1.455684, -19.85)','GateKey/Interactable target_position=(30.7, 1.080501, -15.9)','[playground] placed 198 harvest nodes','[village] placed 29 structures','[village_npcs] placed 18 of 20']))
 observations.append([json.loads(x.split(' ',1)[1]) for x in raw.splitlines() if x.startswith('OPENING_PRODUCTION_OBSERVATION ')])
closure_a,closure_b=receipts[0]['source_before'],receipts[1]['source_before']
check('two actual closures differ only R10 gather',[n for n in set(closure_a)|set(closure_b) if closure_a.get(n)!=closure_b.get(n)]==[g])
for n,pin in m['root_actual_input_sha256'].items():check('actual receipt pin '+n,closure_b.get(n)==pin)
terminal=observations[1][-1];check('actual target and contact refusal',terminal['request'][0]==47 and terminal['request'][2]==-34.5 and terminal['refusal']=='actual production contact observation cap')
check('raw ten contacts unchanged refusal',terminal['slide_point_counts']==[1,5,4] and sum(terminal['slide_point_counts'])==10 and terminal['queries']==3 and terminal['recoveries']==0 and terminal['callback_own_us']<10000)
check('actual fence seam identities',any('FencePanelCollision_87' in x['collider_path'] for x in terminal['live_contacts']) and any('FencePanelCollision_86' in x['collider_path'] for x in terminal['live_contacts']))
b=json.loads(read('inputs/data/config/village_boundary.json'));poly=b['outline']['points'];terrain=json.loads(read('inputs/data/config/terrain_playground.json'));road=next(r['points'] for r in terrain['paths']['routes'] if r['label']=='Practice Meadow')
def gap(a,z):return min(segment_distance(a,z,c,d) for c,d in zip(poly,poly[1:]+poly[:1]))
def hint(a,z):
 if not contains(poly,a) or not contains(poly,z):return 'INVALID'
 return 'MEADOW' if gap(a,z)<=1.55 else 'DIRECT'
wood=[36,-16];stone=[47,-34.5];crossings=[]
for i,(c,d) in enumerate(zip(poly,poly[1:]+poly[:1])):
 ab=sub(stone,wood);cd=sub(d,c);den=cross(ab,cd)
 if abs(den)<1e-10:continue
 f=cross(sub(c,wood),cd)/den;u=cross(sub(c,wood),ab)/den
 if 0<=f<=1 and 0<=u<=1:crossings.append({'edge':i,'point':[wood[k]+f*ab[k] for k in [0,1]]})
check('actual inside endpoints cross concave fence twice',contains(poly,wood) and contains(poly,stone) and len(crossings)==2 and hint(wood,stone)=='MEADOW')
check('actual terminal is outside fence',not contains(poly,[terminal['player'][0],terminal['player'][2]]))
check('first crossing is at already-open actual gate',min(math.dist(x['point'],b['gates']['entries'][0]['at']) for x in crossings)<.6)
matrix=[]
for w in [[-8,8],[36,-16]]:
 for goal in [[-18,6],[22,-34],[47,-34.5]]:
  choice=hint(w,goal);start=min(range(len(road)),key=lambda i:math.dist(w,road[i]));path=[w]+road[start:]+[goal] if choice=='MEADOW' else [w,goal]
  dist=min(gap(a,z) for a,z in zip(path,path[1:]));length=sum(math.dist(a,z) for a,z in zip(path,path[1:]));check('matrix hint covered '+str((w,goal)),choice==('MEADOW' if w==wood and goal==stone else 'DIRECT'))
  check('matrix closed-fence buffered path '+str((w,goal)),all(contains(poly,p) for p in path) and dist>2.201,dist)
  check('matrix original edge/budget scale '+str((w,goal)),max(math.dist(a,z) for a,z in zip(path,path[1:]))<=180 and length/5*60<1800,length)
  matrix.append({'from_wood_metadata':w,'selected_stone_metadata':goal,'hint':choice,'source_path':path,'fence_distance_m':dist,'length_m':length,'nominal5mps60fps_frames':length/5*60})
check('actual failing selected route exact',matrix[-1]['source_path']==[[36,-16],[20,-18],[20,-26],[14.6,-31],[21,-37.5],[30,-40],[47,-34.5]])
check('ordinary merged harvest source','BAND_CONTENT.load_config("res://data/config/harvest.json", "nodes")' in read('inputs/scripts/world/playground_world.gd') and 'node.position = Vector3(float(at[0]), ground, float(at[1]))' in read('inputs/scripts/world/playground_world.gd'))
check('nearest live selection unchanged',of['_nearest_authored_node']==nf['_nearest_authored_node'] and 'distance_to(candidate.global_position)' in nf['_nearest_authored_node'])
check('seed override before fresh title',raws[1].index('world_seed override=4')<raws[1].index('title interactive') and 'OS.set_environment("TB_WORLD_SEED", raw)' in read('inputs/tests/smoke_four_biome_continuous.gd') and 'OS.get_environment(SEED_ENV_VAR)' in read('inputs/scripts/combat/spawn_tables.gd'))
failed=[c for c in checks if not c['passed']];result={'classification':'SOURCEPASS' if not failed else 'SOURCEFAIL','acceptance':'F17#4 OPEN; author-only; no engine/native/independent/whole-prefix credit','passed':len(checks)-len(failed),'total':len(checks),'checks':checks,'actual_terminal':terminal,'source_fence_crossings':crossings,'source_route_matrix':matrix,'limits':'Matrix is metadata for two observed wood and three nearby stone sites; selection remains all real available authored nodes. Exact selection-time player pose not logged. No universal reachability, physics, floor, vegetation, actual frame time or earned proof.'}
(P/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'));print(json.dumps({'classification':result['classification'],'passed':result['passed'],'total':result['total'],'failed':failed,'crossings':crossings,'matrix':matrix},indent=2));raise SystemExit(bool(failed))
