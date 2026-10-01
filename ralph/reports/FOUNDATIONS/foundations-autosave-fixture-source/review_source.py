import copy
import hashlib
import json
import pathlib
import re
import subprocess

BASE = pathlib.Path('D:/tetherbound/redesign-foundations')
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PARENT = '6af251fe8720e859a503830d1a41217c0804fb41'
ROOT_PIN = '85ba143150d08d1e30efe7fc55c7671c2fc02b73'
SCRATCH = BASE / '.tmp/foundations-ci6170'
REPORT = BASE / 'ralph/reports/FOUNDATIONS/foundations-autosave-fixture-source'
REPORT.mkdir(parents=True, exist_ok=True)

def sha(data):
    return hashlib.sha256(data).hexdigest()

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def source(path):
    return git(ROOT, 'show', ROOT_PIN + ':' + path)

def function(text, name):
    start = re.search(r'^(?:static )?func ' + name + r'\(', text, re.M)
    assert start, name
    following = re.search(r'^(?:static )?func ', text[start.end():], re.M)
    return text[start.start():start.end() + following.start() if following else len(text)]

def data(path):
    return json.loads(source(path))

def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')

checks = []
def check(name, passed):
    assert passed, name
    checks.append({'name': name, 'passed': True})

zip_path = SCRATCH / 'artifact.zip'
check('original artifact ZIP digest', sha(zip_path.read_bytes()) == '915c3fa3d04eb97aa9aebea92d52bb2f6dcc4eec01a0bb10c3a8d98ef86da135')
run = SCRATCH / 'extracted/net-foundations-20261001T153343Z'
log = (run / 'peer-0.log').read_text(encoding='utf-8')
refusals = [(i, json.loads(line.split(' ', 1)[1])) for i, line in enumerate(log.splitlines(), 1) if line.startswith('SAVE_SNAPSHOT_REFUSAL ')]
check('one retained host refusal', len(refusals) == 1)
line, refusal = refusals[0]
check('actual production trait refusal', refusal['stage'] == 'redesign_pre_identity' and refusal['errors'] == ['unknown or duplicate taught trait'])
check('rejected exact snapshot string digest', sha(refusal['snapshot_json'].encode()) == refusal['snapshot_sha256'])
snapshot = json.loads(refusal['snapshot_json'])
uid, old_record = next(iter(snapshot['redesign_character']['creatures'].items()))
check('actual duplicate rolled/taught trait', old_record['rolled_traits'] == ['hardy'] and old_record['taught_traits'] == {'1': 'hardy'})
check('actual snapshot already canonicalized loadout', len(old_record) == 12 and old_record['mastery'] == {} and old_record['loadout']['ultimate'] == 'ultimate_terrapup')
raw_files = [{'path': p.relative_to(run).as_posix(), 'bytes': p.stat().st_size, 'sha256': sha(p.read_bytes())} for p in sorted(run.rglob('*')) if p.is_file()]
selected_refusal = {k: v for k, v in refusal.items() if k != 'snapshot_json'}
selected_refusal.update({'raw_log_line': line, 'snapshot_utf8_bytes': len(refusal['snapshot_json'].encode()), 'rejected_creature_record': old_record, 'raw_files': raw_files})
write('actual-refusal.json', selected_refusal)

paths = ['tools/net/peer_runner.gd', 'tests/smoke_net_foundations.gd']
binding = []
for path in paths:
    before = git(BASE, 'show', PARENT + ':' + path)
    root_before = source(path)
    candidate = (BASE / path).read_bytes()
    check('allocated preimage matches pinned ROOT: ' + path, before == root_before)
    check('ROOT working file still pinned: ' + path, (ROOT / path).read_bytes() == root_before)
    (SCRATCH / (pathlib.Path(path).name + '.preimage')).write_bytes(before)
    binding.append({'path': path, 'parent_blob': git(BASE, 'rev-parse', PARENT + ':' + path).decode().strip(), 'root_blob': git(ROOT, 'rev-parse', ROOT_PIN + ':' + path).decode().strip(), 'preimage_sha256': sha(before), 'candidate_sha256': sha(candidate), 'candidate_blob': git(BASE, 'hash-object', path).decode().strip()})
    old, new = before.decode(), candidate.decode()
    if 'peer_runner' in path:
        start, end = 'func _step_foundations_state(', '\nfunc '
        old_start, new_start = old.index(start), new.index(start)
        old_end, new_end = old.find(end, old_start + 1), new.find(end, new_start + 1)
        if old_end < 0: old_end = len(old)
        if new_end < 0: new_end = len(new)
        check('all other peer runner bytes unchanged', old[:old_start] == new[:new_start] and old[old_end:] == new[new_end:])
        old_step, new_step = old[old_start:old_end], new[new_start:new_end]
        old_post, new_post = old_step.index('\telif mode == "roundtrip":'), new_step.index('\telif mode == "roundtrip":')
        check('roundtrip/full equality/all negative modes unchanged', old_step[old_post:] == new_step[new_post:])
        check('fixture values guarded before canonical adoption', new_step.index('canonical.creatures[uid].get(field) != personal.creatures[uid][field]') < new_step.index('local.set("redesign_character", canonical)') < new_post)
        check('real production loadout and trait preflight retained in seed', 'party_loadout_errors(fixture_snapshot.party, canonical, true)' in new_step and 'trait_party_errors(fixture_snapshot.party, canonical)' in new_step)
    else:
        check('all native smoke actions/assertions/budgets unchanged', old[:old.index('func _populated(')] == new[:new.index('func _populated(')])
        check('all original world/personal population checks unchanged', old[old.index('func _populated('):old.index('\tvar creatures:')] == new[new.index('func _populated('):new.index('\tvar creatures:')])

