from pathlib import Path
import json,hashlib,gzip,re,math
P=Path(__file__).resolve().parent;W=P.parents[4];checks=[]
def sha(b):return hashlib.sha256(b).hexdigest()
def txt(n):return (P/n).read_bytes().decode('utf8').replace('\r\n','\n')
def ok(n,v):
 if not v:raise AssertionError(n)
 checks.append(n)
def funcs(s):
 lines=s.splitlines();out={}
 for i,line in enumerate(lines):
  m=re.match(r'^(?:static )?func (\w+)\(',line)
  if not m:continue
  body=[line]
  for l in lines[i+1:]:
   if l and not l[0].isspace() and not l.startswith('#'):break
   if l.strip() and not l.lstrip().startswith('#'):body.append(l)
  out[m.group(1)]='\n'.join(body)
 return out
seg='tests/helpers/gate_a_npc_gather_segment.gd';unit='tests/test_gate_a_npc_gather_segment_contract.gd'
old=txt('originals/'+seg);new=txt('proposal/'+seg);a=funcs(old);b=funcs(new)
for n,s in a.items():
 if n not in ['_enter_through','_send_stick']:ok('unchanged original helper '+n,s==b[n])
ok('all14 original named unit cases byte preserved',(P/'proposal'/unit).read_bytes().startswith((P/'originals'/unit).read_bytes()))
ok('two meaningful added cases',sum(n.startswith('test_') for n in funcs(txt('proposal/'+unit)))-sum(n.startswith('test_') for n in funcs(txt('originals/'+unit)))==2)
ok('original900 standoff and1m arrival remain literal','_walk_toward(door.global_position + outward * DOOR_STANDOFF, 900, 1.0, "", false, hints)' in b['_enter_through'])
ok('no arrival waiver','if not arrived or not run_restored:' in b['_enter_through'])
ok('original1200 activation45opening600 inward budgets unchanged',all(s in b['_enter_through'] for s in ['_walk_to_and_activate(prompt, 1200)','for _i in 45:','_walk_toward(step, 600, 0.7)']))
ok('same original route metadata/static helper',b['mira_approach_hint']==a['mira_approach_hint'] and b['_mira_approach_hint']==a['_mira_approach_hint'])
ok('long return only and preference ownership','not hints.has(Vector2(20, -12)) or _player.global_position.z >= -12.0 or bool(_game.get("auto_run"))' in b['_begin_mira_road_run'])
ok('must have actual pad-button binding','not _event_for(&"auto_run", true) is InputEventJoypadButton' in b['_begin_mira_road_run'])
ok('same physical-event path','Input.parse_input_event(event)' in b['_mira_road_run_edge'] and '_event_for(&"auto_run", edge == RoadRunTap.Edge.PRESS) as InputEventJoypadButton' in b['_mira_road_run_edge'])
ok('same left-stick events remain','_send_axis(JOY_AXIS_LEFT_X, x)' in b['_send_stick'] and '_send_axis(JOY_AXIS_LEFT_Y, y)' in b['_send_stick'])
ok('only failed owned toggle suppresses stick','if _mira_run_refused:' in b['_send_stick'])
ok('callback only services physical edges','_mira_road_run_edge(false)' in b['_service_mira_road_run'] and 'PhysicsServer3D' not in b['_service_mira_road_run'])
ok('callback disconnects at completion or failure','_tree.disconnect("physics_frame", Callable(self, "_service_mira_road_run"))' in b['_mira_road_run_edge'])
ok('observed production state decides edges','driving, bool(_game.get("auto_run"))' in b['_mira_road_run_edge'])
ok('refused cleanup uses only unused original ticks','900 - int(Engine.get_physics_frames() - _mira_walk_started)' in b['_finish_mira_road_run'] and 'while _mira_road_run != null and remaining > 0:' in b['_finish_mira_road_run'] and 'remaining -= 1' in b['_finish_mira_road_run'])
ok('pending restoration cannot be accepted','if _mira_road_run != null:' in b['_finish_mira_road_run'] and 'did not finish within the original standoff allowance' in b['_finish_mira_road_run'])
ok('trace is non-admission only','"acceptance": false' in b['_finish_mira_road_run'])
for token in ['PhysicsServer3D','_nav.reset()','_nav.push_once(','_nav.walk_to(','safe_margin','collision_mask','global_position =','global_transform =','velocity =','set_auto_run(','Input.action_press','Input.action_release']:
 ok('no new mutation/query/reset path '+token,new.count(token)==old.count(token))
