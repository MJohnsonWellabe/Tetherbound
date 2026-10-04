import copy
import hashlib
import json
import pathlib
import re
import subprocess

BASE = pathlib.Path('D:/tetherbound/redesign-foundations')
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PARENT = '473b3c117ba7479c85c4a96da086587b92de5e70'
ROOT_PIN = '71d8065ef5aea5a43191d95ee76eb9d14e7a04ba'
CI_PIN = '705556e360f1f84a3cbdb0e0f65996814a59c967'
PATH = 'tests/smoke_stormwood_stormheart_choice.gd'
SCRATCH = BASE / '.tmp/stormheart-choice-ci6172'
REPORT = BASE / 'ralph/reports/FOUNDATIONS/stormheart-choice-fixture-source'
REPORT.mkdir(parents=True, exist_ok=True)

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def src(path):
    return git(ROOT, 'show', ROOT_PIN+':'+path)

def data(path):
    return json.loads(src(path))

def sha(value):
    return hashlib.sha256(value).hexdigest()

def write(name, value):
    (REPORT/name).write_text(json.dumps(value, indent=2)+'\n', encoding='utf-8', newline='\n')

checks = []
def check(name, passed):
    assert passed, name
    checks.append({'name': name, 'passed': True})

raw = (SCRATCH/'original-ci6172-job.log').read_bytes()
check('retained actual job bytes bound', sha(raw) == 'c26d66df0faa9ab583536222240a10bdc2b876b232acf4c4358444cd060b31ed')
lines = raw.decode('utf-8-sig').splitlines()
head_line = next(i for i,line in enumerate(lines) if 'git log -1 --format=%H' in line)
check('actual CI checkout head bound', lines[head_line+1].endswith(CI_PIN))
rows = [(i+1,json.loads(line.split('SAVE_SNAPSHOT_REFUSAL ',1)[1])) for i,line in enumerate(lines) if 'SAVE_SNAPSHOT_REFUSAL ' in line]
check('one actual refusal snapshot', len(rows) == 1)
line, refusal = rows[0]
snapshot_bytes = refusal['snapshot_json'].encode()
check('actual serialized snapshot exact digest', sha(snapshot_bytes) == refusal['snapshot_sha256'] == 'de6d6395c6085c02ef631aded2fd8daa1c70e456b319eb8beef2087f6913d753')
(SCRATCH/'rejected-snapshot.json').write_bytes(snapshot_bytes)
snapshot = json.loads(snapshot_bytes)
check('actual exact refusal stage/error', refusal['stage'] == 'redesign_pre_identity' and refusal['errors'] == ['party[0]: invalid_mastery_document'])
check('actual rejected ordinary stand-in is a renamed Fulgocobra', snapshot['party'][0]['species_id'] == 'stand_in_wild_catch' and snapshot['party'][0]['known_moves'] == snapshot['party'][1]['known_moves'] and snapshot['party'][1]['species_id'] == 'fulgocobra')
check('actual rejected UID differs from real Stormheart', snapshot['party'][0]['uid'] != snapshot['party'][1]['uid'])
error_line = next(i for i,line in enumerate(lines) if 'ERROR: Save refused: invalid redesign state' in line)
check('actual stack reaches original Stormheart save', any('_finish_local_claim' in line for line in lines[error_line:error_line+12]))
check('original CI smoke invocation remains 120 seconds', any('timeout 120s python3 tools/ci/run_godot_smoke.py' in line and PATH in line for line in lines))
selected = {k:v for k,v in refusal.items() if k != 'snapshot_json'}
selected.update({'job_log_sha256':sha(raw),'job_log_bytes':len(raw),'diagnostic_line':line,'snapshot_utf8_bytes':len(snapshot_bytes),'ci_merge_head':CI_PIN,'raw_save_refusal_stack':lines[error_line:error_line+10],'rejected_party':snapshot['party'],'raw_job_original_path':str(ROOT/'.tmp/closeout/ci6172-job-110511919850.log'),'raw_job_retained_path':str(SCRATCH/'original-ci6172-job.log')})
write('actual-refusal.json',selected)

