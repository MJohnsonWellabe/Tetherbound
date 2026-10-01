"""Author SOURCE geometry checks; no Godot, parser, imports, or native acceptance.
Run from the packet directory. NumPy is the bundled author math dependency.
"""
from pathlib import Path
import hashlib, json, math, re
import numpy as np

P = Path(__file__).resolve().parent
W = P.parents[4]
G = json.loads((P / 'native-failed/tree-geometry.json').read_bytes())
O = np.array(G['target']); V = np.array(G['mesh']['vertices']) - O
I = np.array(G['mesh']['triangle_indices']); A = V[I]
N = np.cross(A[:, 1] - A[:, 0], A[:, 2] - A[:, 0])
N *= np.where(N[:, 1] < 0, -1, 1)[:, None]
N /= np.linalg.norm(N, axis=1)[:, None]
angle = G['settled_start']['floor_max_angle']
walk = N[:, 1] >= math.cos(angle) + .0001
bad = A[~walk][:, :, [0, 2]]
radius = G['settled_start']['player']['shape_data']['radius']
margin = G['settled_start']['safe_margin']
trunk_radius = G['trunk']['shape_data']['radius']
path = np.array([[0, 4], [.7, 4.7], [4.3, 4.7], [4.7, 4.3], [4.7, 2.7], [4.3, 2.3], [1.5, .5]])
path = (O[[0,2]].astype(np.float32) + path.astype(np.float32)).astype(float) - O[[0,2]]
touch_direction = np.array([1.5,.5],dtype=np.float32)
touch_direction /= np.linalg.norm(touch_direction)
touch = (O[[0,2]].astype(np.float32) + touch_direction * (radius + trunk_radius - .002)).astype(float) - O[[0,2]]
checks = []
def check(label, value):
    assert value, label
    checks.append(label)
def cross(a, b): return a[0]*b[1] - a[1]*b[0]
def inside(p, tri):
    signs = [cross(tri[(i+1)%3]-tri[i], p-tri[i]) for i in range(3)]
    return min(signs) >= -1e-11 or max(signs) <= 1e-11
def ptseg(p, a, b):
    v = b-a; n = v@v
    return float(np.linalg.norm(p-a-v*np.clip((p-a)@v/n, 0, 1))) if n else float(np.linalg.norm(p-a))
def intersects(a, b, c, d):
    return (np.all(np.minimum(a,b) <= np.maximum(c,d)) and np.all(np.minimum(c,d) <= np.maximum(a,b))
        and cross(b-a,c-a)*cross(b-a,d-a) <= 0 and cross(d-c,a-c)*cross(d-c,b-c) <= 0)
def segtri(a, b, tri):
    if inside(a, tri) or inside(b, tri): return 0.
    best = math.inf
    for i in range(3):
        c, d = tri[i], tri[(i+1)%3]
        if intersects(a,b,c,d): return 0.
        best = min(best,ptseg(a,c,d),ptseg(b,c,d),ptseg(c,a,b),ptseg(d,a,b))
    return best
def topology(faces):
    if len(faces) != 1176 or not np.isfinite(faces).all(): return False
    heights = {}
    for k, tri in enumerate(faces.reshape((392,3,3))):
        x, z = k//2//14-7, k//2%14-7
        expected = [(x,z),(x+1,z),(x,z+1)] if k%2 == 0 else [(x+1,z),(x+1,z+1),(x,z+1)]
        for p, key in zip(tri, expected):
            if tuple(p[[0,2]]) != key or (key in heights and heights[key] != p[1]): return False
            heights[key] = p[1]
    return len(heights) == 225
def clear(faces, route, clearance):
    if not topology(faces) or len(route)<2 or len(route)>7 or not np.isfinite(route).all() or clearance<=0:
        return False
    if np.max(np.abs(route))+clearance > 7: return False
    triangles=faces.reshape((392,3,3))
    normals=np.cross(triangles[:,1]-triangles[:,0],triangles[:,2]-triangles[:,0])
    if np.any(np.abs(normals[:,1])<.0001): return False
    steep=np.abs(normals[:,1])/np.linalg.norm(normals,axis=1)<math.cos(angle)+.0001
    return all(segtri(a,b,t)>=clearance for t in triangles[steep][:,:,[0,2]] for a,b in zip(route,route[1:]))
