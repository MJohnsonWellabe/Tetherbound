"""Source/byte review only. Does not invoke Godot or claim native validation."""
import difflib
import hashlib
import json
import pathlib
import re
import subprocess
import zipfile

BASE = pathlib.Path(__file__).resolve().parents[4]
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PIN = '63429ee77e31341ed82b106ce5489b6479916e3f'
ROOT_PIN = '601a66fc9fddbd0c009d74596b993c59999f1c5c'
CI = 'c6d0670585d2776e4931126f00dedca9d8a2d048'
REPORT = pathlib.Path(__file__).resolve().parent
SCRATCH = BASE / '.tmp/shared-boss-ci6173'
PATHS = ['scripts/combat/combat_manager.gd', 'scripts/combat/encounter_director.gd',
         'scripts/net/encounter_host.gd', 'tests/test_stormwood_hosted_combat.gd']
checks = []


def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])


def sha(value):
    return hashlib.sha256(value).hexdigest()


def norm(value):
    return value.replace(b'\r\n', b'\n')


def check(name, condition):
    assert condition, name
    checks.append({'name': name, 'passed': True})


def write(name, value):
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')


raw = (SCRATCH / 'original-ci6173-job.log').read_bytes()
check('actual job raw bytes', len(raw) == 528416 and sha(raw) ==
      '1173018e179cc173022d61400e88ca51b47d099821cee488ede5753ab6e9bf4f')
lines = raw.decode('utf-8-sig').splitlines()
head_line = next(i for i, line in enumerate(lines) if 'git log -1 --format=%H' in line)
check('actual merge checkout', lines[head_line + 1].endswith(CI))
selected = [(i + 1, line) for i, line in enumerate(lines) if
            '2026-10-01T20:00:51.' in line or '2026-10-01T20:00:53.' in line or
            '2026-10-01T20:00:54.' in line or '2026-10-01T20:01:08.' in line]
check('original second-round pass precedes body failure',
      next(i for i, line in selected if "SECOND creature" in line) <
      next(i for i, line in selected if 'no opponent body' in line))
check('original missing body and missing network binding both retained',
      any('no opponent body' in line for _, line in selected) and
      any('not in a networked fight' in line for _, line in selected))
check('original host successful damage and absent guest HUD retained',
      any('212.1 -> 203.0' in line for _, line in selected) and
      any('host 203.028, guest -1.000' in line for _, line in selected))
archive = (SCRATCH / 'artifact.zip').read_bytes()
check('original artifact zip digest', sha(archive) ==
      '0e12fdc0f8c81cfdcb6f822e4b3820e70d077b8b14bacdf29c4c9bbd80330be0')
manifest = []
with zipfile.ZipFile(SCRATCH / 'artifact.zip') as z:
    for path in sorted((SCRATCH / 'extracted').rglob('*')):
        if path.is_file():
            relative = path.relative_to(SCRATCH / 'extracted').as_posix()
            content = path.read_bytes()
            check('unaltered original artifact member ' + relative, content == z.read(relative))
            manifest.append({'path': relative, 'bytes': len(content), 'sha256': sha(content)})
check('sixteen retained original members', len(manifest) == 16)
errors = []
for peer in [0, 1]:
    relative = f'net-shared_boss-20261001T195856Z/peer-{peer}.log'
    peer_lines = (SCRATCH / 'extracted' / relative).read_text(encoding='utf-8').splitlines()
    rows = [{'line': i + 1, 'text': line} for i, line in enumerate(peer_lines)
            if 'adopt_starter is not a swap' in line]
    check('unretired original adoption error peer ' + str(peer), len(rows) == 1)
    errors.append({'path': relative, 'rows': rows})
write('actual-failure.json', {
    'source_pin': PIN, 'ci_merge': CI, 'run_id': 36915534683, 'job_id': 110549151039,
    'raw_job': {'path': str(SCRATCH / 'original-ci6173-job.log'), 'bytes': len(raw), 'sha256': sha(raw)},
    'artifact': {'id': 11190524116, 'sha256': sha(archive), 'members': manifest},
    'actual_rows': [{'line': i, 'text': line} for i, line in selected],
    'unretired_other_errors': errors,
    'limits': ['Individual RPC arrival and timer ordering are not logged.',
               'Both source-permitted arrival orders are covered; neither is claimed as observed.',
               'No attribution to the five cancelled CI6173 jobs; their raw logs are unavailable.',
               'Original adoption errors remain outside this lifetime repair.'],
})

