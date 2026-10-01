from pathlib import Path
import json,hashlib,gzip,re,math
P=Path(__file__).resolve().parent;W=P.parents[4]
results=[]
def check(name,ok):
 assert ok,name
 results.append(name)
def digest(p):return hashlib.sha256(p.read_bytes()).hexdigest()
paths=['tests/helpers/gate_a_opening_drive.gd','tests/test_opening_beats.gd']
old=(P/'originals'/paths[0]).read_bytes();new=(W/paths[0]).read_bytes()
for n in paths:check('sealed proposal '+n,(P/'proposal'/n).read_bytes()==(W/n).read_bytes())
def funcs(b):
 starts=list(re.finditer(rb'^(?:static )?func ([a-zA-Z0-9_]+)\(',b,re.M))
 return {m.group(1).decode():b[m.start():starts[i+1].start() if i+1<len(starts) else len(b)].rstrip() for i,m in enumerate(starts)}
a=funcs(old);b=funcs(new)
# Inserted comments precede the unchanged walker, so exclude only that suffix
# from the preceding pure road function comparison.
marker=b'## Select for the destination we actually walk to.'
for name,body in a.items():
 if name=='run':continue
 current=b[name].split(marker)[0].rstrip()
 check('old function byte-preserved '+name,body==current)
check('run one assignment only',b['run']==a['run'].replace(b'_wild = _encounter.call("wild_creature") as Node3D',b'_wild = _tutorial_wild_at_road_end()'))
check('exact two new functions',set(b)-set(a)=={'_tutorial_wild_at_road_end','practice_wild_index'})
t=(W/paths[1]).read_bytes();o=(P/'originals'/paths[1]).read_bytes()
check('all original test bytes prefix-preserved',t.startswith(o))
check('three meaningful cases appended',len(re.findall(rb'^func test_',t,re.M))==len(re.findall(rb'^func test_',o,re.M))+3)
for n,d in json.loads((P/'unchanged-paths.json').read_bytes()).items():check('unchanged '+n,digest(W/n)==d)
selection=b['_tutorial_wild_at_road_end'];pure=b['practice_wild_index']
for token in [b'wild_approach_road(',b'var anchor: Vector3 = plan.points[-1]',b'_encounter.call("wild_creatures")',b'body.global_position',b'body.visible',b'body.call("is_alive")',b'return target',b'"acceptance": false']:
 check('selection source owns '+token.decode(),token in selection)
for token in [b'await ',b'Input.',b'.set(',b'.global_position =',b'.position =',b'.velocity =',b'test_move(',b'body_test_motion(',b'physics_frame']:
 check('no selection side effect '+token.decode(),token not in selection+pure)
for token in [b'_walk_to_and_engage_wild(_wild, 2600)',b'_combat.call("enemy_body") != _wild',b'_wild_offer_ready(target)',b'await _tap_action("interact")',b'const STALL_FRAMES := 90',b'const SIDESTEP_FRAMES := 45',b'offset.length() <= 0.8 and _player.is_on_floor()']:
 check('original acceptance guard '+token.decode(),new.count(token)==old.count(token))
