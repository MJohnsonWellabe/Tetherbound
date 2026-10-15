"""F36#1 post-pass: rewrite only the hit, faint, swim, fly_grip and ride frames
of data/creatures/f36_pose_candidates.json by rig family, in place.

The live recipe file is the source of truth (its per-species profile names,
rig contracts and other roles are not reproduced by author_f36_pose_profiles.py),
so this pass never regenerates rows. It reads each profile's measured rest rig,
derives the body's own forward/up/lateral axes from it, and writes each pose
as anatomical world-space turns converted to the bone-local deltas the runtime
expects. Everything else in the file stays byte-identical, except that each
rewritten species declares all five roles as grounded so the runtime's skinned
contact pass seats every pose on the floor.

Deterministic and idempotent: the output depends only on the rig contracts.

  python3 tools/art_pipeline/f36_pose_postpass.py            # rewrite in place
  python3 tools/art_pipeline/f36_pose_postpass.py --out=X    # write elsewhere
  python3 tools/art_pipeline/f36_pose_postpass.py --check    # exit 1 if stale
"""
import importlib.util
import json
import math
import re
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
LIVE = ROOT / 'data/creatures/f36_pose_candidates.json'
_spec = importlib.util.spec_from_file_location('f36_author', Path(__file__).with_name('author_f36_pose_profiles.py'))
AUTHOR = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(AUTHOR)
sys.path.insert(0, str(Path(__file__).parent))
import f36_pose_solver as SOLVER  # noqa: E402
import f36_skin as SKIN  # noqa: E402

ROLES = ('hit', 'faint', 'swim', 'fly_grip', 'ride')
GROUNDED = ['hit', 'faint', 'ride', 'fly_grip', 'swim']
# Stale recipes whose installed model needs a dedicated profile first.
SKIP_SPECIES = {'voltarach'}
# Round 3 (judged upright in round 2): bodies that stand upright swim level
# and carry a rider on a lowered, forward-pitched back.
UPRIGHT_SWIM = {'duskhush', 'aquaryn', 'ripplet', 'breezetail', 'tidecoil', 'reedwing', 'brooktail',
                'pipwing', 'bramblebun', 'paddlenewt', 'riftfrill'}
UPRIGHT_RIDE = {'breezetail', 'tidecoil', 'brooktail'}
SAMPLES = 9
NECK_PITCH_LIMIT = 20.0
# Bodies at least this much wider than tall (fins, spread wings, hoods) would
# end a side roll balanced on an edge; they collapse belly-down instead.
FLAT_WIDTH_TO_HEIGHT = 1.42
# These installed wing meshes weight their wings to front-upper/front-lower
# chains rather than wing-named bones. The ordinary wing opener finds no roots.
# Solmane's broad rest wings need a beat more than added span. Tempestwing's
# outer wing is pelvis-weighted and tears at the quarter-beat with this route.
FRONT_WING_RIGS = {'stormraven', 'breezetail', 'solmane'}
# Round 4 swim stroke (degrees of rig swing): front reach, hind trail, knee bends.
SWIM_REACH = 40.0
SWIM_TRAIL = -50.0
SWIM_FRONT_BEND = 20.0
SWIM_REAR_BEND = 18.0


# --- 3x3 rotation helpers (row-major lists) -------------------------------

def mat_from_rest(rest):
    # Column-major 4x4 -> orthonormal 3x3 rotation (scale removed).
    cols = [rest[0:3], rest[4:7], rest[8:11]]
    cols = [normalise(c) for c in cols]
    return [[cols[c][r] for c in range(3)] for r in range(3)]


def normalise(v):
    length = math.sqrt(sum(x * x for x in v))
    return [x / length for x in v] if length > 1e-12 else [0.0, 0.0, 0.0]


def mul(a, b):
    return [[sum(a[r][k] * b[k][c] for k in range(3)) for c in range(3)] for r in range(3)]


def transpose(a):
    return [[a[c][r] for c in range(3)] for r in range(3)]


