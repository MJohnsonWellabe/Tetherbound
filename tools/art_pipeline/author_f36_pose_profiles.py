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
import sys
import copy


def qmul(a, b):
    x, y, z, w = a
    X, Y, Z, W = b
    return [w*X+x*W+y*Z-z*Y, w*Y-x*Z+y*W+z*X,
            w*Z+x*Y-y*X+z*W, w*W-x*X-y*Y-z*Z]


def qinverse(q):
    return [-q[0], -q[1], -q[2], q[3]]


def qvector(q, v):
    return qmul(qmul(q, [*v, 0]), qinverse(q))[:3]


def aim_delta(rest, parent, direction, twist_deg=0):
    """Aim the installed bone's +Y axis in source space; no guessed rig axes."""
    world = qmul(parent, rest)
    current = qvector(world, [0, 1, 0])
    length = math.sqrt(sum(x*x for x in direction))
    target = [x / length for x in direction]
    cross = [current[1]*target[2]-current[2]*target[1],
             current[2]*target[0]-current[0]*target[2],
             current[0]*target[1]-current[1]*target[0]]
    turn = [*cross, 1 + sum(a*b for a, b in zip(current, target))]
    norm = math.sqrt(sum(x*x for x in turn))
    if norm < 1e-6:
        raise ValueError('Authored tuck must not use an ambiguous opposite-axis aim')
    turn = [x/norm for x in turn]
    local = qmul(qinverse(parent), qmul(turn, world))
    # Rotate the feather/paw cross-section around the aimed bone, preserving
    # its direction. A folded wing also needs its broad plane laid flat.
    twist = math.radians(twist_deg) / 2
    local = qmul(local, [0, math.sin(twist), 0, math.cos(twist)])
    delta = qmul(qinverse(rest), local)
    # Godot Quaternion.from_euler uses YXZ. Keep the existing recipe format.
    x, y, z, w = delta
    degrees = [math.asin(max(-1, min(1, 2*(w*x-y*z)))),
               math.atan2(2*(x*z+w*y), 1-2*(x*x+y*y)),
               math.atan2(2*(x*y+w*z), 1-2*(x*x+z*z))]
    return [math.degrees(a) for a in degrees], local


STARTER_TUCKS = {
    # Knees/paws curl toward the belly instead of remaining below the flank.
    'terrapup': {
        'spine': [-.25, 0, .968],
        'neck': [.3, .8, .52],
        **{f'{end}_upper_{side}': [.55, -.35, .76]
           for end in ('front', 'rear') for side in ('l', 'r')},
        **{f'{end}_lower_{side}': [.4, .75, -.53]
           for end in ('front', 'rear') for side in ('l', 'r')},
    },
    # Arms and bent hind legs lie alongside the torso, not as floor props.
    'ripplet': {
        'spine': [-.9, .4, .2],
        'neck': [.8, .5, .33],
        **{f'arm_{side}': [inward*.5, -.6, -.62]
           for side, inward in (('l', 1), ('r', -1))},
        **{f'leg_upper_{side}': [inward*.4, -.35, .85]
           for side, inward in (('l', 1), ('r', -1))},
        **{f'leg_lower_{side}': [inward*.2, .8, -.56]
           for side, inward in (('l', 1), ('r', -1))},
    },
    # Fold both wing chains back along the body, then return their tips.
    # The installed lateral 2.075-unit wing span is not a folded-wing rest.
    'galewisp': {
        'spine': [-.6, .4, .69],
        'neck': [.2, .6, .77],
        **{f'wing_upper_{side}': [.55, -.25, -.80]
           for side in ('l', 'r')},
        **{f'wing_tip_{side}': [inward*.15, .3, .942]
           for side, inward in (('l', 1), ('r', -1))},
        **{f'leg_upper_{side}': [.4, -.4, .82]
           for side in ('l', 'r')},
        **{f'leg_lower_{side}': [.2, .8, -.56]
           for side in ('l', 'r')},
    },
}

STARTER_TWISTS = {'terrapup': {f'{end}_upper_{side}': 90
                             for end in ('front', 'rear') for side in ('l', 'r')},
                  'ripplet': {'neck': 90},
                  'galewisp': {'wing_upper_l': 150, 'wing_upper_r': -90,
                              'wing_tip_l': 90, 'wing_tip_r': -90, 'neck': 90}}


