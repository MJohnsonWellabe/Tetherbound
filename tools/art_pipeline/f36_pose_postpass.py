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
  python3 tools/art_pipeline/f36_pose_postpass.py --topple=a,b  # only a/b hit+faint
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


# Restart r1 (17 Oct): the rigid side roll read as a ball (Cannonback), a
# back-up rock pile (Tuskroot) or a nose-down tumble (Stormursa). On these
# weakly weighted rigs ground_faint's chain lifts drag the hindquarters up
# with the legs, and splaying the legs barely moves the mesh. These bodies
# take a clean side flop instead: the whole body rolls onto its flank with
# slack legs and a dropped head, without the chain lifts. Base Cannonback
# is enabled, so Water Cannonback carries this faint as its own
# presentation_role_overrides entry (written from the Cannonback rig). A
# full 180-degree flip (r3 trial) left it standing on its cannon spires and
# a belly-down fold does not lower this short-legged shell, so it keeps the
# 90-degree flop the r2 judges preferred. Water Sirenseal's level_fluke_swim is an
# override for the same reason (base Sirenseal is enabled).
LIMP_SPRAWL = {'tuskroot', 'stormursa'}


def mesh_long_axis(skin):
    """Horizontal principal axis of the rest mesh, signed toward the rig forward.
    Stormursa's Meshy mesh sits about 36 degrees off its rig's forward line."""
    import numpy as np
    pts = skin.pose({})[:, [0, 2]]
    _, vectors = np.linalg.eigh(np.cov((pts - pts.mean(0)).T))
    x, z = vectors[:, -1]
    return [float(x), 0.0, float(z)] if z >= 0 else [float(-x), 0.0, float(-z)]


def limp_sprawl(rig, frames, axis=None, roll=-90.0):
    roll_axis = axis or rig.forward
    for frame in frames:
        e = min(1.0, frame['phase'] / .7)
        turns = {}

        def add(b, m):
            if b in rig.contract:
                turns[b] = mul(m, turns[b]) if b in turns else m
        add('neck', rig.pitch(-14 * e))
        add('head', rig.pitch(-6 * e))
        for b in rig.contract:
            g = group(b)
            if g == 'front_lower':
                add(b, rig.swing(-25 * e))
            elif g == 'rear_lower':
                add(b, rig.swing(25 * e))
            elif g == 'tail':
                add(b, rig.pitch(-8 * e))
        frame['bones'] = rig.solve(turns)
        frame['pivot_roll_deg'] = 0
        frame['pivot_rotation_deg'] = euler(axis_angle(roll_axis, roll * e))


def level_fluke_swim(skin, rig, frames):
    """Restart r2: Water Sirenseal swam upright with its tail curled out of
    the water, because the generic hind-leg trail lifts the rear flipper
    chains that carry its tail. Give those chains an alternating up-down
    fluke stroke, then pitch the whole body level, head forward."""
    for frame in frames:
        a = math.sin(frame['phase'] * math.tau)
        b = math.sin(frame['phase'] * math.tau - 1.2)
        for side in ('_l', '_r'):
            frame['bones']['rear_upper' + side] = [round(-12.0 * a, 4), 0, 0]
            frame['bones']['rear_lower' + side] = [round(-14.0 * b, 4), 0, 0]
    SOLVER.level_body(skin, rig, frames, keep_feet=False)
    SOLVER.guard_stretch(skin, frames)


# Restart r4 (17 Oct): judges across r1-r3 found every role a single rotated
# keyframe on a rigid body. These replace that with staged cycles: a faint
# that buckles, rolls, overshoots and settles; a hit that jolts, holds and
# recovers; a ride that bobs and shifts weight under the rider.
def _ease(x):
    x = max(0.0, min(1.0, x))
    return x * x * (3 - 2 * x)


# Wing lift (degrees) added to every wing_upper turn while topple() authors a
# species' hit and faint; 0 outside it.
_wing_lift = 0.0


