"""Author default-enabled pose recipes from installed rigs; no engine or service tasks.

No original mesh, animation, skin, texture or durable creature identity changes.
Runtime verifies the source hash or packaged UID/rest/bind contract before installation.
Re-run after any mesh replacement: source hashes bind each recipe to its rig.
"""
import hashlib
import copy
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


def quaternion(degrees):
    x, y, z = (math.radians(value) / 2 for value in degrees)
    sx, cx, sy, cy, sz, cz = math.sin(x), math.cos(x), math.sin(y), math.cos(y), math.sin(z), math.cos(z)
    qx = cy * sx * cz + sy * cx * sz
    qy = sy * cx * cz - cy * sx * sz
    qz = cy * cx * sz - sy * sx * cz
    qw = cy * cx * cz + sy * sx * sz
    return [qx, qy, qz, qw]


def euler_degrees(q):
    qx, qy, qz, qw = q
    return [math.degrees(math.asin(max(-1, min(1, 2 * (qw * qx - qy * qz))))),
            math.degrees(math.atan2(2 * (qx * qz + qw * qy), 1 - 2 * (qx*qx + qy*qy))),
            math.degrees(math.atan2(2 * (qx * qy + qw * qz), 1 - 2 * (qx*qx + qz*qz)))]


def blend_rotation(degrees, amount):
    """Fold along the shortest quaternion arc, not three large Euler sweeps."""
    qx, qy, qz, qw = quaternion(degrees)
    if qw < 0:
        qx, qy, qz, qw = -qx, -qy, -qz, -qw
    angle = math.acos(max(-1, min(1, qw)))
    scale = math.sin(angle * amount) / math.sin(angle) if angle > .000001 else amount
    qx, qy, qz, qw = qx * scale, qy * scale, qz * scale, math.cos(angle * amount)
    return euler_degrees([qx, qy, qz, qw])


def folded_wings(rig):
    # Equal bone names do not imply equal wing axes. Resolve each installed
    # rig's rest hierarchy, then fold upper wings toward the tail and return
    # the distal segments alongside the body. No mesh or bind is changed.
    folds = {}

    def global_pose(bone):
        local = multiply(rig[bone]['rest'], node_matrix({'rotation': quaternion(folds.get(bone, [0, 0, 0]))}))
        parent = rig[bone]['parent']
        return multiply(global_pose(parent), local) if parent else local

    def depth(bone):
        parent = rig[bone]['parent']
        return 1 + depth(parent) if parent else 0

    for bone in sorted((name for name in rig if name.startswith('wing_')), key=depth):
        side = -1 if bone.endswith('_l') else 1
        target = [side * .12, -.08, -1] if bone.startswith('wing_upper') else [side * .1, 0, 1]
        length = math.sqrt(sum(value * value for value in target))
        target = [value / length for value in target]
        basis = global_pose(bone)
        # Inverse rotation takes the anatomical direction into this bone's
        # local frame. A joint's longitudinal direction is local +Y.
        local = []
        for column in range(3):
            axis = basis[column * 4:column * 4 + 3]
            axis_length = math.sqrt(sum(value * value for value in axis))
            local.append(sum(axis[row] * target[row] for row in range(3)) / axis_length)
        q = [local[2], 0, -local[0], 1 + local[1]]
        length = math.sqrt(sum(value * value for value in q))
        if length < .000001:
            q = [1, 0, 0, 0]
        else:
            q = [value / length for value in q]
        folds[bone] = euler_degrees(q)
    return folds


