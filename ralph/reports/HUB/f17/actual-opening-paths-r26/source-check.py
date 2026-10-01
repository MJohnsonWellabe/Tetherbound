from pathlib import Path
import json, hashlib, gzip, re, math
P=Path(__file__).resolve().parent; checks=[]
def sha(b): return hashlib.sha256(b).hexdigest()
def ok(name,value):
 if not value: raise AssertionError(name)
 checks.append(name)
def text(n): return (P/n).read_bytes().decode('utf8').replace('\r\n','\n')
def funcs(s):
 lines=s.splitlines(); result={}
 starts=[(i,re.match(r'^(?:static )?func (\w+)\(',line).group(1)) for i,line in enumerate(lines) if re.match(r'^(?:static )?func (\w+)\(',line)]
 for i,name in starts:
  body=[lines[i]]
  for line in lines[i+1:]:
   if line and not line[0].isspace() and not line.startswith('#'): break
   if line.strip() and not line.lstrip().startswith('#'): body.append(line)
  result[name]='\n'.join(body)
 return result
paths=['scripts/player/player_controller.gd','tests/helpers/gate_a_npc_gather_segment.gd',
 'tests/helpers/gate_a_opening_drive.gd','tests/test_player_runaway_velocity_guard.gd',
 'tests/test_gate_a_npc_gather_segment_contract.gd','tests/test_opening_beats.gd']
allowed={'scripts/player/player_controller.gd':{'_apply_movement'},
 'tests/helpers/gate_a_npc_gather_segment.gd':{'_visit_villager','_prove_movement_resumed'},
 'tests/helpers/gate_a_opening_drive.gd':{'_walk_to_and_engage_wild','_drive_body_toward'}}
old={};new={};cases={}
for n in paths:
 old[n]=text('originals/'+n);new[n]=text('proposal/'+n)
 a=funcs(old[n]);b=funcs(new[n])
 for f,body in a.items():
  if f not in allowed.get(n,set()): ok('unchanged original function '+n+'::'+f,body==b.get(f))
 if '/test_' in n:
  ok('all original named test bytes preserved '+n,(P/'proposal'/n).read_bytes().startswith((P/'originals'/n).read_bytes()))
  cases[n]={'original':sum(k.startswith('test_') for k in a),'added':sum(k.startswith('test_') for k in b)-sum(k.startswith('test_') for k in a)}
player='scripts/player/player_controller.gd';segment='tests/helpers/gate_a_npc_gather_segment.gd';drive='tests/helpers/gate_a_opening_drive.gd'
f=funcs(new[player]);prior=funcs(old[player])
ok('only movement policy assignment changed',f['_apply_movement'].replace('floor_stop_on_slope = idle_slope_stop(direction, get_floor_normal(), up_direction)','floor_stop_on_slope = direction == Vector3.ZERO')==prior['_apply_movement'])
ok('exact flat idle policy',f['idle_slope_stop'].endswith('return direction == Vector3.ZERO and not floor_normal.is_equal_approx(up)'))
for token in ['move_and_slide()','PhysicsServer3D.body_test_motion(','global_position =','global_transform =','safe_margin','floor_snap_length','collision_mask','STEP_HEIGHT :=','_max_speed']:
 ok('production mutation/query/ceiling count preserved '+token,new[player].count(token)==old[player].count(token))
engine=text('native-source/character_body_3d.cpp')
ok('exact pinned native character source',sha((P/'native-source/character_body_3d.cpp').read_bytes())=='97f7a62669d7fea06a450be8eecad53d2d1523f4323425af2ac6bf1b19c68383')
ok('native idle recovery cancellation mechanism retained as evidence','bool sliding_enabled = !floor_stop_on_slope;' in engine and 'move_and_collide(parameters, result, false, !sliding_enabled)' in engine and 'if (result.travel.length() <= margin + CMP_EPSILON)' in engine and 'gt.origin -= result.travel;' in engine)
for label,direction,normal,up,wanted in [('actual Tam flat',(0,0,0),(0,1,0),(0,1,0),False),('idle20degree',(0,0,0),(0,math.cos(.35),math.sin(.35)),(0,1,0),True),('active20degree',(0,0,-1),(0,math.cos(.35),math.sin(.35)),(0,1,0),False),('missing normal',(0,0,0),(0,0,0),(0,1,0),True),('rotated up',(0,0,0),(1,0,0),(1,0,0),False)]:
 ok('source policy boundary '+label,(direction==(0,0,0) and normal!=up)==wanted)
