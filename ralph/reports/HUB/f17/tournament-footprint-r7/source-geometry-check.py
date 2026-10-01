"""Frozen source and actual glTF vertex footprint controls; no engine/CI."""
from pathlib import Path
import hashlib,json,math,re,struct
PACK=Path(__file__).resolve().parent
checks=[]
def check(name,ok,detail=None):checks.append({'name':name,'passed':bool(ok),'detail':detail})
def text(rel):return (PACK/rel).read_text(encoding='utf-8')
def data(rel):return json.loads(text(rel))
def inp(rel):return data('inputs/'+rel)
def leaves(a,b,path=()):
    if isinstance(a,dict) and isinstance(b,dict) and a.keys()==b.keys():return [v for k in a for v in leaves(a[k],b[k],path+(k,))]
    if isinstance(a,list) and isinstance(b,list) and len(a)==len(b):return [v for i,(x,y) in enumerate(zip(a,b)) for v in leaves(x,y,path+(i,))]
    return [] if a==b else [(path,a,b)]
manifest=data('manifest.json')
for rel,entry in manifest['files'].items():
    raw=(PACK/rel).read_bytes()
    check('frozen input '+rel,len(raw)==entry['bytes'] and hashlib.sha256(raw).hexdigest()==entry['sha256'])
cfgpath='data/config/tournament_ground_presentation.json'
before,after=data('originals/'+cfgpath),data('proposal/'+cfgpath)
diff=leaves(before,after)
check('exact canopy pose/rationale scope',{d[0] for d in diff}=={('marshal_canopy','at',0),('marshal_canopy','at',1),('marshal_canopy','_why')},diff)
check('same authored lawn centre',before['arena']==after['arena'] and after['arena']['centre']==[78,44])
check('same presentation collision ban',before['collision_enabled']==after['collision_enabled']==False)
check('same yaw/scale/height/lighting/accent budgets',{k:v for k,v in before['marshal_canopy'].items() if k not in ['at','_why']}=={k:v for k,v in after['marshal_canopy'].items() if k not in ['at','_why']})
check('equipment/light all unchanged',before['equipment']==after['equipment'] and before['equipment_light']==after['equipment_light'])
test='tests/test_tournament_ground_presentation.gd'
old,new=text('originals/'+test),text('proposal/'+test)
def functions(s):
    markers=list(re.finditer(r'^func (\w+)\(',s,re.M))
    return {m[1]:s[m.start():markers[i+1].start() if i+1<len(markers) else len(s)].rstrip() for i,m in enumerate(markers)}
of,nf=functions(old),functions(new)
primary='test_training_ground_has_one_primary_canopy_and_a_readable_lists_ring'
check('every original test entrypoint retained',{k for k in of if k.startswith('test_')}=={k for k in nf if k.startswith('test_')})
check('all other original function bodies unchanged',all(of[k]==nf[k] for k in of if k!=primary))
assertions=re.findall(r'(?m)^\tassert_\w+\([^\n]*(?:\n\t{2,}[^\n]*)*',of[primary])
check('every original assertion except retired centre pin exact',all(a in nf[primary] for a in assertions[1:]),len(assertions)-1)
for anchor in ['const BRYN := Vector2(78.0, 44.0)','const HALDA := Vector2(88.5, 46.5)','const PRACTICE_BERRY := Vector2(30.0, 8.0)']:
    check('current authoritative clearance anchor '+anchor,anchor in new)
check('new footprint model is cleaned up','model.free()' in nf['_canopy_footprint'])
check('no skip/quarantine',not re.search(r'(?m)^\s*(?:skip|pending|quarantine)\(',new))
trainers=inp('data/config/bands/band1_lower_meadows/trainers.json')['trainers']
practice=next(t for t in trainers if t['id']=='practice_trainer')
check('marking reads actual practice/lawn anchor',practice['position']==after['arena']['centre']==[78,44])
check('three rounds retain existing source positions',all(t['position']==[85,47] for t in trainers if t['id'].startswith('tournament_')))
director=text('inputs/scripts/combat/encounter_director.gd')
check('live null-body fight deployment stays player-relative','return _player.global_position + forward.normalized() * (reach * 2.0)' in director)
production=text('inputs/scripts/world/tournament_ground_presentation.gd')
for token in ['top_level = true','global_transform = Transform3D.IDENTITY','var centre := _xz(spec.get("centre", []))','PRESENTATION_BOUNDS.measure(stall)']:
    check('actual presentation consumer '+token,token in production)
