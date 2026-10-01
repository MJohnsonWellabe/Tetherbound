"""R21 immutable source analysis. No engine or runtime collision query."""
from pathlib import Path
import hashlib,json,math,re,struct
from fractions import Fraction as F
P=Path(__file__).resolve().parent
checks=[]
def ck(label,value):
 if not value:raise AssertionError(label)
 checks.append(label)
def txt(path):return (P/path).read_text(encoding='utf-8')
def src(path):return txt('native-source/'+path)
def original(path):return txt('originals/'+path)
def f32(x):return struct.unpack('<f',struct.pack('<f',x))[0]
def save(path,obj):(P/path).write_bytes((json.dumps(obj,indent=2)+'\n').encode('utf-8'))
for name,meta in json.loads(txt('native-source/provenance.json')).items():
 data=(P/'native-source'/name).read_bytes()
 ck('exact pinned source '+name,hashlib.sha256(data).hexdigest()==meta['sha256'] and len(data)==meta['bytes'] and '/5b4e0cb0f/' in meta['url'])
space=src('modules/godot_physics_3d/godot_space_3d.cpp')
cull=space.split('int GodotSpace3D::_cull_aabb_for_body',1)[1].split('bool GodotSpace3D::test_body_motion',1)[0]
motion=space.split('bool GodotSpace3D::test_body_motion',1)[1].split('// Assumes a valid collision pair',1)[0]
server=src('modules/godot_physics_3d/godot_physics_server_3d.cpp')
cbk=server.split('void GodotPhysicsServer3D::_shape_col_cbk',1)[1].split('GodotPhysicsServer3D *GodotPhysicsServer3D::godot_singleton',1)[0]
ck('same internal body filter','p_body->collides_with' in cull)
ck('one directional original mask','return p_other->collision_layer & collision_mask;' in src('modules/godot_physics_3d/godot_collision_object_3d.h'))
ck('exceptions in BOTH directions','->has_exception(p_body->get_self()) || p_body->has_exception(' in cull)
ck('self/areas/softbodies removed','== p_body' in cull and 'TYPE_AREA' in cull and 'TYPE_SOFT_BODY' in cull)
ck('hidden candidate cap2048','INTERSECTION_QUERY_MAX = 2048' in src('modules/godot_physics_3d/godot_space_3d.h'))
ck('hidden cap before effective filters',cull.index('cull_aabb(')<cull.index('collides_with('))
ck('no exposed cull completeness','return amount;' in cull and 'INTERSECTION_QUERY_MAX' not in motion)
ck('zero margin clamped','TEST_MOTION_MARGIN_MIN_VALUE 0.0001' in space and 'MAX(p_parameters.margin, TEST_MOTION_MARGIN_MIN_VALUE)' in motion)
ck('minimum depth factor .05','TEST_MOTION_MIN_CONTACT_DEPTH_FACTOR 0.05' in space)
ck('epsilon .00001','#define CMP_EPSILON 0.00001' in src('core/math/math_defs.h'))
ck('whole enabled shape union','p_body->get_shape_count()' in motion and 'body_aabb.merge(p_body->get_shape_aabb(i))' in motion and 'is_shape_disabled(i)' in motion)
ck('original registered whole-body AABB transform','p_parameters.from.xform(p_body->get_inv_transform().xform(body_aabb))' in motion)
ck('margin applied to candidate AABB','body_aabb = body_aabb.grow(margin)' in motion)
ck('recovery pair cap32 independent of contact8','const int max_results = 32;' in motion and 'cbk.max = max_results;' in motion)
ck('recovery attempts4','int recover_attempts = 4;' in motion and 'recover_attempts--;' in motion and 'while (recover_attempts)' in motion)
ck('priority weighted .4 relaxation','* 0.4 * priorities[i] * inv_total_weight' in motion)
ck('residual tolerance and zero-motion exit','depth > min_contact_depth + CMP_EPSILON' in motion and 'recover_motion == Vector3()' in motion)
ck('virtual transform updated, not native body write','body_transform.origin += recover_motion;' in motion and 'p_body->set_transform' not in motion)
ck('initial cull recurs per recovery iteration',motion.index('_cull_aabb_for_body(p_body, body_aabb)')<motion.index('body_aabb.position += recover_motion'))
ck('contact callback capped then replaces deepest','cbk->amount == cbk->max' in cbk and 'min_depth_idx' in cbk and 'cbk->ptr[min_depth_idx * 2 + 0] = p_point_A' in cbk)
ck('replacement does not add saturation signal','cbk->amount++' in cbk and 'saturated' not in cbk)
ck('priority copied only for newly appended slots','while (cbk.amount > priority_amount)' in motion)
ck('recovery traversal loops all CULLED candidates',motion.index('for (int i = 0; i < amount; i++)')<motion.index('recover_motion -=') and 'i < p_parameters.max_collisions' not in motion)
ck('distance stage after recovery','// STEP 2 ATTEMPT MOTION' in motion and motion.index('// STEP 2 ATTEMPT MOTION')>motion.index('while (recover_attempts)'))
ck('distance stage cull same bound','_cull_aabb_for_body(p_body, motion_aabb)' in motion)
ck('contact details are post-recovery','Transform3D ugt = body_transform' in motion and 'ugt.origin += p_parameters.motion * unsafe' in motion)
ck('external cap8 only rest results','rcd.max_results = p_parameters.max_collisions' in motion)
ck('zero requested motion result contains virtual recovery','travel += (body_transform.get_origin() - p_parameters.from.get_origin())' in motion)
ck('false result still can carry recovery','if (!collided && r_result)' in motion and motion.count('travel += (body_transform.get_origin() - p_parameters.from.get_origin())')==2)
ck('server updates queued shapes and does not expose cull flags','_update_shapes();' in server.split('bool GodotPhysicsServer3D::body_test_motion',1)[1].split('PhysicsDirectBodyState3D',1)[0])
nav=original('tests/helpers/opening_geometry_navigator.gd')
ck('both original guard phases retained','_production_live_check(post: bool)' in nav and 'zero-motion recovery exceeds unchanged skin' in nav)
ck('original fixed skin in motion params','params.margin = _body.safe_margin' in nav or 'parameters.margin = _body.safe_margin' in nav)
minimum=F(1,10000);skin=F(f32(.001));delta=skin
ck('shifted minimum-margin AABB can leave original envelope',delta+minimum>skin)
ck('sufficient translation envelope bound less than skin',skin-minimum<skin)
# Simplified one-plane, one contact, equal priority model ONLY. Shows why
# recovery travel and a second recovery are not initial penetration metrics.
pair=json.loads(txt('r20-frozen/source-results.json'))
penetration=F(pair['initial_pair_penetration']['fraction'])
def four(initial_depth,margin):
 threshold=margin/F(20);depth=initial_depth+margin;travel=F(0)
 for _ in range(4):
  if depth<=threshold+F(1,100000):break
  advance=(depth-threshold)*F(2,5);travel+=advance;depth-=advance
 return travel,depth
