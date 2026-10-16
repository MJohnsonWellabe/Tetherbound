"""F36#1 round 3: refine post-pass frames against each species' installed skin.

The post-pass writes anatomical turns from rig axes alone. Round 2's judges
showed where axes are not enough: a fainted body propped on a horn, tail,
limb tip or wing; fliers whose wings stay folded; upright bodies that swim
and carry a rider standing up; a few stretched meshes. Each fix here measures
the posed skin (f36_skin) and edits only that species' recipe numbers:

- faint: lift whichever appendage chain holds the torso off the floor until
  the torso itself rests on the floor (bounded turns, no stretch).
- fly_grip (winged rigs): spread each wing chain out to the side, then beat.
- swim / ride (upright bodies): pitch the body level with the pivot so it
  swims flat and carries its rider on a horizontal back.
- every role: back off any bone turn that stretches a mesh edge visibly.
"""
import math

import numpy as np

from f36_skin import euler_matrix

UP = np.array([0.0, 1.0, 0.0])
FAINT_GAP = 0.06          # torso-to-floor gap allowed, as a share of height
LIFT_STEP = 8.0
LIFT_LIMIT = 96.0
SPIKE_LIMIT = 0.09        # largest edge growth allowed, as a share of height
WING_SPREAD_UP = 12.0
WING_BEAT = 24.0


def to_euler(m):
    """3x3 -> Godot YXZ Euler degrees (inverse of euler_matrix)."""
    sx = -m[1, 2]
    x = math.asin(max(-1.0, min(1.0, sx)))
    if abs(sx) < 0.9999999:
        y = math.atan2(m[0, 2], m[2, 2])
        z = math.atan2(m[1, 0], m[1, 1])
    else:
        y = math.atan2(-m[2, 0], m[0, 0])
        z = 0.0
    return [round(math.degrees(v), 4) + 0.0 for v in (x, y, z)]


def axis_angle(axis, degrees):
    axis = np.asarray(axis, float)
    n = np.linalg.norm(axis)
    if n < 1e-9 or abs(degrees) < 1e-9:
        return np.eye(3)
    x, y, z = axis / n
    t = math.radians(degrees)
    c, s, k = math.cos(t), math.sin(t), 1 - math.cos(t)
    return np.array([[c + x * x * k, x * y * k - z * s, x * z * k + y * s],
                     [y * x * k + z * s, c + y * y * k, y * z * k - x * s],
                     [z * x * k - y * s, z * y * k + x * s, c + z * z * k]])


def rotation_between(a, b):
    a = a / np.linalg.norm(a)
    b = b / np.linalg.norm(b)
    axis = np.cross(a, b)
    angle = math.degrees(math.atan2(np.linalg.norm(axis), float(np.dot(a, b))))
    if np.linalg.norm(axis) < 1e-9:
        return np.eye(3), 0.0, axis
    return axis_angle(axis, angle), angle, axis


def orthonormal(m):
    u, _, vt = np.linalg.svd(m[:3, :3])
    return u @ vt


def slerp_identity(q, amount):
    """Rotation matrix q scaled to `amount` of its angle."""
    angle = math.degrees(math.acos(max(-1.0, min(1.0, (np.trace(q) - 1) / 2))))
    if angle < 1e-6:
        return np.eye(3)
    axis = np.array([q[2, 1] - q[1, 2], q[0, 2] - q[2, 0], q[1, 0] - q[0, 1]])
    if np.linalg.norm(axis) < 1e-9:
        w, v = np.linalg.eigh((q + q.T) / 2)
        axis = v[:, np.argmax(w)]
    return axis_angle(axis, angle * amount)