def rotation(bone, role, phase, winged, biped, wing_folds=None):
    wave = math.sin(phase * math.tau)
    opposite = -1 if bone.endswith('_r') else 1
    quadruped = not winged and not biped
    if quadruped and role == 'hit':
        # The measured quad spine points local X opposite to neck/head X.
        # Bow all three in the same anatomical direction, with a quick impact
        # and a held wince rather than the old mutually cancelling bob.
        envelope = phase / .125 if phase <= .125 else ((1 - phase) / .875) ** .55
        angle = {'pelvis': -6, 'spine': -28, 'neck': 32, 'head': 28}.get(bone, 0)
        if 'upper' in bone:
            angle = -90 if bone.startswith('front') else -55
        elif 'lower' in bone:
            angle = 90 if bone.startswith('front') else 60
        return [angle * envelope, 0, 0]
    if quadruped and role == 'faint':
        envelope = min(1, phase / .7)
        # Adduct the outboard paw width inside the flank's contact envelope.
        # Stagger the upper/lower-side folds so paws do not occupy one volume.
        if 'upper' in bone:
            return [(-36 if bone.endswith('_l') else 20) * envelope, 0,
                    -20 * envelope if bone.endswith('_l') else 0]
        if 'lower' in bone:
            return [(48 if bone.endswith('_l') else 90) * envelope, 0, 0]
        return [({'neck': 26, 'head': 22}.get(bone, 0)) * envelope, 0, 0]
    if quadruped and role == 'fly_grip':
        # Elevated forearms and returning lower legs form an unmistakable
        # hook/clasp; the rear feet tuck up rather than support a standing dog.
        if bone.startswith('front_upper'):
            return [-100, 0, -opposite * 8]
        if bone.startswith('front_lower'):
            return [152, 0, 0]
        if bone.startswith('rear_upper'):
            return [58, 0, -opposite * 5]
        if bone.startswith('rear_lower'):
            return [78, 0, 0]
        return [10 if bone in ('neck', 'head') else 0, 0, 0]
    if role == 'hit':
        envelope = phase / .125 if phase <= .125 else ((1 - phase) / .875) ** .55
        # These upright rigs have matching torso/head X axes. A full-body bow
        # and bent knees carry the impact, including at the mid/late samples.
        angle = {'pelvis': 12, 'spine': 26, 'neck': 35, 'head': 25}.get(bone, 0)
        if bone.startswith('leg_upper'):
            angle = -45
        elif bone.startswith('leg_lower'):
            angle = 80
        elif bone.startswith('arm'):
            angle = -40
        if bone.startswith('wing'):
            return [0, 0, opposite * -18 * envelope]
        return [angle * envelope, 0, 0]
    if role == 'faint':
        envelope = min(1, phase / .7)
        if bone.startswith('wing'):
            return blend_rotation((wing_folds or {}).get(bone, [0, 0, 0]), envelope)
        if bone.startswith('arm'):
            return blend_rotation([-24.577, -45.848, 125.497] if bone.endswith('_l')
                                  else [-23.67, 44.326, -125.556], envelope)
        if bone.startswith('leg_upper'):
            return [(-35 if bone.endswith('_l') else 20) * envelope, 0,
                    -12 * envelope if bone.endswith('_l') else 0]
        if bone.startswith('leg_lower'):
            return [(55 if bone.endswith('_l') else 85) * envelope, 0, 0]
        return [({'neck': 35, 'head': 25}.get(bone, -20 if bone.startswith('foot') else 0)) * envelope, 0, 0]
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
        if bone.startswith('arm'):
            return [-42.59, -32.895, 74.28] if bone.endswith('_l') else [-42.208, 33.001, -75.013]
        if 'upper' in bone:
            return [50, 0, 0]
        if 'lower' in bone:
            return [90, 0, 0]
        if bone.startswith('foot'):
            return [-45, 0, 0]
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


ANATOMICAL_SPECIES = {'terrapup', 'brooktail', 'ripplet'}
WING_ANATOMICAL_SPECIES = {'pipwing', 'galecrest', 'galewisp', 'duskhush', 'reedwing'}
SPECIAL_ANATOMICAL_SPECIES = {'glimmermoth', 'abyssal_guardian'}


def rigid_inverse(matrix):
    inverse = [0.0] * 16
    inverse[15] = 1.0
    for column in range(3):
        for row in range(3):
            inverse[column * 4 + row] = matrix[row * 4 + column]
    for row in range(3):
        inverse[12 + row] = -sum(inverse[column * 4 + row] * matrix[12 + column] for column in range(3))
    return inverse


def follow_head_details(rig, pose):
    # These two installed rigs put small facial details on a separate root.
    # Keep those existing weighted details attached to the posed head. This
    # changes pose only, not skin weights, bone parents, rests or expression.
    if 'neutral_bone' not in rig or rig['neutral_bone']['parent']:
        return {}

    def global_pose(bone, rotations):
        local = multiply(rig[bone]['rest'], node_matrix({'rotation': quaternion(rotations.get(bone, [0, 0, 0]))}))
        parent = rig[bone]['parent']
        return multiply(global_pose(parent, rotations), local) if parent else local

    head_delta = multiply(global_pose('head', pose), rigid_inverse(global_pose('head', {})))
    rest = rig['neutral_bone']['rest']
    desired = multiply(head_delta, rest)
    local_delta = multiply(rigid_inverse(rest), desired)
    pose['neutral_bone'] = [math.degrees(math.asin(max(-1, min(1, -local_delta[9])))),
                            math.degrees(math.atan2(local_delta[8], local_delta[10])),
                            math.degrees(math.atan2(local_delta[1], local_delta[5]))]
    return {'neutral_bone': [desired[12 + axis] - rest[12 + axis] for axis in range(3)]}