first,residual=four(penetration,minimum)
second,residual2=four(penetration-first,minimum)
ck('one-plane model travel not initial depth',first!=penetration)
ck('one-plane physically clear before second, yet margin recovers again',first>penetration and second>0)
ck('one-plane virtual combined rise within skin',first+second<skin)
ck('one-plane remaining margin contact after second',residual2>0)
save('body-motion-analysis.json',{'scope':'exact source conclusions plus explicitly simplified one-plane rational model; NO native run','effective_min_margin_m':float(minimum),'recovery_pair_cap':32,'max_recovery_attempts':4,'raw_candidate_cap_before_filters':2048,'external_contact_cap':8,'filters':'other.layer & body.mask; reciprocal RID exceptions; exclude self/areas/soft bodies and original motion exclusions','first_initial_aabb_contained_in_original':True,'second_contained_if_each_translation_axis_at_most':float(skin-minimum),'whole_world_completeness_proven':False,'initial_depth_inferred_from_travel':False,'native_clearance_certified':False,'admission':False,'simplified_one_plane_model':{'input_geometric_pair_depth_m':float(penetration),'first_virtual_travel_m':float(first),'second_virtual_travel_m':float(second),'combined_virtual_travel_m':float(first+second),'remaining_MARGIN_contact_depth_m':float(residual2),'actual_native_result':'UNRUN; not substituted for original raw result'}})
log=txt('r20-frozen/tree-failed/smoke.log')
ck('actual R19 failure raw binding',hashlib.sha256((P/'r20-frozen/tree-failed/smoke.log').read_bytes()).hexdigest()=='0e267141c080a2bca82fbec627606fe35e4db822ad7bb1b4c49be7e96b9626a7')
probe=original('tools/_probe_scatter_tree_prompt_height.gd')
ck('same immutable target','98.15209197998047, 5.79111909866333, -35.932098388671875' in probe)
ck('same exact mesh topology','range(-7, 7)' in probe and '[0, 1, 2, 1, 3, 2]' in probe and 'field.height_at(at.x, at.z)' in probe)
ck('same frame and physical criteria','for frame in 180:' in probe and 'for frame in 30:' in probe and 'for frame in 8:' in probe and 'and touched and int(_player.get("_unstick_count")) == 0' in probe)
target=(98.15209197998047,5.79111909866333,-35.932098388671875)
flatlog=re.sub(r'\s+',' ',log)
samples=[]
for segment in flatlog.split('APPROACH cached sample=')[1:]:
 segment=segment.split('APPROACH cached sample=',1)[0].split('TERRAIN stick turns=',1)[0]
 frame=int(re.search(r'"approach_frame": (\d+)',segment).group(1))
 contacts=[]
 for m in re.finditer(r'"body": "CanonicalLocalTerrain", "position": \(([^)]+)\), "normal": \(([^)]+)\), "depth": ([0-9.eE+-]+)',segment):
  point=tuple(map(float,m[1].split(',')));normal=tuple(map(float,m[2].split(',')))
  x=point[0]-target[0];z=point[2]-target[2];i=math.floor(x);j=math.floor(z)
  fx=x-i;fz=z-j;diag=fx+fz-1
  # Printed contact coordinates are rounded. Boundary associations are
  # uncertain; even an interior association is not frozen vertex geometry.
  stable=min(fx,1-fx,fz,1-fz,abs(diag))>.0001
  norm=math.sqrt(sum(v*v for v in normal));slope=math.degrees(math.acos(max(-1,min(1,normal[1]/norm))))
  contacts.append({'point':point,'normal':normal,'slope_degrees':slope,'reported_depth':float(m[3]),'candidate_facet':[i,j,0 if diag<0 else 1] if stable else None,'facet_association_stable_at_print_precision':stable,'full_facet_geometry_certified':False})
 samples.append({'approach_frame':frame,'contacts':contacts})