class Frame:
    """One recipe frame as matrices, editable by model-space turns."""

    def __init__(self, skin, data):
        self.skin = skin
        self.data = data
        self.delta = {b: euler_matrix(data['bones'].get(b, [0, 0, 0])) for b in skin.bones}
        self.pivot = euler_matrix(data.get('pivot_rotation_deg', [0, 0, 0]))

    def eulers(self):
        return {b: to_euler(m) for b, m in self.delta.items()}

    def points(self):
        return self.skin.pose(self.eulers()) @ self.pivot.T

    def joints(self):
        return self.skin.joint_positions(self.eulers()) @ self.pivot.T

    def base(self, bone):
        """Posed parent rotation times local rest (skeleton space)."""
        i = self.skin.index[bone]
        g = self.skin.globals(self.eulers())
        p = self.skin.parent[i]
        parent = orthonormal(g[p]) if p >= 0 else np.eye(3)
        return parent @ orthonormal(self.skin.rest[i])

    def local_for_turn(self, bone, turn_model):
        """Local pre-delta equivalent to turning `bone` by a model-space turn."""
        turn = self.pivot.T @ turn_model @ self.pivot
        base = self.base(bone)
        return base.T @ turn @ base

    def turn(self, bone, turn_model):
        q = self.local_for_turn(bone, turn_model)
        self.delta[bone] = q @ self.delta[bone]
        return q

    def write(self):
        self.data['bones'] = {b: to_euler(self.delta[b]) for b in self.skin.bones if b in self.data['bones']}
        self.data['pivot_rotation_deg'] = to_euler(self.pivot)


def spike(skin, points):
    length = np.linalg.norm(points[skin.edges[:, 0]] - points[skin.edges[:, 1]], axis=1)
    return float(((length - skin.rest_edges) / skin.height).max())


def chains(skin):
    """Appendage chain roots: non-torso bones hanging off the torso."""
    from f36_skin import TORSO_BONES
    out = []
    for b, i in skin.index.items():
        p = skin.parent[i]
        if b in TORSO_BONES or b == 'neutral_bone':
            continue
        if p < 0 or skin.bones[p] in TORSO_BONES:
            members = skin.descendants(b)
            mask = np.isin(skin.dominant, list(members))
            if mask.sum() >= 10:
                out.append((b, mask))
    return out


def faint_gap(skin, points):
    return (points[skin.torso, 1].min() - points[:, 1].min()) / skin.height


def ground_faint(skin, frames, amount_of):
    """Lift propping chains on the end frame; blend the same lifts in by phase."""
    end = Frame(skin, frames[-1])
    roots = chains(skin)
    lifted = {b: 0.0 for b, _ in roots}
    blocked = set()
    local = {b: np.eye(3) for b, _ in roots}
    base_spike = spike(skin, end.points())
    for _ in range(int(len(roots) * LIFT_LIMIT / LIFT_STEP) + 1):
        pts = end.points()
        if faint_gap(skin, pts) <= FAINT_GAP:
            break
        torso_floor = pts[skin.torso, 1].min()
        candidates = []
        for b, mask in roots:
            if b in blocked or lifted[b] >= LIFT_LIMIT:
                continue
            low = pts[mask, 1].min()
            if low < torso_floor - FAINT_GAP * skin.height * 0.5:
                candidates.append((low, b, mask))
        if not candidates:
            break
        _, b, mask = min(candidates, key=lambda c: c[0])
        joint = end.joints()[skin.index[b]]
        sub = np.where(mask)[0]
        lowest = pts[sub[np.argmin(pts[sub, 1])]]
        d = lowest - joint
        axis = np.cross(d, UP)
        if np.linalg.norm(axis) < 1e-6 or np.linalg.norm(d) < 1e-6:
            blocked.add(b)
            continue
        saved = end.delta[b].copy()
        q = end.turn(b, axis_angle(axis, LIFT_STEP))
        trial = end.points()
        if spike(skin, trial) > max(SPIKE_LIMIT, base_spike + 0.02) or trial[mask, 1].min() <= pts[mask, 1].min() + 1e-5:
            end.delta[b] = saved
            blocked.add(b)
            continue
        local[b] = q @ local[b]
        lifted[b] += LIFT_STEP
    end.write()
    for data in frames[:-1]:
        amount = amount_of(data['phase'])
        if amount <= 0:
            continue
        f = Frame(skin, data)
        for b, q in local.items():
            f.delta[b] = slerp_identity(q, amount) @ f.delta[b]
        f.write()
    return {b: a for b, a in lifted.items() if a > 0}


