from pathlib import Path
import hashlib, json, math, re, struct

baseline = Path('D:/tetherbound/lookdev-cloudreach-medium-visual-r1')
candidate = Path('D:/tetherbound/f26-trainer-medium-ff0395c9ae')
baseline_sha = 'f43cde88acde0648123b89895d3023e1f5c50a08'
candidate_sha = 'ff0395c9ae9c7ba80d8d1f0ea003c1cab3bc06cd'
before = json.loads((baseline / 'manifest.json').read_text(encoding='utf-8'))
after = json.loads((candidate / 'manifest.json').read_text(encoding='utf-8'))
native = json.loads(candidate.with_suffix('.native.json').read_text(encoding='utf-8'))
assert before['graphics_capture']['source_commit'] == baseline_sha
assert after['graphics_capture']['source_commit'] == candidate_sha == native['source_commit']
assert native['native_exit'] == 0 and not native['timed_out'] and not native['errors']
assert before['complete'] and after['complete'] and not after['failures']
assert after['planned_frame_count'] == after['captured_frame_count'] == 2
for receipt in [before, after]:
    assert receipt['graphics_capture']['preset'] == 'Medium'
    assert receipt['graphics_capture']['renderer'] == 'forward_plus'
    assert receipt['resolution'] == [1920, 1080]
    assert receipt['bound_player_character'] == 'trainer'
    assert receipt['capture_camera']['source'] == 'production CameraRig/Camera3D'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def distances(a, b):
    return math.sqrt(sum((x-y)**2 for x, y in zip(a, b)))

def numeric_diff(a, b):
    if isinstance(a, dict):
        assert a.keys() == b.keys()
        return max((numeric_diff(a[k], b[k]) for k in a), default=0)
    if isinstance(a, list):
        assert len(a) == len(b)
        return max((numeric_diff(x, y) for x, y in zip(a, b)), default=0)
    return abs(a-b)

files = []
comparisons = []
for time in ['day', 'night']:
    frame_id = f'cloudreach__gate_lower_cliffs__02__galefoot_waycamp__{time}'
    a = next(f for f in before['frames'] if f['frame_id'] == frame_id)
    b = next(f for f in after['frames'] if f['frame_id'] == frame_id)
    assert a['time'] == b['time'] == time
    assert a['observed_clock']['time_of_day'] == b['observed_clock']['time_of_day'] == time
    for prefix, directory, row in [('baseline', baseline, a), ('candidate', candidate, b)]:
        path = directory / f'{frame_id}.png'
        data = path.read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR'
        width, height = struct.unpack('>II', data[16:24])
        assert [width, height] == [1920, 1080] and len(data) == row['bytes']
        files.append(dict(kind=prefix, path=str(path), sha256=hashlib.sha256(data).hexdigest(),
                          bytes=len(data), dimensions=[width, height], frame_id=frame_id))
    comparisons.append(dict(frame_id=frame_id,
        player_distance_delta_m=distances(a['player_position'], b['player_position']),
        camera_distance_delta_m=distances(a['camera_position'], b['camera_position']),
        camera_transform_max_component_delta=numeric_diff(a['camera_transform'], b['camera_transform']),
        rig_transform_max_component_delta=numeric_diff(a['camera_rig_transform'], b['camera_rig_transform']),
        heading_delta=numeric_diff(a['view_heading_xz'], b['view_heading_xz']),
        spring_length_delta_m=b['camera_rig_spring_length']-a['camera_rig_spring_length'],
        resolved_ground_delta_m=b['resolved_ground_y']-a['resolved_ground_y'],
        baseline_clock=a['observed_clock'], candidate_clock=b['observed_clock'],
        hour_delta=b['observed_clock']['hour']-a['observed_clock']['hour'],
        nearby_creatures_baseline=a.get('nearby_creatures_160m'),
        nearby_creatures_candidate=b.get('nearby_creatures_160m')))

log_path = candidate.with_suffix('.log')
log_lines = log_path.read_text(encoding='utf-8', errors='replace').splitlines()
errors = [line for line in log_lines if re.search(r'ERROR:|SCRIPT ERROR:|Parse Error:', line)]
assert not errors
camera_header_keys = ['path', 'fov', 'near', 'far', 'source']
header_same = {key: before['capture_camera'][key] == after['capture_camera'][key] for key in camera_header_keys}
assert all(header_same.values())
report = dict(scope='Read-only source/receipt/pose/clock/PNG-header/hash verification. No pixel editing, engine, visual verdict or criterion MET.',
    baseline_source=baseline_sha, candidate_source=candidate_sha,
    baseline_art_text_sha256=before['graphics_capture']['graphics_config_sha256'],
    candidate_art_text_sha256=after['graphics_capture']['graphics_config_sha256'],
    manifest_hashes={'baseline': sha(baseline/'manifest.json'), 'candidate': sha(candidate/'manifest.json')},
    native_receipt=native, native_receipt_sha256=sha(candidate.with_suffix('.native.json')),
    native_log_sha256=sha(log_path), native_log_errors=errors,
    native_log_warnings=[line for line in log_lines if 'WARNING:' in line],
    camera_header_matches=header_same, comparisons=comparisons, files=files,
    limits=['Only Medium and trainer/Galefoot sampled. High is explicitly deferred, other three playable profiles and other-biome rim outcomes unproved.',
            'Prior Cloudreach full-bar FAIL remains. Matching poses/source receipts do not prove artistic improvement or unchanged animation/population/weather pixels.',
            'Prior baseline was a full24frame catalogue; candidate uses2frame subset with different startup/capture history.',
            'Night clock around23 is an interpolated golden-to-night interval, not the exact midnight rim endpoint.',
            'Hashes cover original PNG bytes, not a re-encoded or altered image.'])
output = Path('.tmp/f26-medium-independent-receipt-review.json')
output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(dict(output=str(output), native_exit=native['native_exit'],
    native_errors=len(errors), pngs_verified=len(files), comparisons=comparisons), indent=2))