def author_starter_tuck(name, row, roles):
    raw = (ROOT / row['model'].replace('res://', '')).read_bytes()
    if hashlib.sha256(raw).hexdigest() != row['source_sha256']:
        raise ValueError(f'{name}: installed rig changed; refuse stale tuck recipe')
    length = struct.unpack_from('<I', raw, 12)[0]
    nodes = json.loads(raw[20:20+length])['nodes']
    parents = {child: i for i, node in enumerate(nodes) for child in node.get('children', [])}
    worlds, terminal = {}, {}
    def visit(i):
        if i in worlds:
            return worlds[i]
        node = nodes[i]
        parent = visit(parents[i]) if i in parents else [0, 0, 0, 1]
        rest = node.get('rotation', [0, 0, 0, 1])
        if node.get('name') in STARTER_TUCKS[name]:
            degrees, local = aim_delta(rest, parent, STARTER_TUCKS[name][node['name']],
                                      STARTER_TWISTS.get(name, {}).get(node['name'], 0))
            terminal[node['name']] = degrees
        else:
            local = rest
        worlds[i] = qmul(parent, local)
        return worlds[i]
    for i in range(len(nodes)):
        visit(i)
    for frame in roles['faint']['frames']:
        envelope = min(1, frame['phase'] / .7)
        # Authored spine/neck settling and appendage tucks; no translation,
        # scaling or missing vertices can conceal a projecting body part.
        frame['bones'] = {bone: [angle * envelope for angle in terminal.get(bone, [0, 0, 0])]
                          for bone in row['bones']}
    return roles

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
            # The installed folded wing is the stable collapse shape. Opening
            # it while rolling made the bird balance on an upright wing tip.
            return [0, 0, 0]
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
    # Recipe-only edits reuse the previously bound rig census in sparse lanes.
    # Runtime still rejects any installed model whose exact hash has changed.
    existing = json.loads(OUT.read_text())['species'] if '--profiles-only' in sys.argv else None
    rows = {}
    profiles = {}
    rig_profiles = {}
    for name, definition in species.items():
        path = ROOT / definition['placeholder']['model'].replace('res://', '')
        if existing is not None:
            prior = existing[name]
            if prior['model'] != definition['placeholder']['model']:
                raise ValueError(f'{name}: model path changed; require full rig census')
            bones = prior['bones']
            source_hash = prior['source_sha256']
        else:
            raw = path.read_bytes()
            length = struct.unpack_from('<I', raw, 12)[0]
            gltf = json.loads(raw[20:20 + length])
            bones = list(dict.fromkeys(gltf['nodes'][i]['name'] for skin in gltf.get('skins', []) for i in skin['joints']))
            source_hash = hashlib.sha256(raw).hexdigest()
        if not bones:
            raise ValueError(f'{name}: no installed rig')
        winged = 'wing_upper_l' in bones
        biped = 'arm_l' in bones
        family = 'winged' if winged else 'biped' if biped else 'quadruped'
        signature = tuple(bones)
        if signature in rig_profiles:
            rows[name] = {'model': definition['placeholder']['model'], 'source_sha256': source_hash,
                          'rig_family': family, 'bones': bones, 'profile': rig_profiles[signature]}
            continue
        roles = {}
        for role in ('hit', 'faint', 'swim', 'fly_grip', 'ride'):
            frames = []
            for sample in range(9):
                phase = sample / 8
                frames.append({'phase': phase, 'bones': {bone: rotation(bone, role, phase, winged, biped) for bone in bones},
                               'pivot_roll_deg': 90 * min(1, phase / .7) if role == 'faint' else 0})
            roles[role] = {'duration_s': {'hit': .24, 'faint': 1.2, 'swim': 1.15, 'fly_grip': .9, 'ride': .8}[role],
                           'loop': role in ('swim', 'fly_grip', 'ride'), 'frames': frames}
        profile = f'{family}_{len(profiles) + 1}'
        profiles[profile] = roles
        rig_profiles[signature] = profile
        rows[name] = {'model': definition['placeholder']['model'], 'source_sha256': source_hash,
                      'rig_family': family, 'bones': bones, 'profile': profile}
    # These recipes belong only to the measured starters. Sharing a bone-name
    # signature is not evidence that another species shares their proportions.
    for name in STARTER_TUCKS:
        row = rows[name]
        profile = name + '_tucked'
        profiles[profile] = author_starter_tuck(name, row, copy.deepcopy(profiles[row['profile']]))
        row['profile'] = profile
    OUT.write_text(json.dumps({'enabled_species': [], 'scope': 'presentation_only_no_save_or_network_payload',
                               'status': 'unjudged_candidate_off', 'species': rows, 'profiles': profiles}, indent=2) + '\n')
    print(f'Authored five candidate roles for {len(rows)} installed species; all disabled')


if __name__ == '__main__':
    main()
