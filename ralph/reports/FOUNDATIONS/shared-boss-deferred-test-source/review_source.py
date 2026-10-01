"""Test-entry byte/source review; no engine execution."""
import hashlib
import json
import pathlib
import subprocess

BASE = pathlib.Path(__file__).resolve().parents[4]
ROOT = pathlib.Path('D:/tetherbound/foundations-batch-check')
PIN = '354998f2a51bb990d0a9f0e5fc84427f369ad3dd'
ORIGINAL = '63429ee77e31341ed82b106ce5489b6479916e3f'
ROOT_PIN = 'd69ce16ec1e7e3484b845056c1bb4b92a4106e07'
PATH = 'tests/test_stormwood_hosted_combat.gd'
REPORT = pathlib.Path(__file__).resolve().parent
checks = []

def git(repo, *args):
    return subprocess.check_output(['git', '-C', str(repo), *args])

def sha(value):
    return hashlib.sha256(value).hexdigest()

def read(path):
    return (BASE / path).read_bytes().replace(b'\r\n', b'\n')

def check(name, condition):
    assert condition, name
    checks.append({'name': name, 'passed': True})

old = git(BASE, 'show', PIN + ':' + PATH)
new = read(PATH)
check('ROOT selected preimage matches reviewed core', git(ROOT, 'show', ROOT_PIN + ':' + PATH) == old)
inverse = new.decode().split('\n\nfunc _drain_shared_lifetime_pipes(', 1)[0]
cases = ['shared_boss_guest_survives_next_round_before_and_after_faint_pause',
         'shared_round_wait_requires_host_boolean_and_matching_card',
         'shared_round_terminal_close_and_disconnect_release_the_wait',
         'shared_round_loss_flee_and_wild_keep_normal_finish']
for name in cases:
    check('one relocated case ' + name, inverse.count('func _case_' + name + '(') == 1)
    inverse = inverse.replace('func _case_' + name + '(', 'func test_' + name + '(')
    check('one deferred invocation ' + name, new.decode().count('test._case_' + name + '()') == 1)
check('all prior helper/case bodies and assertions exact inverse', inverse.rstrip('\n').encode() == old.rstrip(b'\n'))
original = git(BASE, 'show', ORIGINAL + ':' + PATH)
check('pre-boss original hosted-case prefix unchanged', new.startswith(original.rstrip(b'\n') + b'\n\n\nclass SharedRoundTransport'))
unchanged = []
for path in ['scripts/combat/combat_manager.gd', 'scripts/combat/encounter_director.gd',
             'scripts/net/encounter_host.gd', 'scripts/story/sequence_director.gd',
             'tools/net/peer_runner.gd', 'tests/helpers/net_harness.gd',
             'tests/smoke_net_shared_boss.gd', 'tests/smoke_net_meadows_identity_fresh_join.gd',
             'scripts/combat/combat_math.gd', 'tests/run_tests.gd']:
    expected = git(BASE, 'show', PIN + ':' + path)
    check('unchanged production/scenario/budget ' + path, read(path) == expected)
    unchanged.append({'path': path, 'sha256': sha(expected)})
text = new.decode()
checks_required = {
    'deferred initialized SceneTree': 'func _initialize():\\n\\tcall_deferred("run")',
    'real lifecycle assertion count': 'test.assertion_count == 70',
    'parent checks exact completed count': 'int(result.get("assertions", 0)), 70',
    'nonblocking direct child': '"--log-file", log_path], false)',
    'finite focused child cap': 'Time.get_ticks_msec() + 60000',
    'deadline checked while draining': 'OS.is_process_running(pid) and Time.get_ticks_msec() < deadline',
    'per-drain bounded work': 'for _chunk in 16:',
    'timeout kills actual child': 'OS.kill(pid)',
    'bounded kill confirmation': 'Time.get_ticks_msec() + 2000',
    'timed out child fails': 'assert_false(timed_out,',
    'remaining child fails': 'assert_false(running,',
    'reads actual native exit': 'OS.get_process_exit_code(pid)',
    'nonzero and unknown exit fail': 'assert_eq(code, 0, combined)',
    'stdout and stderr retained': 'stdout_bytes.get_string_from_utf8() + "\\n" + stderr_bytes.get_string_from_utf8()',
    'native log required': 'assert_true(not native_log.is_empty(),',
    'native log scanned': 'combined += "\\n" + native_log',
    'script/native errors fail': 'assert_false(combined.contains("ERROR:"), combined)',
    'object and resource leaks fail': 'combined.contains("ObjectDB instances leaked") or combined.contains("resources still in use")',
    'old log cannot supply stale proof': 'DirAccess.remove_absolute(log_path)',
    'pipe handles closed': 'pipe.close()',
}
for name, snippet in checks_required.items():
    check(name, snippet in text)

# Independent result controls. These do not execute the GDScript wrapper.
def acceptable(code=0, timeout=False, running=False, count=70, failures=(), output='', log=True):
    return (code == 0 and not timeout and not running and count == 70 and not failures and log
            and not any(marker in output for marker in ['ERROR:', 'ObjectDB instances leaked', 'resources still in use']))
check('result model clean complete child accepted', acceptable())
for name, kwargs in [('nonzero', {'code': 1}), ('unknown code', {'code': -1}),
                     ('timeout', {'timeout': True}), ('surviving child', {'running': True}),
                     ('missing result', {'count': 0}), ('partial assertions', {'count': 69}),
                     ('failed case', {'failures': ('failed',)}), ('missing log', {'log': False}),
                     ('SCRIPT ERROR', {'output': 'SCRIPT ERROR: invalid call'}),
                     ('native ERROR', {'output': 'ERROR: refusal'}),
                     ('ObjectDB leak', {'output': 'ObjectDB instances leaked'}),
                     ('resource leak', {'output': 'resources still in use'})]:
    check('result model refuses ' + name, not acceptable(**kwargs))
patch = git(BASE, 'diff', PIN, '--', PATH)
patch_path = BASE / '.tmp/shared-boss-ci6173/deferred-test.patch'
patch_path.write_bytes(patch)
subprocess.run(['git', '-C', str(ROOT), 'apply', '--check', str(patch_path)], check=True)
check('read-only ROOT apply check', True)
subprocess.run(['git', '-C', str(BASE), 'diff', '--check'], check=True)
check('diff whitespace check', True)
cut = {'preimage': PIN, 'root_review_pin': ROOT_PIN, 'path': PATH,
       'preimage_blob': git(BASE, 'rev-parse', PIN + ':' + PATH).decode().strip(),
       'preimage_sha256': sha(old), 'candidate_blob': git(BASE, 'hash-object', PATH).decode().strip(),
       'candidate_normalized_sha256': sha(new), 'patch': {'path': str(patch_path), 'sha256': sha(patch)},
       'unchanged': unchanged, 'validation': 'Source/byte and independent result controls only; native not run.'}
for name, value in [('source-cut.json', cut), ('policy-controls.json', {'checks': checks, 'passed': len(checks), 'failed': 0})]:
    (REPORT / name).write_text(json.dumps(value, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps({'source_checks_passed': len(checks), 'patch_sha256': sha(patch),
                  'source_cut_sha256': sha((REPORT / 'source-cut.json').read_bytes())}))
