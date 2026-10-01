"""Independent read-only source audit. Writes only beside this script; no engine."""
from pathlib import Path
import hashlib, json, subprocess, difflib, re

ROOT = Path('D:/tetherbound/redesign-hub')
OUT = Path(__file__).resolve().parent
PACKET = OUT.parent
PARENT = 'f65692df960435918da196301aebac72ac827cfc'
OWNED = 'tests/helpers/opening_geometry_navigator.gd'
SOURCE = '0f52318d89e75a2d4ec486c35d7d78dc953d536f81c3874b6bcfbfe2f50bde1f'
PATCH = '4b09e95dc189ff57eab3c7b429032b1c5ee5e34ad0cbeb8d6fe0f8f350c12150'
H = lambda data: hashlib.sha256(data).hexdigest()
checks = []
def check(name, ok, details=None):
    checks.append({'check': name, 'passed': bool(ok), 'details': details})
def git(*args):
    return subprocess.check_output(['git', *args], cwd=ROOT)
freeze = json.loads((PACKET/'freeze.json').read_bytes())
cause = json.loads((PACKET/'cause-and-constraints.json').read_bytes())
check('pinned HEAD', git('rev-parse','HEAD').decode().strip() == PARENT)
check('pinned branch', git('branch','--show-current').decode().strip() == 'tb/hub')
check('tracked diff scope', git('diff','--name-only').decode().splitlines() == [OWNED])
check('no staged changes', not git('diff','--cached','--name-only').strip())
check('freeze parent and state', freeze['parent'] == PARENT and freeze['state'] == 'FROZEN_SOURCE_CANDIDATE')
actual_packet = {p.relative_to(PACKET).as_posix(): H(p.read_bytes()) for p in PACKET.rglob('*')
                 if p.is_file() and p.name != 'freeze.json' and 'independent' not in p.relative_to(PACKET).parts}
check('exact frozen manifest set and every hash', actual_packet == freeze['files_sha256'], {'files':len(actual_packet)})
check('exact proposal hash', H((PACKET/'proposal'/OWNED).read_bytes()) == SOURCE)
check('exact patch hash', H((PACKET/'opening-production-callback.patch').read_bytes()) == PATCH == freeze['patch_sha256'])
check('live source equals frozen proposal', (ROOT/OWNED).read_bytes() == (PACKET/'proposal'/OWNED).read_bytes())
old = (PACKET/'originals'/OWNED).read_text()
new = (PACKET/'proposal'/OWNED).read_text()
patch = ''.join(difflib.unified_diff((PACKET/'originals'/OWNED).read_bytes().decode().splitlines(True),
                                  (PACKET/'proposal'/OWNED).read_bytes().decode().splitlines(True),
                                  fromfile='a/'+OWNED,tofile='b/'+OWNED)).encode()
check('patch independently regenerated', patch == (PACKET/'opening-production-callback.patch').read_bytes())
for name, pin in cause['before_source_sha256'].items():
    original = (PACKET/'originals'/name).read_bytes()
    check('original pin '+name, H(original) == pin)
    check('original Git equivalence '+name, original.replace(b'\r\n',b'\n') == git('show',PARENT+':'+name).replace(b'\r\n',b'\n'))
    if name != OWNED:
        check('protected live source '+name, H((ROOT/name).read_bytes()) == pin)
archives = cause['archives_sha256']
tracked_archives = git('ls-files','ralph/reports/HUB/f17','ralph/reports/HUB/f18').decode().splitlines()
bad_archives = [name for name,pin in archives.items() if not (ROOT/name).is_file() or H((ROOT/name).read_bytes()) != pin]
check('exact protected archive path set', set(tracked_archives) == set(archives), {'count':len(archives)})
check('all protected archive hashes', not bad_archives, bad_archives)
receipt = json.loads((PACKET/'evidence/receipt.json').read_bytes())
native = (PACKET/'evidence/native.txt').read_text()
check('prior failure retained', receipt['source'] == PARENT and receipt['runs'][1]['native_exit'] == 1
      and H((PACKET/'evidence/native.txt').read_bytes()) == receipt['runs'][1]['raw_sha256']
      and '"requested_prefix_passed":false' in native and 'production observation cooperative callback deadline' in native)
check('prior parser is parent only', receipt['runs'][0]['native_exit'] == 0 and receipt['source_after'][OWNED] != SOURCE)
for name, meta in cause['primary_sources'].items():
    check('official included Godot pin '+name, meta['url'] == 'https://raw.githubusercontent.com/godotengine/godot/4.7-stable/'+name
          and H((PACKET/'api'/name).read_bytes()) == meta['sha256'])
def funcs(text):
    starts = list(re.finditer(r'^func ([\w]+)\([^\n]*',text,re.M))
    result = {}
    for i,m in enumerate(starts):
        end = starts[i+1].start() if i+1<len(starts) else len(text)
        block = text[m.start():end].rstrip()
        # Strip trailing class/variable declarations between outer functions.
        cut = re.search(r'\n(?:class |var |# Opt-in)',block)
        result[m.group(1)] = block[:cut.start()].rstrip() if cut else block
    return result
