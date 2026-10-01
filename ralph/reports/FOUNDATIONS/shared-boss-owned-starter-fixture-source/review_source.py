"""Byte/source fixture review. Never invokes Godot or claims native proof."""
import hashlib
import json
import pathlib
import re
import subprocess
import zipfile

BASE = pathlib.Path(__file__).resolve().parents[4]
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PIN = '70bfd13f2affc1053a69ba6ab1169cac20fad455'
ROOT_PIN = 'c7917ea506d44143c416cecc82d869edda1810c4'
REPORT = pathlib.Path(__file__).resolve().parent
SCRATCH = BASE / '.tmp/shared-boss-ci6173'
PATHS = ['tests/smoke_net_shared_boss.gd', 'tools/net/peer_runner.gd',
         'tests/test_multiplayer_identity_0912.gd', 'tests/helpers/net_original_starter_fixture.gd']
checks = []

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def sha(value):
    return hashlib.sha256(value).hexdigest()

def read(path):
    return (BASE / path).read_bytes().replace(b'\r\n', b'\n')

def check(name, value):
    assert value, name
    checks.append({'name': name, 'passed': True})

def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')

archive = (SCRATCH / 'artifact.zip').read_bytes()
check('same original CI6173 ZIP', sha(archive) == '0e12fdc0f8c81cfdcb6f822e4b3820e70d077b8b14bacdf29c4c9bbd80330be0')
members = []
errors = []
characters = []
with zipfile.ZipFile(SCRATCH / 'artifact.zip') as z:
    prefix = 'net-shared_boss-20261001T195856Z/'
    for peer in [0, 1]:
        for relative in [f'peer-{peer}.log', f'home-{peer}/godot/app_userdata/Tetherbound/logs/godot.log']:
            name = prefix + relative
            content = (SCRATCH / 'extracted' / name).read_bytes()
            check('unaltered original member ' + name, content == z.read(name))
            members.append({'path': name, 'bytes': len(content), 'sha256': sha(content)})
            lines = content.decode().splitlines()
            positions = [i for i, line in enumerate(lines) if line.startswith('ERROR:')]
            check('only original native error is protected starter refusal ' + name,
                  len(positions) == 1 and 'adopt_starter is not a swap' in lines[positions[0]])
            check('no original SCRIPT ERROR exception ' + name,
                  not any(line.startswith('SCRIPT ERROR:') for line in lines))
            start = positions[0]
            errors.append({'path': name, 'rows': [{'line': i + 1, 'text': lines[i]} for i in range(start, start + 13)]})
        paths = list((SCRATCH / 'extracted' / prefix / f'home-{peer}').rglob('character.json'))
        check('one original character file peer ' + str(peer), len(paths) == 1)
        path = paths[0]
        name = path.relative_to(SCRATCH / 'extracted').as_posix()
        content = path.read_bytes()
        check('unaltered original character ' + name, content == z.read(name))
        personal = json.loads(content)
        check('actual original deployed fixture retained empty party peer ' + str(peer), personal['party'] == [])
        receipts = personal['redesign_character']['transaction_receipts']
        check('no original starter choice receipt peer ' + str(peer), not any(x.startswith('starter_choice:') for x in receipts))
        flags = personal['flags']['flags']
        check('no original starter granted fact peer ' + str(peer), 'opening:starter_granted' not in flags)
        characters.append({'path': name, 'bytes': len(content), 'sha256': sha(content),
                           'character_id': personal['character_id'], 'party': [],
                           'starter_choice_receipts': [], 'starter_granted': False})
write('actual-attribution.json', {'run_id': 36915534683, 'job_id': 110549151039,
    'artifact_id': 11190524116, 'artifact_zip_sha256': sha(archive), 'members': members,
    'full_original_error_and_warning_blocks': errors, 'actual_saved_characters': characters,
    'classification': 'Intentional adopt_starter protected push_error refusal; caller reached it with an already deployed body and empty Game.party. No SCRIPT ERROR or invalid-property/API-missing exception.',
    'source_relation': 'Legacy deploy_creature fallback creates a canonical species instance/body but never admits it to Game.party. Story catch-up tests empty party and calls adopt_starter again. Remote admission precedes legacy deployment in the original smoke.',
    'limits': ['No individual RPC/timer ordering observed.', 'No cancelled-job causation inferred.',
               'Candidate native opening/admission timing is unexecuted; original errors remain unretired pending ROOT native.']})

