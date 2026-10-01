"""Frozen source/planar geometry controls only. Never invokes Godot or CI.

Run with Python from any directory. The report is not execution acceptance.
"""
from pathlib import Path
import hashlib, json, math, re, struct

PACK = Path(__file__).resolve().parent
CHECKS = []
DETAILS = {}

def check(name, condition, detail=None):
    CHECKS.append({'name': name, 'pass': bool(condition), 'detail': detail})

def read(rel, side='candidate'):
    return (PACK/'frozen'/side/rel).read_text(encoding='utf-8')

def data(rel, side='candidate'):
    return json.loads(read(rel, side))

def functions(source):
    matches = list(re.finditer(r'^(?:static )?func (\w+)\(', source, re.M))
    return {m[1]: source[m.start():matches[i+1].start() if i+1 < len(matches) else len(source)].rstrip()
            for i,m in enumerate(matches)}

def code(source):
    # Comments between functions belong to the next declaration semantically.
    return '\n'.join(line for line in source.splitlines() if line.strip() and not line.lstrip().startswith('#'))

def leaves(before, after, path=()):
    if type(before) is dict and type(after) is dict:
        if before.keys()!=after.keys(): return [(path, before, after)]
        return [v for k in before for v in leaves(before[k],after[k],path+(k,))]
    if type(before) is list and type(after) is list:
        if len(before)!=len(after): return [(path,before,after)]
        return [v for i in range(len(before)) for v in leaves(before[i],after[i],path+(i,))]
    return [] if before==after else [(path,before,after)]

def distance(a,b): return math.hypot(a[0]-b[0], a[1]-b[1])
def plus(a,b): return (a[0]+b[0], a[1]+b[1])
def minus(a,b): return (a[0]-b[0], a[1]-b[1])
def times(a,n): return (a[0]*n,a[1]*n)
def dot(a,b): return a[0]*b[0]+a[1]*b[1]
def cross(a,b): return a[0]*b[1]-a[1]*b[0]

def point_segment(p,a,b):
    ab=minus(b,a)
    t=max(0,min(1,dot(minus(p,a),ab)/dot(ab,ab))) if dot(ab,ab)>0 else 0
    return distance(p,plus(a,times(ab,t)))

def intersection(a,b,c,d):
    ab,cd=minus(b,a),minus(d,c)
    denominator=cross(ab,cd)
    if abs(denominator)<1e-12: return None
    t=cross(minus(c,a),cd)/denominator
    u=cross(minus(c,a),ab)/denominator
    return plus(a,times(ab,t)) if -1e-9<=t<=1+1e-9 and -1e-9<=u<=1+1e-9 else None

def inside(p,polygon):
    odd=False
    for a,b in zip(polygon,polygon[1:]+polygon[:1]):
        if point_segment(p,a,b)<1e-8: return True
        if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]: odd=not odd
    return odd

def rotate(p,yaw):
    # Godot Basis(UP,yaw): x'=cos*x+sin*z, z'=-sin*x+cos*z.
    r=math.radians(yaw)
    return (math.cos(r)*p[0]+math.sin(r)*p[1],-math.sin(r)*p[0]+math.cos(r)*p[1])

manifest=json.loads((PACK/'manifest.json').read_text(encoding='utf-8'))
for entry in manifest['files']:
    raw=(PACK/entry['path']).read_bytes()
    check('frozen hash '+entry['path'],len(raw)==entry['bytes'] and hashlib.sha256(raw).hexdigest()==entry['sha256'])

nav='tests/helpers/opening_geometry_navigator.gd'
insertion='''\t\t# A position walk ends at the current route waypoint. Geometry beyond it
\t\t# cannot justify steering away from this leg (the shop counter is beyond
\t\t# the axial entry point). Raw directional requests retain their horizon.
\t\t# This caps an advisory cast only; actual pre/post validation is unchanged.
\t\tif not _raw:
\t\t\treach = minf(reach, direction.length())
'''
old,new=read(nav,'before'),read(nav)
check('navigator exact six-line insertion only',new.count(insertion)==1 and new.replace(insertion,'')==old)
old_funcs,new_funcs=functions(old),functions(new)
changed_funcs=[k for k in old_funcs if old_funcs[k]!=new_funcs.get(k)]
check('only production advisory heading function changes',changed_funcs==['_production_heading'] and old_funcs.keys()==new_funcs.keys(),changed_funcs)
check('finite and max edge guards precede clipping',new.index('reach > MAX_EDGE:',new.index('func _production_heading'))<new.index(insertion))
heading=new_funcs['_production_heading']
check('single native advisory query remains',heading.count('_motion(')==1)
for rel in ['tests/helpers/gate_a_npc_gather_segment.gd','tests/helpers/fresh_opening_segment.gd',
            'scripts/player/player_controller.gd','scripts/world/shop_interior.gd','scripts/world/vegetation.gd']:
    check('unchanged producer/validator '+rel,read(rel)==read(rel,'before'))
