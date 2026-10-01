"""R8 author source/planar audit. Does not execute Godot or certify traversal."""
from pathlib import Path
import hashlib, json, math, re, struct

PACK = Path(__file__).resolve().parent
ROOT = PACK.parents[4]
H = lambda b: hashlib.sha256(b).hexdigest()
checks = []
def check(name, ok, detail=None):
    checks.append({'name': name, 'passed': bool(ok), 'detail': detail})
def read(name):
    return (PACK/name).read_text(encoding='utf-8').replace('\r\n', '\n')
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

manifest = json.loads(read('manifest.json'))
for name, entry in manifest['files'].items():
    data = (PACK/name).read_bytes()
    check('frozen bytes '+name, len(data) == entry['bytes'] and H(data) == entry['sha256'])
for name, pin in manifest['unchanged_runtime_and_config_sha256'].items():
    check('protected live '+name, H((ROOT/name).read_bytes()) == pin)
for name in manifest['changed_paths']:
    check('proposal equals live '+name, (ROOT/name).read_bytes() == (PACK/'proposal'/name).read_bytes())
    check('ROOT executed original '+name, read('originals/'+name) == read('root-actual/'+name))

navname, gathername, testname = manifest['changed_paths']
oldnav, nav = read('originals/'+navname), read('proposal/'+navname)
oldg, gather = read('originals/'+gathername), read('proposal/'+gathername)
ot, nt = read('originals/'+testname), read('proposal/'+testname)
of, nf, og, ng = functions(oldnav), functions(nav), functions(oldg), functions(gather)
check('only walk_to changed in existing navigator functions', [k for k in of if of[k] != nf.get(k)] == ['walk_to'])
check('only bounded prefix function added', set(nf)-set(of) == {'_road_prefix_to_goal'})
for name in of:
    if name != 'walk_to':
        check('unchanged navigator function '+name, of[name] == nf[name])
check('only gather heading and forwarding change', [k for k in og if og[k] != ng.get(k)] == ['_gather_authored_node', '_walk_toward'])
for name in og:
    if name not in ['_gather_authored_node', '_walk_toward']:
        check('unchanged earned function '+name, og[name] == ng[name])
for name, body in functions(ot).items():
    check('unchanged original contract '+name, functions(nt)[name] == body)

walk = nf['walk_to']
normalized = walk.replace(', end_road_at_goal: bool = false', '')
normalized = normalized.replace('\tif end_road_at_goal and authored_road.is_empty():\n\t\t_stop_geometry("road exit requested without an authored road")\n\t\treturn false\n', '')
normalized = normalized.replace('\t\tif end_road_at_goal:\n\t\t\t_guided_road.assign(_road_prefix_to_goal(_guided_road, _xz(point)))\n\t\t\tif _guided_road.is_empty():\n\t\t\t\t_stop_geometry("missing/malformed bounded authored road prefix")\n\t\t\t\treturn false\n', '')
check('default whole walk exactly original', normalized == of['walk_to'])
def code_only(text):
    return '\n'.join(line for line in text.splitlines() if line.strip() and not line.lstrip().startswith('#'))
