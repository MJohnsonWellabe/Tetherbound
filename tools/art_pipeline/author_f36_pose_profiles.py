"""Author default-enabled pose recipes from installed rigs; no engine or service tasks.

No original mesh, animation, skin, texture or durable creature identity changes.
Runtime verifies the source hash or packaged UID/rest/bind contract before installation.
Re-run after any mesh replacement: source hashes bind each recipe to its rig.
"""
import hashlib
import json
import math
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'data/creatures/f36_pose_candidates.json'


def node_matrix(node):
    if 'matrix' in node:
        return node['matrix']
    x, y, z, w = node.get('rotation', [0, 0, 0, 1])
    sx, sy, sz = node.get('scale', [1, 1, 1])
    tx, ty, tz = node.get('translation', [0, 0, 0])
    return [(1 - 2 * (y*y + z*z)) * sx, 2 * (x*y + z*w) * sx, 2 * (x*z - y*w) * sx, 0,
            2 * (x*y - z*w) * sy, (1 - 2 * (x*x + z*z)) * sy, 2 * (y*z + x*w) * sy, 0,
            2 * (x*z + y*w) * sz, 2 * (y*z - x*w) * sz, (1 - 2 * (x*x + y*y)) * sz, 0,
            tx, ty, tz, 1]


def multiply(left, right):
    return [sum(left[k * 4 + row] * right[column * 4 + k] for k in range(4))
            for column in range(4) for row in range(4)]


def rig_contracts(gltf, binary):
    nodes = gltf['nodes']
    joints = list(dict.fromkeys(i for skin in gltf.get('skins', []) for i in skin['joints']))
    names = [nodes[i]['name'] for i in joints]
    if not joints or len(set(names)) != len(names):
        raise ValueError('installed rig needs uniquely named joints')
    parents = {child: parent for parent, node in enumerate(nodes) for child in node.get('children', [])}
    rig = {}
    for joint in joints:
        rest = node_matrix(nodes[joint])
        parent = parents.get(joint)
        # An intermediate GLTF node belongs in the joint's local rest, while
        # the armature transform above a root joint belongs to Skeleton3D.
        intermediates = []
        while parent is not None and parent not in joints:
            intermediates.append(parent)
            parent = parents.get(parent)
        if parent is not None:
            for intermediate in intermediates:
                rest = multiply(node_matrix(nodes[intermediate]), rest)
        rig[nodes[joint]['name']] = {'parent': nodes[parent]['name'] if parent is not None else '', 'rest': rest}
    binds = {}
    for skin in gltf.get('skins', []):
        accessor = gltf['accessors'][skin['inverseBindMatrices']]
        if accessor['componentType'] != 5126 or accessor['type'] != 'MAT4' or 'sparse' in accessor:
            raise ValueError('installed rig needs dense float inverse bind matrices')
        if accessor['count'] != len(skin['joints']):
            raise ValueError('inverse bind count must match joint count')
        view = gltf['bufferViews'][accessor['bufferView']]
        if view.get('buffer', 0) != 0:
            raise ValueError('installed GLB must embed its skin buffer')
        start = view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        stride = view.get('byteStride', 64)
        for index, joint in enumerate(skin['joints']):
            name = nodes[joint]['name']
            matrix = list(struct.unpack_from('<16f', binary, start + index * stride))
            if name in binds and binds[name] != matrix:
                raise ValueError(f'{name}: inconsistent inverse binds between meshes')
            binds[name] = matrix
    return names, rig, binds


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
        binary_start = 20 + length
        binary_length, binary_type = struct.unpack_from('<II', raw, binary_start)
        if binary_type != 0x004e4942:
            raise ValueError(f'{name}: missing embedded GLB binary chunk')
        binary = raw[binary_start + 8:binary_start + 8 + binary_length]
        bones, rig, binds = rig_contracts(gltf, binary)
        uid_match = re.search(r'^uid="([^"]+)"$', Path(str(path) + '.import').read_text(), re.MULTILINE)
        if uid_match is None:
            raise ValueError(f'{name}: missing stable Godot import UID')
        winged = 'wing_upper_l' in bones
        biped = 'arm_l' in bones
        family = 'winged' if winged else 'biped' if biped else 'quadruped'
        signature = tuple(bones)
        row = {'model': definition['placeholder']['model'], 'source_sha256': hashlib.sha256(raw).hexdigest(),
               'resource_uid': uid_match.group(1), 'rig_contract': rig, 'bind_contract': binds,
               'rig_family': family, 'bones': bones}
        if signature in rig_profiles:
            row['profile'] = rig_profiles[signature]
            rows[name] = row
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
        row['profile'] = profile
        rows[name] = row
    OUT.write_text(json.dumps({'enabled_species': list(rows), 'rig_tolerance': .0001,
                               'scope': 'presentation_only_no_save_or_network_payload',
                               'status': 'owner_enabled_phase1_visual_acceptance_pending',
                               'species': rows, 'profiles': profiles}, indent=2) + '\n')
    print(f'Authored five enabled pose roles and packaged rig contracts for {len(rows)} installed species')


if __name__ == '__main__':
    main()