def _solve(rig, frame, turns, pivot):
    if _wing_lift:
        for b in rig.contract:
            if b.startswith('wing_upper'):
                lift = rig.wing_lift(b, _wing_lift)
                turns[b] = mul(lift, turns[b]) if b in turns else lift
    frame['bones'] = rig.solve(turns)
    frame['pivot_roll_deg'] = 0
    frame['pivot_rotation_deg'] = euler(pivot)


def _adder(rig, turns):
    def add(b, m):
        if b in rig.contract:
            turns[b] = mul(m, turns[b]) if b in turns else m
    return add


def staged_faint(rig, frames, axis, roll=-90.0, tuck=30.0, adduct=-25.0):
    """Front knees buckle and the chest pitches down (0-.35), the body rolls
    onto its flank past the rest angle (.35-.75), then settles back (.75-1)
    with the head down on the ground and the legs slack. Restart r5: r4 judges
    saw the downed body propped on its lower legs above a detached shadow, so
    the legs tuck fore and aft along the belly and draw toward the midline,
    letting the flank rest on the floor."""
    for frame in frames:
        p = frame['phase']
        buckle = _ease(p / .35)
        fall = _ease((p - .3) / .45)
        settle = math.sin(math.pi * _ease((p - .72) / .28)) * (1.0 - _ease((p - .9) / .1))
        turns = {}
        add = _adder(rig, turns)
        add('neck', rig.pitch(-12 * buckle - 18 * fall))
        add('head', rig.pitch(-10 * fall))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, mul(rig.swing(-14 * buckle * (1 - fall) + tuck * fall), rig.abduct(b, adduct * fall)))
            elif g == 'rear_upper':
                add(b, mul(rig.swing(-tuck * fall), rig.abduct(b, adduct * fall)))
            elif g == 'front_lower':
                add(b, rig.swing(-40 * buckle * (1 - fall)))
            elif g == 'tail':
                add(b, rig.pitch(-10 * fall))
        pivot = mul(axis_angle(axis, roll * fall + roll * .08 * settle), rig.pitch(-9 * buckle * (1 - fall)))
        _solve(rig, frame, turns, pivot)


def held_hit(rig, frames, scale=1.0):
    """A sharp jolt back and to one side at .15, held to .45, recovered by 1."""
    for frame in frames:
        p = frame['phase']
        e = _ease(p / .15) * (1.0 - _ease((p - .45) / .55))
        turns = {}
        add = _adder(rig, turns)
        add('spine', rig.pitch(6 * e * scale))
        add('neck', mul(rig.yaw(-14 * e * scale), rig.pitch(-16 * e * scale)))
        add('head', rig.pitch(-10 * e * scale))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(-10 * e * scale))
            elif g == 'rear_lower':
                add(b, rig.swing(12 * e * scale))
            elif g == 'tail':
                add(b, rig.pitch(-8 * e * scale))
        _solve(rig, frame, turns, mul(rig.roll(7 * e * scale), rig.pitch(11 * e * scale)))


def ride_bob(rig, frames, neck=0.0):
    """Braced under a rider with a stride bob, a side-to-side weight shift
    and a nodding head; `neck` lowers an upright neck while mounted."""
    for frame in frames:
        a = math.sin(frame['phase'] * math.tau)
        c = math.cos(frame['phase'] * math.tau)
        turns = {}
        add = _adder(rig, turns)
        add('neck', rig.pitch(neck + 5 * a))
        add('head', rig.pitch(-4 * a))
        for b in rig.contract:
            g = group(b)
            side = 1 if b.endswith('_l') else -1
            if g in ('front_upper', 'rear_upper'):
                add(b, rig.abduct(b, 10))
                add(b, rig.swing((8 if g == 'front_upper' else -8) + 14 * a * side))
            elif g == 'front_lower':
                add(b, rig.swing(-(26 + 10 * max(0.0, a * side))))
            elif g == 'rear_lower':
                add(b, rig.swing(26 + 10 * max(0.0, -a * side)))
            elif g == 'tail':
                add(b, rig.yaw(8 * c))
        _solve(rig, frame, turns, mul(rig.roll(3 * c), rig.pitch(2.5 * a)))