def apply(a, v):
    return [sum(a[r][k] * v[k] for k in range(3)) for r in range(3)]


def cross(a, b):
    return [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def axis_angle(axis, degrees):
    x, y, z = normalise(axis)
    t = math.radians(degrees)
    c, s, k = math.cos(t), math.sin(t), 1 - math.cos(t)
    return [[c + x * x * k, x * y * k - z * s, x * z * k + y * s],
            [y * x * k + z * s, c + y * y * k, y * z * k - x * s],
            [z * x * k - y * s, z * y * k + x * s, c + z * z * k]]


IDENTITY = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]]


def mat_to_quat(m):
    trace = m[0][0] + m[1][1] + m[2][2]
    if trace > 0:
        s = math.sqrt(trace + 1.0) * 2
        q = [(m[2][1] - m[1][2]) / s, (m[0][2] - m[2][0]) / s, (m[1][0] - m[0][1]) / s, 0.25 * s]
    elif m[0][0] > m[1][1] and m[0][0] > m[2][2]:
        s = math.sqrt(1.0 + m[0][0] - m[1][1] - m[2][2]) * 2
        q = [0.25 * s, (m[0][1] + m[1][0]) / s, (m[0][2] + m[2][0]) / s, (m[2][1] - m[1][2]) / s]
    elif m[1][1] > m[2][2]:
        s = math.sqrt(1.0 + m[1][1] - m[0][0] - m[2][2]) * 2
        q = [(m[0][1] + m[1][0]) / s, 0.25 * s, (m[1][2] + m[2][1]) / s, (m[0][2] - m[2][0]) / s]
    else:
        s = math.sqrt(1.0 + m[2][2] - m[0][0] - m[1][1]) * 2
        q = [(m[0][2] + m[2][0]) / s, (m[1][2] + m[2][1]) / s, 0.25 * s, (m[1][0] - m[0][1]) / s]
    return normalise(q) if q[3] >= 0 else normalise([-x for x in q])


def quat_to_mat(q):
    x, y, z, w = q
    return [[1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w)],
            [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w)],
            [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y)]]


def euler(m):
    return [round(v, 4) + 0.0 for v in AUTHOR.euler_degrees(mat_to_quat(m))]


def euler_to_mat(degrees):
    return quat_to_mat(AUTHOR.quaternion(degrees))


# --- rig reading -------------------------------------------------------------