def anatomical_poses(name, bones, rig, roles):
    """Bounded installed-skin repairs; keep successful roles unchanged.

    Brooktail's tail joints have zero skin influence: its tail is weighted to
    rear-leg joints. Do not curl those joints as if they were independent feet.
    Rigid pivot attitude carries/swims the body without stretching its skin.
    """
    if name not in ANATOMICAL_SPECIES:
        return roles
    result = copy.deepcopy(roles)
    for role in (('faint', 'swim') if name == 'ripplet' else ('fly_grip', 'faint')):
        for frame in result[role]['frames']:
            phase = frame['phase']
            amount = min(1, phase / .7) if role == 'faint' else 1
            wave = math.sin(phase * math.tau)
            pose = {bone: [0, 0, 0] for bone in bones}
            if role == 'fly_grip':
                # Small clasp arcs around rest, with a rigid carrying attitude.
                # Large limb curls stretch blended underside/torso weights.
                pitch = -30 if name == 'terrapup' else -25
                for bone in bones:
                    if bone.startswith('front_upper'):
                        pose[bone] = [-15 if name == 'terrapup' else -10, 0, 0]
                    elif bone.startswith('front_lower'):
                        pose[bone] = [20 if name == 'terrapup' else 15, 0, 0]
                    elif name == 'terrapup' and bone.startswith('rear_upper'):
                        pose[bone] = [10, 0, 0]
                    elif name == 'terrapup' and bone.startswith('rear_lower'):
                        pose[bone] = [20, 0, 0]
                frame['pivot_rotation_deg'] = [pitch, 0, 0]
            elif role == 'swim':
                # Ripplet floats along its body's long axis, with alternating
                # flipper strokes and a tail scull, rather than an upright gait.
                pose.update(arm_l=[-8 + 10 * wave, 0, 8], arm_r=[-8 - 10 * wave, 0, -8],
                            leg_upper_l=[8 + 6 * wave, 0, 0], leg_upper_r=[8 - 6 * wave, 0, 0],
                            leg_lower_l=[15, 0, 0], leg_lower_r=[15, 0, 0],
                            tail_1=[0, 5 * wave, 0], tail_2=[0, 8 * wave, 0])
                frame['pivot_rotation_deg'] = [65, 0, 3 * wave]
            elif name == 'terrapup':
                # Keep the demonstrated grounded flank, but relax the upper
                # paws and expose the face instead of retaining a hard curl.
                pose.update(frame['bones'])
                for bone in bones:
                    if 'upper' in bone and bone.endswith('_r'):
                        pose[bone] = [5 * amount, 0, 0]
                    elif 'lower' in bone and bone.endswith('_r'):
                        pose[bone] = [30 * amount, 0, 0]
                pose.update(neck=[8 * amount, 0, 0], head=[-5 * amount, 0, 0],
                            tail_1=[15 * amount, 0, 0], tail_2=[-8 * amount, 0, 0])
            elif name == 'brooktail':
                pose.update(front_upper_l=[-15 * amount, 0, -10 * amount],
                            front_upper_r=[5 * amount, 0, 0],
                            front_lower_l=[20 * amount, 0, 0], front_lower_r=[20 * amount, 0, 0],
                            neck=[5 * amount, 0, 0], head=[-5 * amount, 0, 0])
                # Rear-leg curls would bend the wrongly assigned tail weights.
            else:
                pose.update(neck=[5 * amount, 0, 0], head=[-5 * amount, 0, 0],
                            tail_2=[10 * amount, 0, 0], leg_upper_r=[-10 * amount, 0, 10 * amount],
                            leg_lower_r=[20 * amount, 0, 0], leg_upper_l=[5 * amount, 0, 0],
                            leg_lower_l=[10 * amount, 0, 0])
                frame['pivot_rotation_deg'] = [40 * amount, 0, -75 * amount]
            frame['bones'] = pose
            if role == 'faint':
                offsets = follow_head_details(rig, pose)
                if offsets:
                    frame['bone_positions'] = offsets
    return result