f=funcs(new[segment]);prior=funcs(old[segment]);resume=f['_prove_movement_resumed']
ok('only visit context argument changes',f['_visit_villager'].replace('_prove_movement_resumed(door, npc.global_position)','_prove_movement_resumed()')==prior['_visit_villager'])
for token in ['for _i in 120:','for _i in 22:','for _i in 4:','Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)','length() >= 0.3:','_nav.push_once(Vector3.ZERO)','Native opening refused during movement resume','Native opening refused during movement-resume settle','INPUT_OWNER.current(_tree)','locomotion_enabled']:
 ok('original resume contract '+token,token in resume and token in prior['_prove_movement_resumed'])
ok('first indoor candidate only uses aisle', 'if axis == Vector2(0, -1) and aisle.is_finite():' in resume and 'await _nav.step(aisle)' in resume)
ok('remaining original real cardinal requests retained','var requested := basis * Vector3(axis.x, 0.0, axis.y)' in resume and '_nav.push_once(requested)' in resume)
ok('one existing physics frame per candidate iteration',resume.count('await _nav.step(aisle)')==1 and resume.count('await _tree.physics_frame')==3)
ok('same original doorway axis point',f['doorway_resume_goal'].endswith('return door - outward * DOOR_STEP_IN'))
ok('same original inward distance','const DOOR_STEP_IN := 2.2' in new[segment] and 'var step := door.global_position - outward * DOOR_STEP_IN' in f['_exit_through'])
for door,expect in [((44,.85,7),(44,.85,4.8)),((27,.85,5),(27,.85,2.8))]:
 actual=(door[0],door[1],door[2]-2.2);ok('declared original inward goal '+str(door),all(abs(a-b)<1e-12 for a,b in zip(actual,expect)))
f=funcs(new[drive]);prior=funcs(old[drive]);chase=f['_walk_to_and_engage_wild'];driver=f['_drive_body_toward']
start=chase.index('\n\tprint("WILD_APPROACH_FINAL ');stop=chase.index('\n\tprint("wild approach: exhausted',start)
ok('original chase code unchanged except final non-admission record',chase[:start]+chase[stop:]==prior['_walk_to_and_engage_wild'])
for token in ['if int(Engine.get_physics_frames() - started_frame) >= budget:','_wild_offer_ready(target)','SIDESTEP_FRAMES, remaining','await _tap_action("interact")','road_index','_player.is_on_floor()']:
 ok('original chase condition/budget '+token,(chase[:start]+chase[stop:]).count(token)==prior['_walk_to_and_engage_wild'].count(token))
ok('original tutorial total budget2600 retained','_walk_to_and_engage_wild(_wild, 2600)' in new[drive])
ok('driver still consumes requested frame count','for _i in frames:' in driver and driver.count('await _tree.physics_frame')==1)
ok('current body and camera recalculated inside each tick',driver.index('for _i in frames:')<driver.index('point - body.global_position')<driver.index('_rig.call("planar_basis")'))
ok('same joypad axes delivered before each tick',driver.index('_send_axis(JOY_AXIS_LEFT_X, axis.x)')<driver.index('_send_axis(JOY_AXIS_LEFT_Y, axis.y)')<driver.index('Input.flush_buffered_events()')<driver.index('await _tree.physics_frame'))
ok('zero input policy yields instead of early return','return Vector2.ZERO' in f['drive_axis'] and 'if direction.length_squared() < 0.01:' not in driver)
ok('finite nonsingular drive basis','not direction.is_finite() or not basis.is_finite() or absf(basis.determinant()) < 0.00001' in f['drive_axis'])
ok('horizontal camera conversion original semantics','direction.y = 0.0' in f['drive_axis'] and 'basis.inverse() * direction.normalized()' in f['drive_axis'])
ok('no direct movement or physics query added in legacy drive',all(driver.count(t)==prior['_drive_body_toward'].count(t) for t in ['global_position =','global_transform =','PhysicsServer3D','test_move(','move_and_slide(']))
expected={'110548567437':'3f46912ea003e9cefd47da3521a864df94142517957afa5db174d86bdec1256f','110548567544':'63dd06178e65314f8630e5453b321289635d6dbd3a8e3dcf780c7786ee7e2607','110548567294':'5625bfa758a0480fc546df406783c35322faaa9a01bf0058278fa5a87b8238c1'}
for job,sha256 in expected.items():
 raw=gzip.decompress((P/f'ci6173/job-{job}.log.gz').read_bytes());ok('whole actual CI6173 original raw '+job,sha(raw)==sha256)
 ok('actual engine matches pinned source '+job,b'Godot Engine v4.7.stable.official.5b4e0cb0f' in raw)