def height(p):
    x,z=p; i,j=math.floor(x)+7,math.floor(z)+7
    k=(i*14+j)*2+(0 if x-math.floor(x)+z-math.floor(z)<=1 else 1)
    a=A[k,0]; n=N[k]
    return float(a[1]-(n[0]*(x-a[0])+n[2]*(z-a[2]))/n[1]+O[1])
def exact_ground_length(a,b):
    # Split each straight XZ leg at EVERY projected original mesh edge.
    # Height is affine in each resulting interval, so the 3D chord sum is exact.
    v=b-a; ts={0.,1.}
    for tri in A[:,:,[0,2]]:
        for i in range(3):
            c,d=tri[i],tri[(i+1)%3]; e=d-c; den=cross(v,e)
            if abs(den)<1e-12: continue
            t=cross(c-a,e)/den; u=cross(c-a,v)/den
            if 0<t<1 and -1e-10<=u<=1+1e-10: ts.add(float(t))
    points=[a+v*t for t in sorted(ts)]
    return sum(math.hypot(float(np.linalg.norm(y-x)),height(y)-height(x)) for x,y in zip(points,points[1:]))
def capsule_support(p, effective_radius):
    # Upper envelope of height(q)+sqrt(R^2-|q-p|^2), over ALL triangles.
    # Interior plane stationary point plus concave maxima on each edge.
    # This raises a VIRTUAL upright full capsule; no runtime pose is written.
    best=-math.inf; active=[]
    for k,tri in enumerate(A):
        xy=tri[:,[0,2]]; gradient=-N[k,[0,2]]/N[k,1]
        q=p+effective_radius*gradient/math.sqrt(1+gradient@gradient)
        candidates=[]
        if inside(q,xy): candidates.append((q,float(tri[0,1]+gradient@(q-xy[0]))))
        for i in range(3):
            a,b=xy[i],xy[(i+1)%3]; edge=b-a; length=float(np.linalg.norm(edge)); unit=edge/length
            projection=float((p-a)@unit); perpendicular2=max(0.,float((p-a)@(p-a))-projection**2)
            if perpendicular2>effective_radius**2: continue
            circle=math.sqrt(max(0.,effective_radius**2-perpendicular2))
            lo=max(0.,projection-circle); hi=min(length,projection+circle)
            if lo>hi: continue
            grade=float((tri[(i+1)%3,1]-tri[i,1])/length)
            along=float(np.clip(projection+circle*grade/math.sqrt(1+grade*grade),lo,hi))
            candidates.append((a+unit*along,float(tri[i,1]+grade*along)))
        for q,h in candidates:
            value=h+math.sqrt(max(0.,effective_radius**2-float((q-p)@(q-p))))
            if value>best: best=value; active=[k]
    lower_center=(G['settled_start']['player']['shape_local_pose']['origin'][1]
        -(G['settled_start']['player']['shape_data']['height']/2-radius))
    return best+O[1]-lower_center, active

check('exact native failure log',hashlib.sha256((P/'native-failed/smoke.log').read_bytes()).hexdigest()
    =='7d7de091fbf727de1af2fe9430f8183fe5e3b0566bfc064f98cf0366a7ba72d7')
check('actual geometry complete and not acceptance',G['complete'] and not G['acceptance'])
geometry_lines=[line[len('TREE_GEOMETRY '):] for line in (P/'native-failed/smoke.log').read_text().splitlines()
    if line.startswith('TREE_GEOMETRY ')]