class Rig:
    def __init__(self, contract, bones):
        self.contract = contract
        self.bones = bones
        self.local = {b: mat_from_rest(contract[b]['rest']) for b in contract}
        self.origin = {b: contract[b]['rest'][12:15] for b in contract}
        self._rest_global = {}
        self._rest_position = {}
        for b in contract:
            self.rest_global(b)
        up = [0.0, 1.0, 0.0]
        head = self._find('head') or self._find('neck')
        tail = self._find('pelvis') or self._find('root')
        f = [0.0, 0.0, 1.0]
        if head and tail:
            d = [self._rest_position[head][i] - self._rest_position[tail][i] for i in range(3)]
            d[1] = 0.0
            if math.sqrt(dot(d, d)) > 1e-4:
                f = normalise(d)
        self.up = up
        self.forward = f
        self.lateral = normalise(cross(up, f))   # body's left (+) by right-hand rule

    def _find(self, name):
        return name if name in self.contract else None

    def parent(self, b):
        return self.contract[b].get('parent') or None

    def rest_global(self, b):
        if b in self._rest_global:
            return self._rest_global[b]
        p = self.parent(b)
        if p:
            pg = self.rest_global(p)
            g = mul(pg, self.local[b])
            pos = [self._rest_position[p][i] + apply(pg, self.origin[b])[i] for i in range(3)]
        else:
            g = self.local[b]
            pos = list(self.origin[b])
        self._rest_global[b] = g
        self._rest_position[b] = pos
        return g

    def side(self, b):
        s = dot(self._rest_position[b], self.lateral)
        if abs(s) < 1e-5:
            return 1.0 if b.endswith('_l') else -1.0
        return 1.0 if s > 0 else -1.0

    def depth(self, b):
        p = self.parent(b)
        return 1 + self.depth(p) if p else 0

    def solve(self, turns, local_override=None):
        """turns: bone -> world rotation (3x3) applied relative to its posed parent.
        local_override: bone -> local delta (3x3) used as-is (wing folds).
        Returns bone -> local Euler degrees for every recipe bone."""
        local_override = local_override or {}
        posed = {}
        out = {}
        for b in sorted(self.contract, key=self.depth):
            p = self.parent(b)
            base = mul(posed[p], self.local[b]) if p else self.local[b]
            if b in local_override:
                delta = local_override[b]
            elif b in turns:
                delta = mul(transpose(base), mul(turns[b], base))
            else:
                delta = IDENTITY
            posed[b] = mul(base, delta)
            out[b] = delta
        return {b: euler(out[b]) if b in out else [0, 0, 0] for b in self.bones}

    # Anatomical world rotations ------------------------------------------
    def pitch(self, degrees):
        """Nose (or a bone's tip along forward) up by `degrees`."""
        return axis_angle(cross(self.forward, self.up), degrees)

    def roll(self, degrees):
        return axis_angle(self.forward, degrees)

    def yaw(self, degrees):
        return axis_angle(self.up, degrees)

    def swing(self, degrees):
        """A downward limb swings its foot forward by `degrees`."""
        return axis_angle(cross([-x for x in self.up], self.forward), degrees)

    def abduct(self, bone, degrees):
        """A downward limb swings its foot out to its own side."""
        side = [x * self.side(bone) for x in self.lateral]
        return axis_angle(cross([-x for x in self.up], side), degrees)

    def wing_lift(self, bone, degrees):
        side = [x * self.side(bone) for x in self.lateral]
        return axis_angle(cross(side, self.up), degrees)


# --- families and poses ------------------------------------------------------

def mesh_ratio(model_path, rig):
    """Installed mesh width across the body's lateral axis over its height."""
    raw = (ROOT / model_path.replace('res://', '')).read_bytes()
    length = struct.unpack_from('<I', raw, 12)[0]
    gltf = json.loads(raw[20:20 + length])
    lo, hi = [math.inf] * 3, [-math.inf] * 3
    for mesh in gltf.get('meshes', []):
        for primitive in mesh['primitives']:
            accessor = gltf['accessors'][primitive['attributes']['POSITION']]
            lo = [min(a, b) for a, b in zip(lo, accessor['min'])]
            hi = [max(a, b) for a, b in zip(hi, accessor['max'])]
    corners = [[x, y, z] for x in (lo[0], hi[0]) for y in (lo[1], hi[1]) for z in (lo[2], hi[2])]
    across = [dot(c, rig.lateral) for c in corners]
    height = hi[1] - lo[1]
    return (max(across) - min(across)) / height if height > 1e-6 else 0.0


def family(bones):
    if any(b.startswith('wing_') for b in bones):
        return 'winged'
    if 'arm_l' in bones:
        return 'biped'
    return 'quadruped'


def group(b):
    if b.startswith(('front_upper', 'arm_')):
        return 'front_upper'
    if b.startswith('front_lower'):
        return 'front_lower'
    if b.startswith(('rear_upper', 'leg_upper')):
        return 'rear_upper'
    if b.startswith(('rear_lower', 'leg_lower')):
        return 'rear_lower'
    if b.startswith('wing_upper'):
        return 'wing_upper'
    if b.startswith('tail_'):
        return 'tail'
    return b


def hit_envelope(phase):
    return phase / .125 if phase <= .125 else ((1 - phase) / .875) ** .55


