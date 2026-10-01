"""R10 author source and planar audit only; no engine or earned proof."""
from pathlib import Path
import hashlib,json,math,re,struct
PACK=Path(__file__).resolve().parent
ROOT=PACK.parents[4]
H=lambda b:hashlib.sha256(b).hexdigest()
checks=[]
def check(name,ok,detail=None): checks.append({'name':name,'passed':bool(ok),'detail':detail})
def read(name): return (PACK/name).read_text(encoding='utf-8').replace('\r\n','\n')
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

def asset_bounds(model):
    base = PACK/'inputs/assets/props/quaternius_fantasy'
    j=json.loads((base/(model+'.gltf')).read_text(encoding='utf-8'))
    check('asset root untransformed '+model, j['nodes'] == [{'mesh':0,'name':model}])
    vertices=[]
    for mesh in j['meshes']:
        for prim in mesh['primitives']:
            accessor=j['accessors'][prim['attributes']['POSITION']]; view=j['bufferViews'][accessor['bufferView']]
            check('real float32 positions '+model, accessor['componentType']==5126 and accessor['type']=='VEC3')
            data=(base/j['buffers'][view['buffer']]['uri']).read_bytes()
            offset=view.get('byteOffset',0)+accessor.get('byteOffset',0); stride=view.get('byteStride',12)
            vs=[struct.unpack_from('<3f',data,offset+i*stride) for i in range(accessor['count'])]
            check('real vertices match declared bounds '+model, all(abs(min(v[k] for v in vs)-accessor['min'][k])<1e-6 and abs(max(v[k] for v in vs)-accessor['max'][k])<1e-6 for k in range(3)))
            vertices.extend(vs)
    return [min(v[k] for v in vertices) for k in range(3)], [max(v[k] for v in vertices) for k in range(3)]

m=json.loads(read('manifest.json'))
for n,e in m['files'].items():
 b=(PACK/n).read_bytes();check('frozen '+n,len(b)==e['bytes'] and H(b)==e['sha256'])
for n,pin in m['unchanged_hub_sha256'].items():check('unchanged live '+n,H((ROOT/n).read_bytes())==pin)
n=m['changed_paths'][0];old=read('originals/'+n);new=read('proposal/'+n);of=functions(old);nf=functions(new)
check('ROOT executed original exact',(PACK/'originals'/n).read_bytes()==(PACK/'root-actual'/n).read_bytes())
check('proposal equals live',(PACK/'proposal'/n).read_bytes()==(ROOT/n).read_bytes())
check('only gather function changed',[k for k in of if of[k]!=nf.get(k)]==['_gather_authored_node'] and set(of)==set(nf))
for k in of:
 if k!='_gather_authored_node':check('original earned function '+k,of[k]==nf[k])
