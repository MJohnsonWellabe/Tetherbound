from pathlib import Path
import hashlib, json, struct, zlib, re
from PIL import Image
packet = Path(__file__).parent
root = Path('D:/CodexTemp/tetherbound-native/d-e2d54b40aa')
menu = 'ui-menu' in packet.name
context = 'menu' if menu else 'craft'
biome, subset, dirname = ('cloudreach', 'Galefoot', 'e-ui-cloudreach-menu-1e2-day-r1') if menu else ('meadows', 'South Bridge', 'e-ui-meadows-craft-9a359-day-r1')
raw = root / '.tmp' / dirname
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
source = '1e2cc89ae9e74fbd64f195616fba3fe37695774b'
t = read(packet / 'capture-terminal.json')
assert t['source'] == source and t['exit_code'] == 0 and t['reason'] == 'process_exit'
b, a = [read(packet / ('source-' + phase + '-capture.json')) for phase in ['before', 'after']]
assert b['source'] == a['source'] == source and b['tracked_clean'] and a['tracked_clean']
assert b['head_tree'] == b['index_tree'] == a['head_tree'] == a['index_tree']
m = read(raw / 'manifest.json')
assert m['complete'] is True and m['failures'] == []
assert m['biome_id'] == biome and m['subsets'] == [subset.lower()] and m['requested_times'] == ['day']
assert m['captured_frame_count'] == m['planned_frame_count'] == len(m['frames']) == 1
assert m['planned_frame_ids'] == [m['frames'][0]['frame_id']] and m['ui_contexts'] == [context]
g = m['graphics_capture']
assert g['source_commit'] == source and g['renderer'] == m['rendering_method'] == 'forward_plus'
assert g['preset'] == 'High' and g['resolution'] == m['resolution'] == [1920, 1080]
expected = ['ui-backpack', 'ui-quest_log', 'ui-build', 'ui-players', 'ui-settings', 'ui-settings-controls', 'ui-map'] if menu else ['ui-craft-longest-known']
u = m['ui_frames']
assert [row['context'] for row in u] == expected
for row in u:
    assert row['state_guard_pass'] is True and row['input_owner'] and row['focus'] and row['visible_text']
    assert row['focus'].startswith(row['input_owner'] + '/')
if menu:
    mp = u[-1]
    assert mp['display_realm'] == biome and mp['terrain_ready'] and mp['realm_tabs_visible']
    assert any(r.get('discovered') is True for r in mp['regions'])
    assert any(v.startswith('A on a binding to change it') for v in u[5]['visible_text'])
else:
    row = u[0]
    assert row['recipe_id'] and row['recipe_count'] > 0 and row['material_text'] and row['output_text'] and row['action_hint']
    assert row['material_lines'] <= row['material_visible_lines'] and not row['material_clip_text']
rows = [m['frames'][0]] + u
names = []
checks = []
for row in rows:
    assert row['file'].startswith('res://.tmp/' + dirname + '/')
    p = root / row['file'].removeprefix('res://')
    assert p.parent == raw
    names.append(p.name)
    data = p.read_bytes()
    assert data[:8] == b'\x89PNG\r\n\x1a\n'
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
    checks.append({'original': str(p), 'sha256': sha(p), 'bytes': len(data), 'png_crc_and_decode_valid': True})
assert len(set(names)) == len(rows) and {p.name for p in raw.glob('*.png')} == set(names)
logs = '\n'.join((packet / ('capture.' + k + '.log')).read_text(encoding='utf-8-sig', errors='replace') for k in ['stdout', 'stderr'])
assert not re.search(r'^(?:SCRIPT ERROR:|ERROR:)', logs, re.M)
assert len(re.findall(r'^Vulkan .* - Forward\+ - Using Device', logs, re.M)) == 1
assert 'CATALOGUE SURVEY OK: 1/1 frames' in logs
summary = {'source': source, 'exit_code': 0, 'context': context, 'base_frames': 1, 'ui_frames': len(u), 'total_original_pngs': len(rows), 'manifest_sha256': sha(raw / 'manifest.json'), 'source_and_index_clean': True, 'graphics': g, 'original_images': checks, 'warnings': len(re.findall(r'^WARNING:', logs, re.M)), 'scope': 'Original bounded UI contexts and one base view only. Pixel readability, original runtime/blind review and whole criterion pending; no campaign or full matrix credit.'}
(packet / 'native-verified-summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k:summary[k] for k in ['source','exit_code','context','base_frames','ui_frames','total_original_pngs','manifest_sha256','warnings']}))