def pose(rig, fam, role, phase, folds, flat=False, upright=False):
    """World turns for one sample; returns (bone eulers, pivot euler)."""
    turns = {}
    local = {}
    a = math.sin(phase * math.tau)
    c = math.cos(phase * math.tau)
    pivot = IDENTITY
    bones = rig.contract

    def add(b, m):
        if b in bones:
            turns[b] = mul(m, turns[b]) if b in turns else m

    def fold(amount):
        for b, deg in folds.items():
            if b in bones and amount > 0:
                local[b] = euler_to_mat(AUTHOR.blend_rotation(deg, amount))

    if role == 'hit':
        # Recoil away from the blow: chest and head pitch up and back, weight
        # settles onto the hind legs, feet stay where they stood.
        e = hit_envelope(phase)
        add('spine', rig.pitch(8 * e))
        add('neck', rig.pitch(min(14.0, NECK_PITCH_LIMIT) * e))
        add('head', rig.pitch(8 * e))
        pivot = rig.pitch(7 * e)
        for b in bones:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(6 * e))
            elif g == 'rear_lower':
                add(b, rig.swing(10 * e))
            elif g == 'wing_upper':
                add(b, rig.wing_lift(b, 18 * e))
            elif g == 'tail':
                add(b, rig.pitch(-5 * e))
    elif role == 'faint':
        # Collapse onto the side; legs go slack, wings fold along the body.
        e = min(1.0, phase / .7)
        if flat:
            # Wide, flat bodies settle belly-down: legs splay, head drops.
            pivot = rig.pitch(-6 * e)
            add('neck', rig.pitch(-16 * e))
            add('head', rig.pitch(-6 * e))
            for b in bones:
                g = group(b)
                # Legs fold right under the body so it drops onto its belly.
                if g == 'front_upper':
                    add(b, rig.abduct(b, 20 * e))
                    add(b, rig.swing(-45 * e))
                elif g == 'rear_upper':
                    add(b, rig.abduct(b, 20 * e))
                    add(b, rig.swing(45 * e))
                elif g == 'front_lower':
                    add(b, rig.swing(-85 * e))
                elif g == 'rear_lower':
                    add(b, rig.swing(85 * e))
                elif g == 'tail':
                    add(b, rig.pitch(-6 * e))
        else:
            pivot = rig.roll(90 * e)
            add('neck', rig.pitch(-10 * e))
            for b in bones:
                g = group(b)
                if g == 'front_lower':
                    add(b, rig.swing(-25 * e))
                elif g == 'rear_lower':
                    add(b, rig.swing(25 * e))
                elif g == 'front_upper' and b.startswith('arm_'):
                    add(b, rig.swing(20 * e))
        fold(e)
    elif role == 'swim':
        # Level and low; a paddle cycle whose quarter phases all differ.
        # Round 4 (r3 judges: four-legged bodies waded on a walk swing): the
        # front legs reach forward and stroke under the chest, the hind legs
        # trail out behind and kick, so no leg stands under the body.
        # Round 5: bodies the solver already pitches level (UPRIGHT_SWIM)
        # nose-dived with the stroke on top; they keep the r3 swing.
        reach, trail = (0.0, 0.0) if upright else (SWIM_REACH, SWIM_TRAIL)
        add('neck', rig.pitch(12))
        add('head', rig.pitch(4))
        side = 1
        for b in bones:
            g = group(b)
            side = 1 if b.endswith('_l') else -1
            if g == 'front_upper':
                add(b, rig.swing(reach + (28 if fam != 'biped' else 40) * a * side))
            elif g == 'front_lower':
                add(b, rig.swing(-(SWIM_FRONT_BEND + 18 * max(0.0, a * side))))
            elif g == 'rear_upper':
                add(b, rig.swing(trail + 18 * c * side))
            elif g == 'rear_lower':
                add(b, rig.swing(SWIM_REAR_BEND + 10 * max(0.0, c * side)))
            elif g == 'tail':
                add(b, rig.yaw(12 * a))
        if fam == 'winged':
            fold(1.0)
    elif role == 'fly_grip':
        # Airborne and level. Flyers: wings spread on a beat, legs reaching
        # down to grip. Non-flyers: legs tucked under the body.
        add('neck', rig.pitch(6))
        for b in bones:
            g = group(b)
            if fam == 'winged':
                if g == 'wing_upper':
                    add(b, rig.wing_lift(b, 28 * a))
                elif b.startswith('wing_') and not b.startswith('wing_upper'):
                    add(b, rig.wing_lift(b, 10 * a))
                elif g == 'rear_upper':
                    add(b, rig.swing(15))
            else:
                if g == 'front_upper':
                    add(b, rig.swing(-30))
                elif g == 'front_lower':
                    add(b, rig.swing(-70))
                elif g == 'rear_upper':
                    add(b, rig.swing(35))
                elif g == 'rear_lower':
                    add(b, rig.swing(60))
            if g == 'tail':
                add(b, rig.yaw(6 * a))
    elif role == 'ride':
        # Braced under a rider: lowered, legs set wide and bent, head up.
        breathe = 0.5 + 0.5 * c
        add('neck', rig.pitch(6))
        for b in bones:
            g = group(b)
            if g in ('front_upper', 'rear_upper'):
                add(b, rig.abduct(b, 10))
                add(b, rig.swing(8 if g == 'front_upper' else -8))
            elif g == 'front_lower':
                add(b, rig.swing(-(26 + 4 * breathe)))
            elif g == 'rear_lower':
                add(b, rig.swing(26 + 4 * breathe))
        if fam == 'winged':
            fold(0.6)
    return rig.solve(turns, local), euler(pivot)


