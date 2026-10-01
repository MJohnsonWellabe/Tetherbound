"""Independent frozen R5 review. Static bytes, JSON and planar math only.

Reproduce with --packet pointing to a whole frozen packet copy and --output
pointing to an ignored directory. source-geometry-results.json records the
separately authorized static author's audit; this script never runs that audit.
The default packet is the originally reviewed ignored copy, preserving its
reviewed 2976-check author script/results even if the unfrozen audit evolves.
"""
from pathlib import Path
import hashlib, json, math, re, struct, io, argparse

ROOT = Path('D:/tetherbound/redesign-hub')
arguments=argparse.ArgumentParser(description=__doc__)
arguments.add_argument('--packet',type=Path,default=ROOT/'.tmp/f17-r5-independent-review')
arguments.add_argument('--output',type=Path,default=Path(__file__).resolve().parent)
options=arguments.parse_args()
PACK,OUT=options.packet.resolve(),options.output.resolve()
OUT.mkdir(parents=True,exist_ok=True)
B, C = PACK/'frozen/before', PACK/'frozen/candidate'
checks, details = [], {}
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def require(name, ok, detail=None): checks.append(dict(name=name, passed=bool(ok), detail=detail))
def text(p): return p.read_bytes().decode('utf-8').replace('\r\n','\n')
def obj(p): return json.loads(p.read_bytes())
def changes(a,b,p=()):
    if isinstance(a,dict) and isinstance(b,dict) and a.keys()==b.keys():
        return sum((changes(a[k],b[k],p+(k,)) for k in a),[])
    if isinstance(a,list) and isinstance(b,list) and len(a)==len(b):
        return sum((changes(x,y,p+(i,)) for i,(x,y) in enumerate(zip(a,b))),[])
    return [] if a==b else [(p,a,b)]
def funcs(s):
    names=list(re.finditer(r'^(?:static )?func (\w+)\(',s,re.M))
    return {m[1]:s[m.start():names[i+1].start() if i+1<len(names) else len(s)] for i,m in enumerate(names)}

manifest=obj(PACK/'manifest.json')
require('exact manifest',sha(PACK/'manifest.json')=='72302312c4b770714639742dc852aa0979c7775542f5cb61107cb8861572d551')
require('before commit',manifest['base_commit']=='c21be258900a2de22ac4eef61cf71f9b55c6e426')
require('exact 16 scope paths',len(manifest['changed_paths'])==16 and len(set(manifest['changed_paths']))==16)
for pin in manifest['files']:
    f=PACK/pin['path']
    require('manifest '+pin['path'],f.stat().st_size==pin['bytes'] and sha(f)==pin['sha256'])
logical, representation=[] ,[]
for f in C.rglob('*'):
    if not f.is_file(): continue
    rel=f.relative_to(C); old=B/rel
    if not old.exists(): continue
    if old.read_bytes()!=f.read_bytes():
        (logical if text(old)!=text(f) else representation).append(rel.as_posix())
require('logical delta equals declared scope',set(logical)==set(manifest['changed_paths']),logical)
require('eight representation-only context files',len(representation)==8,representation)
for rel in representation:
    require('context JSON identity '+rel,obj(B/rel)==obj(C/rel))
for rel in manifest['changed_paths']:
    require('candidate equals current raw repair '+rel,(ROOT/rel).read_bytes()==(C/rel).read_bytes())

nav='tests/helpers/opening_geometry_navigator.gd'
old,new=text(B/nav),text(C/nav)
added='\t\t# A position walk ends at the current route waypoint. Geometry beyond it\n\t\t# cannot justify steering away from this leg (the shop counter is beyond\n\t\t# the axial entry point). Raw directional requests retain their horizon.\n\t\t# This caps an advisory cast only; actual pre/post validation is unchanged.\n\t\tif not _raw:\n\t\t\treach = minf(reach, direction.length())\n'
require('navigator exact six logical lines',new.count(added)==1 and new.replace(added,'')==old)
of,nf=funcs(old),funcs(new)
require('only production heading function changed',[n for n in of if of[n]!=nf.get(n)]==['_production_heading'] and of.keys()==nf.keys())
require('finite MAX_EDGE guard before clipping before query',new.index('reach > MAX_EDGE:',new.index('func _production_heading'))<new.index(added)<new.index('var predicted: Dictionary = _motion',new.index(added)))
require('single prospective query unchanged',nf['_production_heading'].count('_motion(')==1)
require('position direction is current route displacement','direction = Vector3(at.x - _player.global_position.x, 0.0, at.y - _player.global_position.z)' in nf['_native_tick_impl'])
require('tiny direction early stop before heading',nf['_native_tick_impl'].index('direction.length_squared() <= 0.000001')<nf['_native_tick_impl'].index('_production_heading(direction)'))
for rel in ['tests/helpers/gate_a_npc_gather_segment.gd','tests/helpers/fresh_opening_segment.gd','scripts/player/player_controller.gd','scripts/world/shop_interior.gd','scripts/world/vegetation.gd']:
    require('unchanged functional source '+rel,text(B/rel)==text(C/rel))