DETAILS['helper_sha256']={rel:hashlib.sha256((PACK/'frozen/candidate'/rel).read_bytes()).hexdigest()
                         for rel in [nav,'tests/helpers/gate_a_npc_gather_segment.gd']}

rewritten={
 'tests/test_farming.gd': {'test_farm_json_places_beds_where_r7_6_allows'},
 'tests/test_gate_f_village_passage.gd': {'test_closed_gate_refuses_crossing_but_allows_outside_detour'},
 'tests/test_grandpa_yard_visual_identity.gd': {'test_grandpa_work_yard_has_one_coherent_domestic_cluster','test_grandpa_domestic_apron_is_bounded_off_progression_space'},
 'tests/test_meadows_south_trail_pulls_0912.gd': {'test_nessa_makes_the_overlook_a_persisted_person_and_gift_pull'},
}
for rel in manifest['changed_paths']:
    if not rel.startswith('tests/test_') or not rel.endswith('.gd'): continue
    before,after=functions(read(rel,'before')),functions(read(rel))
    before_tests={n for n in before if n.startswith('test_')}
    after_tests={n for n in after if n.startswith('test_')}
    check('all existing test entrypoints retained '+rel,before_tests<=after_tests and len(before_tests)==len(after_tests),len(after_tests))
    check('no test skip/quarantine directive added '+rel,
          not re.search(r'(?im)^\s*(?:skip|pending|quarantine|disabled)\s*\(',read(rel)))
    changed=[n for n in before_tests if code(before[n])!=code(after[n])]
    DETAILS.setdefault('changed_test_bodies',{})[rel]=changed
    if rel != 'tests/test_village_street_0912.gd':
        check('bounded changed test bodies '+rel,set(changed)<=rewritten.get(rel,set()),changed)

# Exact mirror leaf whitelist; baseline prefix equality remains order/value strict.
fixture_specs=[('props','clusters'),('vegetation','clearings'),('vegetation','footprints')]
allowed_props={('clusters',1,'props',i,'at',axis) for i in range(5) for axis in range(2)}
allowed_veg={('clearings',i,k) for i in [2,4] for k in ['x','z']}|{('footprints',i,k) for i in [0,6] for k in ['x','z']}
for name,allowed in [('props',allowed_props),('vegetation',allowed_veg)]:
    rel='tests/fixtures/band_split_baseline/'+name+'.json'
    diff=leaves(data(rel,'before'),data(rel))
    check('exact fixture coordinate whitelist '+name,{x[0] for x in diff}==allowed,[list(x[0]) for x in diff])
for name,key in [('props','clusters'),('spawns','spawns'),('harvest','nodes'),('trainers','trainers'),('vegetation','clearings'),('vegetation','footprints')]:
    baseline=data('tests/fixtures/band_split_baseline/'+name+'.json')[key]
    entries=[]
    for band in ['band1_lower_meadows','band2_stone_and_root','band3_the_river_lock','band4_upper_meadows_ironwood','band5_stronghold_approach']:
        path=PACK/'frozen/candidate/data/config/bands'/band/(name+'.json')
        if path.exists(): entries.extend(json.loads(path.read_text(encoding='utf-8')).get(key,[]))
    entries.sort(key=lambda x:x['order'])
    merged=[{k:v for k,v in x.items() if k!='order'} for x in entries[:len(baseline)]]
    if name in ['spawns','trainers']:
        before_entries=[]
        for band in ['band1_lower_meadows','band2_stone_and_root','band3_the_river_lock','band4_upper_meadows_ironwood','band5_stronghold_approach']:
            path=PACK/'frozen/before/data/config/bands'/band/(name+'.json')
            if path.exists():before_entries.extend(json.loads(path.read_text(encoding='utf-8')).get(key,[]))
        before_entries.sort(key=lambda x:x['order'])
        prior=[{k:v for k,v in x.items() if k!='order'} for x in before_entries[:len(baseline)]]
        DETAILS.setdefault('out_of_scope_existing_baseline_drift',{})[name]={'mismatch_paths':[list(p) for p,a,b in leaves(baseline,merged)],'unchanged':prior==merged,'status':'Existing strict Godot comparison may fail; separate owner repair required.'}
        check('existing out-of-scope baseline drift unchanged '+name,prior==merged and data('tests/fixtures/band_split_baseline/'+name+'.json','before')[key]==baseline)
    else:
        check('strict merged baseline prefix '+name+'.'+key,merged==baseline,{'baseline':len(baseline),'merged_total':len(entries)})
    # Failable controls: a deletion and an order/value swap must break this comparison.
    check('baseline deletion negative control '+name+'.'+key,merged[1:]!=baseline)
    swapped=merged[:]
    if len(swapped)>1: swapped[0],swapped[1]=swapped[1],swapped[0]
    check('baseline order negative control '+name+'.'+key,swapped!=baseline)

