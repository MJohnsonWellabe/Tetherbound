from pathlib import Path
import hashlib, json, subprocess, urllib.request, difflib

root = Path('D:/tetherbound/redesign-hub')
packet = Path(__file__).resolve().parent
parent = 'f65692df960435918da196301aebac72ac827cfc'
owned = 'tests/helpers/opening_geometry_navigator.gd'
H = lambda b: hashlib.sha256(b).hexdigest()
assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root).decode().strip() == parent
changed = subprocess.check_output(['git', 'diff', '--name-only'], cwd=root).decode().splitlines()
assert changed == [owned], changed
receipt = json.loads(Path('D:/tetherbound/m1-production-steering-r1/receipt.json').read_bytes())
pins = dict(receipt['source_after'])
for extra in ['data/config/building_prefabs.json', 'data/config/movement.json', 'scenes/player/player.tscn']:
    pins[extra] = H((root / extra).read_bytes())
for name, pin in pins.items():
    raw = (root / name).read_bytes()
    if name == owned:
        raw = subprocess.check_output(['git', 'show', parent + ':' + name], cwd=root)
        # Windows working tree raw bytes are CRLF. Use the executed source from
        # the immutable prior packet, after checking exact Git equivalence.
        executed = (root / '.tmp/opening-production-steering-r1/proposal' / name).read_bytes()
        assert raw.replace(b'\r\n', b'\n') == executed.replace(b'\r\n', b'\n')
        raw = executed
    assert H(raw) == pin, (name, H(raw), pin)
    path = packet / 'originals' / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(raw)
after = (root / owned).read_bytes()
target = packet / 'proposal' / owned
target.parent.mkdir(parents=True, exist_ok=True)
target.write_bytes(after)
patch = ''.join(difflib.unified_diff((packet / 'originals' / owned).read_bytes().decode().splitlines(True),
                                  after.decode().splitlines(True), fromfile='a/' + owned, tofile='b/' + owned)).encode()
(packet / 'opening-production-callback.patch').write_bytes(patch)
for name in ['receipt.json', 'native.txt', 'parser.txt']:
    (packet / 'evidence').mkdir(exist_ok=True)
    (packet / 'evidence' / name).write_bytes((Path('D:/tetherbound/m1-production-steering-r1') / name).read_bytes())
primary = {}
for name in ['core/input/input.cpp', 'main/main.cpp', 'scene/main/scene_tree.cpp']:
    url = 'https://raw.githubusercontent.com/godotengine/godot/4.7-stable/' + name
    data = urllib.request.urlopen(url, timeout=30).read()
    target = packet / 'api' / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    primary[name] = {'url': url, 'sha256': H(data)}
archive_names = subprocess.check_output(['git', 'ls-files', 'ralph/reports/HUB/f17', 'ralph/reports/HUB/f18'], cwd=root).decode().splitlines()
archives = {name: H((root / name).read_bytes()) for name in archive_names}
cause = {
    'parent': parent, 'permissions': {'sandbox_mode': 'danger-full-access', 'approval_policy': 'never'},
    'owned_paths': [owned], 'before_source_sha256': pins, 'after_source_sha256': {owned: H(after)},
    'prior_failure': {'source': receipt['source'], 'native_exit': receipt['runs'][1]['native_exit'],
                      'native_sha256': H((packet / 'evidence/native.txt').read_bytes()),
                      'status': 'FAIL preserved; no F17#4 credit',
                      'position': [37.333366394043, -2.01156902313232, -19.4326572418213],
                      'actual_delta': [0, 0, 0], 'queries': 2, 'on_floor': True},
    'causal_evidence': {
        'input_order': 'Godot4.7 Input::parse_input_event queues under accumulated/agile input; Main flushes before physics callbacks. NativeTick sent events after that flush. Explicit flush before controller corrects this ordering; real joypad input retained.',
        'callback_logging': 'Old successful observation was serialized/printed before final deadline guard and duplicated after failure. Prior receipt cannot isolate its cost. Deferred bounded output corrects accounting, but logging as runtime root cause remains a hypothesis until new timing exists.',
        'timings': 'Pre/post own elapsed includes live query/registration checks, input flush, snapshot and scheduling. Gap includes controller plus other nodes and is honestly excluded. Deferred serialization and primary observation print costs separately reported; cost-line print itself unmeasured.',
        'queue': 'At most two value-only snapshots pending; first eight, each 90th, one terminal. No per-frame history or native queries in deferred sink; saturation conservatively refuses.',
        'terminal': 'Failure snapshot/output and stop-input flush may occur after cap already refused. No travel credit is added by that work.'},
    'unchanged_caps': {'callback_us': 10000, 'gather_frames': 1800, 'team_frames': 3600,
                       'stall_frames': 90, 'retry_frames': 26, 'frame_queries': 96,
                       'lifetime_queries': 250000, 'requests': 24000},
    'physical_guards': 'Original _observed_live_clear, _motion, _trainer_contract, _registered_body_contract, capsule shape/mask/currentworld/deep skin/floor/slide shape/recovery/movement bounds retained. Default predictive APIs retained. No body/velocity/HP/AI/progression/geometry writes.',
    'archives_sha256': archives, 'primary_sources': primary,
    'root_proof': {'owner': 'ROOT sole engine writer', 'command_tail': ['--headless', '--path', str(root), '--script', 'res://tests/smoke_four_biome_continuous.gd', '--', '--through-tournament', '--world-seed=4', '--no-checkpoints', '--opening-contact-diagnostics'],
                   'required': 'Original earned full fresh title/starter/catch/village+gather/camp/three-bed readiness/three played tournament rounds. One affected path; first failure diagnostic; no unchanged retry. Independent criterion verdict and same-workflow PR remain ROOT.'},
    'status': 'SOURCE_CANDIDATE; no engine validation in this task; F17#4 remains OPEN'
}
(packet / 'cause-and-constraints.json').write_text(json.dumps(cause, indent=2) + '\n', encoding='utf-8')
manifest = {str(p.relative_to(packet)).replace('\\','/'): H(p.read_bytes()) for p in sorted(packet.rglob('*')) if p.is_file() and p.name != 'freeze.json' and 'independent' not in p.relative_to(packet).parts}
freeze = {'parent': parent, 'state': 'FROZEN_SOURCE_CANDIDATE', 'patch_sha256': H(patch), 'files_sha256': manifest}
(packet / 'freeze.json').write_text(json.dumps(freeze, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'packet': str(packet), 'source_sha256': H(after), 'patch_sha256': H(patch), 'frozen_files': len(manifest), 'preserved_archive_files': len(archives)}))