# close-1020 (21 Oct): F29#3 r7 judges preferred these 3/3 on Stormursa over
# staged_faint/held_hit: the feet stay planted while the front knees buckle
# before the roll (no airborne mid-faint), and the hit snaps the head away and
# down with the shoulders hunched instead of rearing up.
def topple_faint(rig, frames, axis, roll=-90.0, curl=0.0, fold=0.0, crouch=0.0):
    """`curl` (batch-3 judges: "side-lie with the head turned to the camera")
    bends the neck and head toward the camera-facing side as the body lands:
    nose down toward the belly for a negative roll, up toward the back for a
    positive one. `fold` bends the knees late in the fall so the legs curl
    limp instead of sticking out stiffly (fight-pitch judges). `crouch` folds
    the hind legs during the buckle too, so the hindquarters sink with the
    chest instead of staying high (judges read that as a pounce or leap)."""
    for f in frames:
        p = f['phase']
        buckle = _ease(p / .45)
        fall = _ease((p - .4) / .4)
        late = _ease((p - .75) / .25)
        settle = math.sin(math.pi * _ease((p - .78) / .22)) * (1 - _ease((p - .92) / .08))
        turns = {}
        add = _adder(rig, turns)
        side = -1.0 if roll < 0 else 1.0
        add('neck', rig.pitch(-14 * buckle * (1 - fall) - 4 * fall + side * curl * fall))
        add('head', rig.pitch(-6 * buckle * (1 - fall) + side * curl * .5 * fall))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(-10 * buckle * (1 - fall) + 10 * late))
            elif g == 'front_lower':
                add(b, rig.swing(-38 * buckle * (1 - fall) - 10 * late - fold * late))
            elif g == 'rear_upper':
                add(b, rig.swing(-8 * late + crouch * buckle * (1 - fall)))
            elif g == 'rear_lower':
                add(b, rig.swing(12 * buckle * (1 - fall) + 8 * late + fold * late - 1.6 * crouch * buckle * (1 - fall)))
            elif g == 'tail':
                add(b, rig.pitch(-10 * fall))
        pivot = mul(axis_angle(axis, roll * fall + roll * .06 * settle),
                    rig.pitch((-7 + .25 * crouch) * buckle * (1 - fall)))
        _solve(rig, f, turns, pivot)


# Close-1020 batch 10: batches 4, 7, 8 and 9 tuned the roll-based topple and
# all ran flat; every judge read its end as belly-up with the legs in the air,
# hiding the face and the dorsal feature. This collapses forward with no roll:
# the front knees buckle and the chest drops (0-.45), then the hindquarters
# give and the body settles on its belly (.4-.8) with the head down and turned
# toward the camera. `tuck` folds the hind legs under the body (sphinx);
# without it they slide out behind (splat).
def prone_faint(rig, frames, tuck=False, turn=14.0, splay=14.0, dip=1.0, rest_head=0.0):
    """`dip` scales the mid-collapse chest pitch and neck drop (judges: faint
    mid reads as standing); 1.0 keeps the batch-10 judged pose."""
    for f in frames:
        p = f['phase']
        buckle = _ease(p / .45)
        fall = _ease((p - .4) / .4)
        settle = math.sin(math.pi * _ease((p - .78) / .22)) * (1 - _ease((p - .92) / .08))
        turns = {}
        add = _adder(rig, turns)
        # rest_head lays the neck down so the head ends on the floor, the head
        # tipped back half as far so antlers sweep back rather than dig in.
        add('neck', mul(rig.yaw(turn * fall), rig.pitch(-16 * dip * buckle * (1 - fall) - 16 * buckle * fall - 6 * fall + 3 * settle - rest_head * fall)))
        add('head', rig.pitch(-6 * buckle * (1 - fall) + 10 * fall + .5 * rest_head * fall))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, mul(rig.swing(-12 * buckle * (1 - fall) + 55 * fall), rig.abduct(b, splay * fall)))
            elif g == 'front_lower':
                add(b, rig.swing(-42 * buckle * (1 - fall) + 10 * fall))
            elif g == 'rear_upper':
                rear = 38 if tuck else -55
                add(b, mul(rig.swing(rear * fall), rig.abduct(b, splay * fall)))
            elif g == 'rear_lower':
                add(b, rig.swing((-80 if tuck else -10) * fall + 10 * buckle * (1 - fall)))
            elif g == 'tail':
                add(b, rig.pitch(-12 * fall))
        _solve(rig, f, turns, rig.pitch(-8 * dip * buckle * (1 - fall) - 2 * settle))