def build_role(rig, fam, role, spec, folds, flat=False, upright=False):
    frames = []
    for sample in range(SAMPLES):
        phase = sample / (SAMPLES - 1)
        bones, pivot = pose(rig, fam, role, phase, folds, flat, upright)
        frames.append({'phase': phase, 'bones': bones, 'pivot_roll_deg': 0, 'pivot_rotation_deg': pivot})
    out = {'duration_s': spec['duration_s'], 'loop': spec['loop'], 'frames': frames}
    for key in ('start_phase', 'release_phase'):
        if key in spec:
            out[key] = spec[key]
    return out


def refine(name, row, rig, fam, prof):
    """Round 3: measure the installed skin and correct what rig axes miss."""
    skin = SKIN.Skin(row['model'], row['rig_contract'], row['bones'])
    if name in UPRIGHT_SWIM:
        SOLVER.level_body(skin, rig, prof['swim']['frames'], keep_feet=False)
    if name == 'ripplet':
        # F36#1 direct r6: matching the swim pitch laid the mount flat while
        # the rider stayed at the tail. A braced diagonal ride keeps the head
        # and torso above the trainer. The seat experiment was parked after
        # two flat rounds; the production mount offset stays unchanged.
        for ride, swim in zip(prof['ride']['frames'], prof['swim']['frames']):
            ride['pivot_rotation_deg'] = [round(swim['pivot_rotation_deg'][0] * .72, 4), 0, 0]
        # The installed r5 recoil moved less than a silhouette-width at the
        # fixed camera distance. Give the torso and head a readable reaction.
        for frame in prof['hit']['frames']:
            for bone, factor in (('spine', 2.5), ('neck', 2.0), ('head', 2.0)):
                if bone in frame['bones']:
                    frame['bones'][bone] = [round(v * factor, 4) for v in frame['bones'][bone]]
            frame['pivot_rotation_deg'] = [round(frame['pivot_rotation_deg'][0] * 2.5, 4), 0, 0]
    if name == 'paddlenewt':
        # The first direct pass still read as an idle hit, a knotted side
        # tumble, a submerged face and a straight-armed airborne lunge.
        # Give impact a brief full-silhouette recoil and let the faint settle
        # into a broad, belly-led sprawl rather than a 90-degree side roll.
        for frame in prof['hit']['frames']:
            e = hit_envelope(frame['phase'])
            frame['pivot_rotation_deg'] = [round(-24.0 * e, 4), 0, round(8.0 * e, 4)]
            frame['bones']['spine'] = [round(22.0 * e, 4), 0, 0]
            frame['bones']['neck'] = [round(-34.0 * e, 4), 0, 0]
            frame['bones']['head'] = [round(-18.0 * e, 4), 0, 0]
            for bone in ('front_upper_l', 'front_upper_r'):
                frame['bones'][bone] = [round(-27.0 * e, 4), 0, 0]
            for bone in ('front_lower_l', 'front_lower_r'):
                frame['bones'][bone] = [round(-18.0 * e, 4), 0, 0]
        for frame in prof['faint']['frames']:
            e = min(1.0, frame['phase'] / .7)
            frame['pivot_rotation_deg'] = [round(58.0 * e, 4), 0, round(14.0 * e, 4)]
            frame['bones']['spine'] = [round(-8.0 * e, 4), 0, 0]
            frame['bones']['neck'] = [round(-18.0 * e, 4), 0, 0]
            frame['bones']['head'] = [round(-10.0 * e, 4), 0, 0]
            for side, suffix in ((-1, '_l'), (1, '_r')):
                frame['bones']['front_upper' + suffix] = [round(-42.0 * e, 4), 0, round(22.0 * side * e, 4)]
                frame['bones']['front_lower' + suffix] = [round(-18.0 * e, 4), 0, 0]
                frame['bones']['rear_upper' + suffix] = [round(28.0 * e, 4), 0, round(16.0 * side * e, 4)]
                frame['bones']['rear_lower' + suffix] = [round(20.0 * e, 4), 0, 0]
        # Pitch the chest less steeply and counter-raise the face. Keep an
        # alternating front stroke instead of folding both forelimbs under.
        for frame in prof['swim']['frames']:
            frame['pivot_rotation_deg'] = [36.0, 0, 0]
            for bone in ('front_upper_l', 'front_upper_r'):
                frame['bones'][bone] = [round(v * 2.0, 4) for v in frame['bones'][bone]]
            for bone in ('rear_upper_l', 'rear_upper_r'):
                frame['bones'][bone] = [round(v * 1.5, 4) for v in frame['bones'][bone]]
            for bone in ('tail_1', 'tail_2'):
                frame['bones'][bone] = [round(v * 1.6, 4) for v in frame['bones'][bone]]
            frame['bones']['neck'] = [-36.0, 0, 0]
            frame['bones']['head'] = [-15.0, 0, 0]
        for frame in prof['fly_grip']['frames']:
            phase = frame['phase']
            swing = math.sin(phase * math.tau)
            reach = math.cos(phase * math.tau)
            frame['pivot_rotation_deg'] = [round(27.0 + 4.0 * swing, 4), 0,
                                            round(5.0 * swing, 4)]
            for side, suffix in ((-1, '_l'), (1, '_r')):
                frame['bones']['front_upper' + suffix] = [round(-43.0 - 5.0 * reach, 4), 0, 14.0 * side]
                frame['bones']['front_lower' + suffix] = [-46.0, 0, 0]
            for bone in ('rear_upper_l', 'rear_upper_r'):
                frame['bones'][bone] = [25.0, 0, 0]
            for bone in ('rear_lower_l', 'rear_lower_r'):
                frame['bones'][bone] = [-12.0, 0, 0]
            frame['bones']['neck'] = [round(v * 2.0, 4) for v in frame['bones']['neck']]
            for bone in ('tail_1', 'tail_2'):
                frame['bones'][bone] = [round(v * 1.8, 4) for v in frame['bones'][bone]]
    if name == 'galecrest':
        # Direct turn 24 showed that pitching the whole bird for a float
        # lifted it clear of the water. Keep the lower, retained swim and
        # make impact a sideways loss of balance instead of more head pitch.
        for frame in prof['hit']['frames']:
            e = hit_envelope(frame['phase'])
            frame['pivot_rotation_deg'] = [round(-18.0 * e, 4), 0, round(24.0 * e, 4)]
            frame['bones']['spine'] = [round(-16.0 * e, 4), 0, round(12.0 * e, 4)]
            frame['bones']['neck'] = [round(-20.0 * e, 4), 0, round(-9.0 * e, 4)]
            frame['bones']['head'] = [round(-12.0 * e, 4), 0, 0]
    if name == 'aquaryn':
        # r5's full level turn puts the muzzle at the torso's waterline.
        # Retain a diagonal float while lifting the head clear of that line;
        # the water form shares this installed rig but gets a separate verdict.
        for frame in prof['swim']['frames']:
            frame['pivot_rotation_deg'] = [42.0, 0, 0]
    if name in UPRIGHT_RIDE:
        SOLVER.level_body(skin, rig, prof['ride']['frames'], keep_feet=True)
    if name in FRONT_WING_RIGS:
        roots = [b for b in skin.bones if b.startswith('front_upper')]
        SOLVER.open_wings(skin, rig, prof['fly_grip']['frames'], roots=roots, child_prefix='front_')
    elif fam == 'winged':
        SOLVER.open_wings(skin, rig, prof['fly_grip']['frames'])
    for role in ROLES:
        SOLVER.guard_stretch(skin, prof[role]['frames'])
    SOLVER.ground_faint(skin, prof['faint']['frames'], lambda phase: min(1.0, phase / .7))


