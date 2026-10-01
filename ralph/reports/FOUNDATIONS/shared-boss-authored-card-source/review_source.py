"""Source and retained evidence checks only. Never launches Godot."""
import gzip
import hashlib
import json
import pathlib
import re
import subprocess

BASE = pathlib.Path(__file__).resolve().parents[4]
REPORT = pathlib.Path(__file__).resolve().parent
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PIN = '7a76a506beccd51aa04b81ab743b1140e33bfeb2'
RETURN = '68cd25df29'
RETURN_PATH = 'ralph/reports/INTEGRATION/branch-closeout/returned-evidence/ci6173-owner-returns/shared-boss/original-native-return/'
SCRATCH = BASE / '.tmp/shared-boss-7a76'
PATHS = ['scripts/world/trainer_npc.gd', 'tests/test_shared_boss_authored_pipeline.gd']
checks = []

def git(*args):
    return subprocess.check_output(['git', '-C', str(BASE), *args])

def sha(value):
    return hashlib.sha256(value).hexdigest()

def read(path):
    return (BASE / path).read_bytes().replace(b'\r\n', b'\n')

def check(name, condition):
    assert condition, name
    checks.append({'name': name, 'passed': True})

def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')

SCRATCH.mkdir(parents=True, exist_ok=True)
members = []
for name in ['native-return.json', 'NET_RUN.json.gz', 'source-and-runtime-receipt.json.gz'] + [f'native-{i}.log.gz' for i in range(4)]:
    immutable = git('show', RETURN + ':' + RETURN_PATH + name)
    check('retained immutable return ' + name, (SCRATCH / name).read_bytes() == immutable)
    members.append({'path': RETURN_PATH + name, 'bytes': len(immutable), 'sha256': sha(immutable)})
actual = json.loads((SCRATCH / 'native-return.json').read_bytes())
receipt = json.loads(gzip.decompress((SCRATCH / 'source-and-runtime-receipt.json.gz').read_bytes()))
net = json.loads(gzip.decompress((SCRATCH / 'NET_RUN.json.gz').read_bytes()))
check('actual fresh source pin', actual['head'] == receipt['head'] == PIN)
check('actual assertion FAIL without timeout', actual['exit'] == receipt['exit'] == 1 and actual['timed_out'] is False)
check('actual elapsed 231.828 seconds', abs(actual['elapsed_seconds'] - 231.828) < 0.001)
check('all 3253 actual source hashes frozen', receipt['source_before'] == receipt['source_after'] and len(receipt['source_before']) == 3253)
check('actual handles absent', receipt['engine_handles_after'] == '')
check('actual ten failures agree with NET_RUN', actual['actual_failures'] == net['failures'] and len(net['failures']) == 10)
check('actual no fatal error', net['fatal'] == '')
selected = []
for index, row in enumerate(actual['logs']):
    value = gzip.decompress((SCRATCH / row['lossless_log']).read_bytes())
    check('actual full raw log digest ' + str(index), sha(value) == row['sha256'] and len(value) == row['bytes'])
    text = value.decode('utf-8-sig')
    check('actual strict clean log ' + str(index), not re.search(r'(?:SCRIPT )?ERROR:|ObjectDB instances leaked|resources still in use', text))
    check('actual old protected starter refusal absent ' + str(index), 'adopt_starter is not a swap' not in text)
    if index == 0:
        selected = [{'line': i+1, 'text': line} for i, line in enumerate(text.splitlines()) if
                    'retained that SAME UID in actual party/body and host-admitted roster' in line or 'FIRST creature' in line or
                    'SECOND creature' in line or 'no opponent body' in line or
                    'not in a networked fight' in line or 'host 203.270, guest -1.000' in line]
check('actual owned fixture passes for both peers', len([x for x in selected if 'PASS: original starter fixture:' in x['text']]) == 2)
check('actual absent guest body and binding retained', any('no opponent body' in x['text'] for x in selected) and any('not in a networked fight' in x['text'] for x in selected))
write('actual-failure.json', {'evidence_commit': git('rev-parse', RETURN).decode().strip(), 'source_pin': PIN,
    'members': members, 'selected_raw_lines': selected, 'actual_failures': actual['actual_failures'],
    'actual_result': 'FAIL, exit 1, 231.828s, no timeout; four strict clean logs, source frozen, handles gone.',
    'limits': ['Individual record/RPC/card contents and timer interleaving were not logged.',
               'The codec/UID defect below is demonstrated from pinned source/data, not asserted observed wire bytes.',
               'No original smoke pass or criterion/main completion claimed.']})