before = git(BASE,'show',PARENT+':'+PATH)
candidate = (BASE/PATH).read_bytes()
check('selected preimage equals reviewed ROOT', before == src(PATH))
check('ROOT working selected file still unchanged', (ROOT/PATH).read_bytes() == before)
old, new = before.decode(), candidate.decode()
start = '\t# A disclosed ordinary catch fixture, with its own authored loadout and UID.\n'
a, b = new.index(start), new.index('\tgame.pending_catch = other_catch\n',new.index(start))
original_fixture = '\tvar other_catch: RefCounted = ending.call("_make_legendary")\n\tother_catch.set("species_id", "stand_in_wild_catch")\n'
check('full-file inverse preserves every original path/assertion/budget', (new[:a]+original_fixture+new[b:]).encode() == before)
check('original await sites and frame counts exactly unchanged', re.findall(r'^.*\bawait\b.*$',old,re.M) == re.findall(r'^.*\bawait\b.*$',new,re.M))
check('all remaining helpers byte-identical', old[old.index('func _two_worlds('):] == new[new.index('func _two_worlds('):])
check('candidate uses actual registered factory with no species rename', 'game.make_creature("terrapup", "Other catch fixture")' in new and 'stand_in_wild_catch' not in new and 'other_catch.set("species_id"' not in new)
check('production codec preflight runs before pending assignment', new.index('var other_payload := CAPTURE_CODEC.encode(other_catch)') < b)
check('real UID validity/codec identity/claim distinction checks precede assignment', all(text in new[a:b] for text in ['valid_uid(other_uid)','str(other_payload.get("uid", "")) == other_uid','other_uid != ENDING.claim_id(ending.get("_local_claim") as Dictionary)']))
check('failed factory cannot produce test success', '_check(other_catch != null' in new[a:b] and 'if other_catch == null:\n\t\t_finish()\n\t\treturn' in new[a:b])

def function(text,name):
    m = re.search(r'^(?:static )?func '+re.escape(name)+r'\(',text,re.M)
    assert m,name
    following = re.search(r'^(?:static )?func ',text[m.end():],re.M)
    return text[m.start():m.end()+following.start() if following else len(text)]

called = [('autoload/game_state.gd',['make_creature']),('autoload/player_state.gd',['make_creature','_species']),('scripts/creatures/creature_instance.gd',['from_species','mint_uid','valid_uid']),('scripts/save/water_capture_codec.gd',['encode','_valid']),('scripts/world/stormwood_ending.gd',['claim_id'])]
for path,names in called:
    own = git(BASE,'show',PARENT+':'+path).decode()
    root = src(path).decode()
    for name in names:
        check('called factory/codec/UID function matches reviewed ROOT: '+name, function(own,name) == function(root,name))

species = data('data/creatures/species.json')['species']
learnsets = data('data/moves/learnsets.json')['species']
moves = data('data/moves/moves.json')['moves']
cfg = data('data/config/move_mastery.json')
check('ordinary fixture registered and not legendary', 'terrapup' in species and 'terrapup' != snapshot['party'][1]['species_id'])
check('original unregistered stand-in absent from catalogue', 'stand_in_wild_catch' not in species)

# Independent Python data-policy models only; not GDScript execution/parser.
def allowed(saved):
    definition = species.get(saved['species_id'],{})
    result = set(definition.get('moves',{}).values()) - {''}
    for unlock in learnsets.get(saved['species_id'],{}).get('unlocks',[]):
        if 'level' in unlock and saved['level'] >= unlock['level']:
            result.add(unlock['move_id'])
    return result

def valid(saved):
    known, uses, receipts = saved['known_moves'], saved['move_mastery_uses'], saved['move_mastery_receipts']
    if saved['species_id'] not in species or len(set(known)) != len(known) or not set(known) <= allowed(saved) or not set(known) <= moves.keys(): return False
    for slot in ['quick','charged','utility','ultimate']:
        move = saved['move_'+slot]
        if move and (move not in known or moves[move]['slot'] != slot): return False
    for move,count in uses.items():
        if move not in known or not isinstance(count,int) or not 0 <= count <= cfg['rank_thresholds'][-1]: return False
        history = receipts.get(move,[])
        if len(history) != count or len(set(history)) != len(history): return False
    for move,history in receipts.items():
        if move not in known or len(history) != uses.get(move,0) or len(set(history)) != len(history): return False
    return True

ordinary = copy.deepcopy(snapshot['party'][0])
ordinary['species_id'] = 'terrapup'
ordinary['level'] = 1
ordinary['uid'] = 'creature-0123456789abcdef0123456789abcdef'
definition = species['terrapup']
known = []
for slot in ['quick','charged','utility','ultimate']:
    move = definition['moves'].get(slot,'')
    ordinary['move_'+slot] = move
    if move and move not in known: known.append(move)