check('presentation still creates no body/area',not any(s in production for s in ['StaticBody3D.new()','CollisionShape3D.new()','Area3D.new()']))
board=inp('data/config/tournament.json')['board']['position']
halda=next(p['position'] for p in inp('data/config/village_npcs.json')['villagers'] if p['name']=='Halda')
berry=next(n for n in inp('data/config/bands/band1_lower_meadows/harvest.json')['nodes'] if n['order']==1031)
check('board unchanged current anchor',board==[85,50])
check('marshal unchanged current anchor',halda==[88.5,46.5])
check('practice berry unchanged identity/anchor',berry['item']=='berries' and berry['at']==[30,8])

# Decode every POSITION vertex, rather than treating declared min/max as proof.
g=inp('assets/props/quaternius_fantasy/Stall_Empty.gltf')
raw=(PACK/'inputs/assets/props/quaternius_fantasy/Stall_Empty.bin').read_bytes()
check('stall root has no transform/skin ambiguity',g['nodes']==[{'mesh':0,'name':'Stall_Empty'}] and len(g['buffers'])==1)
vertices=[]
for primitive in g['meshes'][0]['primitives']:
    accessor=g['accessors'][primitive['attributes']['POSITION']]
    view=g['bufferViews'][accessor['bufferView']]
    check('float32 vertex positions',accessor['componentType']==5126 and accessor['type']=='VEC3' and view['buffer']==0)
    offset=view.get('byteOffset',0)+accessor.get('byteOffset',0);stride=view.get('byteStride',12)
    points=[struct.unpack_from('<fff',raw,offset+i*stride) for i in range(accessor['count'])]
    check('declared accessor bounds match real vertices',all(min(p[i] for p in points)==accessor['min'][i] and max(p[i] for p in points)==accessor['max'][i] for i in range(3)))
    vertices.extend(points)
lo=[min(p[i] for p in vertices) for i in range(3)];hi=[max(p[i] for p in vertices) for i in range(3)]
spec=after['marshal_canopy'];factor=spec['fit_height_m']/(hi[1]-lo[1]);yaw=math.radians(spec['yaw_deg'])
boundary=inp('data/config/village_boundary.json')['outline']['points']
def segment_distance(p,a,b):
    ab=[b[i]-a[i] for i in range(2)];delta=[p[i]-a[i] for i in range(2)]
    t=max(0,min(1,sum(ab[i]*delta[i] for i in range(2))/sum(v*v for v in ab)))
    return math.dist(p,[a[i]+t*ab[i] for i in range(2)])
def inside(p):
    odd=False
    for a,b in zip(boundary,boundary[1:]+boundary[:1]):
        if (a[1]>p[1])!=(b[1]>p[1]) and p[0]<(b[0]-a[0])*(p[1]-a[1])/(b[1]-a[1])+a[0]:odd=not odd
    return odd
def signed_clear(p):
    d=min(segment_distance(p,a,b) for a,b in zip(boundary,boundary[1:]+boundary[:1]))
    return d if inside(p) else -d
def footprint(at):
    return [[at[0]+math.cos(yaw)*x*factor*spec['width_scale']+math.sin(yaw)*z*factor,
             at[1]-math.sin(yaw)*x*factor*spec['width_scale']+math.cos(yaw)*z*factor]
            for x,z in [(lo[0],lo[2]),(hi[0],lo[2]),(hi[0],hi[2]),(lo[0],hi[2])]]
old_corners,new_corners=footprint(before['marshal_canopy']['at']),footprint(spec['at'])
terrain=inp('data/config/terrain_playground.json');lawn=next(f for f in terrain['flats'] if f['centre']==[78,44])
check('existing full-flatten lawn unchanged',lawn['radius']==16 and lawn['height']==.9)
check('old centre fails original2m negative control',signed_clear(before['marshal_canopy']['at'])<2)
check('old full stall crosses actual fence negative control',any(not inside(p) for p in old_corners))
check('new centre retains original2m clearance',signed_clear(spec['at'])>=2)
for i,p in enumerate(new_corners):
    check('actual fitted corner inside with original2m guard '+str(i),signed_clear(p)>=2)
    check('actual fitted corner on unchanged lawn pad '+str(i),math.dist(p,lawn['centre'])<=lawn['radius'])