npc = read(PATHS[0]).decode()
old = git('show', PIN + ':' + PATHS[0]).decode()
addition = '\t\t\tif not creature.known_moves.has({slot}):\n\t\t\t\tcreature.known_moves.append({slot})\n'
inverse = npc
for slot in ['quick', 'charged']:
    fragment = addition.format(slot=slot)
    check('one guarded authored knowledge insertion ' + slot, inverse.count(fragment) == 1)
    inverse = inverse.replace(fragment, '')
comment = ('\t\t# Authored equipment is also knowledge on this NPC instance. The owned\n'
           '\t\t# card codec otherwise refuses the slot and a guest spawns a new UID\n'
           '\t\t# instead of mirroring the host\'s actual trainer creature.\n')
check('one explanatory constructor comment', inverse.count(comment) == 1)
check('complete constructor file inverse', inverse.replace(comment, '') == old)
unchanged = ['scripts/save/water_capture_codec.gd', 'scripts/creatures/teaching.gd',
    'scripts/creatures/creature_instance.gd', 'scripts/creatures/move_mastery.gd', 'scripts/save/save_game.gd',
    'scripts/combat/encounter_director.gd', 'scripts/combat/combat_manager.gd', 'scripts/net/encounter_host.gd',
    'scripts/creatures/shared_opponent_proxy.gd', 'tests/test_stormwood_hosted_combat.gd',
    'tests/smoke_net_shared_boss.gd', 'tests/helpers/net_original_starter_fixture.gd',
    'tools/net/peer_runner.gd', 'tests/test_multiplayer_identity_0912.gd', 'tests/helpers/net_harness.gd',
    'scripts/net/session.gd', 'data/config/trainers.json', 'data/config/bands/band5_stronghold_approach/trainers.json',
    'data/config/combat.json', 'data/config/multiplayer.json', 'data/config/progression.json',
    'data/moves/learnsets.json', 'data/moves/moves.json', 'data/moves/tms.json', 'data/creatures/species.json', 'project.godot']
for path in unchanged:
    check('unchanged policy/control ' + path, read(path) == git('show', PIN + ':' + path))

# Source/data derivation of constructor knowledge; not an execution of Godot's codec.
species = json.loads(read('data/creatures/species.json'))['species']
learnsets = json.loads(read('data/moves/learnsets.json'))['species']
moves = json.loads(read('data/moves/moves.json'))['moves']
tms = json.loads(read('data/moves/tms.json'))['tms']
team = next(x for x in json.loads(read('data/config/bands/band5_stronghold_approach/trainers.json'))['trainers'] if x['id'] == 'warden_aldis')['team']
derived = []
check('actual authored five-member roster', len(team) == 5)
for index, entry in enumerate(team):
    sid = entry['species']
    known = list(dict.fromkeys(x for x in species[sid]['moves'].values() if x))
    for unlock in learnsets[sid]['unlocks']:
        if 'level' in unlock and entry['level'] >= unlock['level'] and unlock['move_id'] not in known:
            known.append(unlock['move_id'])
    before = known.copy()
    overrides = entry.get('moves', {})
    for slot, move in overrides.items():
        check('authored override is a valid slot ' + str(index) + '/' + slot, moves[move]['slot'] == slot)
        check('authored override compatible with canonical TM eligibility ' + str(index) + '/' + slot,
              any(x['move_id'] == move and species[sid]['type'] in x['compatible_types'] for x in tms.values()))
        if move not in known:
            known.append(move)
    check('candidate override knowledge complete ' + str(index), all(move in known for move in overrides.values()))
    check('candidate knowledge unique ' + str(index), len(known) == len(set(known)))
    derived.append({'species_id': sid, 'level': entry['level'], 'authored_override': overrides,
                    'knowledge_before': before, 'knowledge_after': known})
check('first host override absent before correction', 'rock_throw' not in derived[0]['knowledge_before'])
check('second host override absent before correction', 'wind_blade' not in derived[1]['knowledge_before'])
codec = read('scripts/save/water_capture_codec.gd').decode()
teaching = read('scripts/creatures/teaching.gd').decode()
director = read('scripts/combat/encounter_director.gd').decode()
manager = read('scripts/combat/combat_manager.gd').decode()
for name, text, fragment in [
    ('codec gates real encoding through strict validity', codec, 'return payload if _valid(payload) else {}'),
    ('codec invokes canonical semantic preflight', codec, 'TEACHING.party_loadout_errors([payload])'),
    ('equipped unknown move refuses', teaching, 'if not (known as Array).has(raw) or not moves.has(raw) or str(moves.slot(raw))!=slot:'),
    ('director publishes actual NPC codec', director, '"card": WATER_CAPTURE_CODEC.encode(instance as RefCounted)'),
    ('director fallback spawns a fresh local instance', director, 'if card == null and SPECIES.has(species) and level > 0:'),
    ('existing continuation requires installed host UID', manager, 'card.get("uid") != _enemy.get("uid")')]:
    check(name, fragment in text)