for unlock in learnsets['terrapup']['unlocks']:
    if 'level' in unlock and unlock['level'] <= 1 and unlock['move_id'] not in known: known.append(unlock['move_id'])
ordinary['known_moves'] = known
ordinary['move_mastery_uses'] = {}
ordinary['move_mastery_receipts'] = {}
check('actual rejected renamed Fulgocobra refuses policy', not valid(snapshot['party'][0]))
check('actual real Fulgocobra remains valid policy', valid(snapshot['party'][1]))
check('ordinary authored level1 defaults/knowledge/mastery valid policy', valid(ordinary))
check('ordinary model UID well-formed and distinct; not native UID evidence', re.fullmatch(r'creature-[0-9a-f]{32}',ordinary['uid']) is not None and ordinary['uid'] != snapshot['party'][1]['uid'])
mutant = copy.deepcopy(ordinary);mutant['species_id'] = 'stand_in_wild_catch'
check('unregistered identity still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['known_moves'] = snapshot['party'][0]['known_moves']
check('borrowed legendary knowledge still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['known_moves'].append(mutant['known_moves'][0])
check('duplicate known move still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['move_quick'] = 'stone_rush'
check('wrong equipped slot still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['move_mastery_uses'] = {'pebble_toss':1}
check('mastery use without receipt still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['move_mastery_uses'] = {'pebble_toss':2};mutant['move_mastery_receipts'] = {'pebble_toss':['fixture:a','fixture:a']}
check('replayed mastery receipt still refuses', not valid(mutant))
mutant = copy.deepcopy(ordinary);mutant['move_mastery_uses'] = {'pebble_toss':-1}
check('negative mastery still refuses', not valid(mutant))
for key,value in [('known_moves',[]),('move_mastery_uses',{'unregistered_move':0})]:
    mutant = copy.deepcopy(ordinary);mutant[key] = value
    check('incompatible mastery knowledge mutation refuses: '+key,not valid(mutant))

dependencies = [path for path,names in called]+['scripts/creatures/teaching.gd','scripts/creatures/move_mastery.gd','scripts/save/save_game.gd','data/creatures/species.json','data/moves/learnsets.json','data/moves/moves.json','data/config/move_mastery.json']
dependency_rows = []
for path in dependencies:
    check('production dependency untouched locally: '+path,(BASE/path).read_bytes() == git(BASE,'show',PARENT+':'+path))
    dependency_rows.append({'path':path,'reviewed_root_blob':git(ROOT,'rev-parse',ROOT_PIN+':'+path).decode().strip(),'reviewed_root_sha256':sha(src(path))})
write('policy-controls.json',{'kind':'source checks and independent pure Python data-policy models; no GDScript execution/parser','count':len(checks),'checks':checks,'ordinary_policy_model_selected_loadout':{k:ordinary[k] for k in ['species_id','level','uid','known_moves','move_quick','move_charged','move_utility','move_ultimate','move_mastery_uses','move_mastery_receipts']}})
write('source-cut.json',{'schema_version':1,'scope':'existing Stormheart choice ordinary pending-catch fixture only','parent':PARENT,'reviewed_root_pin':ROOT_PIN,'actual_ci_merge':CI_PIN,'actual_job_log_sha256':sha(raw),'selected_file':{'path':PATH,'preimage_blob':git(BASE,'rev-parse',PARENT+':'+PATH).decode().strip(),'preimage_sha256':sha(before),'candidate_blob':git(BASE,'hash-object',PATH).decode().strip(),'candidate_sha256':sha(candidate)},'dependencies':dependency_rows,'dependency_merge':'not needed: invoked factory/codec/UID functions identical to reviewed ROOT','verification':{'source_policy_checks_passed':len(checks),'native':'not run; ROOT original120s smoke pending','criterion_credit':False}})
(REPORT/'review_source.py').write_bytes(pathlib.Path(__file__).read_bytes())
(SCRATCH/'selected-preimage.gd').write_bytes(before)
patch = git(BASE,'diff','--',PATH)
(SCRATCH/'fixture-only.patch').write_bytes(patch)
subprocess.run(['git','-C',str(ROOT),'apply','--check',str(SCRATCH/'fixture-only.patch')],check=True)
print(json.dumps({'controls_passed':len(checks),'source_cut_sha256':sha((REPORT/'source-cut.json').read_bytes()),'patch_sha256':sha(patch),'read_only_root_apply_check':'PASS'}))