def flinch_hit(rig, frames):
    for f in frames:
        p = f['phase']
        e = _ease(p / .12) * (1 - _ease((p - .35) / .45))
        turns = {}
        add = _adder(rig, turns)
        add('spine', rig.pitch(-4 * e))
        add('neck', mul(rig.yaw(-26 * e), rig.pitch(-14 * e)))
        add('head', mul(rig.yaw(-12 * e), rig.pitch(-10 * e)))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(-14 * e))
            elif g == 'front_lower':
                add(b, rig.swing(-20 * e))
            elif g == 'rear_lower':
                add(b, rig.swing(10 * e))
            elif g == 'tail':
                add(b, rig.pitch(-10 * e))
        _solve(rig, f, turns, mul(rig.roll(9 * e), rig.pitch(-3 * e)))



def recoil_hit(rig, frames, scale=1.0):
    """Close-1020 batch-1 judges: the clearest flinch throws the head up and
    back, away from the blow, with the weight rocking onto the haunches and
    the forelegs lifting; held to .35, back to stance by .8."""
    for f in frames:
        p = f['phase']
        e = scale * _ease(p / .12) * (1 - _ease((p - .35) / .45))
        turns = {}
        add = _adder(rig, turns)
        add('spine', rig.pitch(5 * e))
        add('neck', mul(rig.yaw(-18 * e), rig.pitch(22 * e)))
        add('head', mul(rig.yaw(-8 * e), rig.pitch(12 * e)))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(10 * e))
            elif g == 'front_lower':
                add(b, rig.swing(-18 * e))
            elif g == 'rear_lower':
                add(b, rig.swing(14 * e))
            elif g == 'tail':
                add(b, rig.pitch(-10 * e))
        _solve(rig, f, turns, mul(rig.roll(6 * e), rig.pitch(9 * e)))



def shove_hit(rig, frames, gain=1.0, hold=None):
    """Close-1020 batch-7 judges: a doubled recoil whips the head and tears the
    throat. The blow is carried by the body instead: the spine and chest rock
    back and away, the neck stays within 12 degrees, the forelegs lift and the
    hind legs brace; held to .35, back to stance by .8. `gain` scales only the
    body-carried rock (spine, legs and pivot), never the neck."""
    for f in frames:
        p = f['phase']
        release, end = hold or (SHOVE_RELEASE, SHOVE_END)
        e = _ease(p / .12) * (1 - _ease((p - release) / (end - release)))
        b_ = gain * e
        turns = {}
        add = _adder(rig, turns)
        add('spine', rig.pitch(10 * b_))
        add('neck', mul(rig.yaw(-10 * e), rig.pitch(12 * e)))
        add('head', rig.pitch(-4 * e))
        for b in rig.contract:
            g = group(b)
            if g == 'front_upper':
                add(b, rig.swing(16 * b_))
            elif g == 'front_lower':
                add(b, rig.swing(-24 * b_))
            elif g == 'rear_lower':
                add(b, rig.swing(16 * b_))
            elif g == 'tail':
                add(b, rig.pitch(-12 * b_))
        _solve(rig, f, turns, mul(rig.roll(10 * b_), rig.pitch(13 * b_)))