npcs=data('data/config/village_npcs.json')
diff=leaves(data('data/config/village_npcs.json','before'),npcs)
names={x['name']:i for i,x in enumerate(npcs['villagers'])}
check('only Mira/Bram production facing edits',diff==[(('villagers',names['Mira'],'facing_deg'),180,0),(('villagers',names['Bram'],'facing_deg'),180,0)],[(list(p),a,b) for p,a,b in diff])
check('installed cast count retained',len(npcs['villagers'])==20)
village=data('data/config/village.json')
houses={s['id']:s for s in village['structures'] if s.get('road_house')}
check('eight current road houses retained',len(houses)==8)
terrain=data('data/config/terrain_playground.json')
prefabs=data('data/config/building_prefabs.json')['prefabs']
flats=terrain['flats']
veg=data('data/config/bands/band1_lower_meadows/vegetation.json')
footprints={(x['x'],x['z']):x for x in veg['footprints']}
corners_checked=0
for id,house in houses.items():
    checked=0
    for c in prefabs[house['prefab']]['colliders']:
        a,size=c['at'],c['size']
        if a[1]-size[1]*.5>.1: continue
        checked+=1
        for sx in [-1,1]:
            for sz in [-1,1]:
                corner=plus(house['at'],rotate((a[0]+sx*size[0]*.5,a[2]+sz*size[2]*.5),house['yaw_deg']))
                covered=any(f.get('height')==.9 and distance(corner,f['centre'])<=f['radius'] for f in flats)
                check('ground wall on full-flatten pad '+id+' '+str(corner),covered)
                check('actual wall footprint has random-obstruction clearing '+id+' '+str(corner),any(distance(corner,(c['x'],c['z']))<=c['radius'] for c in veg['clearings']))
                corners_checked+=1
    check('all actual ground walls covered '+id,checked>=4,checked)
    r=footprints[tuple(house['at'])]['radius']
    check('live ground-cover footprint retained '+id,r>=3.9,r)
    person={'mira_shop':'Mira','bram_inn':'Bram'}.get(id)
    if person: check('counter operator faces actual doorway '+person,npcs['villagers'][names[person]]['facing_deg']==house['yaw_deg'])
DETAILS['ground_wall_corners_checked']=corners_checked

farm=data('data/config/farm.json')
home=village['road_plan']['home_centre']
pad=next(f for f in flats if f['centre']==home)
green=terrain['paths']['village_topology']['green']
check('six farm production identities retained',len(farm['plots'])==6)
for plot in farm['plots']:
    check('whole farm bed fits flatten '+str(plot['at']),distance(plot['at'],home)+math.sqrt(2)*.79<=pad['radius'])
    check('farm bed clear of actual public green '+str(plot['at']),distance(plot['at'],green['centre'])>green['radius_m'])
    for s in village['structures']:
        if s['prefab']=='fence_run':check('farm bed clear of actual rail '+str(plot['at'])+' '+str(s['at']),distance(plot['at'],s['at'])>4)