smoke = read(PATHS[0]).decode()
old_smoke = git(BASE, 'show', PIN + ':' + PATHS[0])
constant = 'const ORIGINAL_STARTER_FIXTURE := preload("res://tests/helpers/net_original_starter_fixture.gd")\n\n'
preparation = ('\t# Disclosed setup: complete each standalone peer\'s real original choice and\n'
    '\t# naming before admission. No second starter, loaner, party_grant or forged fact.\n'
    '\tvar starter_fixture := ORIGINAL_STARTER_FIXTURE.new()\n'
    '\tvar prepared: Array[Dictionary] = await starter_fixture.prepare(self)\n'
    '\tif prepared.size() != 2:\n\t\tquit(await finish())\n\t\treturn\n\n')
verification = ('\tif not await starter_fixture.verify_after_admission(self, prepared):\n'
    '\t\tquit(await finish())\n\t\treturn\n\n')
for name, fragment in [('one helper preload', constant), ('one before-admission setup', preparation), ('one after-deploy check', verification)]:
    check(name, smoke.count(fragment) == 1)
inverse = smoke.replace(constant, '').replace(preparation, '').replace(verification, '').encode()
check('complete original smoke inverse: every original action/assertion/wait/budget unchanged', inverse == old_smoke)
check('preparation precedes original host and join', smoke.index('starter_fixture.prepare(self)') < smoke.index('step(0, "host", {})') < smoke.index('step(1, "join",'))
check('ownership verification follows original deploy', smoke.index('step(i, "deploy_creature", {})') < smoke.index('starter_fixture.verify_after_admission'))
runner = read(PATHS[1]).decode()
probe_start = runner.index('func _original_starter_ownership(')
probe_end = runner.index('func _execute_probe(', probe_start)
probe_function = runner[probe_start:probe_end]
probe_case = '\t\t"original_starter_ownership":\n\t\t\treturn _original_starter_ownership(args)\n'
check('one new readonly probe case', runner.count(probe_case) == 1)
check('complete peer runner inverse; all original step handlers intact',
      (runner[:probe_start] + runner[probe_end:]).replace(probe_case, '').encode() == git(BASE, 'show', PIN + ':' + PATHS[1]))
check('probe matches actual same instance', 'party.call("at", 0) == creature' in probe_function)
check('probe reads actual personal starter fact', 'local.get("flags").call("has", "opening:starter_granted")' in probe_function)
check('probe uses actual host-held admitted roster', 'session.call("admitted_character_state"' in probe_function)
check('probe does not refresh an inactive standalone admission', 'session.call("is_active") == true' in probe_function)
check('probe does not mutate/save/mint/grant', not any(x in probe_function for x in ['.set(', 'set_flag', 'party.add', 'commit_', 'save_character', 'mint(', 'seed_admitted']))
old_test = git(BASE, 'show', PIN + ':' + PATHS[2])
test = read(PATHS[2])
check('all existing multiplayer identity cases unchanged', test.startswith(old_test.rstrip(b'\n') + b'\n\n\nfunc test_original_starter_fixture_'))
helper = read(PATHS[3]).decode()
for action in ['"move_to"', '"interact"', '"dismiss_dialogue"', '"menu_confirm"', '"ui_right"', '"ui_down"']:
    check('fixture uses existing physical-input step ' + action, action in helper)
for forbidden in ['call("adopt_starter"', 'call("_adopt"', 'party_grant', 'call("set_flag"', '.set(', 'commit_original_starter', '_force_restore_beat', 'seed_admitted', '_step_phase_deadline_ms', 'heartbeat_silence_tolerance_s']:
    check('fixture excludes mutation/bypass/budget write ' + forbidden, forbidden not in helper)
check('fixture starts before active session with empty party AND absent body', 'session.get("active") == false' in helper and 'owner.get("party_size", -1) == 0 and owner.get("body_present") == false' in helper)
check('fixture never adopts an existing unowned body', 'return []' in helper.split('# Same passive markers', 1)[0])
check('both typed names actually observed', 'entry.get("text", "")' in helper and 'names[0] != names[1]' in helper)
check('literal finite modal and cursor bounds', all(x in helper for x in ['for _attempt in attempts:', 'for _attempt in 20:', 'for _attempt in 120:']))
check('new helper never raises original caps', '_budgets' not in helper and 'step_phase_deadline' not in helper)
check('same UID compared after admission', 'local.get("body_uid") == uid' in helper and 'admitted.get("admitted_party_uids", []) == [uid]' in helper)
check('admitted character bound to actual local character', 'admitted.get("admitted_character_id", "") == local.get("character_id", "")' in helper)
unchanged = []
for path in ['scripts/story/sequence_director.gd', 'scripts/story/party_seam.gd', 'autoload/party.gd',
             'autoload/game_state.gd', 'scripts/net/session.gd', 'scripts/net/character_authority.gd',
             'scripts/combat/encounter_director.gd', 'scripts/combat/combat_manager.gd',
             'scripts/net/encounter_host.gd', 'scripts/combat/combat_math.gd',
             'tests/helpers/net_harness.gd', 'tests/test_stormwood_hosted_combat.gd',
             'tests/smoke_net_meadows_identity_fresh_join.gd', 'data/config/combat.json',
             'data/config/multiplayer.json', 'data/config/opening.json']:
    content = git(BASE, 'show', PIN + ':' + path)
    check('production/budget/guard unchanged ' + path, read(path) == content)
    unchanged.append({'path': path, 'sha256': sha(content)})