def wing_roots(skin):
    return [b for b in skin.bones if b.startswith('wing_upper')]


def open_wings(skin, rig, frames, roots=None, child_prefix='wing_'):
    """Spread every wing chain to its side (slightly raised), then beat."""
    lateral = np.array(rig.lateral)
    roots = wing_roots(skin) if roots is None else roots
    for data in frames:
        f = Frame(skin, data)
        phase = data['phase']
        for root in roots:
            side = rig.side(root)
            beat = WING_SPREAD_UP + WING_BEAT * math.sin(phase * math.tau)
            target = side * lateral * math.cos(math.radians(beat)) + UP * math.sin(math.radians(beat))
            chain = [root]
            while True:
                kids = [b for b in skin.bones if skin.parent[skin.index[b]] == skin.index[chain[-1]]
                        and b.startswith(child_prefix)]
                if not kids:
                    break
                chain.append(kids[0])
            for bone in chain:
                members = skin.descendants(bone)
                mask = np.isin(skin.dominant, list(members))
                if mask.sum() < 10:
                    continue
                pts = f.points()
                joint = f.joints()[skin.index[bone]]
                rel = pts[mask] - joint
                dist = np.linalg.norm(rel, axis=1)
                far = rel[dist >= np.quantile(dist, 0.9)].mean(axis=0)
                turn, _, _ = rotation_between(far, target)
                f.turn(bone, turn)
        f.write()


def body_tilt(skin, rig):
    """Main axis of the rest mesh in the forward/up plane, degrees above level."""
    forward = np.array(rig.forward)
    pts = skin.rest_points
    flat = np.stack([pts @ forward, pts[:, 1]], axis=1)
    flat = flat - flat.mean(axis=0)
    w, v = np.linalg.eigh(flat.T @ flat)
    axis = v[:, np.argmax(w)]
    if axis[0] < 0:
        axis = -axis
    return math.degrees(math.atan2(axis[1], axis[0]))


def level_body(skin, rig, frames, keep_feet, limit=75.0):
    """Pitch an upright body level with the pivot (nose forward and down)."""
    forward = np.array(rig.forward)
    pitch_axis = np.cross(forward, UP)
    degrees = max(0.0, min(limit, abs(body_tilt(skin, rig))))
    if keep_feet:
        degrees = max(0.0, degrees - 20.0)
    if degrees < 10.0:
        return 0.0
    turn = axis_angle(pitch_axis, -degrees)
    for data in frames:
        f = Frame(skin, data)
        f.pivot = turn @ f.pivot
        if keep_feet:
            for b in skin.bones:
                if b.startswith(('rear_upper', 'leg_upper')):
                    f.turn(b, axis_angle(pitch_axis, degrees))
        f.write()
    return degrees


def guard_stretch(skin, frames):
    """Scale back the bone turns that stretch an edge past SPIKE_LIMIT."""
    worst = 0.0
    for data in frames:
        f = Frame(skin, data)
        for _ in range(24):
            pts = f.points()
            s = spike(skin, pts)
            if s <= SPIKE_LIMIT:
                break
            length = np.linalg.norm(pts[skin.edges[:, 0]] - pts[skin.edges[:, 1]], axis=1)
            edge = skin.edges[np.argmax(length - skin.rest_edges)]
            bones = set(skin.joints[edge[0]][skin.weights[edge[0]] > 0]) | set(skin.joints[edge[1]][skin.weights[edge[1]] > 0])
            for i in list(bones):
                while skin.parent[i] >= 0:
                    i = skin.parent[i]
                    bones.add(i)
            best = None
            for i in bones:
                b = skin.bones[i]
                saved = f.delta[b]
                f.delta[b] = slerp_identity(saved, 0.5)
                trial = spike(skin, f.points())
                f.delta[b] = saved
                if best is None or trial < best[0]:
                    best = (trial, b)
            if best is None or best[0] >= s - 1e-4:
                break
            f.delta[best[1]] = slerp_identity(f.delta[best[1]], 0.5)
        f.write()
        worst = max(worst, spike(skin, f.points()))
    return worst