# Hit style per species (default flinch_hit, the batch-1 winner).
# Batch-2 judges (r1) preferred the recoil hit with the topple faint on these.
HIT_STYLE = {s: 'recoil' for s in ('ashtusk', 'sparkit', 'cindercub', 'shadelet', 'mirejaw',
                                  'torrentoad', 'cragclaw', 'pebbik', 'stormbrush', 'thundertunnel')}
HIT_STYLE.update({s: 'recoil' for s in ('mudsnout', 'meadowhart', 'riptusk', 'mangrove_monitor', 'voltwig', 'skyrill')})
# Close-1020 batch 8 (fight camera): the body-carried shove beat the live hit by 0.37-0.53 on these.
HIT_STYLE.update({s: 'shove' for s in ('terrapup', 'trailpup', 'burrowback')})
HIT_STYLE['meadowhart'] = 'shove'  # close-1022 b3, see SHOVE_GAIN_BY

# Per species, the roll the close-1020 batch-1 judges preferred (r1/r2 paired):
# negative shows the belly, legs and face to the side-on stage camera, positive
# the back. Mudsnout and Tuskroot kept their earlier faint (judged better).
# Neck curl toward the camera per species (degrees); 0 keeps the judged poses.
TOPPLE_CURL = {}
# Late knee fold in the side-lie, and recoil amplitude, per species (defaults keep judged poses).
TOPPLE_FOLD = {}
TOPPLE_CROUCH = {}
HIT_SCALE = {}
# F36#1 hurt candidate (OFF, unjudged; paused by owner 21 Oct): matrix-1 judges
# read the recoil as a small head raise, hard to tell from idle. The candidate
# moves every recoil species to the body-carried shove with SHOVE_GAIN 1.5:
#   HIT_STYLE.update({s: 'shove' for s, style in list(HIT_STYLE.items()) if style == 'recoil'})
# 1.0 reproduces the judged live shove exactly.
SHOVE_GAIN = 1.0
# Shove hold: release starts at .35 and is back to stance by .8 (the judged clip).
SHOVE_RELEASE, SHOVE_END = 0.35, 0.8
# Close-1022 b3 (CPU yardstick, three judges, confirming batch): the body-carried
# shove at gain 1.5, held to .5 and back by .97 so hit recover differs from
# standing, mapped Meadowhart 6.28 -> 7.56 (with its resting-deer prone faint,
# dip 2.5, antlers off the floor) and Riverdrake 6.72 -> 7.51.
SHOVE_GAIN_BY = {'meadowhart': 1.5, 'riverdrake': 1.5}
SHOVE_HOLD_BY = {'meadowhart': (0.5, 0.97), 'riverdrake': (0.5, 0.97)}
LIVE_SHOVE_HIT = ('riverdrake',)
# Close-1022 candidate (OFF until judged; enable with --candidate-1022): the hurt
# shove above for every recoil species, and Mirejaw's faint as a side topple
# (GPU pass 22 Oct: its belly-down prone faint reads as standing, all three judges).
CANDIDATE_1022 = '--candidate-1022' in sys.argv
if CANDIDATE_1022:
    HIT_STYLE.update({s: 'shove' for s, style in list(HIT_STYLE.items()) if style == 'recoil'})
    SHOVE_GAIN = 1.5
TOPPLE_ROLL = {'staticub': 90.0, 'cindercub': 90.0, 'terrapup': -90.0, 'burrowback': -90.0, 'trailpup': -90.0}
# Close-1020 fight-pitch round (capture --combat-pitch, the 25-degree fight
# camera): +90 (back and markings to the camera) beat the live faint by 0.3-1.4
# on these; the level-camera rounds that chose -90 for some of them could not
# see the side-lie the fight camera does.
TOPPLE_ROLL.update({s: 90.0 for s in ('terrapup', 'mudsnout', 'trailpup', 'burrowback', 'meadowhart', 'ashtusk', 'riptusk', 'mirejaw', 'torrentoad', 'cragclaw', 'mangrove_monitor', 'voltwig', 'stormbrush', 'thundertunnel', 'skyrill')})