traits = data('data/config/traits.json')
schema = data('data/schema/character_state.schema.json')['properties']['creatures']['additionalProperties']
mastery_cfg = data('data/config/move_mastery.json')
moves = data('data/moves/moves.json')['moves']
species = data('data/creatures/species.json')['species']['terrapup']
learnset = data('data/moves/learnsets.json')['species']['terrapup']
required = schema['required']
defaults = {'cap_level': 10, 'breakthroughs': [], 'evolution_choices': {}, 'rolled_traits': [], 'taught_traits': {}, 'known_moves': [], 'loadout': {'quick': '', 'charged': '', 'utility': '', 'ultimate': ''}, 'mastery': {}, 'best': False}
extensions = {'mastery_receipts', 'loadout_revision', 'loadout_last_edit'}
check('nine original schema fields exactly retained', set(required) == set(defaults) and len(required) == 9)
check('all three exact extensions allowed by existing schema', extensions <= schema['properties'].keys() and schema['additionalProperties'] is False)
check('trait runtime flag stays off', traits['runtime_enabled'] is False)

# Independent Python policy models below exercise data constraints and mutants.
# They do not execute or parse GDScript and are not native/runtime evidence.
def traits_valid(record):
    rolled, taught = record['rolled_traits'], record['taught_traits']
    ids = rolled + list(taught.values())
    # Production trait preflight adopts missing legacy initialization in a
    # detached copy; storage is not rewritten by that validation.
    return record.get('traits_initialized', True) is True and len(ids) == len(set(ids)) and all(x in traits['traits'] for x in ids) and all(k in ['1', '2', '3'] and traits['slot_breakthrough_tiers'][int(k)-1] in record['breakthroughs'] for k in taught)

def rank(uses):
    return sum(uses >= threshold for threshold in mastery_cfg['rank_thresholds'])

def loadout_valid(party, record):
    allowed = set(species['moves'].values()) - {''}
    allowed.update(row['move_id'] for row in learnset['unlocks'] if row.get('level', 10000) <= party['level'] or row.get('breakthrough_tier') in record['breakthroughs'])
    known = party['known_moves']
    if len(known) != len(set(known)) or not set(known) <= allowed or not set(known) <= moves.keys(): return False
    for slot in ['quick', 'charged', 'utility', 'ultimate']:
        move = party['move_' + slot]
        if move and (move not in known or moves[move]['slot'] != slot): return False
    for move, uses in party['move_mastery_uses'].items():
        receipts = party['move_mastery_receipts'].get(move, [])
        if move not in known or not isinstance(uses, int) or not 0 <= uses <= mastery_cfg['rank_thresholds'][-1] or len(receipts) != uses or len(receipts) != len(set(receipts)) or any(not x or len(x) > 160 for x in receipts): return False
    return True

def populated(record):
    return set(record) == set(defaults) | extensions and all(record[k] != v for k, v in defaults.items()) and bool(record['mastery_receipts'])

