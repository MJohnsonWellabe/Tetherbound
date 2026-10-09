"""Author review-only pose recipes from installed rigs; no engine or service tasks.

No original mesh, animation, skin, texture or durable creature identity changes.
Runtime verifies bone names before installing a per-instance AnimationLibrary.
Re-run after any mesh replacement: source hashes bind each recipe to its rig.
"""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'data/creatures/f36_pose_candidates.json'


def rotation(bone, role, phase, winged, biped):
    wave = math.sin(phase * math.tau)
    opposite = -1 if bone.endswith('_r') else 1
    if role == 'hit':
        envelope = math.sin(phase * math.pi)
        return [(-16 if bone in ('spine', 'neck') else 12 if bone == 'head' else 0) * envelope, 0, 0]
    if role == 'faint':
        envelope = min(1, phase / .7)
        angle = 0
        if 'upper' in bone and 'wing' not in bone:
            angle = -42
        elif 'lower' in bone:
            angle = 68
        elif bone == 'neck':
            angle = 20
        elif bone == 'head':
            angle = 12
        if 'wing' in bone:
            return [0, 0, opposite * (52 if 'upper' in bone else -34) * envelope]
        return [angle * envelope, 0, 0]
    if role == 'swim':
        if 'tail' in bone:
            return [0, 18 * wave, 0]
        if 'upper' in bone and 'wing' not in bone or bone.startswith('arm'):
            return [-25 + 22 * wave * opposite, 0, 0]
        if 'lower' in bone:
            return [28 - 12 * wave * opposite, 0, 0]
        if 'wing' in bone:
            return [0, 0, opposite * 38]
        return [(-10 if bone == 'neck' else 0), 0, 0]
    if role == 'fly_grip':
        if 'wing' in bone:
            return [0, 0, opposite * (12 + 24 * wave if 'upper' in bone else -12 + 10 * wave)]
        if 'upper' in bone:
            return [-30 if winged else -15, 0, 0]
        if 'lower' in bone:
            return [52, 0, 0]
        return [(-8 if bone == 'neck' else 0), 0, 0]
    if role == 'ride':
        if 'upper' in bone and 'wing' not in bone:
            rear = -1 if bone.startswith('rear') else 1
            return [18 * wave * opposite * rear, 0, 0]
        if 'lower' in bone:
            return [12 + 12 * wave * opposite, 0, 0]
        if 'wing' in bone:
            return [0, 0, opposite * 40]
        if bone == 'neck':
            return [-6, 0, 0]
    return [0, 0, 0]


def main():
    species = json.loads((ROOT / 'data/creatures/species.json').read_text())['species']
    rows = {}
    profiles = {}
    rig_profiles = {}
    for name, definition in species.items():
        path = ROOT / definition['placeholder']['model'].replace('res://', '')
        raw = path.read_bytes()
        length = struct.unpack_from('<I', raw, 12)[0]
        gltf = json.loads(raw[20:20 + length])
        bones = list(dict.fromkeys(gltf['nodes'][i]['name'] for skin in gltf.get('skins', []) for i in skin['joints']))
        if not bones:
            raise ValueError(f'{name}: no installed rig')
        winged = 'wing_upper_l' in bones
        biped = 'arm_l' in bones
        family = 'winged' if winged else 'biped' if biped else 'quadruped'
        signature = tuple(bones)
        if signature in rig_profiles:
            rows[name] = {'model': definition['placeholder']['model'], 'source_sha256': hashlib.sha256(raw).hexdigest(),
                          'rig_family': family, 'bones': bones, 'profile': rig_profiles[signature]}
            continue
        roles = {}
        for role in ('hit', 'faint', 'swim', 'fly_grip', 'ride'):
            frames = []
            for sample in range(9):
                phase = sample / 8
                frames.append({'phase': phase, 'bones': {bone: rotation(bone, role, phase, winged, biped) for bone in bones},
                               'pivot_roll_deg': 82 * min(1, phase / .7) if role == 'faint' else 0})
            roles[role] = {'duration_s': {'hit': .24, 'faint': 1.2, 'swim': 1.15, 'fly_grip': .9, 'ride': .8}[role],
                           'loop': role in ('swim', 'fly_grip', 'ride'), 'frames': frames}
        profile = f'{family}_{len(profiles) + 1}'
        profiles[profile] = roles
        rig_profiles[signature] = profile
        rows[name] = {'model': definition['placeholder']['model'], 'source_sha256': hashlib.sha256(raw).hexdigest(),
                      'rig_family': family, 'bones': bones, 'profile': profile}
    OUT.write_text(json.dumps({'enabled_species': [], 'scope': 'presentation_only_no_save_or_network_payload',
                               'status': 'unjudged_candidate_off', 'species': rows, 'profiles': profiles}, indent=2) + '\n')
    print(f'Authored five candidate roles for {len(rows)} installed species; all disabled')


if __name__ == '__main__':
    main()