raw=gzip.decompress((P/'native-failed/smoke.log.gz').read_bytes())
check('full failed raw bytes retained',len(raw)==1319865 and hashlib.sha256(raw).hexdigest()=='3bf2ab6cdd668a0a0a26a44b38e5c7ad4928d265cca9a18782f5e188dd412475')
receipt=json.loads((P/'native-failed/result.json').read_bytes())
check('failure authoritative',receipt['exit']==1 and not receipt['timed_out'] and receipt['watchdog_seconds']==1200 and len(receipt['errors'])==2)
analysis=json.loads((P/'actual-analysis.json').read_bytes());f=analysis['final_native_observation']
check('actual frames exhausted',f['physics_frames']==f['budget']==2600)
check('actual road consumed',f['road_index']==f['road_size']==8)
check('actual grounded final',f['on_floor'] is True)
check('actual final distance',abs(math.dist(f['player'],f['target'])-54.69)<.005)
root=(P/'root-source/scripts/combat/encounter_director.gd').read_bytes()
check('production selector trainer origin',b'var distance := _player.global_position.distance_to(wild.global_position)' in root and b'return _wild_of_species(_role_species("practice"))' in root)
cfg=json.loads((P/'root-source/data/config/terrain_playground.json').read_bytes())
roads=[r for r in cfg['paths']['routes'] if r['label']=='Practice Meadow']
check('actual authored road endpoint',len(roads)==1 and roads[0]['points'][-1]==[30,-40])
spawns=json.loads((P/'root-source/data/config/bands/band1_lower_meadows/spawns.json').read_bytes())['spawns']
practice=next(s for s in spawns if s['order']==0);ambient=next(s for s in spawns if s['order']==1006)
check('authored practice cluster unchanged',practice['centre']==[30,0,-40] and practice['species']=='bramblebun' and practice['count']==3 and practice['level']==2 and 'table' not in practice)
check('other nearby cluster exists',ambient['centre']==[-2.4,0,62] and ambient['species']=='bramblebun')
# Pure record selection only: never a motion, timing or geometry simulation.
def select(rows,species,anchor):
 if not species or not all(math.isfinite(v) for v in anchor):return -1
 best=-1;distance=math.inf
 for i,c in enumerate(rows):
  if not isinstance(c,dict) or c.get('species')!=species or not c.get('visible',False) or not c.get('alive',False):continue
  pos=c.get('position')
  if not isinstance(pos,tuple) or len(pos)!=3 or not all(math.isfinite(v) for v in pos):continue
  d=math.dist(anchor,pos)**2
  if d<distance:best=i;distance=d
 return best
def row(pos,**kw):return dict(species='bramblebun',position=pos,visible=True,alive=True,**kw)
anchor=(30,.9,-40);ambient_pos=tuple(f['target']);far=(38.824909,-1.001545,-48.624557);near=(29,0,-36)
rows=[row(ambient_pos),row(far),row(near)]
check('source selection destination differs from farmhouse',select(rows,'bramblebun',anchor)==2 and select(rows,'bramblebun',(8.3,.9,14))==0)
check('far meadow body not excluded',select(rows[:2],'bramblebun',anchor)==1)
for key,value in [('species','mudsnout'),('visible',False),('alive',False),('position',(math.inf,0,0)),('position',[30,0,-40])]:
 bad=row(anchor);bad[key]=value
 check('invalid/ineligible record '+key+' '+str(value),select([bad,row(far)],'bramblebun',anchor)==1)
for rows,species,point in [([], 'bramblebun',anchor),([None,{}],'bramblebun',anchor),([row(far)],'',anchor),([row(far)],'bramblebun',(math.inf,0,0))]:
 check('missing evidence refuses '+str((rows,species,point)),select(rows,species,point)==-1)
check('tie preserves director iteration order',select([row(far),row(far)],'bramblebun',anchor)==0)
check('removed nearest keeps living next candidate',select([row(ambient_pos),row(far)],'bramblebun',anchor)==1)
prior=json.loads((P/'prior-seals.json').read_bytes())
for rel,h in prior.items():
 q=W/rel;check('prior seal unchanged '+rel,digest(q)==h)
 seal=json.loads(q.read_bytes())
 for n,h in seal['files'].items():assert digest(q.parent/n)==h,(rel,n)
out={'checks':len(results),'passed':len(results),'failed':0,'names':results,'source_only':True,'native_acceptance':False,'parser_unit_native_ci':'UNRUN here','F17#4':'OPEN','R9':'HOLD'}
(P/'source-results.json').write_bytes((json.dumps(out,indent=2)+'\n').encode())
print(json.dumps({k:v for k,v in out.items() if k!='names'}))