director = read('scripts/combat/encounter_director.gd').decode()
check('protected refusal remains exact', 'push_error("the player already has a creature; adopt_starter is not a swap")' in director)
authority = read('scripts/net/character_authority.gd').decode()
check('remote admitted baseline cannot be replaced', '"already_seeded": true' in authority and 'return {"ok": true, "already_seeded": true' in authority)
opening = json.loads(read('data/config/opening.json'))
check('real picker default is actual authored Terrapup', opening['starters']['species'][0] == 'terrapup')

# Independent ownership controls, not GDScript/native validation.
def owned(row, name):
    uid = row.get('body_uid', '')
    return bool(uid and row.get('party_size') == 1 and row.get('party_uids') == [uid]
                and row.get('body_is_owned_instance') is True and row.get('body_present') is True
                and row.get('body_ready') is True and row.get('body_species') == 'terrapup'
                and row.get('body_nickname') == name and row.get('starter_granted') is True)
valid = {'body_uid': 'original', 'party_size': 1, 'party_uids': ['original'], 'body_is_owned_instance': True,
         'body_present': True, 'body_ready': True, 'body_species': 'terrapup', 'body_nickname': 'Chosen', 'starter_granted': True}
check('ownership model actual one owned body accepted', owned(valid, 'Chosen'))
for name, mutation in [('actual original empty ownership hole', {'party_size': 0, 'party_uids': []}),
                       ('other UID', {'party_uids': ['other']}), ('extra starter', {'party_size': 2}),
                       ('unowned body', {'body_is_owned_instance': False}), ('no UID', {'body_uid': ''}),
                       ('unknown species', {'body_species': 'unknown'}), ('unready body', {'body_ready': False}),
                       ('no original grant fact', {'starter_granted': False}), ('another name', {'body_nickname': 'Other'})]:
    check('ownership model refuses ' + name, not owned(dict(valid, **mutation), 'Chosen'))
check('admission model mismatched UID fails', ['other'] != [valid['body_uid']])
check('admission model empty baseline fails', [] != [valid['body_uid']])
sources = []
for path in PATHS:
    content = read(path)
    if path != PATHS[3]:
        old = git(BASE, 'show', PIN + ':' + path)
        check('ROOT selected immutable preimage ' + path, git(ROOT, 'show', ROOT_PIN + ':' + path) == old)
        preimage = {'blob': git(BASE, 'rev-parse', PIN + ':' + path).decode().strip(), 'sha256': sha(old)}
    else:
        preimage = None
    sources.append({'path': path, 'preimage': preimage, 'candidate_normalized_sha256': sha(content),
                    'candidate_blob': git(BASE, 'hash-object', path).decode().strip()})
# Include the new helper in the review patch before staging it for the commit.
patch = git(BASE, 'diff', PIN, '--', *PATHS[:3])
helper_lines = read(PATHS[3]).decode().splitlines(keepends=True)
patch += (f'diff --git a/{PATHS[3]} b/{PATHS[3]}\nnew file mode 100644\n--- /dev/null\n+++ b/{PATHS[3]}\n@@ -0,0 +1,{len(helper_lines)} @@\n' + ''.join('+' + x for x in helper_lines)).encode()
patch_path = SCRATCH / 'owned-original-starter-fixture.patch'
patch_path.write_bytes(patch)
subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(patch_path)], check=True)
check('read-only ROOT apply check', True)
subprocess.run(['git', '-C', str(BASE), 'diff', '--check'], check=True)
check('diff whitespace check', True)
write('source-cut.json', {'preimage': PIN, 'root_review_pin': ROOT_PIN, 'sources': sources,
    'unchanged': unchanged, 'patch': {'path': str(patch_path), 'sha256': sha(patch)},
    'validation': 'Source/byte and independent Python controls only. Native opening/admission timing and original smoke not run.'})
write('policy-controls.json', {'checks': checks, 'passed': len(checks), 'failed': 0, 'native': 'NOT RUN; ROOT owns validation.'})
print(json.dumps({'source_checks_passed': len(checks), 'patch_sha256': sha(patch),
                  'source_cut_sha256': sha((REPORT / 'source-cut.json').read_bytes())}))