allowed_functions = {
    PATHS[0]: {'unbind_encounter', 'begin', 'end_shared_opponent_presentation', '_physics_process',
               'apply_encounter_record', '_apply_shared_trainer_round', '_begin_resolve'},
    PATHS[1]: {'_on_net_session_ended', '_rpc_encounter_record', '_open_encounter_if_networked',
               '_refresh_legacy_mirror'},
    PATHS[2]: {'close', '_opponent_row'},
}


def functions(text):
    starts = list(re.finditer(r'^(?:static )?func (\w+)\(', text, re.M))
    return {m.group(1): text[m.start(): starts[i + 1].start() if i + 1 < len(starts) else len(text)]
            for i, m in enumerate(starts)}


sources = []
for path in PATHS:
    old = git(BASE, 'show', PIN + ':' + path)
    candidate_raw = (BASE / path).read_bytes()
    new = norm(candidate_raw)
    check('ROOT immutable selected preimage matches actual source ' + path,
          git(ROOT, 'show', ROOT_PIN + ':' + path) == old)
    # ndiff's inverse restores every original line, not selected excerpts.
    delta = list(difflib.ndiff(old.decode().splitlines(keepends=True), new.decode().splitlines(keepends=True)))
    check('full file inverse ' + path,
          ''.join(difflib.restore(delta, 1)).encode() == old and
          ''.join(difflib.restore(delta, 2)).encode() == new)
    if path in allowed_functions:
        before, after = functions(old.decode()), functions(new.decode())
        changed = {name for name in set(before) | set(after) if before.get(name) != after.get(name)}
        check('exact production function scope ' + path, changed == allowed_functions[path])
        # Only the three lifecycle fields may change outside functions.
        old_prefix = old.decode().split('func ', 1)[0]
        new_prefix = new.decode().split('func ', 1)[0]
        if path == PATHS[0]:
            fields = ('## A mirrored trainer/boss round can end before the host sends its next member.\n'
                      '## Keep the admitted fight bound through that gap, without simulating the foe.\n'
                      'var _shared_trainer_round := 0\n'
                      'var _shared_trainer_round_continues := false\n'
                      'var _waiting_shared_trainer_round := false\n\n')
            check('only lifecycle fields outside functions', new_prefix.replace(fields, '') == old_prefix)
        else:
            check('unchanged non-function prefix ' + path, old_prefix == new_prefix)
    else:
        check('all existing hosted cases unchanged', new.startswith(old.rstrip(b'\n') + b'\n\n\nclass SharedRoundTransport'))
        check('five appended regression cases', len(re.findall(r'^func test_shared_|^func test_host_round_', new.decode(), re.M)) == 5)
    sources.append({'path': path, 'preimage_blob': git(BASE, 'rev-parse', PIN + ':' + path).decode().strip(),
                    'preimage_sha256': sha(old), 'candidate_raw_sha256': sha(candidate_raw),
                    'candidate_normalized_sha256': sha(new),
                    'candidate_blob': git(BASE, 'hash-object', path).decode().strip()})

unchanged = []
for path in ['tests/smoke_net_shared_boss.gd', 'tests/helpers/net_harness.gd', 'tools/net/peer_runner.gd',
             'scripts/creatures/shared_opponent_proxy.gd', 'scripts/combat/combat_math.gd']:
    old = git(BASE, 'show', PIN + ':' + path)
    check('original guards/actions/scaling/body API unchanged ' + path, norm((BASE / path).read_bytes()) == old)
    unchanged.append({'path': path, 'sha256': sha(old)})
director = norm((BASE / PATHS[1]).read_bytes()).decode()
manager = norm((BASE / PATHS[0]).read_bytes()).decode()
host = norm((BASE / PATHS[2]).read_bytes()).decode()
check('queue popped before host opens opponent', director.index('_trainer_queue.pop_front()') <
      director.index('_open_encounter_if_networked', director.index('_trainer_queue.pop_front()')))
