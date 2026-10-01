import hashlib
import json
import pathlib
import re
import subprocess

BASE = pathlib.Path('D:/tetherbound/redesign-foundations')
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PARENT = 'c54be71c979fc58013e8fc99dff1fba40ddac067'
ROOT_PIN = '85ba143150d08d1e30efe7fc55c7671c2fc02b73'
CI_PIN = '8d3bf7eaadde51ebb18c363aeb47c3233309972c'
SCRATCH = BASE / '.tmp/foundations-ci6170'
REPORT = BASE / 'ralph/reports/FOUNDATIONS/warden-xp-flag-scope-source'
REPORT.mkdir(parents=True, exist_ok=True)
PREFIX = 'reward:trainer:warden_aldis:xp:'
IDS = [PREFIX + '1', PREFIX + '1790841056']

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def sha(data):
    return hashlib.sha256(data).hexdigest()

def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')

checks = []
def check(name, passed):
    assert passed, name
    checks.append({'name': name, 'passed': True})

run = SCRATCH / 'extracted/net-veridian_relic_key-20261001T153750Z'
check('original artifact digest', sha((SCRATCH/'artifact.zip').read_bytes()) == '915c3fa3d04eb97aa9aebea92d52bb2f6dcc4eec01a0bb10c3a8d98ef86da135')
receipt = json.loads((run/'NET_RUN.json').read_bytes())
check('original receipt has no assertion failures or fatal', receipt['failures'] == [] and receipt['fatal'] == '')
lines = (run/'peer-0.log').read_text(encoding='utf-8').splitlines()
errors = []
for index, line in enumerate(lines):
    if line.startswith('ERROR: unscoped flag: '):
        errors.append({'line': index+1, 'id': line.split('ERROR: unscoped flag: ',1)[1], 'raw_stack': lines[index:index+9]})
check('two actual host scope errors exactly bound', [r['id'] for r in errors] == IDS)
check('actual original reload stack retained', all('merged_progression.gd:148' in r['raw_stack'][3] and 'save_game.gd:822' in r['raw_stack'][4] and '_step_save_reload_here' in r['raw_stack'][5] for r in errors))
write('actual-errors.json', {'artifact_id':11174329186, 'zip_sha256':sha((SCRATCH/'artifact.zip').read_bytes()), 'ci_merge_head':CI_PIN, 'run_id':receipt['run_id'], 'assertion_failures':receipt['failures'], 'fatal':receipt['fatal'], 'strict_error_clean':False, 'host_scope_errors':errors, 'original_files':[{'path':p.relative_to(run).as_posix(), 'bytes':p.stat().st_size, 'sha256':sha(p.read_bytes())} for p in sorted(run.rglob('*')) if p.is_file()]})

paths = ['data/progression/flag_scopes.json', 'tests/test_flag_scopes.gd']
bindings = []
for path in paths:
    before = git(BASE, 'show', PARENT+':'+path)
    check('allocated file preimage equals pinned ROOT: '+path, before == git(ROOT, 'show', ROOT_PIN+':'+path))
    check('ROOT working preimage still matches: '+path, (ROOT/path).read_bytes() == before)
    current = (BASE/path).read_bytes()
    bindings.append({'path':path, 'preimage_blob':git(BASE,'rev-parse',PARENT+':'+path).decode().strip(), 'preimage_sha256':sha(before), 'candidate_sha256':sha(current), 'candidate_blob':git(BASE,'hash-object',path).decode().strip()})
    if path.endswith('.json'):
        check('registry bytes differ only by exact Warden XP prefix', current.replace(('      "'+PREFIX+'",\n').encode(), b'', 1) == before)
    else:
        new = current.decode()
        for line in ['const ENCOUNTER_REWARDS := preload("res://scripts/net/encounter_rewards.gd")\n', 'const WORLD_LEDGER := preload("res://scripts/net/world_ledger.gd")\n']:
            new = new.replace(line, '', 1)
        start = new.index('func test_warden_host_journal_xp_receipts_resolve_world()')
        end = new.index('func test_generated_ids_from_their_own_helpers_resolve()', start)
        check('all existing registry test bytes preserved', (new[:start]+new[end:]).encode() == before)
        check('new native test uses actual generators and scope', 'ENCOUNTER_REWARDS.source_for("warden_aldis", "xp")' in current.decode() and 'WORLD_LEDGER.reward_flag(source, peer)' in current.decode())
        check('new native test preserves host/guest guard and actual reload', 'host_only_allowed(receipt, 1, WORLD_LEDGER.HOST_ONLY_FLAG_PREFIXES)' in current.decode() and 'host_only_allowed(receipt, 2, WORLD_LEDGER.HOST_ONLY_FLAG_PREFIXES)' in current.decode() and 'merged.load_data({"flags": receipts})' in current.decode())