check('geometry paired byte provenance with actual failure log',len(geometry_lines)==1 and json.loads(geometry_lines[0])==G)
check('actual backend class',G['direct_space_state_class']=='GodotPhysicsDirectSpaceState3D')
check('complete original grid topology and shared heights',topology(A.reshape((-1,3))))
check('225 vertices 392 triangles',len(V)==225 and len(I)==392)
for name,body in [('mesh',G['mesh']['terrain']),('trunk',G['trunk']),('player',G['settled_start']['player'])]:
    check(name+' original registered parity',body['complete'] and not body['shape_node_disabled'])
    check(name+' original unit shape basis',body['shape_world_pose']['basis_x']==[1,0,0]
        and body['shape_world_pose']['basis_y']==[0,1,0] and body['shape_world_pose']['basis_z']==[0,0,1])
check('native capsule full height unchanged',G['settled_start']['player']['shape_data']['height']==1.7999999523162842)
check('native capsule full radius unchanged',radius==.4000000059604645)
check('native skin unchanged',margin==.0010000000474974513)
check('native floor angle unchanged',angle==.7853999733924866)
check('fixed original +Z4 start',np.allclose((np.array(G['settled_start']['position'])-O)[[0,2]],[0,4],atol=0,rtol=0))
clearance=radius+margin+.22
check('continuous seven waypoint corridor',clear(A.reshape((-1,3)),path,clearance))
check('continuous final contact ray',clear(A.reshape((-1,3)),np.array([path[-1],touch]),clearance))
check('approach route stays outside same trunk full capsule ring',all(
    ptseg(np.zeros(2),a,b)>radius+trunk_radius+margin for a,b in zip(path,path[1:])))
check('direct bank chord refused',not clear(A.reshape((-1,3)),np.array([path[0],[0,1.12]]),clearance))
check('single facet cannot fit full capsule',radius>(2-math.sqrt(2))/2)
mutants=[]
mutants.append(('missing vertex',A.reshape((-1,3))[:-1]))
f=A.reshape((-1,3)).copy(); f[0]=f[3]; mutants.append(('duplicated face',f))
f=A.reshape((-1,3)).copy(); f[3,1]+=.1; mutants.append(('discontinuous shared height',f))
f=A.reshape((-1,3)).copy(); f[(f[:,0]==4)&(f[:,2]==4),1]+=4; mutants.append(('new steep facet on corridor',f))
f=A.reshape((-1,3)).copy(); f[0,1]=math.inf; mutants.append(('nonfinite mesh',f))
for label,f in mutants: check(label+' refused',not clear(f,path,clearance))
check('mesh boundary refused',not clear(A.reshape((-1,3)),np.array([[0,4],[7,4]]),clearance))
check('capsule-width edge proximity refused',not clear(A.reshape((-1,3)),path,radius+margin+.31))
distances=[min(segtri(a,b,t) for t in bad) for a,b in zip(path,path[1:])]
contact_clearance=min(segtri(path[-1],touch,t) for t in bad)
lengths=[exact_ground_length(a,b) for a,b in zip(path,path[1:])]
final_length=exact_ground_length(path[-1],touch)
grounded_goal,active=capsule_support(touch,radius+margin)
goal_distance=math.hypot(float(np.linalg.norm(touch)),grounded_goal-G['prompt']['global_transform']['origin'][1])
max_gradient=float(np.max(np.linalg.norm(-N[walk][:,[0,2]]/N[walk,1,None],axis=1)))
# Within the .22 tube the union is continuous with bounded gradient; its
# full-capsule support envelope inherits this Lipschitz bound. The vertical
# full capsule fits because the entire fixture is a graph with no overhead.
goal_distance_bound=math.hypot(float(np.linalg.norm(touch))+.22,
    abs(grounded_goal-G['prompt']['global_transform']['origin'][1])+max_gradient*.22)
check('whole capsule goal support finite',math.isfinite(grounded_goal))
check('goal support facets remain floor-like',all(walk[k] for k in active))
check('prompt sphere contains conservative goal tube',goal_distance_bound<G['prompt']['radius'])
trunk_bottom=G['trunk']['shape_world_pose']['origin'][1]-G['trunk']['shape_data']['height']/2
check('vertical full capsule intersects original trunk span',grounded_goal+G['settled_start']['player']['shape_local_pose']['origin'][1]>trunk_bottom)
check('virtual float32 endpoint overlaps same trunk by 2mm within8um',abs(radius+trunk_radius-np.linalg.norm(touch)-.002)<.000008)