for rel in manifest['changed_paths']:
    if rel.startswith('tests/test_'):
        before,after=funcs(text(B/rel)),funcs(text(C/rel))
        tests=lambda f:{n for n in f if n.startswith('test_')}
        require('exact test entrypoints retained '+rel,tests(before)==tests(after))
        require('no skip or quarantine '+rel,not re.search(r'(?im)^\s*(skip|pending|quarantine|disabled)\s*\(',text(C/rel)))

allowed_props={('clusters',1,'props',i,'at',j) for i in range(5) for j in range(2)}
allowed_veg={('clearings',i,j) for i in (2,4) for j in ('x','z')}|{('footprints',i,j) for i in (0,6) for j in ('x','z')}
for name,allowed in [('props',allowed_props),('vegetation',allowed_veg)]:
    rel='tests/fixtures/band_split_baseline/'+name+'.json'
    delta=changes(obj(B/rel),obj(C/rel))
    require('fixture coordinate leaves only '+name,{x[0] for x in delta}==allowed)
    details[name+'_fixture_delta']=[(list(p),a,b) for p,a,b in delta]
for name,key in [('props','clusters'),('harvest','nodes'),('vegetation','clearings'),('vegetation','footprints')]:
    rows=[]
    for band in sorted((C/'data/config/bands').iterdir()):
        f=band/(name+'.json')
        if f.exists():rows+=obj(f).get(key,[])
    rows.sort(key=lambda r:r['order'])
    base=obj(C/'tests/fixtures/band_split_baseline'/f'{name}.json')[key]
    prefix=[{k:v for k,v in r.items() if k!='order'} for r in rows[:len(base)]]
    require('complete strict prefix '+name+'.'+key,prefix==base)
    require('strict prefix detects deletion '+name+'.'+key,prefix[1:]!=base)
    require('strict prefix detects reversal '+name+'.'+key,list(reversed(prefix))!=base)

vill=obj(C/'data/config/village.json'); people=obj(C/'data/config/village_npcs.json')
delta=changes(obj(B/'data/config/village_npcs.json'),people)
require('only two facing production leaves',len(delta)==2 and all(p[0]=='villagers' and p[-1]=='facing_deg' and a==180 and b==0 for p,a,b in delta) and {people['villagers'][p[1]]['name'] for p,a,b in delta}=={'Mira','Bram'})
prefabs=obj(C/'data/config/building_prefabs.json')['prefabs'];terrain=obj(C/'data/config/terrain_playground.json');veg=obj(C/'data/config/bands/band1_lower_meadows/vegetation.json')
count=0
for house in vill['structures']:
    if not house.get('road_house'):continue
    a=math.radians(house['yaw_deg']);co,si=math.cos(a),math.sin(a)
    for i,col in enumerate(prefabs[house['prefab']]['colliders']):
        at,size=col['at'],col['size']
        if at[1]-size[1]/2>.1:continue
        corners=[(house['at'][0]+co*(at[0]+x*size[0]/2)+si*(at[2]+z*size[2]/2),house['at'][1]-si*(at[0]+x*size[0]/2)+co*(at[2]+z*size[2]/2)) for x in (-1,1) for z in (-1,1)]
        # One convex disk contains ALL four corners, hence the entire rectangle.
        require('whole ground wall flattened '+house['id']+str(i),any(f.get('height')==.9 and all(math.dist(q,f['centre'])<=f['radius'] for q in corners) for f in terrain['flats']))
        require('whole ground wall clearing '+house['id']+str(i),any(all(math.dist(q,(f['x'],f['z']))<=f['radius'] for q in corners) for f in veg['clearings']))
        count+=1
require('40 complete ground rectangles checked',count==40)

pins={'S03':['S03-52','S03-59a','S03-59b','S03-59c'],'S03C':['S03C-52','S03C-59a','S03C-59b','S03C-59c'],'S10e':['S10e-98g','S10e-98h','S10e-103d','S10e-103']}
for shard,ids in pins.items():
    rel=f'tools/gate_f/segments/{shard}.json';before,after=obj(B/rel),obj(C/rel)
    ds=changes(before,after)
    require('only target/title/expected leaves '+shard,all(p[0]=='steps' and p[-1] in ('title','expected',0,1) and (p[-1] in ('title','expected') or p[-3:-1]==('args','at')) and after['steps'][p[1]]['id'] in ids for p,a,b in ds))
    require('exact moved target ids '+shard,{after['steps'][p[1]]['id'] for p,a,b in ds if 'at' in p}==set(ids))
    require('unchanged complete action/budget/control sequence '+shard,[{k:v for k,v in s.items() if k not in ('title','expected','args')}|{'args':{k:v for k,v in s.get('args',{}).items() if k!='at'}} for s in before['steps']]==[{k:v for k,v in s.items() if k not in ('title','expected','args')}|{'args':{k:v for k,v in s.get('args',{}).items() if k!='at'}} for s in after['steps']])