before = json.loads(git(BASE,'show',PARENT+':'+paths[0]))
after = json.loads((BASE/paths[0]).read_bytes())
def scope(table, flag):
    # Independent model of documented exact-id then longest-prefix semantics.
    if not flag: return ''
    for kind in ['world','player']:
        if flag in table[kind]['ids']: return kind
    choices = [(prefix,kind) for kind in ['world','player'] for prefix in table[kind]['prefixes'] if flag.startswith(prefix)]
    return max(choices,key=lambda row:len(row[0]))[1] if choices else ''

for flag in IDS:
    check('actual receipt previously undeclared: '+flag, scope(before,flag) == '')
    check('actual receipt declared world: '+flag, scope(after,flag) == 'world')
for kind in ['world','player']:
    check('all exact '+kind+' ids unchanged', after[kind]['ids'] == before[kind]['ids'])
    for flag in before[kind]['ids']:
        assert scope(before,flag) == scope(after,flag), flag
    for prefix in before[kind]['prefixes']:
        assert scope(before,prefix+'source-policy-sample') == scope(after,prefix+'source-policy-sample'), prefix
check('every prior exact id and prefix representative keeps scope', True)
for flag in ['reward:trainer:unregistered:xp:1','reward:trainer:warden_aldi:xp:1','reward:trainer:warden_aldis:coins:1','reward:trainer:warden_aldis:xp','a_flag_nobody_ever_declared','']:
    check('unrelated or incomplete declaration still unknown: '+repr(flag), scope(after,flag) == '')
check('existing player prefixes unchanged', after['player']['prefixes'] == before['player']['prefixes'])
check('all existing registry metadata unchanged', all(after[k] == before[k] for k in before if k not in ['world']))

deps = ['scripts/net/world_ledger.gd','scripts/net/encounter_rewards.gd','autoload/progression_state.gd','autoload/merged_progression.gd','scripts/save/realm_reward_migration.gd','scripts/save/save_game.gd']
dependency_rows = []
for path in deps:
    src = git(ROOT,'show',ROOT_PIN+':'+path)
    check('production dependency untouched in own working tree: '+path, (BASE/path).read_bytes() == git(BASE,'show',PARENT+':'+path))
    dependency_rows.append({'path':path,'root_blob':git(ROOT,'rev-parse',ROOT_PIN+':'+path).decode().strip(),'ci_blob':git(BASE,'rev-parse',CI_PIN+':'+path).decode().strip(),'root_sha256':sha(src)})
ledger = git(ROOT,'show',ROOT_PIN+':scripts/net/world_ledger.gd').decode()
prefixes = re.findall(r'"([^"]+)"', ledger.split('const HOST_ONLY_FLAG_PREFIXES := [',1)[1].split(']',1)[0])
check('existing host-only Warden journal contract exactly bound', 'reward:trainer:warden_aldis:' in prefixes)
check('existing unchanged receipt writer format bound', 'return "reward:%s:%d" % [source, peer_id]' in ledger)
rewards = git(ROOT,'show',ROOT_PIN+':scripts/net/encounter_rewards.gd').decode()
check('existing unchanged trainer component writer format bound', 'return "trainer:%s:%s" % [trainer_id, component]' in rewards)
check('existing unchanged XP grant source uses component', 'source_for(trainer_id, "xp")' in rewards)
def host_allowed(flag, peer):
    return peer == 1 or not any(flag.startswith(prefix) for prefix in prefixes)
for flag in IDS:
    check('host-only policy allows original host: '+flag, host_allowed(flag,1))
    check('host-only policy rejects guest forgery: '+flag, not host_allowed(flag,2))
world_ids = [flag for flag in IDS if scope(after,flag) != 'player']
player_ids = [flag for flag in IDS if scope(after,flag) == 'player']
check('reload policy preserves original receipt ids in world storage', world_ids == IDS and player_ids == [])
write('policy-controls.json', {'kind':'source preservation and independent pure Python scope/host/reload models; no GDScript execution/parser', 'checks':checks, 'count':len(checks)})
write('source-cut.json', {'schema_version':1,'scope':'exact existing Warden host XP receipt declaration plus existing registry test','parent':PARENT,'root_read_pin':ROOT_PIN,'ci_merge_head':CI_PIN,'selected_files':bindings,'read_dependencies':dependency_rows,'verification':{'source_policy_checks_passed':len(checks),'native':'not run; ROOT-owned','criteria':'no MET or strict-error-clean claim'}})
(REPORT/'review_source.py').write_bytes(pathlib.Path(__file__).read_bytes())
patch = git(BASE,'diff','--',*paths)
(SCRATCH/'warden-xp-scope.patch').write_bytes(patch)
subprocess.run(['git','-C',str(ROOT),'apply','--check',str(SCRATCH/'warden-xp-scope.patch')],check=True)
print(json.dumps({'controls_passed':len(checks),'source_cut_sha256':sha((REPORT/'source-cut.json').read_bytes()),'patch_sha256':sha(patch),'root_read_only_apply_check':'PASS'}))