def steering_model(terrain):
    # Ideal kinematic model only: original 5m/s, 42m/s^2 acceleration, 60Hz.
    # No wall recovery, snap, friction/contact, deflection, or native claims.
    at=path[0].copy(); velocity=np.zeros(2); index=1; rows=[]; dt=1/60
    for frame in range(1,181):
        while index<len(path) and np.linalg.norm(at-path[index])<=.20: index+=1
        aim=path[index] if index<len(path) else np.zeros(2)
        wanted=aim-at; wanted/=np.linalg.norm(wanted)
        delta=wanted*5-velocity; velocity+=delta*min(1,42*dt/np.linalg.norm(delta)) if np.linalg.norm(delta) else 0
        motion=velocity*dt
        if terrain:
            # Full constant speed on a heightfield; solve scalar advance so
            # 3D distance matches the model speed. This is NOT native sliding.
            lo,hi=0.,1.
            for _ in range(24):
                mid=(lo+hi)/2; endpoint=at+motion*mid
                if math.hypot(np.linalg.norm(motion*mid),height(endpoint)-height(at))>np.linalg.norm(motion): hi=mid
                else: lo=mid
            motion*=lo
        at+=motion
        tracking=min(ptseg(at,a,b) for a,b in zip(path,path[1:])) if index<len(path) else ptseg(at,path[-1],touch)
        # Once inside the trunk contact ring, the model stops; it never tests
        # a collider and cannot assert touched_actual_trunk or activation.
        rows.append({'frame':frame,'xz':at.tolist(),'waypoint_index':index,'tracking_error':tracking})
        if index==len(path) and np.linalg.norm(at)<=radius+trunk_radius: break
    return {'kind':'ideal kinematic SOURCE model only','native_acceptance':False,'terrain_constant_speed':terrain,
        'frames':len(rows),'contact_ring_reached':bool(np.linalg.norm(at)<=radius+trunk_radius),
        'max_tracking_error':max(row['tracking_error'] for row in rows),'rows':rows}
models=[steering_model(False),steering_model(True)]
for model in models:
    check('ideal model reaches within original180 '+str(model['terrain_constant_speed']),model['contact_ring_reached'] and model['frames']<=180)
    check('ideal model tracking fits reserve '+str(model['terrain_constant_speed']),model['max_tracking_error']<=.22)

probe='tools/_probe_scatter_tree_prompt_height.gd'; test='tests/test_vegetation_human_prompt_height.gd'
new=(P/'proposal'/probe).read_text(); old=(P/'originals'/probe).read_text()
test_new=(P/'proposal'/test).read_bytes(); test_old=(P/'originals'/test).read_bytes()
check('original five test cases byte preserved',test_new.startswith(test_old))
check('three new meaningful test cases',len(re.findall(r'^func test_',test_new.decode(),re.M))==8)
check('same 180 approach frame loop',new.count('for frame in 180:')==old.count('for frame in 180:')==1)
for text in ['for frame in 30: await physics_frame','for frame in 8: await physics_frame',
        'for frame in 3: await physics_frame','for frame in 5: await physics_frame']:
    check('original frame budget '+text,text in new and text in old)
check('same number of physics awaits',new.count('await physics_frame')==old.count('await physics_frame'))
for name in ['_build_floor','_fixture_geometry','_registered_geometry','_geometry_vector','_geometry_transform','_axis','_contacts','bank_tangent','_terrain_bank_normal','_approach_sample']:
    def function(text,name):
        m=re.search(r'^(?:static )?func '+name+r'\(',text,re.M); tail=text[m.start():]
        stop=re.search(r'\n(?:static )?func ',tail[1:]); return tail[:stop.start()+1].rstrip() if stop else tail.rstrip()
    # Trailing intervening comments are not function semantics.
    def body(text,name): return function(text,name).split('\n\n##')[0].rstrip()
    check('unchanged '+name,body(new,name)==body(old,name))
