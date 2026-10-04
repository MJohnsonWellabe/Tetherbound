"""Source, byte and retained actual-evidence checks. Never executes Godot."""
import hashlib
import json
import math
import pathlib
import re
import subprocess

BASE = pathlib.Path(__file__).resolve().parents[4]
REPORT = pathlib.Path(__file__).resolve().parent
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PIN = '9696b2c3286209b825428ec0b3d8ee548e907503'
RAW = BASE / '.tmp/shared-boss-9696'
ORIGINAL = ROOT / '.tmp/closeout/returned-net-9696b2c32862-shared_boss'
PATHS = ['tests/smoke_net_shared_boss.gd', 'tools/net/peer_runner.gd', 'tests/test_net_boss_snapshot.gd']
checks = []

def git(*args):
    return subprocess.check_output(['git', '-C', str(BASE), *args])

def read(path):
    return (BASE / path).read_bytes().replace(b'\r\n', b'\n')

def old(path):
    return git('show', PIN + ':' + path)

def sha(value):
    return hashlib.sha256(value).hexdigest()

def check(name, value):
    assert value, name
    checks.append({'name': name, 'passed': True})

def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')

def function(text, name):
    return re.search(r'^(?:static )?func ' + re.escape(name) + r'\([^\n]*\n(?:\t[^\n]*\n|\n)*', text, re.M).group(0).rstrip()

receipt_raw = (RAW / 'receipt.json').read_bytes()
check('exact fresh actual receipt', sha(receipt_raw) == '1731d89ac2b082c2468f46636bcb94d74f60bb0d11ac52b293baed83a2e2d4d2')
receipt = json.loads(receipt_raw)
net_raw = (RAW / 'net-run/NET_RUN.json').read_bytes()
check('exact fresh actual NET_RUN', sha(net_raw) == '86159e1bf0f8bc104ac1faa9b718f58f573a0c2cb79ffcd4922c34c6571fb131')
net = json.loads(net_raw)
check('actual fresh source pin', receipt['head'] == PIN)
check('actual native exit 1', receipt['exit'] == 1)
check('actual elapsed 273.922 seconds', abs(receipt['elapsed_seconds'] - 273.922) < 0.001)
check('actual full 3254 closure frozen', receipt['source_before'] == receipt['source_after'] and len(receipt['source_before']) == 3254)
check('actual four clean logs and absent engine handles', receipt['errors'] == [] and len(receipt['logs']) == 4 and receipt['engine_handles_after'] == '')
check('actual no fatal/peer command timeout', net['fatal'] == '' and all(x['command_timeout_observation'] is None for x in net['peers']))
check('actual one failure', len(net['failures']) == 1 and 'peer 0 landed a blow' in net['failures'][0])
check('actual one swing, 28 placements, unchanged HP, last gap 4.47', all(x in net['failures'][0] for x in ['212.1 -> 212.1', '1 swing(s)', '28 placement attempt(s)', '4.47 m']))
manifest = [{'path': 'receipt.json', 'bytes': len(receipt_raw), 'sha256': sha(receipt_raw)},
            {'path': 'net-run/NET_RUN.json', 'bytes': len(net_raw), 'sha256': sha(net_raw)}]
selected = []
for row in receipt['logs']:
    raw = (RAW / row['path']).read_bytes()
    check('full actual raw log ' + row['path'], len(raw) == row['bytes'] and sha(raw) == row['sha256'])
    check('unaltered retained ROOT raw ' + row['path'], raw == (ORIGINAL / row['path']).read_bytes())
    text = raw.decode('utf-8-sig')
    check('strict ERROR/leak clean ' + row['path'], not re.search(r'(?:SCRIPT )?ERROR:|ObjectDB instances leaked|resources still in use', text))
    manifest.append(row)
    if row['path'] == 'coordinator.log':
        selected = [{'line': i+1, 'text': line} for i, line in enumerate(text.splitlines()) if any(x in line for x in
                    ['retained that SAME UID', 'SECOND creature', 'local stand-in was moved', 'landed a blow on the SHARED boss',
                     'both peers draw the same boss health bar', 'friendly_target', 'fought the Warden\'s whole team', 'across reload'])]
check('actual guest damage and final whole team both pass', any(x['text'].startswith('PASS: peer 1 landed a blow') for x in selected) and any('PASS: the two of them fought' in x['text'] for x in selected))
write('actual-failure.json', {'source_pin': PIN, 'original_root_path': str(ORIGINAL), 'retained_author_path': str(RAW),
    'members': manifest, 'selected_raw_lines': selected, 'failures': net['failures'],
    'actual_status': 'FAIL, native 1, 273.922s, no timeout, all four logs strict clean, frozen source, no engine handles.',
    'limits': ['Individual placement geometry and the submitted host swing verdict were not retained in this return.',
               'No actual range/cone/clock/RPC ordering cause is asserted from a 4.47 m final diagnostic.',
               'Earlier card/lifetime fixes now pass this actual original guest path; original smoke remains FAIL.']})