old_remainder = oldnav.replace(of['walk_to'], '')
new_remainder = nav.replace(nf['walk_to'], '').replace(nf['_road_prefix_to_goal'], '')
check('all remaining navigator code/caps/callbacks exact', code_only(old_remainder) == code_only(new_remainder))
gather_normalized = ng['_gather_authored_node'].replace('\tvar road := "The Pond" if item_id == "wood" else ("Practice Meadow" if item_id == "stone" else "")\n', '').replace('1800, 1.55, road, item_id == "wood"', '1800, 1.55, "Practice Meadow" if item_id == "stone" else ""')
check('complete original gather actions and assertions exact', code_only(gather_normalized) == code_only(og['_gather_authored_node']))
forward_normalized = ng['_walk_toward'].replace(', end_road_at_goal: bool = false', '').replace(', authored_road, end_road_at_goal)', ', authored_road)')
check('complete original walk forwarding and refusal exact', forward_normalized == og['_walk_toward'])
check('one entire approach budget counter', walk.count('while walked < budget') == walk.count('walked += 1') == 1)
check('one reset before approach only', walk.count('reset()') == 1 and walk.index('reset()') < walk.index('while walked < budget'))
check('gather single original1800/1.55 request', ng['_gather_authored_node'].count('_walk_toward(') == 1 and 'node.global_position, 1800, 1.55, road, item_id == "wood"' in ng['_gather_authored_node'])
check('stone full original road preserved', '"Practice Meadow" if item_id == "stone" else ""' in ng['_gather_authored_node'])
check('prefix forwarded without resets or second walk', ng['_walk_toward'].count('_nav.walk_to(') == 1 and '_nav.walk_to(point, budget, close_enough, authored_road, end_road_at_goal)' in ng['_walk_toward'])
check('prefix supplies authored points only', 'prefix.append(road[index])' in nf['_road_prefix_to_goal'] and 'prefix.append(goal)' not in nf['_road_prefix_to_goal'])
check('prefix validation precedes exit selection', all(token in nf['_road_prefix_to_goal'].split('var exit := 0')[0] for token in ['road.is_empty()', 'road.size() > MAX_ROAD_INPUTS', 'not goal.is_finite()', 'not road[index].is_finite()', 'distance_to(road[index]) > MAX_EDGE']))
check('final exit keeps original edge scope', 'if goal.distance_to(road[exit]) > MAX_EDGE:\n\t\treturn []' in nf['_road_prefix_to_goal'])
check('prefix contains no engine/input/native/pose seam', not any(x in nf['_road_prefix_to_goal'] for x in ['Physics', 'Input.', 'await ', 'global_', '_motion(', '_drive', 'reset(']))
check('absent road still sticky refusal', 'not _authored_roads.has(authored_road)' in walk and 'requested authored road is unavailable in production steering' in walk)
check('malformed prefix is sticky refusal', '_guided_road.is_empty()' in walk and 'missing/malformed bounded authored road prefix' in walk)
check('default predictive API exact', read('inputs/tests/helpers/stick_navigator.gd') == (ROOT/'tests/helpers/stick_navigator.gd').read_text(encoding='utf-8').replace('\r\n', '\n'))

terrain = json.loads(read('inputs/data/config/terrain_playground.json'))
roads = {r['label']: r['points'] for r in terrain['paths']['routes']}
goal = [-8., 8.]
def prefix(road, target):
    if not road or len(road) > 64 or not all(math.isfinite(v) for v in target):
        return []
    for i, p in enumerate(road):
        if len(p) != 2 or not all(isinstance(v, (int, float)) and math.isfinite(v) for v in p):
            return []
        if i and math.dist(road[i-1], p) > 180:
            return []
    exit_index = min(range(len(road)), key=lambda i: math.dist(target, road[i]))
    return road[:exit_index+1] if math.dist(target, road[exit_index]) <= 180 else []
route = prefix(roads['The Pond'], goal)
expected = [[20,14],[20,-12],[-8,-12],[-12.5,6.5]]
check('actual authored prefix exactly pinned', route == expected, route)
check('original road untouched and prefix contiguous', route == roads['The Pond'][:4] and len(roads['The Pond']) == 8)
check('resource target outside road is not inserted into prefix', goal not in route)
check('distant pond omitted', roads['The Pond'][-1] == [-105,115] and roads['The Pond'][-1] not in route)
for name, badroad, badgoal in [('missing', [], goal), ('malformed-pair', [[20]], goal), ('nonfinite-road', [[math.inf,14]], goal), ('nonfinite-goal', route, [math.inf,8]), ('oversize-road', [[i,0] for i in range(65)], goal), ('distant-edge', [[0,0],[181,0]], [0,0]), ('out-of-scope-exit', [[0,0],[10,0]], [191,0])]:
    check('negative model refuses '+name, prefix(badroad,badgoal) == [])
check('negative outsideroute injected coordinate fails exact provenance', route+[goal] != roads['The Pond'][:len(route)+1])
check('negative former full-road detour differs', roads['The Pond'] != expected)
check('new engine unit tests cover absent/malformed/scope inputs', all(x in nt for x in ['Vector2.INF', 'Vector2(191.0, 0.0)', 'Vector2(181.0, 0.0)', 'for index in 65:', 'var empty: Array[Vector2] = []']))

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
props=json.loads(read('inputs/data/config/bands/band1_lower_meadows/props.json'))
yard=next(c for c in props['clusters'] if c['order']==1035)
geometry={}
path=route+[goal]
for spec in yard['props']:
    lo,hi=asset_bounds(spec['model']); scale=spec['scale']; yaw=math.radians(spec['yaw_deg']); at=spec['at']
    corners=[]
    for x,z in [(lo[0],lo[2]),(hi[0],lo[2]),(hi[0],hi[2]),(lo[0],hi[2])]:
        x*=scale;z*=scale;corners.append([at[0]+x*math.cos(yaw)+z*math.sin(yaw),at[1]-x*math.sin(yaw)+z*math.cos(yaw)])
    distance=path_clearance(path,corners)
    check('entire wood path clears yard OBB '+spec['name'], distance > .4+.001+.25, distance)
    geometry[spec['name']]={'corners':corners,'path_distance_m':distance}
    if spec['model']=='Bucket_Wooden_1':
        geometry['terminal_bucket_box_distance_m']=min(point_segment([7.9054102897644,8.9228687286377],a,b) for a,b in zip(corners,corners[1:]+corners[:1]))