check('host authors actual remaining queue marker', '"round_continues": not _trainer_queue.is_empty(),' in director)
receive = functions(director)['_rpc_encounter_record']
check('sequence checked before mirror mutation', receive.index('if int(rec.get("seq", 0)) <') <
      receive.index('_refresh_legacy_mirror'))
check('same-generation pose sequence resets only after new configure succeeds',
      functions(director)['_refresh_legacy_mirror'].index('configure_presentation') <
      functions(director)['_refresh_legacy_mirror'].index('set("last_pose_seq", 0)'))
check('installed card UID guards reactivation', 'card.get("uid") != _enemy.get("uid")' in manager)
check('strict boolean continuation', 'continues is bool and continues == true' in manager)
check('ordinary resolve pause unchanged', functions(manager)['_begin_resolve'].split('\tvar flow:', 1)[1] ==
      functions(git(BASE, 'show', PIN + ':' + PATHS[0]).decode())['_begin_resolve'].split('\tvar flow:', 1)[1])
check('terminal close withdraws continuation', 'opponent["round_continues"] = false' in functions(host)['close'])
check('disconnect withdraws actual mirror', '"end_shared_opponent_presentation", _legacy_mirror' in
      functions(director)['_on_net_session_ended'])

# Independent scheduling model documents controls; it does not execute GDScript.
def schedule(continue_marker, next_delay=None, outcome='won', kind='boss', installed=True,
             terminal=False, disconnect=False):
    wait = outcome == 'won' and kind in ['boss', 'trainer'] and continue_marker is True
    bound = wait or (next_delay is not None and next_delay < 1.6)
    active = bool(wait and next_delay is not None and installed)
    if terminal or disconnect:
        wait = False
        bound = False
    elif active:
        wait = False
        bound = True
    return bound, active, wait

for delay in [0.01, 10.0]:
    for kind in ['boss', 'trainer']:
        check(f'model: promised {kind} round at {delay}s resumes same binding',
              schedule(True, delay, kind=kind) == (True, True, False))
check('model: promised gap stays bound', schedule(True) == (True, False, True))
for marker in [False, 'true', None]:
    check('model: absent/nonboolean continuation releases ' + repr(marker), schedule(marker) == (False, False, False))
for outcome in ['lost', 'fled']:
    check('model: nonvictory releases ' + outcome, schedule(True, outcome=outcome) == (False, False, False))
check('model: wild releases', schedule(True, kind='wild') == (False, False, False))
check('model: wrong card does not resume', schedule(True, 10.0, installed=False) == (True, False, True))
check('model: terminal close releases held gap', schedule(True, terminal=True) == (False, False, False))
check('model: disconnect releases held gap', schedule(True, disconnect=True) == (False, False, False))

patch = git(BASE, 'diff', PIN, '--', *PATHS)
patch_path = SCRATCH / 'shared-boss-lifetime.patch'
patch_path.write_bytes(patch)
subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(patch_path)], check=True)
check('read-only ROOT apply check', True)
subprocess.run(['git', '-C', str(BASE), 'diff', '--check'], check=True)
check('diff whitespace check', True)
write('source-cut.json', {'preimage': PIN, 'root_review_pin': ROOT_PIN, 'ci_merge': CI,
                         'candidate_sources': sources, 'unchanged': unchanged,
                         'runtime_and_test_patch': {'path': str(patch_path), 'sha256': sha(patch)},
                         'validation': 'Source/byte and independent Python scheduling controls only; no Godot invoked.'})
write('policy-controls.json', {'checks': checks, 'passed': len(checks), 'failed': 0,
                               'native': 'NOT RUN; ROOT owns original smoke and regression execution.',
                               'authority': 'No protocol authority, scaling, HP formula, simulation, driver or deadline changes.'})
print(json.dumps({'source_checks_passed': len(checks), 'patch_sha256': sha(patch),
                  'source_cut_sha256': sha((REPORT / 'source-cut.json').read_bytes())}))