def anatomical_wing_poses(name, bones, roles):
    """Keep each installed feather fan intact through whole-body attitudes.

    Dominant fore/tip skin vertices put the small birds' fan normals near X;
    Galecrest and Galewisp have fan normals near source Z. Turning whole fans
    with the model avoids the long blended-skin sheets made by joint folds.
    The hash/rest/bind contract still binds these authored angles to that skin.
    """
    if name not in WING_ANATOMICAL_SPECIES:
        return roles
    result = copy.deepcopy(roles)
    flank_fans = name in {'pipwing', 'duskhush', 'reedwing'}
    for role in ('faint', 'swim', 'fly_grip'):
        for frame in result[role]['frames']:
            phase = frame['phase']
            wave = math.sin(phase * math.tau)
            amount = min(1, phase / .7) if role == 'faint' else 1
            pose = {bone: [0, 0, 0] for bone in bones}
            if role == 'faint':
                # A relaxed flank for the X-normal fan, a prone body for the
                # Z-normal fans. Do not rotate feather joints into the torso.
                # Their different chest/beak extents need different pitches
                # to put body mass close to the supporting wing, not above it.
                flank_pitch = {'pipwing': 45, 'duskhush': 55, 'reedwing': 40}.get(name, 0)
                frame['pivot_rotation_deg'] = ([flank_pitch * amount, 0, 90 * amount] if flank_fans
                                               else [75 * amount, 0, 90 * amount])
                pose.update(neck=[(5 if flank_fans else -15) * amount, 0, 0],
                            head=[(-5 if flank_fans else -20) * amount, 0, 0],
                            tail_1=[(5 if flank_fans else 35) * amount, 0, 0],
                            tail_2=[(10 if flank_fans else 25) * amount, 0, 0])
                if name == 'reedwing':
                    pose.update(neck=[-10 * amount, 0, 0], head=[-10 * amount, 0, 0])
                for side in ('l', 'r'):
                    pose['leg_upper_' + side] = [5 * amount, 0, (5 if side == 'l' else -5) * amount]
                    pose['leg_lower_' + side] = [15 * amount, 0, 0]
                    if 'foot_' + side in pose:
                        pose['foot_' + side] = [5 * amount, 0, 0]
            else:
                # Align the long body with travel and keep the feather plane
                # near horizontal. Pipwing reaches that attitude via Z/Y;
                # its skin cannot safely take a 90-degree upper-wing twist.
                if flank_fans:
                    # Reedwing's duck torso already runs along Z. Swimming
                    # keeps its head above that torso with a shallow pitch.
                    frame['pivot_rotation_deg'] = ([25, 0, 3 * wave] if name == 'reedwing' and role == 'swim'
                                                   else [0, 90, 80 if role == 'fly_grip' else 70 + 3 * wave])
                else:
                    frame['pivot_rotation_deg'] = [70 if role == 'fly_grip' else 60, 0,
                                                   0 if role == 'fly_grip' else 3 * wave]
                pose.update(neck=[-5, 0, 0], head=[5, 0, 0],
                            tail_1=[0, 4 * wave, 0], tail_2=[0, 6 * wave, 0])
                for side in ('l', 'r'):
                    opposite = 1 if side == 'l' else -1
                    # Synchronous flight beats; alternating swimming strokes.
                    stroke = wave if role == 'fly_grip' else wave * opposite
                    pose['wing_upper_' + side] = [0, 0, opposite * 6 * stroke]
                    if 'wing_fore_' + side in pose:
                        pose['wing_fore_' + side] = [0, 0, opposite * 3 * stroke]
                    pose['wing_tip_' + side] = [0, 0, opposite * 3 * stroke]
                    pose['leg_upper_' + side] = [5 + (6 * wave * opposite if role == 'swim' else 0), 0, 0]
                    pose['leg_lower_' + side] = [15 - (5 * wave * opposite if role == 'swim' else 0), 0, 0]
                    if 'foot_' + side in pose:
                        # Existing foot joints curl the claws downward. The
                        # old negative angle lifted the toes away from a grip.
                        pose['foot_' + side] = [25 if role == 'fly_grip' else 5, 0, 0]
            frame['bones'] = pose
    return result


