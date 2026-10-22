"""F36#1: bind Voltarach's pose recipe to its native eight-leg model.

Rebinds the voltarach row in data/creatures/f36_pose_candidates.json to the
switched-on native model (rig and bind contracts read from the GLB, as the
other native rebinds were) and writes a dedicated arachnid profile for the
five pose roles. Other rows and profiles stay byte-identical. The pose post-pass
keeps skipping voltarach; this script owns its row. Faint frames are seated
with the same skin-measured grounding as every other species.

  python3 tools/art_pipeline/f36_arachnid_profile.py [--check]
"""
import hashlib
import json
import math
import re
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import f36_pose_postpass as POST  # noqa: E402
import f36_pose_solver as SOLVER  # noqa: E402
import f36_skin as SKIN  # noqa: E402

SPECIES = 'voltarach'
MODEL = 'res://assets/creatures/tetherbound/voltarach/candidate/models/creature_voltarach_native.glb'
PROFILE = 'voltarach_arachnid_native'
ROLE_SPECS = {
    'hit': {'duration_s': 0.24, 'loop': False, 'start_phase': 0.125, 'release_phase': 0.25},
    'faint': {'duration_s': 1.2, 'loop': False},
    'swim': {'duration_s': 1.15, 'loop': True},
    'fly_grip': {'duration_s': 0.9, 'loop': True},
    'ride': {'duration_s': 0.8, 'loop': True},
}
SAMPLES = 9
CANDIDATE_1022 = '--candidate-1022' in sys.argv


def legs(bones, segment):
    return [b for b in bones if b.startswith('leg_') and b.endswith('_%d' % segment)]


def pair(bone):
    return int(bone.split('_')[1])


def pose(rig, role, phase):
    turns = {}
    pivot = POST.IDENTITY
    bones = rig.contract
    a = math.sin(phase * math.tau)

    def add(b, m):
        if b in bones:
            turns[b] = POST.mul(m, turns[b]) if b in turns else m

    if role == 'hit':
        # Rear up from the blow: front pairs lift, the body tips back.
        e = POST.hit_envelope(phase)
        # Close-1022 candidate (OFF): b1/b2 judges still read the spider's hit as standing.
        k = 2.0 if CANDIDATE_1022 else 1.0
        pivot = rig.pitch(8 * k * e)
        add('head', rig.pitch(10 * e))
        for b in legs(bones, 1):
            if pair(b) <= 2:
                add(b, rig.abduct(b, (26 if pair(b) == 1 else 14) * k * e))
                add(b, rig.swing(12 * k * e))
    elif role == 'faint' and CANDIDATE_1022:
        # Close-1022 candidate (OFF): GPU judges read the belly-down curl as
        # standing. Tip onto the side with every leg curled tight, head down.
        e = min(1.0, phase / .7)
        pivot = rig.roll(72 * e)
        add('head', rig.pitch(-18 * e))
        for b in legs(bones, 1):
            add(b, rig.abduct(b, 10 * e))
        for b in legs(bones, 2):
            add(b, rig.abduct(b, -80 * e))
        for b in legs(bones, 3):
            add(b, rig.abduct(b, -95 * e))
    elif role == 'faint':
        # Collapse belly-down with every leg curled in under the body.
        e = min(1.0, phase / .7)
        pivot = rig.roll(12 * e)
        add('head', rig.pitch(-12 * e))
        for b in legs(bones, 1):
            add(b, rig.abduct(b, 18 * e))
        for b in legs(bones, 2):
            add(b, rig.abduct(b, -55 * e))
        for b in legs(bones, 3):
            add(b, rig.abduct(b, -70 * e))
    elif role == 'swim':
        # Level body; the pairs sweep in alternating waves.
        add('head', rig.pitch(8))
        for b in legs(bones, 1):
            offset = (pair(b) - 1) * 0.25 + (0 if b.split('_')[2] == 'l' else 0.5)
            wave = math.sin((phase + offset) * math.tau)
            add(b, rig.swing(28 * wave * (1 if pair(b) <= 2 else -1)))
            add(b, rig.abduct(b, 10 + 8 * wave))
    elif role == 'fly_grip':
        # Carried aloft: legs drawn in, a slight dangle on the beat.
        for b in legs(bones, 2):
            add(b, rig.abduct(b, -48 - 6 * a))
        for b in legs(bones, 3):
            add(b, rig.abduct(b, -60))
        add('head', rig.pitch(-6))
    elif role == 'ride':
        # Braced under a rider: knees high and wide, body lowered.
        breathe = 0.5 + 0.5 * math.cos(phase * math.tau)
        for b in legs(bones, 1):
            add(b, rig.abduct(b, 16 + 3 * breathe))
        for b in legs(bones, 2):
            add(b, rig.abduct(b, -(22 + 4 * breathe)))
        add('head', rig.pitch(6))
    return rig.solve(turns), POST.euler(pivot)