# Species whose hit and faint the close-1020 judges chose per species; the
# full rewrite replays them so the committed file stays reproducible.
TOPPLED = ('ashtusk', 'burrowback', 'cindercub', 'cragclaw', 'mangrove_monitor', 'meadowhart',
           'mirejaw', 'mudsnout', 'pebbik', 'riptusk', 'shadelet', 'skyrill', 'sparkit', 'staticub',
           'stormbrush', 'stormursa', 'terrapup', 'thundertunnel', 'torrentoad', 'trailpup', 'voltwig')
# Close-1020 native-clip round (fight camera, three judges): the grounded topple
# with the recoil hit beat these species' own clips (Galewisp 5.83 vs 4.77,
# Aeriex 5.60 vs 5.20).
TOPPLED += ('galewisp', 'aeriex')
TOPPLE_ROLL.update({'galewisp': 90.0, 'aeriex': 90.0})
HIT_STYLE.update({'galewisp': 'recoil', 'aeriex': 'recoil'})
# Close-1020 Galewisp wing round: lifting the folded wings 55 degrees through the
# hit and faint beat the live edge-on blade read (5.33 vs 4.80, three judges).
WING_LIFT = {'galewisp': 55.0}


# Close-1020 batch 10 (fight camera, three judges): the belly-down prone collapse
# beat the live topple by 0.47-1.07 on these; set mean 6.02 vs 5.54.
# Batch 11: a deeper nose-down mid collapse (dip 2 or 3) gained 0.34-0.63 over
# the batch-10 pose on these five; it lifted the body on the rest, so they stay.
# F36#1 settle round (three judges, 20 species, base vs settle): folding the
# propping limbs so a faint's torso only ever sinks lifted the set 6.22 -> 6.37
# (mudsnout +0.90, terrapup +0.67, skyrill +0.60); brooktail lost 0.50, so it
# keeps the unsettled collapse. Settle applies only to the judged species; the
# rest keep their earlier collapse until a judge has seen them settled.
SETTLE_ONLY = {'ashtusk', 'burrowback', 'cannonback', 'cindercub', 'cliffspike', 'mangrove_monitor',
               'mosshock', 'mudsnout', 'pebbik', 'riptusk', 'shadelet', 'sirenseal', 'skyrill',
               'sparkit', 'staticub', 'terrapup', 'thundertunnel', 'torrentoad', 'voltwig'}
PRONE_DIP = {'ashtusk': 2.0, 'burrowback': 2.0, 'mudsnout': 3.0, 'shadelet': 2.0, 'thundertunnel': 3.0}
# Stormursa is not prone: its Meshy auto-rig weights the paws to the spine and
# pelvis rather than the upper legs, so the belly-down sprawl stretched paw edges
# to ~10x rest (spike 0.258, grey slabs on GPU and CPU) and propped the torso up.
# It keeps the judged side-on topple (F29#3 r8: spike 0.031, grounded).
PRONE = ('ashtusk', 'burrowback', 'cragclaw', 'mirejaw', 'mudsnout', 'riptusk', 'shadelet', 'skyrill',
         'staticub', 'stormbrush', 'terrapup', 'thundertunnel', 'torrentoad', 'trailpup', 'voltwig')
# Close-1022 b3: Meadowhart lies down like a resting deer (its side-lie put the
# antlers through the floor) and buckles deep enough mid-fall to read as going down.
PRONE += ('meadowhart',)
PRONE_DIP['meadowhart'] = 2.5
PRONE_HEAD_REST = {}
if CANDIDATE_1022:
    # GPU yardstick r3 (2 of 3 judges): Meadowhart's head-high faint end reads as
    # kneeling or resting. Lay the neck down so the head ends on the ground.
    PRONE_HEAD_REST['meadowhart'] = 34.0
