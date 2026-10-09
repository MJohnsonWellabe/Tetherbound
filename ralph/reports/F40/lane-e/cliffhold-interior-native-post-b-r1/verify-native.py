from pathlib import Path
import hashlib, json, struct, zlib, re
from PIL import Image

packet = Path(__file__).parent
root = Path('D:/CodexTemp/tetherbound-native/d-e2d54b40aa')
raw = root / '.tmp/e-cliffhold-interior-9a359-day-r1'
read = lambda p: json.loads(p.read_text(encoding='utf-8-sig'))
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
source = '9a359dfd5c545aa471f9dbe317ef063e0408dc1d'
terminal = read(packet / 'capture-terminal.json')
assert terminal['source'] == source and terminal['exit_code'] == 0 and terminal['reason'] == 'process_exit'
before, after = [read(packet / ('source-' + phase + '-capture.json')) for phase in ['before', 'after']]
assert before['source'] == after['source'] == source and before['tracked_clean'] and after['tracked_clean']
assert before['head_tree'] == before['index_tree'] == after['head_tree'] == after['index_tree']
m = read(raw / 'manifest.json')
assert m['complete'] is True and m['full_matrix_complete'] is False and m['cliffhold_interior_only'] is True
assert m['candidate_preview'] is False and m['failures'] == []
assert m['captured_frame_count'] == m['planned_frame_count'] == len(m['frames']) == 1
frame_id = 'cloudreach__upper_cloudreach__09__cliffhold__approach__day__clear'
assert m['selected_frame_ids'] == [frame_id] and m['frames'][0]['frame_id'] == frame_id
graphics = m['graphics_capture']
assert graphics['source_commit'] == source and graphics['renderer'] == 'forward_plus'
assert graphics['preset'] == 'High' and graphics['resolution'] == [1920, 1080]
p = raw / (frame_id + '.png')
assert {f.name for f in raw.glob('*.png')} == {p.name}
assert m['frames'][0]['file'] == 'res://.tmp/e-cliffhold-interior-9a359-day-r1/' + p.name
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
    if kind == b'IEND':
        ended = True
        break
assert ended and offset == len(data)
with Image.open(p) as im:
    im.verify()
with Image.open(p) as im:
    im.load()
    assert im.size == (1920, 1080)
logs = '\n'.join((packet / ('capture.' + k + '.log')).read_text(encoding='utf-8-sig', errors='replace') for k in ['stdout', 'stderr'])
assert not re.search(r'^(?:SCRIPT ERROR:|ERROR:)', logs, re.M)
summary = {'source': source, 'exit': 0, 'frames': 1, 'frame_id': frame_id, 'png': str(p),
           'png_sha256': sha(p), 'png_bytes': len(data), 'png_crc_and_decode_valid': True,
           'manifest_sha256': sha(raw / 'manifest.json'), 'graphics': graphics,
           'full_matrix_complete': False, 'source_and_index_clean': True,
           'warnings': len(re.findall(r'^WARNING:', logs, re.M)),
           'scope': 'Original one interior day/clear approach image only; original runtime/blind review and whole criterion pending.'}
(packet / 'native-verified-summary.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
print(json.dumps({k: summary[k] for k in ['source', 'exit', 'frames', 'frame_id', 'manifest_sha256', 'warnings']}))