code=lambda s:'\n'.join(x for x in s.splitlines() if x.strip() and not x.lstrip().startswith('#'))
check('single functional line; all actions/assertions exact',code(old).replace('var road := "The Pond" if item_id == "wood" else ("Practice Meadow" if item_id == "stone" else "")','var road := "The Pond" if item_id == "wood" else ""')==code(new))
check('one1800/1.55 approach and wood prefix',nf['_gather_authored_node'].count('_walk_toward(')==1 and 'node.global_position, 1800, 1.55, road, item_id == "wood"' in nf['_gather_authored_node'])
receipt=json.loads(read('prior-failure/receipt.json'));raw=read('prior-failure/native.log');campaign=receipt['campaign_result'];terminal=[json.loads(x.split(' ',1)[1]) for x in raw.splitlines() if x.startswith('OPENING_PRODUCTION_OBSERVATION ')][-1]
check('exact failed source closure',receipt['head']==m['root_actual_head'] and receipt['source_before']==receipt['source_after'])
for n,pin in m['root_actual_input_sha256'].items():check('actual closure input '+n,receipt['source_before'].get(n)==pin)
check('prior failure no credit',not campaign['requested_prefix_passed'] and not campaign['campaign_complete'] and campaign['checkpoints']==[] and campaign['resume']=={})
check('actual unchanged stone goal/hint/floor refusal',terminal['request'][0]==-18 and terminal['request'][2]==6 and terminal['authored_road_hint']=='Practice Meadow' and terminal['refusal']=='actual production walk lost grounded floor' and not terminal['on_floor'] and terminal['live_contacts']==terminal['slide_contacts']==[])
check('actual cap bounds preserved',terminal['queries']==3 and terminal['recoveries']==0 and terminal['safe_margin']==.00100000004749745 and terminal['callback_own_us']<=10000)
check('wood earned and no saver diagnostics','axe equipped, swung, gathered +4 Wood' in raw and 'SAVE_SNAPSHOT_REFUSAL' not in raw)
harvest=json.loads(read('inputs/data/config/bands/band1_lower_meadows/harvest.json'))['nodes'];wood=next(n['at'] for n in harvest if n['order']==3);stone=next(n['at'] for n in harvest if n['order']==6)
check('authored targets',wood==[-8,8] and stone==[-18,6]);path=[wood,stone];corridor=1.55+.4+.001+.25
house=[[-3.2,10.8],[7.2,10.8],[7.2,17.2],[-3.2,17.2]];hd=path_clearance(path,house)
check('house source pinned',all(x in read('inputs/scripts/world/grandpa_house.gd') for x in ['const INNER_W := 9.4','const INNER_D := 5.4','const EXT_HALF_W := 5.0','const EXT_HALF_D := 3.0']) and 'const HOUSE_AT := Vector2(2.0, 14.0)' in read('inputs/scripts/world/playground_world.gd'))
check('arrival disk/capsule/probe clears house',hd>corridor,hd)
props=json.loads(read('inputs/data/config/bands/band1_lower_meadows/props.json'));yard=next(c for c in props['clusters'] if c['order']==1035);geometry={}
for spec in yard['props']:
 lo,hi=asset_bounds(spec['model']);scale=spec['scale'];yaw=math.radians(spec['yaw_deg']);at=spec['at'];corners=[]
 for x,z in [(lo[0],lo[2]),(hi[0],lo[2]),(hi[0],hi[2]),(lo[0],hi[2])]:
  x*=scale;z*=scale;corners.append([at[0]+x*math.cos(yaw)+z*math.sin(yaw),at[1]-x*math.sin(yaw)+z*math.cos(yaw)])
 dist=path_clearance(path,corners);check('arrival corridor clears yard '+spec['name'],dist>corridor,dist);geometry[spec['name']]={'corners':corners,'distance_m':dist,'corridor_clearance_m':dist-corridor}
boundary=json.loads(read('inputs/data/config/village_boundary.json'))['outline']['points'];fd=min(segment_distance(a,b,c,d) for a,b in zip(path,path[1:]) for c,d in zip(boundary,boundary[1:]+boundary[:1]))
check('path inside closed fence',all(contains(boundary,p) for p in path));check('arrival corridor clears fence',fd>corridor,fd)
terrain=json.loads(read('inputs/data/config/terrain_playground.json'));roads={r['label']:r['points'] for r in terrain['paths']['routes']}
check('old first Practice heading east',roads['Practice Meadow'][0]==[20,14] and roads['Practice Meadow'][0][0]>wood[0])
check('negative old first leg crosses house',path_clearance([wood,roads['Practice Meadow'][0]],house)==0)
length=math.dist(wood,stone);check('direct actual goal within180m scope',length<180);check('nominal original1800 budget',length/5*60<1800,length/5*60)
check('stone stays nearest in planar wood arrival disk',length+1.55<min(math.dist(wood,n['at'])-1.55 for n in harvest if n['item']=='stone' and n['order']!=6))
geometry.update({'wood_goal':wood,'stone_goal':stone,'length_m':length,'arrival_corridor_m':corridor,'house_distance_m':hd,'fence_distance_m':fd,'nominal5mps60fps_frames':length/5*60,'scope':'Static named house/yard/fence only; terrain/vegetation/native contact, actual path/time/save and earned acceptance unproved.'})
failed=[c for c in checks if not c['passed']];result={'classification':'SOURCEPASS' if not failed else 'SOURCEFAIL','acceptance':'F17#4 OPEN; original failed verdict retained; author-only/no native or independent proof','passed':len(checks)-len(failed),'total':len(checks),'manifest_sha256':H((PACK/'manifest.json').read_bytes()),'geometry':geometry,'terminal_actual_observation':terminal,'checks':checks}
(PACK/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'));print(json.dumps({'passed':result['passed'],'total':result['total'],'geometry':geometry,'failed':failed},indent=2));raise SystemExit(bool(failed))