require('exact retained failed log',sha(PACK/'retained-native-failure/native.log')=='1052b9c5d62cef952424ae10ca23cb6fd7c720fcc95d9f5aa6b2397d27510dee')
require('exact retained failed receipt',sha(PACK/'retained-native-failure/receipt.json')=='2f2c9f9808e7c93bb7fadddca4752052bbea0e78f7953b7fbe8aff100f85879b')
receipt=obj(PACK/'retained-native-failure/receipt.json')
require('retained campaign failed and source closure',not receipt['campaign_result']['campaign_complete'] and not receipt['campaign_result']['requested_prefix_passed'] and receipt['source_before']==receipt['source_after'])
log=text(PACK/'retained-native-failure/native.log')
frame=next(json.loads(l.split(' ',1)[1]) for l in log.splitlines() if l.startswith('OPENING_PRODUCTION_OBSERVATION ') and json.loads(l.split(' ',1)[1])['frame']==397)
require('actual Mira refusal retained',frame['refusal']=='deep actual overlap: zero-motion recovery exceeds unchanged skin' and frame['acceptance'] is False and frame['checked_start'] is False)
start=(frame['player'][0]-frame['actual_delta'][0],frame['player'][2]-frame['actual_delta'][2]);goal=(frame['request'][0],frame['request'][2]);motion=frame['provisional_steering']['prediction_motion'];end=(start[0]+motion[0],start[1]+motion[2])
require('recorded horizon matches route direction',abs(math.hypot(motion[0],motion[2])-2)<1e-6 and abs((goal[0]-start[0])*motion[2]-(goal[1]-start[1])*motion[0])<1e-6)
shop=text(C/'scripts/world/shop_interior.gd')
require('counter dimensions source-bound','_box(Vector3(2.5, 1.0, 0.5), Vector3(-0.35, 0.5, -0.35), COL_COUNTER)' in shop)
mira=next(s for s in vill['structures'] if s.get('id')=='mira_shop')
require('counter source pose',mira['at']==[26.0,2.0] and mira['yaw_deg']==0)
rect=(26-.35-1.25,2-.35-.25,26-.35+1.25,2-.35+.25)
def point_line(p,a,b):
    d=(b[0]-a[0],b[1]-a[1]);n=d[0]**2+d[1]**2
    t=max(0,min(1,((p[0]-a[0])*d[0]+(p[1]-a[1])*d[1])/n)) if n else 0
    return math.dist(p,(a[0]+t*d[0],a[1]+t*d[1]))
def line_box(a,b,r):
    # Independent Liang-Barsky interior test plus endpoint/vertex distances.
    low,high=0.,1.;d=(b[0]-a[0],b[1]-a[1]);hit=True
    for axis in (0,1):
        if d[axis]==0:
            if not r[axis]<=a[axis]<=r[axis+2]:hit=False
        else:
            t0,t1=sorted(((r[axis]-a[axis])/d[axis],(r[axis+2]-a[axis])/d[axis]))
            low,high=max(low,t0),min(high,t1)
    if hit and low<=high:return 0.
    distance=lambda p:math.hypot(max(r[0]-p[0],0,p[0]-r[2]),max(r[1]-p[1],0,p[1]-r[3]))
    return min(distance(a),distance(b),*(point_line((x,z),a,b) for x in (r[0],r[2]) for z in (r[1],r[3])))
od,nd,bd=line_box(start,end,rect),line_box(start,goal,rect),line_box(start,goal,(24.4,2.9,26.9,3.4))
require('old advisory capsule reaches future counter',od<.4)
require('clipped advisory capsule clears future counter',nd>.401 and math.dist(start,goal)<2)
require('before-target obstacle remains hit',bd<.4)
raw=(PACK/'historical-tree/region_0_-1.bin').read_bytes(); stream=io.BytesIO(raw)
def value(fmt):
    values=struct.unpack('<'+fmt,stream.read(struct.calcsize('<'+fmt)))
    return values[0] if len(values)==1 else values