boundary=data('data/config/village_boundary.json')
polygon=boundary['outline']['points']
gates=[g['at'] for g in boundary['gates']['entries']]
inside_names=sorted(n['name'] for n in npcs['villagers'] if inside((n['position'][0],n['position'][-1]),polygon))
check('exact named functions inside real perimeter',inside_names==sorted(['Mira','Oskar','Tam','Bram','Halda','Maren','Nessa']),inside_names)
check('old outside endpoint negative control',inside((70,-10),polygon))
check('new closed chord endpoints both outside',not inside((150,-10),polygon) and not inside((-60,-10),polygon))
check('new closed chord still cuts solid fence',any(intersection((-60,-10),(150,-10),a,b) is not None for a,b in zip(polygon,polygon[1:]+polygon[:1])))

# Each shard keeps actions/arguments/order; only the specified four targets move.
target_pins={'S03':{'S03-52':[27,6.4],'S03-59a':[27,6.4],'S03-59b':[31,6.4],'S03-59c':[31,14]},
 'S03C':{'S03C-52':[27,6.4],'S03C-59a':[27,6.4],'S03C-59b':[31,6.4],'S03C-59c':[31,14]},
 'S10e':{'S10e-98g':[13.44428,26.38503],'S10e-98h':[14.13572,18.41497],'S10e-103d':[8.3,14],'S10e-103':[-.4,15.2]}}
for segment,pins in target_pins.items():
    rel='tools/gate_f/segments/'+segment+'.json'
    before,after=data(rel,'before'),data(rel)
    check('segment ids/order unchanged '+segment,[s['id'] for s in before['steps']]==[s['id'] for s in after['steps']])
    moved=[]
    for b,a in zip(before['steps'],after['steps']):
        check('segment action unchanged '+segment+' '+a['id'],b['action']==a['action'])
        ba,aa=dict(b.get('args',{})),dict(a.get('args',{}))
        if ba!=aa:
            moved.append(a['id'])
            check('only pinned target changes '+segment+' '+a['id'],a['id'] in pins and aa.get('at')==pins.get(a['id']))
            ba.pop('at',None);aa.pop('at',None)
        check('segment budgets/answer/close arguments unchanged '+segment+' '+a['id'],ba==aa)
    check('exact moved target set '+segment,set(moved)==set(pins),moved)

def journey(side):
    chain=['S01','S02','S03','S04','S05','S06','S07','S08','S09','S10a','S10b','S10c','S10d','S10e']
    previous=None
    crossings=[]
    for shard in chain:
        spec=data('tools/gate_f/segments/'+shard+'.json',side)
        for step in spec['steps']:
            if step['action']!='move_to' or 'at' not in step.get('args',{}): continue
            current=step['args']['at']
            if previous is not None:
                for a,b in zip(polygon,polygon[1:]+polygon[:1]):
                    hit=intersection(previous,current,a,b)
                    if hit is not None:
                        crossings.append({'step':step['id'],'point':hit,'nearest_gate_m':min(distance(hit,g) for g in gates)})
            previous=current
    return crossings
old_cross,new_cross=journey('before'),journey('candidate')
old_bad=[x for x in old_cross if x['nearest_gate_m']>boundary['wall']['gate_clear_m']+1]
new_bad=[x for x in new_cross if x['nearest_gate_m']>boundary['wall']['gate_clear_m']+1]
check('old return route negative control crosses solid fence',len(old_bad)>0,old_bad)
check('entire literal earned journey crosses only real gate openings',not new_bad,new_bad)
DETAILS['journey_crossings']={'before':old_cross,'candidate':new_cross}

# Exact historical failed producer input, decoded independently from format v1.
raw=(PACK/'historical-tree/region_0_-1.bin').read_bytes()
cursor=0
def unpack(fmt):
    global cursor
    values=struct.unpack_from('<'+fmt,raw,cursor);cursor+=struct.calcsize('<'+fmt)
    return values[0] if len(values)==1 else values
def string():
    global cursor
    size=unpack('I');value=raw[cursor:cursor+size].decode('utf-8');cursor+=size;return value
check('historical bake header',unpack('II')==(0x53434154,1))
models=[string() for _ in range(unpack('I'))]
tree=None
for _ in range(unpack('I')):
    layer=string();kept,drained=unpack('II')
    for i in range(kept+drained):
        order,model=unpack('IH');position=unpack('fff');yaw,scale=unpack('dd')
        normal=unpack('fff') if unpack('B')==1 else None
        if layer=='trees' and order==320 and i<kept:
            tree={'model':models[model],'position':position,'yaw':yaw,'scale':scale,'normal':normal}
check('historical decoder consumes whole file',cursor==len(raw))
expected={'model':'res://assets/environment/stylized_nature/CommonTree_2.gltf',
 'position':(45.44734573364258,-.18858742713928223,-62.50096893310547),
 'yaw':4.354415416717529,'scale':1.598110499382019,'normal':None}