def footprint_distance(p,corners):return min(segment_distance(p,a,b) for a,b in zip(corners,corners[1:]+corners[:1]))
check('full stall clears unchanged board prompt plus player capsule',footprint_distance(board,new_corners)>2.6+.4+.001)
check('full stall clears actual marshal player capsule',footprint_distance(halda,new_corners)>.4+.001)
check('full stall remains outside marked fight floor',footprint_distance([78,44],new_corners)>max(after['arena']['radius_x_m'],after['arena']['radius_z_m'])+.5)
paths=terrain['paths'];lines=[p['points'] for p in paths['routes']+paths['approaches']]+[b['points'] for b in terrain['trail']['bands'] if b['id']=='band1_lower_meadows']
def roadclear(p):return min(segment_distance(p,a,b) for line in lines for a,b in zip(line,line[1:]))
check('canopy original3.5m real-road guard retained',roadclear(spec['at'])>=3.5)
equipment=after['equipment']
props=next(c['props'] for c in inp('data/config/bands/band1_lower_meadows/props.json')['clusters'] if c.get('name')=='tournament_ground')
for prop in equipment:
    at=prop['at']
    check('equipment actual lawn guard '+prop['name'],math.dist(at,[78,44])>7.15)
    check('equipment actual practice/halda/berry guards '+prop['name'],math.dist(at,[78,44])>=8 and math.dist(at,halda)>=8 and math.dist(at,berry['at'])>=6)
    check('equipment original road/boundary guards '+prop['name'],roadclear(at)>=8 and signed_clear(at)>=2)
    check('equipment existing furniture guard '+prop['name'],all(math.dist(at,p['at'])>=6 for p in props))
lamp=after['equipment_light']['at']
check('standing light original road/boundary/berry guards retained',roadclear(lamp)>=8 and signed_clear(lamp)>=2 and math.dist(lamp,berry['at'])>=6)
log=text('prior-failure/tests.log')
check('original centre failure retained','expected (20.0, 10.0), got (78.0, 44.0)' in log)
check('original fence failure retained','boundary (0.62m)' in log)
geometry={'asset_vertex_bounds':{'min':lo,'max':hi,'decoded_vertices':len(vertices)},'uniform_height_fit':factor,'width_scale':spec['width_scale'],'yaw_deg':spec['yaw_deg'],
 'old':{'at':before['marshal_canopy']['at'],'corners':old_corners,'centre_boundary_m':signed_clear(before['marshal_canopy']['at']),'minimum_signed_corner_boundary_m':min(map(signed_clear,old_corners))},
 'proposal':{'at':spec['at'],'corners':new_corners,'centre_boundary_m':signed_clear(spec['at']),'minimum_signed_corner_boundary_m':min(map(signed_clear,new_corners)),
 'maximum_lawn_extent_m':max(math.dist(p,[78,44]) for p in new_corners),'real_road_centre_clearance_m':roadclear(spec['at']),
 'board_prompt_clearance_m':footprint_distance(board,new_corners),'marshal_capsule_clearance_m':footprint_distance(halda,new_corners),'fight_floor_clearance_m':footprint_distance([78,44],new_corners)},
 'scope':'Static full fitted stall footprint. No Godot render/native contact/arrival/earned proof.'}
result={'classification':'SOURCEPASS' if all(c['passed'] for c in checks) else 'SOURCEFAIL','acceptance':'F17#4 OPEN; original actual failure retained; no engine/CI/new independent review',
 'passed':sum(c['passed'] for c in checks),'total':len(checks),'manifest_sha256':hashlib.sha256((PACK/'manifest.json').read_bytes()).hexdigest(),'geometry':geometry,'checks':checks}
(PACK/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'))
print(json.dumps({k:result[k] for k in ['classification','passed','total','manifest_sha256','geometry']},indent=2))
for c in checks:
    if not c['passed']:print('FAIL',c['name'],c['detail'])
raise SystemExit(0 if result['classification']=='SOURCEPASS' else 1)
