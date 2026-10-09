from pathlib import Path
from PIL import Image
import hashlib, json, math, re, struct, zlib

packet = Path(__file__).parent
root = Path('D:/CodexTemp/tetherbound-native/d-e2d54b40aa')
raw = root / '.tmp/e-stormward-approach-8cca-daycycle-r1'
source = '8cca04f2a5a91917652c8dc66842a38683105368'
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
t = read(packet / 'capture-terminal.json')
assert t['source'] == source and t['exit_code'] == 0 and t['reason'] == 'process_exit'
b, a = [read(packet / ('source-' + phase + '-capture.json')) for phase in ['before', 'after']]
assert b['source'] == a['source'] == source and b['tracked_clean'] and a['tracked_clean']
assert b['head_tree'] == b['index_tree'] == a['head_tree'] == a['index_tree']
m = read(raw / 'manifest.json')
assert m['complete'] is True and m['failures'] == [] and m['biome_id'] == 'cloudreach'
assert m['stormward_approach_only'] is True and m['cliffhold_interior_only'] is False
assert m['segment'] == '' and m['candidate_preview'] is False and m['full_matrix_complete'] is False
assert m['full_matrix_planned_frames'] == 384
rows = m['frames']
assert m['planned_frame_count'] == m['captured_frame_count'] == len(rows) == 8
assert m['selected_frame_ids'] == m['planned_frame_ids'] == [r['frame_id'] for r in rows]
assert len(set(m['selected_frame_ids'])) == 8
assert m['required_segments'] == m['capture_plan']['times']
assert set(m['capture_plan']['times']) == {'dawn', 'day', 'golden', 'night'}
assert set(m['capture_plan']['weather']) == {'clear', 'rain'}
assert {(r['time'], r['weather']) for r in rows} == {(t, w) for t in m['capture_plan']['times'] for w in m['capture_plan']['weather']}
g = m['graphics_capture']
assert g['source_commit'] == source and g['renderer'] == m['rendering_method'] == 'forward_plus'
assert g['preset'] == 'High' and g['resolution'] == m['resolution'] == [1920, 1080]

def finite(value):
    if isinstance(value, dict): return all(finite(v) for v in value.values())
    if isinstance(value, list): return all(finite(v) for v in value)
    if isinstance(value, (int, float)) and not isinstance(value, bool): return math.isfinite(value)
    return True

checks = []
for row in rows:
    assert row['view'] == 'approach'
    assert re.sub(r'[^a-z0-9]+', '_', row['destination_display_name'].lower()).strip('_') == 'stormward_overlook'
    assert row['on_floor'] is True and row['debug_travel'] is True
    assert row['observed_weather'] == row['weather'] == row['observed_clock']['weather']
    assert finite(row)
    for field in ['player_position', 'camera_position', 'camera_transform', 'camera_rig_transform', 'terrain_ground_y', 'resolved_ground_y', 'camera_player_distance_m']:
        assert field in row and row[field] is not None
    assert row['file'].startswith('res://.tmp/e-stormward-approach-8cca-daycycle-r1/')
    p = root / row['file'].removeprefix('res://')
    assert p.parent == raw
    data = p.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n' and len(data) == row['bytes']
    offset, ended = 8, False
    while offset < len(data):
        n = struct.unpack('>I', data[offset:offset+4])[0]
        kind = data[offset+4:offset+8]
        payload = data[offset+8:offset+8+n]
        crc = struct.unpack('>I', data[offset+8+n:offset+12+n])[0]
        assert zlib.crc32(kind + payload) & 0xffffffff == crc
        offset += n + 12
        if kind == b'IEND': ended = True; break
    assert ended and offset == len(data)
    with Image.open(p) as im: im.verify()
    with Image.open(p) as im:
        im.load(); assert im.size == (1920, 1080)
    checks.append({'original': str(p), 'frame_id': row['frame_id'], 'sha256': sha(p), 'bytes': len(data), 'png_crc_and_decode_valid': True})
assert {p.name for p in raw.glob('*.png')} == {Path(c['original']).name for c in checks}
logs = '\n'.join((packet / ('capture.' + k + '.log')).read_text(encoding='utf-8-sig', errors='replace') for k in ['stdout', 'stderr'])
assert not re.search(r'^(?:SCRIPT ERROR:|ERROR:)', logs, re.M)
assert len(re.findall(r'^Vulkan .* - Forward\+ - Using Device', logs, re.M)) == 1
# This producer's lookdev parent finishes through manifest + actual exit,
# without catalogue_survey's optional success banner. Bind all eight saved rows.
assert len(re.findall(r'^CATALOGUE CAPTURE .* -> ', logs, re.M)) == 8
summary = {'source': source, 'exit_code': 0, 'frames': 8, 'manifest_sha256': sha(raw / 'manifest.json'), 'source_and_index_clean': True, 'graphics': g, 'original_images': checks, 'warnings': len(re.findall(r'^WARNING:', logs, re.M)), 'full_matrix_complete': False, 'fixture_disclosure': m['fixture_disclosure'], 'scope': 'Original Stormward approach across four clocks and clear/rain only. Runtime and blind review pending; no full384, earned route, physics contact, whole criterion, performance or device claim.'}
(packet / 'native-verified-summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: summary[k] for k in ['source', 'exit_code', 'frames', 'manifest_sha256', 'warnings', 'full_matrix_complete']}))