class_code=new[new.index('class RoadRunTap '):new.index('var _mira_road_run:')]
for token in ['frame - _edge_frame >= 3','frame - _edge_frame >= 5','Phase.ON_GAP if running else Phase.FAILED','Phase.OFF_GAP if not running else Phase.FAILED','frame - _started_frame >= 900 - 3 - 5 - 2','finish or (driving and z >= _cutoff)','return Edge.RELEASE']:
 ok('source input lifecycle '+token,token in class_code)
ok('tap state adds no await/query/actor mutation',all(t not in class_code for t in ['await','PhysicsServer3D','global_position','velocity','_game']))
# Author's pure input-state mirror; boolean production observations are inputs,
# never simulated travel, physics, stamina or native acceptance.
class Tap:
 ARM,ONREL,ONGAP,RUN,OFFREL,OFFGAP,DONE,FAIL=range(8)
 NONE,PRESS,RELEASE=range(3)
 def __init__(self,cutoff=-12):self.p=self.ARM;self.cutoff=cutoff;self.finish=False;self.edge=-1;self.started=-1
 def advance(self,f,z,drive,run):
  if self.p==self.ARM:
   if self.finish or z>=self.cutoff:self.p=self.DONE
   elif drive:
    if run:self.p=self.FAIL
    else:self.p=self.ONREL;self.edge=f;self.started=f;return self.PRESS
  elif self.p==self.ONREL and f-self.edge>=3:self.p=self.ONGAP if run else self.FAIL;self.edge=f;return self.RELEASE
  elif self.p==self.ONGAP and f-self.edge>=5:self.p=self.RUN
  elif self.p==self.OFFREL and f-self.edge>=3:self.p=self.OFFGAP if not run else self.FAIL;self.edge=f;return self.RELEASE
  elif self.p==self.OFFGAP and f-self.edge>=5:self.p=self.DONE
  if self.p==self.RUN and (self.finish or (drive and z>=self.cutoff) or f-self.started>=900-3-5-2):
   if run:self.p=self.OFFREL;self.edge=f;return self.PRESS
   self.p=self.DONE
  return self.NONE