smoke = read(PATHS[0]).decode()
smoke_old = old(PATHS[0]).decode()
begin = '\t\t\tvar fresh'
end = '\t\t\tif str(struck.get("verdict", "")) != "PASS":'
start = smoke.index(begin)
stop = smoke.index(end, start)
old_start = smoke_old.index(begin)
old_stop = smoke_old.index(end, old_start)
inverse = smoke[:start] + smoke_old[old_start:old_stop] + smoke[stop:]
boss_start = inverse.index('func _boss(')
boss_stop = inverse.index('\n\n\n', boss_start)
old_boss_start = smoke_old.index('func _boss(')
old_boss_stop = smoke_old.index('\n\n\n', old_boss_start)
inverse = inverse[:boss_start] + smoke_old[old_boss_start:old_boss_stop] + inverse[boss_stop:]
for first, last in [('## A swing is only submitted', 'const SWINGS :='),
                    ('## The unchanged conservative distance', 'const SWING_REACH_M :=')]:
    a = inverse.index(first)
    b = inverse.index(last, a)
    old_first = first if first in smoke_old else '## What "within one swing" means here'
    c = smoke_old.index(old_first)
    d = smoke_old.index(last, c)
    inverse = inverse[:a] + smoke_old[c:d] + inverse[b:]
check('complete original smoke inverse', inverse == smoke_old)
check('all original smoke check assertions unchanged', re.findall(r'^\s*check\(.*$', smoke, re.M) == re.findall(r'^\s*check\(.*$', smoke_old, re.M))
check('all original constants/caps unchanged', re.findall(r'^const .*$', smoke, re.M) == re.findall(r'^const .*$', smoke_old, re.M))
check('original 14 swing and 28 placement ceilings unchanged', 'while attempts < SWINGS * 2 and swings < SWINGS' in smoke and 'const SWINGS := 14' in smoke)
check('original settle frames unchanged', 'const PLACE_SETTLE := 20' in smoke and 'const STRIKE_SETTLE := 30' in smoke)
check('original actual host HP drop still required', 'check(host_hp < hp_before - 0.001,' in smoke)
check('fixed friendly staging gate unchanged', 'if guest_at.distance_to(host_creature_at) >= SWING_REACH_M:' in smoke and 'check(apart < SWING_REACH_M,' in smoke)

runner = read(PATHS[1]).decode()
runner_old = old(PATHS[1]).decode()
const = 'const NET_CONTACT_SPACING := preload("res://scripts/combat/contact_spacing.gd")\n'
helper_start = runner.index('## Same centres and body-scaled quick profile')
helper_stop = runner.index('func _original_starter_ownership(', helper_start)
helper = runner[helper_start:helper_stop]
output = ('\t\t\t\t"strike_geometry": boss_strike_geometry(bdirector, bmanager, brec) \\\n'
          '\t\t\t\t\tif bargs.get("strike_geometry", false) == true else [],\n')
check('one optional geometry probe output', runner.count(output) == 1)
check('one contact geometry preload', runner.count(const) == 1)
check('complete peer runner inverse', runner.replace(const, '').replace(helper, '').replace(output, '') == runner_old)
check('existing strike.target implementation and production submission fully unchanged', function(runner, '_step_strike') == function(runner_old, '_step_strike'))
check('existing earned ownership probe unchanged', function(runner, '_original_starter_ownership') == function(runner_old, '_original_starter_ownership'))
check('existing placement step and settle unchanged', function(runner, '_step_place_creature') == function(runner_old, '_step_place_creature'))
check('existing snapshot window read unchanged', function(runner, 'boss_combat_snapshot') == function(runner_old, 'boss_combat_snapshot'))
for name, fragment in [
    ('host-only current fight', 'director.call("is_encounter_host") != true'),
    ('current bound encounter', 'str(manager.call("encounter_id"))'),
    ('actual host-deployed body', 'director.call("deployed_body_for", peer_id)'),
    ('actual host-held card', 'director.call("_creature_card_for", peer_id)'),
    ('centre origin', 'var origin: Vector3 = body.call("centre")'),
    ('same rendered production floor', 'NET_CONTACT_SPACING.pair_reach_need(body, opponent)'),
    ('same production quick profile', 'NET_COMBAT_MANAGER.host_move_profile(moves, "player_quick"'),
    ('same production cone predicate', 'NET_COMBAT_MATH.move_connects(profile, origin, toward, target)'),
    ('horizontal measurement', 'Vector3(target.x - origin.x, 0.0, target.z - origin.z)'),
    ('binding in diagnostics', '"creature_uid": str(card.get("creature_uid", ""))')]:
    check(name, fragment in helper)