def build_profile(rig, skin):
    profile = {}
    for role, spec in ROLE_SPECS.items():
        frames = []
        for sample in range(SAMPLES):
            phase = sample / (SAMPLES - 1)
            bones, pivot = pose(rig, role, phase)
            frames.append({'phase': phase, 'bones': bones, 'pivot_roll_deg': 0, 'pivot_rotation_deg': pivot})
        SOLVER.guard_stretch(skin, frames)
        profile[role] = dict(spec, frames=frames)
    SOLVER.ground_faint(skin, profile['faint']['frames'], lambda phase: min(1.0, phase / .7))
    return {role: {k: profile[role][k] for k in ('duration_s', 'loop', 'frames', 'start_phase', 'release_phase')
                   if k in profile[role]} for role in ROLE_SPECS}


def uid(model):
    text = (SKIN.ROOT / (model.replace('res://', '') + '.import')).read_text()
    return re.search(r'uid="(uid://[a-z0-9]+)"', text).group(1)


def rewrite(text):
    path = SKIN.ROOT / MODEL.replace('res://', '')
    raw = path.read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    gltf = json.loads(raw[20:20 + length])
    names, rig_contract, binds = POST.AUTHOR.rig_contracts(gltf, raw[20 + length + 8:])
    row = {'model': MODEL, 'source_sha256': hashlib.sha256(raw).hexdigest(), 'resource_uid': uid(MODEL),
           'rig_contract': rig_contract, 'bind_contract': binds, 'rig_family': 'arachnid',
           'bones': names, 'profile': PROFILE, 'grounded_roles': POST.GROUNDED}
    rig = POST.Rig(rig_contract, names)
    skin = SKIN.Skin(MODEL, rig_contract, names)
    profile = build_profile(rig, skin)
    live = json.loads(text)
    # Row: replace the whole voltarach block in the species table.
    rows_at = text.index('\n  "species": {')
    m = re.compile(r'\n    %s: \{' % re.escape(json.dumps(SPECIES))).search(text, rows_at)
    start, end = POST.value_span(text, m.end() - 1)
    lines = ['{']
    for i, (key, value) in enumerate(row.items()):
        sep = ',' if i < len(row) - 1 else ''
        lines.append('      %s: %s%s' % (json.dumps(key), json.dumps(value, separators=(',', ':')), sep))
    lines.append('    }')
    text = text[:start] + '\n'.join(lines) + text[end:]
    # Profile: replace the old one in place or rename it.
    profiles_at = text.index('\n  "profiles": {')
    old = live['species'][SPECIES]['profile']
    m = re.compile(r'\n    %s: ' % re.escape(json.dumps(old))).search(text, profiles_at)
    if m is None:
        m = re.compile(r'\n    %s: ' % re.escape(json.dumps(PROFILE))).search(text, profiles_at)
    start, end = POST.value_span(text, m.end())
    key_start = m.start() + 5
    text = text[:key_start] + json.dumps(PROFILE) + ': ' + json.dumps(profile, separators=(',', ':')) + text[end:]
    return text


def main():
    before = POST.LIVE.read_text()
    after = rewrite(before)
    if '--check' in sys.argv:
        print('stale' if after != before else 'current')
        sys.exit(1 if after != before else 0)
    json.loads(after)
    out = next((Path(a.split('=', 1)[1]) for a in sys.argv[1:] if a.startswith('--out=')), POST.LIVE)
    out.write_text(after)
    print('F36 voltarach arachnid profile written')


if __name__ == '__main__':
    main()