if CANDIDATE_1022:
    PRONE = tuple(s for s in PRONE if s != 'mirejaw')
    # Meadowhart lies down like a resting deer (its side-lie put the antlers
    # through the floor). (A Fulgocobra prone hood-drop was tried and dropped
    # unjudged: its quadruped-rig coils lifted the tail off the floor mid-faint.)
    # b2 judges: hit recover equals standing. Hold the shove longer.
    SHOVE_RELEASE, SHOVE_END = 0.5, 0.97
    # F29#3 GPU judges: the bears' hit is a crouch and head dip with no recoil.
    HIT_STYLE.update({'stormursa': 'shove', 'staticub': 'shove'})


def clamp_neck(frames, limit=NECK_PITCH_LIMIT):
    """Scale any neck or head hurt turn back inside the limit, keeping its axis."""
    half = math.radians(limit) / 2
    for f in frames:
        for bone in ('neck', 'head'):
            if bone in f['bones']:
                q = AUTHOR.quaternion(f['bones'][bone])
                if q[3] < 0:
                    q = [-v for v in q]
                angle = 2 * math.acos(min(1.0, q[3]))
                if math.degrees(angle) > limit:
                    s = math.sin(half) / math.sin(angle / 2)
                    q = [q[0] * s, q[1] * s, q[2] * s, math.cos(half)]
                    f['bones'][bone] = [round(v, 4) + 0.0 for v in AUTHOR.euler_degrees(q)]


def topple(name, row, prof):
    global _wing_lift
    _wing_lift = WING_LIFT.get(name, 0.0)
    try:
        _topple(name, row, prof)
    finally:
        _wing_lift = 0.0


def _topple(name, row, prof):
    rig = Rig(row['rig_contract'], row['bones'])
    skin = SKIN.Skin(row['model'], row['rig_contract'], row['bones'])
    if name in PRONE:
        prone_faint(rig, prof['faint']['frames'], dip=PRONE_DIP.get(name, 1.0), rest_head=PRONE_HEAD_REST.get(name, 0.0))
    else:
        topple_faint(rig, prof["faint"]["frames"], mesh_long_axis(skin), roll=TOPPLE_ROLL.get(name, -90.0),
                     curl=TOPPLE_CURL.get(name, 0.0), fold=TOPPLE_FOLD.get(name, 0.0),
                     crouch=TOPPLE_CROUCH.get(name, 0.0))
    SOLVER.guard_stretch(skin, prof['faint']['frames'])
    # Lift the legs that prop the toppled torso off the floor, blended in over the fall.
    SOLVER.ground_faint(skin, prof['faint']['frames'], lambda phase: min(1.0, max(0.0, (phase - .4) / .4)))
    if name in SETTLE_ONLY:
        SOLVER.settle_descent(skin, prof['faint']['frames'])
    if HIT_STYLE.get(name) == 'recoil':
        recoil_hit(rig, prof['hit']['frames'], scale=HIT_SCALE.get(name, 1.0))
    elif HIT_STYLE.get(name) == 'shove':
        shove_hit(rig, prof['hit']['frames'], gain=SHOVE_GAIN_BY.get(name, SHOVE_GAIN), hold=SHOVE_HOLD_BY.get(name))
    else:
        flinch_hit(rig, prof['hit']['frames'])
    SOLVER.guard_stretch(skin, prof['hit']['frames'])


def patch_topple(text, names):
    """Rewrite only the hit and faint frames of the named species' profiles,
    in place, leaving every other byte of the live file unchanged."""
    live = json.loads(text)
    for name in names:
        row = live['species'][name]
        pid = row['profile']
        prof = live['profiles'][pid]
        topple(name, row, prof)
        clamp_neck(prof['hit']['frames'])
        m = re.compile(r'\n    %s: ' % re.escape(json.dumps(pid))).search(text, text.index('\n  "profiles": {'))
        start, end = value_span(text, m.end())
        text = text[:start] + json.dumps(prof, separators=(',', ':')) + text[end:]
    return text


