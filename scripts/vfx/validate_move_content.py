"""Cheap F25 mapping/reference/budget audit. Never starts Godot or imports assets.

Run with --moves <F23 ignored proposal> while its sole writer owns moves.json.
The default audits the actual checkout and fails on unmapped rows. A proposal
pass is source evidence only; it cannot certify main, pixels or frame time.
"""
import argparse
import hashlib
import json
import math
import re
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQUIRED = {
    'stone_throw', 'fireball', 'flame_cone', 'ember_burst', 'sky_lightning',
    'chain_lightning', 'water_jet', 'bubble_volley', 'tidal_wave', 'wind_blade',
    'tornado', 'ice_shard_volley', 'frost_breath', 'shadow_bolt', 'psychic_pulse',
    'root_stone_spikes', 'quake_ring', 'slash_trail', 'charge_dash', 'heal_pulse',
    'buff_aura', 'debuff_hex', 'guard_flash', 'catch_tether_beam',
}
PARAMETERS = ('count', 'size', 'colour', 'arc', 'speed', 'spread', 'trail', 'impact_scale')

def audit(moves_path: Path):
    failures = []
    def check(ok, message):
        if not ok: failures.append(message)
    def read(path): return json.loads(path.read_text(encoding='utf-8-sig'))
    config = read(ROOT/'data/config/vfx.json')['move_library']
    archetypes = config['archetypes']
    cues = read(ROOT/'data/config/audio.json')['move_effect_cues']
    moves = read(moves_path)['moves']
    check(set(archetypes) == REQUIRED, 'Archetype catalogue must contain exactly the24 specified IDs')
    check(config['enabled'] is True, 'Owner rollout requires the production move library enabled')
    consumed = set()
    for name, row in archetypes.items():
        for component in ('body', 'trail', 'impact', 'sound', 'budget', 'parameters', 'damage_timing'):
            check(isinstance(row.get(component), dict) and bool(row[component]), f'{name}: missing {component}')
        check(bool(row['body'].get('shape')) and bool(row['body'].get('motion')), f'{name}: body needs geometry/motion')
        check(row['budget']['impact'] + row['budget']['trail'] <= config['ordinary_particle_limit'], f'{name}: over ordinary particle budget')
        tiers = row.get('mastery', [])
        check(len(tiers) == 5, f'{name}: needs five authored mastery ranks')
        for key in ('size_scale', 'trail_scale', 'impact_scale'):
            values = [t.get(key, 1.0) for t in tiers]
            check(all(math.isfinite(v) and v > 0 for v in values), f'{name}: invalid {key}')
            check(values == sorted(values) and values[-1] > values[0], f'{name}: no monotonic {key} growth')
        sounds = [row['sound'], *row.get('sound_variants', {}).values()]
        for sound in sounds:
            for phase in ('launch', 'travel', 'impact', 'launch_travel', 'launch_mastery', 'impact_mastery', 'launch_travel_mastery'):
                cue = sound.get(phase)
                check(cue in cues, f'{name}: missing sound ID {phase}={cue}')
                if cue in cues: consumed.add(cue)
    for name, row in moves.items():
        spec = row.get('vfx', {})
        check(spec.get('archetype') in archetypes, f'{name}: unmapped archetype')
        check(all(key in spec for key in PARAMETERS), f'{name}: incomplete visual parameters')
        for key in PARAMETERS:
            value = spec.get(key)
            if key == 'colour':
                check(isinstance(value, str) and bool(re.fullmatch(r'#[0-9a-fA-F]{6}', value)), f'{name}: invalid colour')
            else:
                check(type(value) in (int, float) and math.isfinite(value), f'{name}: invalid {key}')
        if row.get('slot') != 'ultimate':
            check(spec.get('mastery_owner') == 'f25', f'{name}: ordinary tier owner must be f25 before activation')
    pebble = moves.get('pebble_toss', {}).get('vfx', {})
    rock = moves.get('rock_throw', {}).get('vfx', {})
    check(pebble.get('count') == 3 and pebble.get('size', 99) < 0.5, 'Pebble Toss must freeze3small stones')
    check(rock.get('count') == 1 and rock.get('size', 0) >= 0.5, 'Rock Throw must freeze1boulder')
    pcm = {}
    for cue in sorted(consumed):
        path = ROOT/cues[cue].removeprefix('res://')
        check(path.is_file(), f'{cue}: missing PCM asset')
        if not path.is_file(): continue
        with wave.open(str(path), 'rb') as sound:
            width = sound.getsampwidth()
            duration = sound.getnframes()/sound.getframerate()
            frames = sound.readframes(sound.getnframes())
        check(width == 2 and 0 < duration <= 2.0, f'{cue}: unsupported or unbounded cue')
        if width == 2:
            samples = struct.unpack('<' + str(len(frames)//2) + 'h', frames)
            peak = max(map(abs, samples), default=0)
            check(0 < peak < 32767, f'{cue}: silent/clipped cue')
            pcm[cue] = {'duration_seconds': duration, 'peak': peak, 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    paths = []
    for folder, pattern in [('scripts/vfx', '*.gd'), ('assets/vfx/shaders', '*.gdshader')]:
        for file in (ROOT/folder).glob(pattern):
            if file.name in ('body_glow.gd','combat_vfx.gd','level_up_flourish.gd','vfx_burst.gd'): continue
            paths.append(file)
            for ref in re.findall(r'(?:preload|load)\("(res://[^\"]+)"\)', file.read_text()):
                check((ROOT/ref.removeprefix('res://')).is_file(), f'{file.name}: missing reference {ref}')
    return {'scope': 'Static source audit; no engine grammar/visual/runtime/authority/performance proof',
            'moves_path': str(moves_path.resolve()), 'moves_sha256': hashlib.sha256(moves_path.read_bytes()).hexdigest(),
            'move_count': len(moves), 'archetype_count': len(archetypes), 'cue_count': len(consumed),
            'audio_pcm': pcm, 'source_reference_files': len(paths), 'failures': failures, 'pass': not failures}

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--moves', type=Path, default=ROOT/'data/moves/moves.json')
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    result = audit(args.moves)
    if args.out: args.out.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({k:v for k,v in result.items() if k!='audio_pcm'}, indent=2))
    raise SystemExit(0 if result['pass'] else 1)
