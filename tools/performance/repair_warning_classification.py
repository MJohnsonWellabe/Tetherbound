"""Reclassify preserved Godot 4.7 error-channel packets; never change timings."""
import argparse
import hashlib
import json
import pathlib
import shutil

from collect_script_profile import is_warning_packet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('capture', type=pathlib.Path)
    args = parser.parse_args()
    receipt_path = args.capture / 'receipt.json'
    original_path = args.capture / 'receipt.original-warning-classification.json'
    if original_path.exists():
        parser.error('Original already preserved; refusing a second repair')
    original_raw = receipt_path.read_bytes()
    original = json.loads(original_raw)
    frames_path = args.capture / 'frames.jsonl'
    frames_raw = frames_path.read_bytes()
    frames = [json.loads(line) for line in frames_raw.splitlines()]
    start, end = original.get('start'), original.get('end')
    errors, warnings = [], []
    for packet in original.get('engine_errors', []):
        (warnings if is_warning_packet(packet) else errors).append(packet)
    gaps = sum(b['frame'] != a['frame'] + 1 for a, b in zip(frames, frames[1:]))
    assert len(frames) == original['profile_frames']
    assert gaps == original['frame_gaps']
    assert all(start[0] < frame['frame'] < end[1] for frame in frames)
    # No timing fields are recalculated, corrected, removed, or synthesized.
    repaired = dict(original)
    repaired.update({
        'engine_errors': errors, 'engine_warnings': warnings,
        'engine_error_count': len(errors), 'engine_warning_count': len(warnings),
        'warning_classification': 'Godot 4.7 OutputError payload[9] boolean warning; raw packets retained; malformed packets remain errors',
        'complete': bool(start and start[1] and end and end[2] and frames
                         and original['top_ten_callbacks'] and not gaps
                         and not original['saturated_frames'] and not errors
                         and original['engine_exit_code'] == 0),
        'classification_repair': {
            'original_receipt': original_path.name,
            'original_receipt_sha256': hashlib.sha256(original_raw).hexdigest(),
            'frames_sha256_unchanged': hashlib.sha256(frames_raw).hexdigest(),
            'native_rerun': False,
            'timing_fields_changed': False,
            'primary_source': 'https://github.com/godotengine/godot/blob/4.7-stable/core/debugger/debugger_marshalls.cpp',
            'reason': 'Remote error-channel packets include warnings; OutputError field 9 classifies them.',
        },
    })
    shutil.copyfile(receipt_path, original_path)
    receipt_path.write_text(json.dumps(repaired, indent=2) + '\n')
    assert frames_raw == frames_path.read_bytes()
    assert repaired['top_ten_callbacks'] == original['top_ten_callbacks']
    assert repaired['all_functions'] == original['all_functions']
    print(json.dumps({'complete': repaired['complete'], 'fatal_errors': len(errors),
                      'warnings': len(warnings), 'frames': len(frames),
                      'timings_unchanged': True, 'native_rerun': False,
                      'top_ten_callbacks': [{'signature': row['signature'],
                           'self_ms_per_process_frame': round(row['self_ms_per_process_frame'], 6)}
                           for row in repaired['top_ten_callbacks']]}, indent=2))
    return 0 if repaired['complete'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