write('source-derived-codec-boundary.json', {'pin': PIN, 'derivation': derived,
    'cause': 'Authored NPC slot override absent from constructor knowledge -> strict codec empty card -> legacy species fallback UID -> existing exact-card continuation guard does not arm.',
    'classification': 'Pinned source/data derivation. Candidate real codec/record tests and original native smoke remain pending ROOT.'})

test = read(PATHS[1]).decode()
case = test.split('func _case_authored_warden_record_pipeline()')[1].split('func test_native_authored_warden_record_pipeline()')[0]
check('two complete changed pipeline schedules', 'for gap: float in [0.01, 10.0]:' in case and len(re.findall(r'^\s*assert_\w+\(', case, re.M)) == 28)
for name, fragment in [
    ('actual merged NPC loader', 'TRAINER.team_of(TRAINER.trainer("warden_aldis"))'),
    ('real NPC constructor', 'TRAINER.creature_for(team[0])'),
    ('real strict codec', '"card": CODEC.encode(creature)'),
    ('real host normalizer', 'host.open(1, "meadows", "boss", first_row)'),
    ('real host same-ID round replacement', 'host.set_opponent(id, second_row)'),
    ('real director card decoding', 'director._legacy_opponent_instance(rec.opponent)'),
    ('real director snapshot callback', 'director._rpc_encounter_record(done)'),
    ('real manager resolution clock', 'manager.call("_physics_process", gap)'),
    ('real terminal closure', 'host.close(id)'),
    ('negative unknown move preflight', 'invalid.known_moves.erase(invalid.move_quick)'),
    ('negative slot preflight', 'wrong_slot.move_charged = wrong_slot.move_quick'),
    ('deferred native entry', 'call_deferred("run")'),
    ('unknown exit fails', 'assert_eq(code, 0, combined)'),
    ('strict native ERROR scan', 'combined.contains("ERROR:")'),
    ('strict native leak scan', 'combined.contains("ObjectDB instances leaked")'),
    ('finite new child cap', 'Time.get_ticks_msec() + 60000'),
    ('actual PID cleanup', 'OS.is_process_running(pid)'),
    ('complete changed pipeline assertion count', 'test.assertion_count == 56')]:
    check(name, fragment in test)
check('visual-only body double does not override record/card/manager methods',
      not any('func ' + x in test for x in ['_rpc_encounter_record', '_legacy_opponent_instance', '_refresh_legacy_mirror', 'apply_encounter_record', '_begin_resolve', '_finish']))

patch = git('diff', PIN, '--', *PATHS)
(SCRATCH / 'authored-card.patch').write_bytes(patch)
result = subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(SCRATCH / 'authored-card.patch')], capture_output=True)
check('readonly ROOT patch application preimages', result.returncode == 0)
check('production/test patch exact path scope', set(re.findall(r'^diff --git a/(.*?) b/', patch.decode(), re.M)) == set(PATHS))
write('policy-controls.json', {'source_pin': PIN, 'checks': checks, 'native_executed_here': False,
    'unchanged_controls': unchanged, 'changed_production': [PATHS[0]], 'changed_test': [PATHS[1]],
    'limits': ['56 new controlled native pipeline assertions are source only until ROOT runs them.',
               'Original two-peer default smoke is still required; no inferred packet ordering or timeout waiver.']})
cut = {'source_pin': PIN, 'source_checks': len(checks), 'native_executed_here': False,
       'patch': {'path': str(SCRATCH / 'authored-card.patch'), 'bytes': len(patch), 'sha256': sha(patch)},
       'paths': [{'path': p, 'sha256_lf': sha(read(p)), 'blob': git('hash-object', p).decode().strip()} for p in PATHS],
       'readonly_root_head': subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD']).decode().strip(),
       'readonly_root_apply_check': True}
write('source-cut.json', cut)
print(json.dumps({'checks': len(checks), 'source_cut_sha256': sha((REPORT / 'source-cut.json').read_bytes()), 'native_executed_here': False}))