def label(): return stream.read(value('I')).decode('utf-8')
require('historical raw input pinned',hashlib.sha256(raw).hexdigest()=='c156f5385982b2d23b84b15d17b0a97c0a4edc141b6ea54c4cca04fbba37dfd4')
require('historical producer header',value('II')==(0x53434154,1))
models=[label() for _ in range(value('I'))]; target=[]
for _ in range(value('I')):
    layer=label(); kept,drained=value('II')
    for index in range(kept+drained):
        order,model=value('IH'); xyz=value('fff'); yaw,scale=value('dd'); normal=value('fff') if value('B') else None
        if layer=='trees' and order==320 and index<kept:target.append((models[model],xyz,yaw,scale,normal))
expected=('res://assets/environment/stylized_nature/CommonTree_2.gltf',(45.44734573364258,-.18858742713928223,-62.50096893310547),4.354415416717529,1.598110499382019,None)
require('exact unique old producer record',target==[expected],target)
require('historical decode consumes complete bytes',stream.tell()==len(raw))
fixture=text(C/'tests/test_vegetation_human_prompt_height.gd')
require('numeric fixture matches original producer record',all(str(x) in fixture for x in (*expected[1],expected[2],expected[3])))
details['independent_planar']={'start':start,'goal':goal,'counter_from_production':rect,'old_distance':od,'clipped_distance':nd,'before_target_obstacle_distance':bd}
details['representation_only_paths']=representation
details['manual_findings']=[
 'Every original actual pre/post full-capsule guard, aggregate-eight admission, shape/mask, finite/deep-overlap/recovery/door checks, 10ms pre+post accounting and final metadata guard, 1800 gather/3600 team/90 stall/26 retry/query/lifetime caps remain identical after removal of the six approved logical lines.',
 'Current waypoint displacement is horizontal and nonzero before heading; raw directional mode bypasses clipping. One original fullbody advisory query remains. No provisional clearance, arrival, inventory or earned milestone credit is added.',
 'Changed tests retain functional constraints: exact cast and opening five plus accepted research residents; named eight house parcels/thresholds, road facing/alignment; actual ground colliders and clearings; translated yard and whole beds; one-time Nessa gift and unchanged supply tests; closed-fence outside chord; real production vegetation prompt/radius regression. Comments and historical names do not imply current path success.',
 'Mira/Bram 180 to 0 facing is a real data correction. village_npcs assigns facing_deg to rotation.y; npc_body uses +Z facing. Both native yaw-zero buildings open toward positive Z public road. Near-player NPC tracking remains unchanged.',
 'Historical tree fixture preserves exact old producer input instead of depending on a retired live tree; production spawning/contact-distance/radius assertions remain. This independent script decodes the entire pinned raw record and confirms the unique kept trees#320 input including model, all float32 coordinates, yaw/scale and absent normal; no present-tree integration claim follows.',
 'Unchanged spawns/trainers strict baseline drift is existing and outside this repair. No full CI green, parser success, engine replay, or acceptance credit claimed.',
 'Planar counter controls support an advisory overreach hypothesis only. They do not prove native contact classification, 10ms runtime, unobstructed doors, or earned completion. ROOT must run required fresh actual path and land to main; F17#4 OPEN.'
]
details['frozen_hashes']={r:sha(C/r) for r in manifest['changed_paths']}
author=obj(PACK/'source-geometry-results.json')
details['copied_author_audit']={'passed':author['passed'],'total':author['total'],'script_sha256':sha(PACK/'source-geometry-audit.py'),'results_sha256':sha(PACK/'source-geometry-results.json'),'execution':'Authorized static copied audit only; no Godot/CI.'}
result={'verdict':'SOURCEPASS' if all(c['passed'] for c in checks) else 'SOURCEFAIL','acceptance':'F17#4 OPEN; retained actual run FAILED; source readiness only','manifest_sha256':sha(PACK/'manifest.json'),'passed':sum(c['passed'] for c in checks),'total':len(checks),'checks':checks,'details':details}
(OUT/'review.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
report=f"{result['verdict']} readiness only. {result['passed']}/{result['total']} independent checks; copied author static audit {author['passed']}/{author['total']}.\nManifest SHA256 {result['manifest_sha256']}.\n225 frozen manifest entries verified. Exact logical repair scope 16; eight context files differ only by LF/CRLF representation.\nNo engine, parser, import, CI, Git, tracked writes or delegates.\n\n"+'\n\n'.join(details['manual_findings'])+'\n\nIndependent planar values: '+json.dumps(details['independent_planar'])+'\n'
(OUT/'strict-review.txt').write_text(report,encoding='utf-8')
print(json.dumps({k:result[k] for k in ('verdict','acceptance','manifest_sha256','passed','total')},indent=2))
for c in checks:
    if not c['passed']:print('FAIL',c['name'],c['detail'])
raise SystemExit(0 if result['verdict']=='SOURCEPASS' else 1)