all_rows=json.loads(text('ci6173/all-observations.json'));failed=json.loads(text('ci6173/failed-observations.json'))
ok('all72 core/full whole native observations retained',sum(x['job'] in ['110548567437','110548567544'] for x in all_rows)==72)
ok('both original complete native failures retained',len(failed)==2 and all(not x['observation']['acceptance'] for x in failed))
tam=next(q['observation'] for q in failed if q['job']=='110548567544');bram=next(q['observation'] for q in failed if q['job']=='110548567437')
ok('actual Tam refused before requested movement',not tam['controller_observation_available'] and tam['actual_delta']==[] and tam['provisional_steering']['source']=='none')
ok('actual Tam native flat floor report',tam['live_contacts'][0]['normal']==[0.0,1.0,0.0] and tam['live_contacts'][0]['collider_shape']==33 and tam['failed_original_pre_sample']['rest_info']['normal']==[0.0,1.0,0.0])
ok('actual full capsule retained',abs(tam['failed_original_pre_sample']['capsule']['height']-1.8)<1e-6 and abs(tam['failed_original_pre_sample']['capsule']['radius']-.4)<1e-6)
a=json.loads(text('actual-analysis.json'));ok('full capsule foot from actual shape query pose',a['tam']['actual_full_capsule_foot_y']==tam['failed_original_pre_sample']['query_pose']['origin'][1]-tam['failed_original_pre_sample']['capsule']['height']/2)
ok('actual Tam raw original guard still rejects',tam['live_recovery_travel'][1]>tam['safe_margin']+1e-5 and a['tam']['nominal_foot_below_sample_plane_m']>0)
ok('reported depth is preserved separately from raw recovery',tam['live_contacts'][0]['depth']<tam['safe_margin'] and not tam['acceptance'])
ok('actual Bram loss of floor still failed',not bram['on_floor'] and not bram['slide_contacts'] and not bram['live_contacts'] and bram['refusal']=='actual production walk lost grounded floor')
ok('no invented sparse tutorial final pose',not a['tutorial']['actual_attempt1_final_pose_available'] and not a['ideal_motion_models_used'])
ok('no geometric admission claims',a['no_native_acceptance'] and 'R9' in a['status'] and 'OPEN' in a['status'])
unchanged=json.loads(text('unchanged-paths.json'));W=P.parents[4]
for n,expected_sha in unchanged.items():ok('unchanged working dependency '+n,sha((W/n).read_bytes())==expected_sha)
nav=(W/'tests/helpers/opening_geometry_navigator.gd').read_bytes()
ok('whole navigator byte preserved from actual R25',sha(nav)=='d078109a915db0c936ca1cb29fce8a7e7f66b1297abf249c5400f71d2183ae3f')
baseline=json.loads(text('baseline-provenance.json'))
ok('six candidate paths byte-match exact CI6173 baseline',all(baseline['paths'][n]['byte_equal'] for n in paths))
for n,method in [('scripts/player/camera_rig.gd','planar_basis'),('scripts/player/player_vitals.gd','move_speed_scale')]:
 ok('required integrated ROOT interface remains unchanged '+n+'::'+method,funcs(text('root-ci-dependencies/'+n))[method]==funcs((W/n).read_bytes().decode('utf8').replace('\r\n','\n'))[method])
for packet in ['mira-initial-overlap-r20','body-motion-corridor-r21','tree-mesh-witness-r22','tree-corridor-r23','tree-fixture-load-r24','mira-native-paths-r25']:
 Q=P.parent/packet
 for n,digest in json.loads((Q/'seal.json').read_bytes())['files'].items():
  if sha((Q/n).read_bytes())!=digest:raise AssertionError('prior immutable evidence '+packet+'/'+n)
 ok('all prior sealed evidence byte preserved '+packet,True)
result={'status':'AUTHOR SOURCE CHECKS PASS; no GD parsing, unit, engine or native run',
 'checks':len(checks),'check_names':checks,'cases':cases,'new_named_cases':sum(c['added'] for c in cases.values()),
 'source_native_actual_arithmetic':a['tam'],'ideal_motion_models_used':False,
 'native_acceptance':False,'criterion':'F17#4 OPEN','R9':'HOLD'}
(P/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode())
print(json.dumps({'source_checks':len(checks),'new_named_cases':result['new_named_cases'],'actual_capsule_foot_deficit_m':a['tam']['nominal_foot_below_sample_plane_m'],'status':result['status']},indent=2))