def special_anatomical_poses(name, bones, roles):
    """Pose the installed moth and long sea creature as their own anatomy.

    Glimmermoth's separate neutral root carries abdomen details, not its face;
    leave it alone. Guardian's long axis is already Z, and its front fins point
    down at rest. A flank roll turns those fins into supports under the body.
    """
    if name not in SPECIAL_ANATOMICAL_SPECIES:
        return roles
    result = copy.deepcopy(roles)
    moth = name == 'glimmermoth'
    for role in ('hit', 'faint', 'swim', 'fly_grip') if moth else ('faint', 'swim', 'fly_grip'):
        for frame in result[role]['frames']:
            phase = frame['phase']
            wave = math.sin(phase * math.tau)
            amount = min(1, phase / .7) if role == 'faint' else 1
            pose = {bone: [0, 0, 0] for bone in bones}
            if role == 'hit':
                amount = phase / .125 if phase <= .125 else ((1 - phase) / .875) ** .55
                # Recoil the intact silhouette; the previous wing bow covered
                # the face. Its real neck carries the face, not the head joint.
                frame['pivot_rotation_deg'] = [-12 * amount, 0, -5 * amount]
                for side in ('l', 'r'):
                    pose['leg_upper_' + side] = [-8 * amount, 0, 0]
                    pose['leg_lower_' + side] = [12 * amount, 0, 0]
            elif role == 'faint' and moth:
                # Prone abdomen contact, with intact fans resting beside it.
                frame['pivot_rotation_deg'] = [85 * amount, 0, 15 * amount]
                pose.update(neck=[-5 * amount, 0, 0], head=[-5 * amount, 0, 0],
                            tail_1=[5 * amount, 0, 0], tail_2=[10 * amount, 0, 0])
                for side in ('l', 'r'):
                    pose['leg_upper_' + side] = [5 * amount, 0, 0]
                    pose['leg_lower_' + side] = [10 * amount, 0, 0]
            elif role == 'faint':
                # Spread the actual downward fin joints into the belly's
                # support plane. Relax head and tail onto that same plane.
                frame['pivot_rotation_deg'] = [15 * amount, 0, 0]
                pose.update(neck=[28 * amount, 0, 0], head=[12 * amount, 0, 0],
                            tail_1=[-15 * amount, 0, 0], tail_2=[-7.5 * amount, 0, 0])
                for side in ('l', 'r'):
                    opposite = 1 if side == 'l' else -1
                    pose['wing_upper_' + side] = [0, 0, opposite * 35 * amount]
                    pose['leg_upper_' + side] = [10 * amount, 0, 0]
                    pose['leg_lower_' + side] = [15 * amount, 0, 0]
            else:
                # Moth changes its upright body attitude for buoyant travel;
                # Guardian already has a horizontal body and sculls its fins.
                frame['pivot_rotation_deg'] = ([65 if role == 'fly_grip' else 60, 0,
                                                0 if role == 'fly_grip' else 3 * wave] if moth
                                               else [-8 if role == 'fly_grip' else 5, 0,
                                                     0 if role == 'fly_grip' else 2 * wave])
                pose.update(neck=[-5, 0, 0], head=[5, 0, 0],
                            tail_1=[0, 5 * wave, 0], tail_2=[0, 8 * wave, 0])
                for side in ('l', 'r'):
                    opposite = 1 if side == 'l' else -1
                    stroke = wave if role == 'fly_grip' else wave * opposite
                    pose['wing_upper_' + side] = [0, 0, opposite * ((6 * stroke) if moth else (25 + 6 * stroke))]
                    pose['wing_tip_' + side] = [0, 0, opposite * 3 * stroke]
                    pose['leg_upper_' + side] = [5 + (6 * wave * opposite if role == 'swim' else 0), 0, 0]
                    pose['leg_lower_' + side] = [15 - (5 * wave * opposite if role == 'swim' else 0), 0, 0]
            frame['bones'] = pose
    return result