check('historical producer record exact',tree==expected,tree)
tree_source=read('tests/test_vegetation_human_prompt_height.gd')
check('historical numeric fixture exact',all(str(v) in tree_source for v in [*expected['position'],expected['yaw'],expected['scale']]))

# Static capsule-vs-counter control from the retained frame397. This is not a
# Godot query replay: full 3D contacts, elapsed costs and arrival remain OPEN.
receipt=json.loads((PACK/'retained-native-failure/receipt.json').read_text(encoding='utf-8'))
log=(PACK/'retained-native-failure/native.log').read_text(encoding='utf-8')
check('original deep recovery refusal retained','zero-motion recovery exceeds unchanged skin' in log)
check('original failed Mira entry retained',"could not naturally enter Mira" in log)
check('retained receipt remains incomplete failed fresh campaign',not receipt['campaign_result']['campaign_complete'] and not receipt['campaign_result']['requested_prefix_passed'] and receipt['campaign_result']['reached']=='road_gate' and receipt['campaign_result']['resumed_from']=='')
check('retained execution source closure unchanged',receipt['source_before']==receipt['source_after'])
observations=[json.loads(line.split(' ',1)[1]) for line in log.splitlines() if line.startswith('OPENING_PRODUCTION_OBSERVATION ')]
frame=next(o for o in observations if o['frame']==397 and o['refusal'])
post=(frame['player'][0],frame['player'][2])
actual=(frame['actual_delta'][0],frame['actual_delta'][2])
start=minus(post,actual);goal=(frame['request'][0],frame['request'][2])
remaining=distance(start,goal)
recorded_motion=frame['provisional_steering']['prediction_motion']
old_end=plus(start,(recorded_motion[0],recorded_motion[2]))
check('retained prediction is original 2m horizon',abs(math.hypot(recorded_motion[0],recorded_motion[2])-2)<1e-6)
new_end=goal
def segment_rect(a,b,rect):
    x0,z0,x1,z1=rect
    corners=[(x0,z0),(x1,z0),(x1,z1),(x0,z1)]
    def d(p): return math.hypot(max(x0-p[0],0,p[0]-x1),max(z0-p[1],0,p[1]-z1))
    if d(a)==0 or d(b)==0 or any(intersection(a,b,c,e) is not None for c,e in zip(corners,corners[1:]+corners[:1])):return 0
    return min(d(a),d(b),*(point_segment(p,a,b) for p in corners))
counter=(24.4,1.4,26.9,1.9)
before_target=(24.4,2.9,26.9,3.4)
old_distance=segment_rect(start,old_end,counter)
new_distance=segment_rect(start,new_end,counter)
obstacle_distance=segment_rect(start,new_end,before_target)
check('old 2m horizon hits future counter negative control',old_distance<.4)
check('clipped horizon stops at clear entry waypoint',new_distance>.401 and remaining<2)
check('obstacle before entry remains within capsule cast',obstacle_distance<.4)
DETAILS['planar_counter_control']={'origin':'retained native frame397, full source guard unchanged',
 'start':start,'goal':goal,'old_prediction_endpoint':old_end,'new_prediction_endpoint':new_end,
 'remaining_m':remaining,'old_counter_distance_m':old_distance,'new_counter_distance_m':new_distance,
 'before_target_obstacle_distance_m':obstacle_distance,'capsule_radius_m':.4,
 'scope':'Static planar geometry only. No engine replay, parser, CI or arrival proof.'}

result={'classification':'SOURCEPASS' if all(x['pass'] for x in CHECKS) else 'SOURCEFAIL',
 'acceptance':'F17#4 OPEN; retained native FAILED; no Godot/CI run',
 'manifest_sha256':hashlib.sha256((PACK/'manifest.json').read_bytes()).hexdigest(),
 'passed':sum(x['pass'] for x in CHECKS),'total':len(CHECKS),'checks':CHECKS,'details':DETAILS}
(PACK/'source-geometry-results.json').write_text(json.dumps(result,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:result[k] for k in ['classification','acceptance','passed','total','manifest_sha256']},indent=2))
for c in CHECKS:
    if not c['pass']:print('FAIL',c['name'],c['detail'])
raise SystemExit(0 if result['classification']=='SOURCEPASS' else 1)