# --- in-place text rewrite ---------------------------------------------------

def value_span(text, start):
    _, end = json.JSONDecoder().raw_decode(text, start)
    return start, end


def rewrite(text):
    live = json.loads(text)
    profiles_at = text.index('\n  "profiles": {')
    species_rows = live['species']
    edited_profiles = {}
    for name, row in species_rows.items():
        if name in SKIP_SPECIES:
            continue
        pid = row['profile']
        if pid in edited_profiles:
            continue
        rig = Rig(row['rig_contract'], row['bones'])
        fam = family(row['bones'])
        folds = AUTHOR.folded_wings(row['rig_contract']) if fam == 'winged' else {}
        flat = mesh_ratio(row['model'], rig) >= FLAT_WIDTH_TO_HEIGHT
        prof = json.loads(json.dumps(live['profiles'][pid]))
        for role in ROLES:
            if role in prof:
                # Mosshell's long domed shell balanced on its rim under the
                # generic side-roll faint; it settles belly-down instead.
                role_flat = flat or (name in ('mosshell', 'galecrest') and role == 'faint')
                prof[role] = build_role(rig, fam, role, prof[role], folds, role_flat, name in UPRIGHT_SWIM)
        refine(name, row, rig, fam, prof)
        edited_profiles[pid] = prof
    # Profiles: replace each edited value in place, compact on one line.
    edits = []
    for pid, prof in edited_profiles.items():
        m = re.compile(r'\n    %s: ' % re.escape(json.dumps(pid))).search(text, profiles_at)
        start, end = value_span(text, m.end())
        edits.append((start, end, json.dumps(prof, separators=(',', ':'))))
    # Rows: grounded_roles for every rewritten species, other fields untouched.
    rows_at = text.index('\n  "species": {')
    for name, row in species_rows.items():
        if name in SKIP_SPECIES:
            continue
        m = re.compile(r'\n    %s: \{' % re.escape(json.dumps(name))).search(text, rows_at)
        start, end = value_span(text, m.end() - 1)
        block = text[start:end]
        line = '"grounded_roles": %s' % json.dumps(GROUNDED)
        if '"grounded_roles": ' in block:
            block = re.sub(r'"grounded_roles": \[[^\]]*\]', line, block)
        else:
            block = block[:block.rindex('\n    }')] + ',\n      ' + line + '\n    }'
        edits.append((start, end, block))
    for start, end, rep in sorted(edits, reverse=True):
        text = text[:start] + rep + text[end:]
    return text


def main():
    out = LIVE
    check = '--check' in sys.argv
    for arg in sys.argv[1:]:
        if arg.startswith('--out='):
            out = Path(arg.split('=', 1)[1])
    before = LIVE.read_text()
    after = rewrite(before)
    if check:
        print('stale' if after != before else 'current')
        sys.exit(1 if after != before else 0)
    out.write_text(after)
    print('F36 post-pass wrote %s (%d bytes)' % (out, len(after)))


if __name__ == '__main__':
    main()