check('new geometry helper never authorizes/mutates/places', not any(x in helper for x in ['preview_wind', 'commit_wind', 'validate_strike', 'submit_encounter_intent', 'set_opponent', '.set(', 'global_position =', 'await ', 'write']))
check('existing target derives aim at actual submission origin', 'facing = Vector3(float(target[0]), float(target[1]), float(target[2])) - origin' in function(runner, '_step_strike'))
check('fixture uses existing target input', '{"target": [aim.x, aim.y, aim.z], "slot": "quick"' in smoke[start:stop])
check('geometry and local verdict are retained for next actual run', '[shared-boss geometry]' in smoke and '[shared-boss strike]' in smoke)

test = read(PATHS[2]).decode()
test_old = old(PATHS[2]).decode()
check('all old snapshot tests byte exact', test.startswith(test_old))
new_test = test[len(test_old):]
check('two new meaningful geometry cases', len(re.findall(r'^func test_', new_test, re.M)) == 2)
for name, fragment in [
    ('real host validator comparison', 'host.validate_strike('),
    ('out-of-range negative control', 'distance == 4.47'),
    ('read-only record control', 'assert_eq(rec, before'),
    ('read-only action/cooldown control', 'authority_before'),
    ('nonhost control', 'director.hosting = false'),
    ('wrong bound fight control', 'manager.id = "other-fight"'),
    ('terminal close control', 'host.close(manager.id)'),
    ('missing body control', 'director.bodies.erase(22)')]:
    check(name, fragment in new_test)

# Formula checks model source geometry only; they are not Godot/real asset proof.
config = json.loads(read('data/config/combat.json'))
contact = config['contact_spacing']
pair = max(min(2.0 + 2.0 + contact['visible_clearance_m'], contact['max_separation_m']), 1.0)
range_m = max(2.6, config['enemy']['body_clearance'] + 0.5, pair + 0.5)
check('unchanged source geometry model permits 4.47 m contact pair', range_m > 4.47)
check('unchanged source geometry model still misses 6 m', range_m < 6.0)
check('vertical distance can make old fixture falsely reject', math.hypot(3.5, 3.0) > 4.0 and 3.5 < range_m)
unchanged = ['scripts/combat/combat_manager.gd', 'scripts/combat/encounter_director.gd',
    'scripts/combat/combat_math.gd', 'scripts/combat/contact_spacing.gd', 'scripts/net/encounter_host.gd',
    'scripts/net/session.gd', 'scripts/world/trainer_npc.gd', 'scripts/creatures/creature_body.gd',
    'scripts/creatures/shared_opponent_proxy.gd', 'scripts/save/water_capture_codec.gd',
    'tests/helpers/net_original_starter_fixture.gd', 'tests/helpers/net_harness.gd',
    'tests/test_stormwood_hosted_combat.gd', 'tests/test_shared_boss_authored_pipeline.gd',
    'tests/test_multiplayer_identity_0912.gd', 'data/config/combat.json', 'data/config/multiplayer.json',
    'data/config/progression.json', 'data/config/trainers.json', 'data/config/bands/band5_stronghold_approach/trainers.json',
    'project.godot']
for path in unchanged:
    check('unchanged control ' + path, read(path) == old(path))
check('no production/config/scene/CI edits', git('diff', PIN, '--', 'scripts', 'data', 'scenes', '.github', 'project.godot') == b'')
patch = git('diff', PIN, '--', *PATHS)
(RAW / 'host-strike-geometry.patch').write_bytes(patch)
result = subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(RAW / 'host-strike-geometry.patch')], capture_output=True)
check('readonly ROOT patch application check', result.returncode == 0)
check('three exact fixture/test paths', set(re.findall(r'^diff --git a/(.*?) b/', patch.decode(), re.M)) == set(PATHS))
write('policy-controls.json', {'source_pin': PIN, 'checks': checks, 'unchanged_controls': unchanged,
    'native_executed_here': False, 'changed_paths': PATHS, 'production_changes': [],
    'source_formula_controls': {'pair_need_m': pair, 'range_m': range_m, 'in_range_m': 4.47, 'out_of_range_m': 6.0}})
write('source-cut.json', {'source_pin': PIN, 'source_checks': len(checks), 'native_executed_here': False,
    'readonly_root_head': subprocess.check_output(['git', '-C', str(ROOT), 'rev-parse', 'HEAD']).decode().strip(),
    'readonly_root_apply_check': True, 'production_changes': [],
    'patch': {'path': str(RAW / 'host-strike-geometry.patch'), 'bytes': len(patch), 'sha256': sha(patch)},
    'paths': [{'path': p, 'sha256_lf': sha(read(p)), 'blob': git('hash-object', p).decode().strip()} for p in PATHS]})
print(json.dumps({'source_checks': len(checks), 'cut_sha256': sha((REPORT / 'source-cut.json').read_bytes()), 'native_executed_here': False}))