ck('all nine actual trace rows parsed',len(samples)==9 and [r['approach_frame'] for r in samples]==[0,1,15,30,60,90,120,150,180])
ck('all parsed contacts are actual cached evidence',all(r['contacts'] for r in samples))
interior={tuple(c['candidate_facet']) for r in samples for c in r['contacts'] if c['candidate_facet'] is not None}
steep={tuple(c['candidate_facet']) for r in samples for c in r['contacts'] if c['candidate_facet'] is not None and c['slope_degrees']>45.000103704}
ck('first actual bank steep at stable interior facet',any(c['slope_degrees']>50 and c['candidate_facet']==[0,2,1] for c in samples[2]['contacts']))
ck('observations do not cover392 triangles',len(interior)<392)
ck('exact392triangles225vertices',14*14*2==392 and 15*15==225)
movement=json.loads(original('data/config/movement.json'))
ck('same configured walk5accel42',movement['locomotion']['walk_speed']==5 and movement['locomotion']['ground_acceleration']==42)
ck('unchanged fullcapsule dimensions','radius = 0.4' in original('scenes/player/player.tscn') and 'height = 1.8' in original('scenes/player/player.tscn'))
radius=f32(.4);trunk_radius=f32(.435*1.6529272198677063);ring=radius+trunk_radius
lower_distance=4-ring;optimistic_distance=5*180/60
inradius=(2-math.sqrt(2))/2
ck('single triangle cannot contain full footprint',inradius<radius)
ck('distance-only lower bound does not refute budget',0<lower_distance<optimistic_distance)
prompt_y=target[1]+f32(1.4)
required_contact_y=prompt_y-math.sqrt(2.6**2-ring**2)
field=original('scripts/world/playground_heightfield.gd')
ck('exact mesh depends on nativeFastNoiseLite','FastNoiseLite.new()' in field and '_hills.get_noise_2d(x, z)' in field and '_rise_relief(x, z)' in field)
config=json.loads(original('data/config/terrain_playground.json'))
ck('fixture lattice different from shipped bake','"vertex_spacing": 2.0' in original('data/config/terrain_playground.json') and 'Vector2(x,z)' in probe)
config_summary={'seed':config['seed'],'hills':config['hills'],'detail':config['detail'],'vertex_spacing':config['vertex_spacing'],'rise_peak0':config['rises']['peaks'][0],'bench_core_width':config['rise_switchback_bench']['core_width_m'],'bench_skirt':config['rise_switchback_bench']['skirt_m']}
save('tree-corridor-analysis.json',{'scope':'native trace associations and necessary geometric/source feasibility bounds only; not a mesh or route certificate','samples':samples,'stable_candidate_facets':sorted(interior),'steep_candidate_facets':sorted(steep),'total_mesh_triangles':392,'total_mesh_vertices':225,'exact_vertices_frozen':False,'exact_facet_grades_known':False,'full_capsule_width_corridor_proven':False,'route_feasible':'UNPROVED; not disproved by distance-only bound','native_success':False,'nominal_contact_ring_radius_m':ring,'direct_planar_distance_lower_bound_m':lower_distance,'optimistic180frame60hz_walk_distance_m':optimistic_distance,'isolated1m_triangle_inradius_m':inradius,'fullcapsule_radius_m':radius,'nominal_contact_ring_offer_requires_player_y_at_least':required_contact_y,'recipe_provenance':config_summary,'same_target_and_mesh':True,'admission':False})
save('source-results.json',{'scope':'AUTHOR SOURCE/EVIDENCE analysis; no engine, parser, native queries or route implementation','checks_passed':len(checks),'checks':checks,'two_body_motion_tests_certify_completeness':False,'general_metric_change':'HOLD','tree_corridor_feasibility':'UNPROVED: full exact225vertex mesh absent; sparse native contacts insufficient','logical_source_changes':0,'R20_immutable':True,'F17_4':'OPEN'})
print(json.dumps({'checks_passed':len(checks),'candidate_facets':len(interior),'steep_candidate_facets':sorted(steep),'minimum_planar_m':lower_distance,'optimistic_distance_m':optimistic_distance,'contact_ring_y_min':required_contact_y,'two_test_certificate':False,'corridor_certificate':False},indent=2))