models = []
for marker in [1, 2]:
    party = copy.deepcopy(snapshot['party'][0])
    uses = marker + 1
    party['move_mastery_uses'] = {'pebble_toss': uses}
    party['move_mastery_receipts'] = {'pebble_toss': [f'fixture:storage-{marker}:pebble_toss:{n}' for n in range(uses)]}
    record = copy.deepcopy(old_record)
    record['taught_traits'] = {'1': 'calm'}
    record['mastery'] = {'pebble_toss': {'uses': uses, 'rank': rank(uses)}}
    record['mastery_receipts'] = copy.deepcopy(party['move_mastery_receipts'])
    check(f'marker{marker} registered distinct unlocked trait', traits_valid(record))
    check(f'marker{marker} actual learnset/default slots/nonzero mastery/unique receipts', loadout_valid(party, record))
    check(f'marker{marker} all nine original fields nondefault plus exact extensions', populated(record))
    check(f'marker{marker} disclosed original mastery uses/rank retained', record['mastery']['pebble_toss'] == {'uses': marker + 1, 'rank': 1})
    check(f'marker{marker} canonical mirror preserves all requested original values', record['known_moves'] == party['known_moves'] and record['loadout'] == {slot: party['move_'+slot] for slot in ['quick', 'charged', 'utility', 'ultimate']})
    for key, value in defaults.items():
        mutant = copy.deepcopy(record); mutant[key] = value
        check(f'marker{marker} missing nondefault {key} refuses', not populated(mutant))
    for key in extensions:
        mutant = copy.deepcopy(record); mutant.pop(key)
        check(f'marker{marker} missing exact extension {key} refuses', not populated(mutant))
    mutant = copy.deepcopy(record); mutant['unlisted_extension'] = True
    check(f'marker{marker} unexpected extension refuses', not populated(mutant))
    for name, mutation in [('duplicate', {'1': 'hardy'}), ('unknown', {'1': 'unknown_trait'}), ('locked', {'2': 'calm'})]:
        mutant = copy.deepcopy(record); mutant['taught_traits'] = mutation
        check(f'marker{marker} {name} taught trait refuses', not traits_valid(mutant))
    mutant = copy.deepcopy(party); mutant['move_mastery_receipts']['pebble_toss'][1] = mutant['move_mastery_receipts']['pebble_toss'][0]
    check(f'marker{marker} duplicate mastery receipt refuses', not loadout_valid(mutant, record))
    mutant = copy.deepcopy(party); mutant['move_mastery_receipts']['pebble_toss'].pop()
    check(f'marker{marker} receipt count mismatch refuses', not loadout_valid(mutant, record))
    mutant = copy.deepcopy(party); mutant['move_quick'] = 'stone_rush'
    check(f'marker{marker} wrong slot refuses', not loadout_valid(mutant, record))
    mutant = copy.deepcopy(party); mutant['known_moves'].append('unregistered_move')
    check(f'marker{marker} unknown move refuses', not loadout_valid(mutant, record))
    models.append({'marker': marker, 'policy_model_record': record})
write('policy-controls.json', {'kind': 'source checks and independent pure Python data-policy models; no GDScript execution/parser', 'checks': checks, 'count': len(checks), 'fixtures': models})
dependencies = ['scripts/save/save_game.gd', 'autoload/game_state.gd', 'scripts/creatures/teaching.gd', 'scripts/creatures/traits.gd', 'scripts/creatures/move_mastery.gd', 'scripts/net/character_record_rules.gd', 'data/config/traits.json', 'data/config/move_mastery.json', 'data/schema/character_state.schema.json', 'data/moves/moves.json', 'data/moves/learnsets.json', 'data/creatures/species.json']
ci = '8d3bf7eaadde51ebb18c363aeb47c3233309972c'
for path, names in [('scripts/creatures/teaching.gd', ['character_loadout_mirror', 'party_loadout_errors']), ('scripts/creatures/traits.gd', ['trait_state_errors', 'initialize_legacy_record', 'normalize_admitted']), ('scripts/save/save_game.gd', ['snapshot', '_redesign_errors']), ('scripts/net/character_record_rules.gd', ['errors'])]:
    ci_source = git(BASE, 'show', ci + ':' + path).decode()
    root_source = source(path).decode()
    for name in names:
        check('actual CI and pinned ROOT relevant function equal: ' + name, function(ci_source, name) == function(root_source, name))
write('policy-controls.json', {'kind': 'source checks and independent pure Python data-policy models; no GDScript execution/parser', 'checks': checks, 'count': len(checks), 'fixtures': models})
write('source-cut.json', {'schema_version': 1, 'scope': 'disclosed foundations storage fixture only', 'parent': PARENT, 'root_read_pin': ROOT_PIN, 'ci_merge_head': ci, 'artifact_id': 11174329186, 'artifact_zip_sha256': sha(zip_path.read_bytes()), 'selected_files': binding, 'root_read_dependencies': [{'path': p, 'blob': git(ROOT, 'rev-parse', ROOT_PIN + ':' + p).decode().strip(), 'ci_blob': git(BASE, 'rev-parse', ci + ':' + p).decode().strip(), 'sha256': sha(source(p))} for p in dependencies], 'verification': {'source_checks_passed': len(checks), 'native': 'not run; ROOT-owned', 'criteria': 'no MET claim'}})
(REPORT / 'review_source.py').write_bytes(pathlib.Path(__file__).read_bytes())
patch = git(BASE, 'diff', '--', *paths)
(SCRATCH / 'fixture-only.patch').write_bytes(patch)
subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(SCRATCH / 'fixture-only.patch')], check=True)
print(json.dumps({'controls_passed': len(checks), 'patch_sha256': sha(patch), 'source_cut_sha256': sha((REPORT/'source-cut.json').read_bytes()), 'root_read_only_apply_check': 'PASS'}))