check('same native success conjunction',new[new.index('var success: bool'):new.index('world.queue_free()')]
    ==old[old.index('var success: bool'):old.index('world.queue_free()')])
check('same stick event calls',new.count('_axis(JOY_AXIS_LEFT_')==old.count('_axis(JOY_AXIS_LEFT_'))
check('same original fixture pose references',new.count('_player.position')==old.count('_player.position')==4)
assignments=r'^\s*_player\.(?:position|global_position|transform|global_transform|safe_margin|floor_max_angle|collision_mask|collision_layer|velocity)(?:\.[xyz])?\s*=.*$'
check('no body pose or collision parameter writes added',re.findall(assignments,new,re.M)==re.findall(assignments,old,re.M))
check('no added collision query API',not any(api in new for api in ['intersect_shape(','cast_motion(','body_test_motion(','intersect_ray(']))
planner=new[new.index('static func tree_corridor'):new.index('static func corridor_clear')]
literal_offsets=np.array([[float(x),float(z)] for x,z in re.findall(r'Vector2\((\d+\.\d+), (\d+\.\d+)\)',planner)][:6])
check('model route matches exact source waypoint literals',np.array_equal(
    (O[[0,2]].astype(np.float32)+literal_offsets.astype(np.float32)).astype(float)-O[[0,2]],path[1:]))
check('tracking reserve source constant',new.count('const CORRIDOR_TRACKING_ALLOWANCE := 0.22')==1)
check('arrival radius source constant',new.count('const CORRIDOR_WAYPOINT_RADIUS := 0.20')==1)
check('runtime validates both full capsule sweeps',planner.count('radius + margin + CORRIDOR_TRACKING_ALLOWANCE')==2)
check('runtime refuses different radius skin angle or tree',all(s in planner for s in
    ['absf(radius - 0.4)','absf(margin - 0.001)','absf(floor_angle - 0.7854)',
     'absf(trunk_radius - 0.7190233469009399)','or target != TARGET']))
for file,sha in json.loads((P/'unchanged-paths.json').read_bytes()).items():
    check('unchanged dependency '+file,hashlib.sha256((W/file).read_bytes()).hexdigest()==sha)
report={'scope':'AUTHOR SOURCE ONLY; GD/native tests UNRUN; F17#4 OPEN; R9 HOLD',
    'passed_checks':len(checks),'checks':checks,'full_capsule':{'radius':radius,'height':G['settled_start']['player']['shape_data']['height'],
        'skin':margin,'tracking_allowance':.22,'required_swept_clearance':clearance,'floor_max_angle':angle},
    'route':{'offsets_xz':path.tolist(),'leg_min_distance_to_every_steep_triangle':distances,'final_ray_min_distance':contact_clearance,
        'exact_piecewise_ground_3d_leg_lengths':lengths,'exact_piecewise_ground_3d_final_ray_length':final_length,
        'total_piecewise_ground_length_with_final_ray':sum(lengths)+final_length,'ground_length_is_not_native_path_bound':True},
    'whole_capsule_envelope':{'definition':'max over ALL projected faces of height(q)+sqrt((radius+skin)^2-|q-p|^2) minus lower segment center local Y',
        'goal_virtual_node_y':grounded_goal,'goal_active_face_indices':active,'goal_prompt_distance':goal_distance,
        'walkable_union_max_gradient':max_gradient,'goal_prompt_distance_with_tracking_bound':goal_distance_bound,
        'goal_virtual_xz':touch.tolist(),'trunk_bottom':trunk_bottom,'body_pose_writes':0,
        'limits':'continuous height graph / upright full capsule only; no hidden candidate, recovery, native-floor/contact or disabled-server-state completeness claim'},
    'ideal_models':models,'native':'UNRUN locally; retained ROOT R22 FAIL; source models do not assert collision or activation'}
(P/'source-results.json').write_bytes((json.dumps(report,indent=2)+'\n').encode())
print(json.dumps({k:v for k,v in report.items() if k not in ['checks','ideal_models']},indent=2))
print('ideal SOURCE models',[(m['frames'],m['max_tracking_error']) for m in models])