def installed_skin_points(gltf, binary, rig, binds, pose):
    """Read the actual installed skin for authoring a body's fall attitude."""
    formats = {5121: 'B', 5123: 'H', 5125: 'I', 5126: 'f'}
    widths = {'SCALAR': 1, 'VEC3': 3, 'VEC4': 4}

    def accessor(index):
        item = gltf['accessors'][index]
        if 'sparse' in item:
            raise ValueError('pose authoring needs a dense installed skin')
        view = gltf['bufferViews'][item['bufferView']]
        if view.get('buffer', 0) != 0:
            raise ValueError('pose authoring needs an embedded skin buffer')
        fmt = '<' + formats[item['componentType']] * widths[item['type']]
        size = struct.calcsize(fmt)
        start = view.get('byteOffset', 0) + item.get('byteOffset', 0)
        values = [struct.unpack_from(fmt, binary, start + i * view.get('byteStride', size))
                  for i in range(item['count'])]
        if item.get('normalized') and item['componentType'] != 5126:
            divisor = {5121: 255, 5123: 65535}[item['componentType']]
            values = [tuple(v / divisor for v in row) for row in values]
        return values

    globals_ = {}

    def global_pose(bone):
        if bone not in globals_:
            local = multiply(rig[bone]['rest'], node_matrix({'rotation': quaternion(pose.get(bone, [0, 0, 0]))}))
            parent = rig[bone]['parent']
            globals_[bone] = multiply(global_pose(parent), local) if parent else local
        return globals_[bone]

    matrices = {bone: multiply(global_pose(bone), bind) for bone, bind in binds.items()}
    points = []
    for node in gltf['nodes']:
        if 'mesh' not in node or 'skin' not in node:
            continue
        if any(key in node for key in ('matrix', 'translation', 'rotation', 'scale')):
            raise ValueError('body authoring needs the installed mesh in skeleton coordinates')
        names = [gltf['nodes'][i]['name'] for i in gltf['skins'][node['skin']]['joints']]
        for primitive in gltf['meshes'][node['mesh']]['primitives']:
            attributes = primitive['attributes']
            positions = accessor(attributes['POSITION'])
            joints, weights = accessor(attributes['JOINTS_0']), accessor(attributes['WEIGHTS_0'])
            if len(positions) != len(joints) or len(positions) != len(weights):
                raise ValueError('installed skin attribute counts differ')
            for position, indices, influences in zip(positions, joints, weights):
                total = sum(influences)
                if total <= 0:
                    raise ValueError('installed skin has an unweighted vertex')
                posed = [0.0, 0.0, 0.0]
                core = 0.0
                for index, weight in zip(indices, influences):
                    if weight <= 0:
                        continue
                    bone = names[index]
                    matrix = matrices[bone]
                    for axis in range(3):
                        posed[axis] += weight * (sum(matrix[column * 4 + axis] * position[column]
                                                    for column in range(3)) + matrix[12 + axis]) / total
                    if bone in ('root', 'pelvis', 'spine'):
                        core += weight / total
                points.append((tuple(posed), position, core >= .35))
    if not points:
        raise ValueError('installed model has no skinned vertices')
    return points


