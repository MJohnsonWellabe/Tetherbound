from pathlib import Path
import hashlib, json, shutil, subprocess

root = Path('D:/tetherbound/redesign-hub')
raw = Path('D:/tetherbound/m1-production-detour-r3')
packet = root / '.tmp/opening-production-detour-r3-failure'
assert not packet.exists()
receipt = json.loads((raw / 'receipt.json').read_bytes())
assert receipt['source'] == receipt['head_after'] == '8189ef734addce12d446c6c9a0f9d4016a0d657d'
assert receipt['same_source'] and receipt['source_before'] == receipt['source_after']
assert [r['native_exit'] for r in receipt['runs']] == [0, 1]
H = lambda b: hashlib.sha256(b).hexdigest()
packet.mkdir()
pins = {}
for name in ['native.txt', 'parser.txt', 'receipt.json']:
    source = raw / name
    if name != 'receipt.json':
        run = next(r for r in receipt['runs'] if r['label'] == name.split('.')[0])
        assert H(source.read_bytes()) == run['raw_sha256']
    shutil.copyfile(source, packet / name)
    assert source.read_bytes() == (packet / name).read_bytes()
    pins[name] = H(source.read_bytes())
observations = [json.loads(line.split(' ', 1)[1]) for line in (packet / 'native.txt').read_text().splitlines() if line.startswith('OPENING_PRODUCTION_OBSERVATION ')]
terminal = next(o for o in reversed(observations) if o['refusal'])
counts = terminal['slide_point_counts']
assert counts == [2] * 6 and terminal['slide_count'] == 6
assert terminal['refusal'] == 'actual production contact observation cap'
assert terminal['on_wall'] and terminal['on_floor'] and not terminal['checked_start']
identities = sorted(set((p['collider_rid'], p['collider_shape']) for p in terminal['slide_contacts']))
assert len(identities) == 2
diagnostic = {'state': 'ACTUAL_FAIL; F17#4 OPEN', 'head': receipt['source'], 'engine_run_here': False, 'tracked_writes': False, 'exact_cached_contact_total': sum(counts), 'cached_manifold_counts': counts, 'contact_points_are_capped_prefix': True, 'recorded_contact_identities': identities, 'live_contacts': terminal['live_contacts'], 'terminal': terminal, 'conclusion': 'Recorded evidence is floor plus near-horizontal wall against a second collider RID. Six Terrain paths in the helper error enumerate only collision.get_collider() default index0, not every manifold point. This is not evidence of a pure overlapping-floor case. The exact cached total is twelve; eight point payload is only a prefix. No omitted point normal/depth identity is reconstructed.', 'source_hold': '8189ef734a; awaiting ROOT authoritative terminal/PID release'}
(packet / 'diagnostic.json').write_text(json.dumps(diagnostic, indent=2) + '\n', encoding='utf-8')
pins['diagnostic.json'] = H((packet / 'diagnostic.json').read_bytes())
shutil.copyfile(__file__, packet / 'freeze-failure.py')
pins['freeze-failure.py'] = H((packet / 'freeze-failure.py').read_bytes())
(packet / 'freeze.json').write_text(json.dumps({'state': 'FROZEN_ACTUAL_FAIL', 'head': receipt['source'], 'files_sha256': pins}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'pins': pins, 'cached_manifold_counts': counts, 'exact_contact_total': sum(counts), 'identities': identities}))