# Envelope conservatively includes all ground floor wall/slab boxes from source.
house=[[-3.2,10.8],[7.2,10.8],[7.2,17.2],[-3.2,17.2]]
check('source house dimensions/pose pinned', all(x in read('inputs/scripts/world/grandpa_house.gd') for x in ['const INNER_W := 9.4','const INNER_D := 5.4','const EXT_HALF_W := 5.0','const EXT_HALF_D := 3.0']) and 'const HOUSE_AT := Vector2(2.0, 14.0)' in read('inputs/scripts/world/playground_world.gd'))
house_distance=path_clearance(path,house)
check('entire proposed centreline clears full house envelope', house_distance > .651,house_distance)
check('direct Tam-to-wood crosses house negative control', path_clearance([[26,20],goal],house)==0)
boundary=json.loads(read('inputs/data/config/village_boundary.json'))['outline']['points']
fence_distance=min(segment_distance(a,b,c,d) for a,b in zip(path,path[1:]) for c,d in zip(boundary,boundary[1:]+boundary[:1]))
check('all selected authored nodes and final goal remain inside fence',all(contains(boundary,p) for p in path))
check('entire path avoids closed fence geometry',fence_distance>.651,fence_distance)
nominal_path = [[26,20]] + path
length = sum(math.dist(a,b) for a,b in zip(nominal_path,nominal_path[1:]))
check('nominal path fits original1800frames at5m/s60fps', length/5*60 < 1800,length)
geometry.update({'authored_prefix':route,'actual_wood_goal':goal,'nominal_from_Tam_length_m':length,'nominal_constant5mps_60fps_frames':length/5*60,'house_envelope_clearance_m':house_distance,'fence_centreline_clearance_m':fence_distance,'scope':'Static authored centreline and named yard OBBs only; not native ground, steering envelope, rendered, timing or earned proof.'})

raw=read('prior-failure/native.log')
observations=[json.loads(line.split(' ',1)[1]) for line in raw.splitlines() if line.startswith('OPENING_PRODUCTION_OBSERVATION ')]
terminal=observations[-1]
check('exact floor loss original preserved',terminal['frame']==808 and terminal['requests']==809 and not terminal['on_floor'] and not terminal['on_wall'] and terminal['live_state_phase']=='post' and terminal['live_contacts']==terminal['slide_contacts']==[])
check('exact desired/prospective zero-wall state',terminal['provisional_steering']['wall_normal']==[0.,0.,0.] and terminal['provisional_steering']['retry_choice']==0 and terminal['request'][0]==-8. and terminal['request'][2]==8.)
receipt=json.loads(read('prior-failure/receipt.json'));campaign=receipt['campaign_result']
check('ROOT exact frozen source after run',receipt['head']==manifest['root_actual_head'] and receipt['source_before']==receipt['source_after'])
check('prior fail not earned credit',not campaign['requested_prefix_passed'] and not campaign['campaign_complete'] and campaign['reached']=='road_gate' and campaign['checkpoints']==[] and campaign['resume']=={})
check('successful tool gifts retained in original trace',all(x in raw for x in ['Mira handed over axe, pickaxe and the Basic Orb pattern through dialogue','Tam handed over knife, torch and build hammer through dialogue','Satchel assigned four tools by focused controller input']))
failed=[c for c in checks if not c['passed']]
result={'classification':'SOURCEPASS' if not failed else 'SOURCEFAIL','acceptance':'F17#4 OPEN; immutable original actual floor failure; no engine/independent acceptance credit','passed':len(checks)-len(failed),'total':len(checks),'manifest_sha256':H((PACK/'manifest.json').read_bytes()),'geometry':geometry,'terminal_actual_observation':terminal,'checks':checks}
(PACK/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode('utf-8'))
print(json.dumps({'passed':result['passed'],'total':result['total'],'classification':result['classification'],'geometry':geometry,'failures':failed},indent=2))
raise SystemExit(1 if failed else 0)