of,nf = funcs(old),funcs(new)
changed = sorted(k for k in of if of[k] != nf.get(k))
check('only intended outer functions changed', changed == ['_native_tick','_native_tick_impl','_production_observe','_production_record'], changed)
for name in ['_trainer_contract','_registered_body_contract','_motion','_observed_live_clear','_production_contract',
             '_spend','_start_clear_impl','_floor_contacts','_paired_floor_skin','_supported_step_from',
             '_prepare_departure','_choose_route','walk_to','step','push_once','reset','_stop_geometry']:
    check('unchanged physical/default contract '+name, of.get(name) == nf.get(name) and name in of)
for constant,value in [('FRAME_QUERY_US','10000'),('MAX_QUERIES_FRAME','96'),('MAX_QUERIES_LIFETIME','250000'),
                       ('MAX_REQUESTS','24000'),('MAX_PLANS','256'),('CONTACTS','8')]:
    check('unchanged cap '+constant, f'const {constant} := {value}' in old and f'const {constant} := {value}' in new)
gather=(PACKET/'originals/tests/helpers/gate_a_npc_gather_segment.gd').read_text()
team=(PACKET/'originals/tests/helpers/meadows_earned_team_segment.gd').read_text()
stick=(PACKET/'originals/tests/helpers/stick_navigator.gd').read_text()
check('gather/team/retry/stall allowances retained', '1800' in gather and 'const APPROACH_FRAMES := 3600' in team
      and 'const STALL_FRAMES := 26' in stick and 'if _stalled > 90:' in nf['_production_observe'])
check('real motion event seam retained', 'InputEventJoypadMotion.new()' in gather and 'Input.parse_input_event(event)' in gather
      and '_push(direction.normalized()' in nf['_native_tick_impl'] and 'Input.flush_buffered_events()' in nf['_native_tick_impl'])
check('successful own callback accounting includes pre and snapshot', '_pre_observe_us = _production_pre_end - began' in nf['_native_tick']
      and '_deadline = began + maxi(0, FRAME_QUERY_US - _pre_observe_us)' in nf['_production_observe']
      and nf['_production_observe'].index('var record: Dictionary = _production_record()') < nf['_production_observe'].index('if Time.get_ticks_usec() > _deadline:'))
check('bounded record queue and terminal suppression', '_tick.records.size() >= 2' in nf['_production_record']
      and '(refused() and _recorded_failure)' in nf['_production_record'] and '_recorded_failure = true' in nf['_production_observe']
      and 'record["refusal"] = _reason' in nf['_production_observe'])
sink = new[new.index('\tfunc flush_records()'):new.index('\tfunc _physics_process(delta: float)')]
check('deferred sink has no body/native reads', '_body' not in sink and 'PhysicsServer' not in sink and 'JSON.stringify(record)' in sink
      and '_tick.call_deferred("flush_records")' in nf['_production_record'])
check('no serialization in observed callback/snapshot', 'JSON.stringify' not in nf['_production_observe'] and 'JSON.stringify' not in nf['_production_record'])
check('diagnostics explicitly no acceptance', '"acceptance": false' in nf['_production_record'])
check('causal claim distinguishes logging hypothesis', 'hypothesis' in cause['causal_evidence']['callback_logging'])
input_cpp=(PACKET/'api/core/input/input.cpp').read_text()
main_cpp=(PACKET/'api/main/main.cpp').read_text()
tree_cpp=(PACKET/'api/scene/main/scene_tree.cpp').read_text()
check('input queues and explicit flush drains', 'if (use_accumulated_input)' in input_cpp and 'else if (agile_input_event_flushing)' in input_cpp
      and 'void Input::flush_buffered_events()' in input_cpp and '_parse_input_event_impl(e, false)' in input_cpp)
check('official physics priority ordering', 'nodes.sort_custom<Node::ComparatorWithPhysicsPriority>();' in tree_cpp)
check('deferred physics tick location', '_process(true);' in tree_cpp and tree_cpp.index('_process(true);') < tree_cpp.index('MessageQueue::get_singleton()->flush();',tree_cpp.index('_process(true);')))
check('final successful cap guard covers last measured metadata work',
      nf['_production_observe'].rfind('if Time.get_ticks_usec() > _deadline:') > nf['_production_observe'].rfind('record["callback_own_us"]'),
      'Frozen candidate checks deadline before the last two record metadata assignments; its later measured callback_own_us can exceed 10000 while checked_start remains true.')
failed=[r for r in checks if not r['passed']]
report = {'verdict':'SOURCEFAIL' if failed else 'SOURCEPASS', 'scope':'source readiness only; F17#4 OPEN',
          'parent':PARENT,'source_sha256':SOURCE,'patch_sha256':PATCH,'freeze_sha256':H((PACKET/'freeze.json').read_bytes()),
          'review_script_sha256':H(Path(__file__).read_bytes()),'engine_executed':False,'tracked_files_written':False,
          'checks':checks,'failed_checks':failed}
(OUT/'review.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'verdict':report['verdict'],'checks':len(checks),'failed':failed,'archives':len(archives)}))