t=Tap();timeline=[(10,-48.6,False,False,0),(10,-48.6,True,False,1),(10,-48.6,True,False,0),(12,-48.4,False,True,0),(13,-48.3,False,True,2),(17,-48,True,True,0),(18,-47.9,True,True,0),(400,-12,True,True,1),(403,-11.8,False,False,2),(408,-11.4,False,False,0),(900,6.65,True,False,0)]
for i,(f,z,d,r,e) in enumerate(timeline):ok('pure tap lifecycle case '+str(i),t.advance(f,z,d,r)==e)
ok('pure lifecycle completed',t.p==t.DONE)
f=Tap();ok('failed on tap begins',f.advance(0,-40,True,False)==1);ok('failed on tap releases',f.advance(3,-40,False,False)==2 and f.p==f.FAIL)
f=Tap();f.advance(0,-40,True,False);f.finish=True
for frame,run,edge in [(3,True,2),(8,True,1),(11,False,2),(16,False,0)]:ok('early refused cleanup edge '+str(frame),f.advance(frame,-40,False,run)==edge)
ok('early refused cleanup completed',f.p==f.DONE)
f=Tap();f.advance(10,-40,True,False);f.advance(13,-40,False,True);f.advance(18,-40,True,True)
for frame,run,edge in [(900,True,1),(903,False,2),(908,False,0)]:ok('original deadline cleanup edge '+str(frame),f.advance(frame,-30,False,run)==edge)
ok('deadline finishes before first-edge plus900',f.p==f.DONE and 908<10+900)
f=Tap();ok('short return does not run',f.advance(0,-11,True,False)==0 and f.p==f.DONE)
f=Tap();f.advance(0,-40,True,False);f.advance(3,-40,False,True);f.advance(8,-40,True,True);f.advance(20,-12,True,True)
ok('unobserved off tap also fails and releases',f.advance(23,-11,False,True)==2 and f.p==f.FAIL)
raw=gzip.decompress((P/'native-failed/smoke.log.gz').read_bytes());ok('entire actual failed raw retained',len(raw)==1394919 and sha(raw)=='ee552a1fd9553539d6e33a3e14709756666e07067d38e236a763dfa9ca3cb7ef')
receipt=json.loads(txt('native-failed/result.json'));ok('actual immutable head exit1 noTO retained',receipt['head']=='c7917ea506d44143c416cecc82d869edda1810c4' and receipt['exit']==1 and not receipt['timed_out'] and receipt['watchdog_seconds']==1200)
rows=json.loads(txt('native-failed/all-observations.json'));ok('all18 sampled full observations preserved',len(rows)==18)
last=rows[-1]['observation'];analysis=json.loads(txt('actual-analysis.json'))
ok('actual900requests2700queries exhausted without refusal',last['frame']==900 and last['requests']==900 and last['total_queries']==2700 and last['refusal']=='' and last['stall_frames']==0)
ok('actual final native floor remains valid',last['on_floor'] and last['checked_start'] and last['live_contacts'][0]['normal']==[0,1,0] and last['live_contacts'][0]['collider_shape']==33 and last['live_recovery_travel'][1]<last['safe_margin'])
ok('actual ordinary5m/s step retained',abs(math.hypot(last['actual_delta'][0],last['actual_delta'][2])-5/60)<1e-5)
ok('actual goal is standoff not diagnosticdoor',last['request']==[27.0,0.849999964237213,7.59999990463257] and analysis['actual_goal_xz_distance_m']>1 and abs(analysis['door_centre_diagnostic_distance_m']-3.49)<.01)
ok('all original sampled observations have passed guards',analysis['all18_observations_guard_passed'])
ok('far actual catch endpoint retained',analysis['actual_first_pre_xz'][0]>38 and analysis['actual_first_pre_xz'][1]<-48)
project=txt('production-input-source/project.godot');player=txt('production-input-source/scripts/player/player_controller.gd');vitals=txt('production-input-source/scripts/player/player_vitals.gd');game=txt('production-input-source/autoload/game_state.gd')
ok('actual auto-run physical button exists','auto_run={' in project and 'button_index":15' in project.split('auto_run={',1)[1].split('\n}',1)[0])
ok('actual production poll toggles via ordinary control','Input.is_action_just_pressed("auto_run")' in player and 'game.call("set_auto_run", not bool(game.get("auto_run")))' in player)
ok('actual production sprint remains stamina gated','_sprinting = wants_run and vitals.can_sprint() and input != Vector2.ZERO' in player and '(_sprint_speed if _sprinting else _walk_speed) * vitals.move_speed_scale()' in player)
ok('actual production stamina spending unchanged','_spend(_sprint_drain * delta * clampf(sprint_efficiency, 0.0, 1.0))' in vitals)
ok('real persistent preference effect acknowledged','table[PREF_AUTO_RUN] = on' in game and 'prefs.call("save")' in game)
ok('no ideal travel-model acceptance',analysis['source_only'] and not analysis['native_acceptance'] and not analysis['ideal_motion_models_used'])
for n,digest in json.loads(txt('unchanged-paths.json')).items():ok('unchanged working dependency '+n,sha((W/n).read_bytes())==digest)
ok('whole guarded navigator unchanged',sha((W/'tests/helpers/opening_geometry_navigator.gd').read_bytes())=='d078109a915db0c936ca1cb29fce8a7e7f66b1297abf249c5400f71d2183ae3f')
ok('whole accepted R26 controller unchanged',sha((W/'scripts/player/player_controller.gd').read_bytes())=='df8b89efa2f5dffd96b46e808662d398b5496aa7cb3d290a436b24f3cd5bfe2e')
unitraw=gzip.decompress((P/'prior-r26-unit-passed/tests.log.gz').read_bytes());ok('actual scoped R26 unit raw preserved',sha(unitraw)=='efbbcfcc4546d159bff85bb2deca69c95569d226e6b7bb7f65776cc7358e5b1c')
for packet in ['mira-initial-overlap-r20','body-motion-corridor-r21','tree-mesh-witness-r22','tree-corridor-r23','tree-fixture-load-r24','mira-native-paths-r25','actual-opening-paths-r26']:
 Q=P.parent/packet
 for n,d in json.loads((Q/'seal.json').read_bytes())['files'].items():
  if sha((Q/n).read_bytes())!=d:raise AssertionError(packet+'/'+n)
 ok('prior immutable seal '+packet,True)
result={'source_checks':len(checks),'check_names':checks,'new_named_cases':2,'original_named_cases_byte_preserved':14,'native_query_or_guard_changes':0,'ideal_motion_model_acceptance':False,'gd_parser_unit_native':'UNRUN by HUB','status':'AUTHOR SOURCE CHECKS PASS; candidate native outcome unproven','F17#4':'OPEN','R9':'HOLD'}
(P/'source-results.json').write_bytes((json.dumps(result,indent=2)+'\n').encode());print(json.dumps({k:v for k,v in result.items() if k!='check_names'},indent=2))