def patch_hit(text, names, gain):
    """Close-1022 candidate: replace only the named species' hit frames with the
    body-carried shove (GPU yardstick: Riverdrake's hit react reads as standing)."""
    live = json.loads(text)
    for name in names:
        row = live['species'][name]
        pid = row['profile']
        prof = live['profiles'][pid]
        rig = Rig(row['rig_contract'], row['bones'])
        skin = SKIN.Skin(row['model'], row['rig_contract'], row['bones'])
        shove_hit(rig, prof['hit']['frames'], gain=gain)
        SOLVER.guard_stretch(skin, prof['hit']['frames'])
        clamp_neck(prof['hit']['frames'])
        m = re.compile(r'\n    %s: ' % re.escape(json.dumps(pid))).search(text, text.index('\n  "profiles": {'))
        start, end = value_span(text, m.end())
        text = text[:start] + json.dumps(prof, separators=(',', ':')) + text[end:]
    return text


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
    if name == 'mosshell':
        # The first alternating stroke gained only 0.30: its forefeet stayed
        # below the staged waterline, so the action still read as wading.
        # Splay and extend each power-stroke foreleg out through the surface,
        # then return it under the shell while the other side rows. The shell
        # roll and face-lifting float pitch remain as in the scored treatment.
        for frame in prof['swim']['frames']:
            stroke = math.sin(frame['phase'] * math.tau)
            left = max(0.0, stroke)
            right = max(0.0, -stroke)
            frame['pivot_rotation_deg'] = [-6.0, 0, round(8.0 * stroke, 4)]
            frame['bones']['front_upper_l'] = [round(-42.0 - 8.0 * left + 18.0 * right, 4), 0, round(-40.0 * left, 4)]
            frame['bones']['front_upper_r'] = [round(-42.0 - 8.0 * right + 18.0 * left, 4), 0, round(40.0 * right, 4)]
            frame['bones']['front_lower_l'] = [round(25.0 * (1.0 - left), 4), 0, 0]
            frame['bones']['front_lower_r'] = [round(25.0 * (1.0 - right), 4), 0, 0]
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
    if name in LIMP_SPRAWL:
        limp_sprawl(rig, prof['faint']['frames'], mesh_long_axis(skin))
        SOLVER.guard_stretch(skin, prof['faint']['frames'])
    else:
        SOLVER.ground_faint(skin, prof['faint']['frames'], lambda phase: min(1.0, phase / .7))
        if name in SETTLE_ONLY:
            SOLVER.settle_descent(skin, prof['faint']['frames'])


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
        if name in TOPPLED:
            topple(name, row, prof)
        if name in LIVE_SHOVE_HIT:
            skin = SKIN.Skin(row['model'], row['rig_contract'], row['bones'])
            shove_hit(rig, prof['hit']['frames'], gain=SHOVE_GAIN_BY.get(name, SHOVE_GAIN), hold=SHOVE_HOLD_BY.get(name))
            SOLVER.guard_stretch(skin, prof['hit']['frames'])
        if 'hit' in prof:
            clamp_neck(prof['hit']['frames'])
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
    topple = [a.split('=', 1)[1].split(',') for a in sys.argv[1:] if a.startswith('--topple=')]
    after = patch_topple(before, topple[0]) if topple else rewrite(before)
    hits = [a.split('=', 1)[1].split(',') for a in sys.argv[1:] if a.startswith('--shove-hit=')]
    if hits:
        after = patch_hit(after, hits[0], SHOVE_GAIN)
    if check:
        print('stale' if after != before else 'current')
        sys.exit(1 if after != before else 0)
    out.write_text(after)
    print('F36 post-pass wrote %s (%d bytes)' % (out, len(after)))


if __name__ == '__main__':
    main()