def quadruped_fall_attitude(points):
    """Choose a rigid flank attitude from the posed skin, never a sink offset.

    Some installed bodies put their torso on head/limb weights. For those rigs
    use the central source silhouette instead of assuming pelvis is body mass.
    Runtime grounding still uses every weighted vertex, independently of this
    authoring choice, so no selected point can conceal an intersecting foot.
    """
    core = [posed for posed, _, selected in points if selected]
    if len(core) < len(points) * .02:
        centre = [sum(rest[axis] for _, rest, _ in points) / len(points) for axis in range(3)]
        central = sorted(points, key=lambda item: sum((item[1][axis] - centre[axis]) ** 2 for axis in range(3)))
        core = [posed for posed, _, _ in central[:max(1, len(points) // 3)]]
    skin = [posed for posed, _, _ in points]
    height = max(p[1] for p in skin) - min(p[1] for p in skin)
    candidates = []
    for pitch in (-30, -15, 0, 15, 30, 45):
        for roll in (75, 90, 105):
            matrix = node_matrix({'rotation': quaternion([pitch, 0, roll])})
            axis = [matrix[column * 4 + 1] for column in range(3)]
            ys = [sum(axis[i] * p[i] for i in range(3)) for p in skin]
            floor, ceiling = min(ys), max(ys)
            gap = min(sum(axis[i] * p[i] for i in range(3)) for p in core) - floor
            # Prefer mass contact and a low collapsed silhouette. This only
            # selects rigid orientation; existing skin grounding owns height.
            score = gap + .03 * (ceiling - floor) + height * abs(pitch) * .0002
            candidates.append((score, abs(roll - 90), abs(pitch), pitch, roll))
    _, _, _, pitch, roll = min(candidates)
    return [pitch, 0, roll]


def quadruped_anatomical_poses(name, bones, roles, fall_attitude):
    if name in ANATOMICAL_SPECIES | {'stormursa'} or 'wing_upper_l' in bones or 'arm_l' in bones:
        return roles
    result = copy.deepcopy(roles)
    for role in ('faint', 'swim', 'fly_grip'):
        for frame in result[role]['frames']:
            phase = frame['phase']
            wave = math.sin(phase * math.tau)
            amount = min(1, phase / .7) if role == 'faint' else 1
            pose = {bone: [0, 0, 0] for bone in bones}
            if role == 'faint':
                frame['pivot_rotation_deg'] = [angle * amount for angle in fall_attitude]
                for bone in bones:
                    if bone.startswith('front_upper'):
                        pose[bone] = [(-15 if bone.endswith('_l') else 5) * amount, 0,
                                      -15 * amount if bone.endswith('_l') else 0]
                    elif bone.startswith('rear_upper'):
                        pose[bone] = [5 * amount, 0, -15 * amount if bone.endswith('_l') else 0]
                    elif 'lower' in bone:
                        pose[bone] = [20 * amount, 0, 0]
                # Keep the head and neutral details at rest: a few source rigs
                # assign body mass to the head rather than to torso bones.
            else:
                frame['pivot_rotation_deg'] = [-30, 0, 0] if role == 'fly_grip' else [10, 0, 3 * wave]
                for bone in bones:
                    opposite = -1 if bone.endswith('_r') else 1
                    if bone.startswith('front_upper'):
                        pose[bone] = [-15 if role == 'fly_grip' else -22 + 8 * wave * opposite, 0, 0]
                    elif bone.startswith('front_lower'):
                        pose[bone] = [20 if role == 'fly_grip' else 30, 0, 0]
                    elif bone.startswith('rear_upper'):
                        pose[bone] = [10 if role == 'fly_grip' else 15 - 6 * wave * opposite, 0, 0]
                    elif bone.startswith('rear_lower'):
                        pose[bone] = [20, 0, 0]
                    elif role == 'swim' and bone.startswith('tail'):
                        pose[bone] = [0, (5 if bone == 'tail_1' else 8) * wave, 0]
            frame['bones'] = pose
    return result


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
        wing_folds = folded_wings(rig) if winged else {}
        anatomical_quad = family == 'quadruped' and name not in ANATOMICAL_SPECIES | {'stormursa'}
        signature = (name if anatomical_quad or name in ANATOMICAL_SPECIES | WING_ANATOMICAL_SPECIES | SPECIAL_ANATOMICAL_SPECIES else '', tuple(bones),
                     tuple((bone, tuple(round(value, 5) for value in angles))
                           for bone, angles in wing_folds.items()))
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
                frames.append({'phase': phase, 'bones': {bone: rotation(bone, role, phase, winged, biped, wing_folds) for bone in bones},
                               'pivot_roll_deg': 90 * min(1, phase / .7) if role == 'faint' else 0})
            roles[role] = {'duration_s': {'hit': .24, 'faint': 1.2, 'swim': 1.15, 'fly_grip': .9, 'ride': .8}[role],
                           'loop': role in ('swim', 'fly_grip', 'ride'), 'frames': frames}
            if role == 'hit':
                roles[role]['start_phase'] = .125
                roles[role]['release_phase'] = .25
        profile = f'{family}_{len(profiles) + 1}'
        if anatomical_quad:
            resting_fall = quadruped_anatomical_poses(name, bones, roles, [0, 0, 90])['faint']['frames'][-1]['bones']
            fall_attitude = quadruped_fall_attitude(installed_skin_points(gltf, binary, rig, binds, resting_fall))
            roles = quadruped_anatomical_poses(name, bones, roles, fall_attitude)
        profiles[profile] = special_anatomical_poses(name, bones,
                                                   anatomical_wing_poses(name, bones, anatomical_poses(name, bones, rig, roles)))
        if name in {'terrapup', 'brooktail'}:
            # Ground the stage's carrying attitude on its actual skin, not an
            # invented lift. Real carriers still align their foot to the hand.
            row['grounded_roles'] = ['hit', 'faint', 'ride', 'fly_grip']
        elif anatomical_quad or name in WING_ANATOMICAL_SPECIES | SPECIAL_ANATOMICAL_SPECIES:
            row['grounded_roles'] = ['hit', 'faint', 'ride', 'fly_grip', 'swim']
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
