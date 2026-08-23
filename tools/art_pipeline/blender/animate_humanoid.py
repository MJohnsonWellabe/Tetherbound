"""Author the trainer's gameplay clips onto a Meshy humanoid rig, procedurally.

    blender --background --python tools/art_pipeline/blender/animate_humanoid.py \
            -- <rigged.glb> --out <animated.glb>

The game drives five roles for the human (data/config/art.json, read by
scripts/player/trainer_model.gd): idle, walk, sprint, jump, throw.

## Why not reuse the rig the game already had

The trainer shipped on KayKit's Ranger, whose 23-bone skeleton comes with all
five clips in shared libraries — so the obvious move was to fit the new mesh
to that skeleton and inherit them for nothing. Measured, it does not work:
KayKit's character is 2.27 units tall with a head from 1.19 to 2.27, i.e.
roughly TWO heads tall, and the new trainer is drawn at 6.25. Nearest-surface
weight transfer between those two maps the boy's chest onto the chibi's jaw,
and the clips themselves are authored with chibi arm arcs. Wrong proportions
in, wrong deformation out.

## Why not Meshy's animation library

Meshy's rigging response ships exactly two clips with skin, `walking` and
`running`. The wider library is addressed by numeric action id, and the API
exposes no way to list them — every documented listing path answers "Invalid
ID". Two of five clips, with no route to the other three.

So the clips are authored here on the rig Meshy fitted to this mesh, which is
a standard humanoid skeleton (Hips / UpLeg / Leg / Foot, Spine / Spine01 /
Spine02, Shoulder / Arm / ForeArm / Hand, neck / Head).

WHAT THESE CLIPS ARE, HONESTLY. Key-pose authored cycles (MQ1A): each gait is
a table of anatomical key poses — contact, loading, mid-stance, toe-off, whip,
mid-swing, reach — sampled through a cyclic Catmull-Rom spline, with pelvis
rotation/list, chest counter-rotation and head stabilisation on top. They are
authored in this script rather than hand-keyed in a DCC, but they are pose
work, not oscillators: the earlier sine-synthesis version (OF5) hit a ceiling
a blind pass kept calling robotic, and its axis conventions were part-inverted
(knees folded forward, elbows hyperextended backward — see AXES below).

AXES, VERIFIED BY RENDER (tools/_probe_pose_axes.gd, MQ1A). Blender pose
eulers on this rig, in the bone's own rest frame:
  thigh  X:  + = swing back,   - = swing forward
  shin   X:  + = knee flexion, - = IMPOSSIBLE forward hyperextension
  foot   X:  + = plantarflex (toes down), - = dorsiflex (toes up)
  arm    X:  + = swing back,   - = swing forward
  forearm X: - = elbow flexion, + = IMPOSSIBLE backward hyperextension
  hips/chest/head Y: + = left side leads (yaw)
  hips   Z:  + = left hip up (pelvic list)
Do not key a joint here without checking this table; the pre-MQ1A clips keyed
knee folds and elbow bends on the wrong sign for months and every render
review read it as "unnatural" without anyone spotting why.

All clips animate bones only — the object's origin never moves, because the
game drives the body's position and expects animation in place. That includes
the jump: the character crouches, extends and lands, and the actual vertical
travel is the controller's.
"""

import math
import pathlib
import sys

import bpy

FPS = 24

## name -> frames. The names are the ROLES the game asks for, so
## data/config/art.json maps role to clip one-to-one with no translation.
##
## Gait cycle lengths are DERIVED from movement.json's speeds, not styled (OF5).
## The clip plays while the controller translates the body at walk_speed /
## sprint_speed, and a planted foot must sweep backward under the body at that
## same speed or the feet visibly skate over the ground. Peak backward foot
## speed of a sinusoidal swing is amplitude(rad) x (2*pi/cycle) x leg length
## (~0.9m on a 1.8m human). The old walk (32 frames, +-24 deg) peaked at
## ~1.7 m/s under a 5.0 m/s body -- a >3 m/s skate, and the single loudest
## thing the owner read as "unnatural". The sprint runs an 11-frame cycle:
## 0.458s at 8.6 m/s is a 1.97m step at 4.4 steps/s with ~0.1s of ground
## contact, which is what a real 8.6 m/s runner actually does -- the 12-frame
## version measured ~2 m/s of planted skate because an ankle on a flexed knee
## cannot sweep 8.6 m/s horizontally for any longer contact than that.
CLIPS = {
    "idle": 96,
    "walk": 15,
    "sprint": 11,
    "jump": 28,
    "throw": 24,
    "chop": 15,
}

## Meshy's humanoid bone names. Kept in one table so a rig that names things
## differently is a data edit rather than a rewrite.
BONES = {
    "hips": "Hips",
    "spine": "Spine",
    "chest": "Spine02",
    "neck": "neck",
    "head": "Head",
    "upleg.l": "LeftUpLeg", "leg.l": "LeftLeg", "foot.l": "LeftFoot",
    "upleg.r": "RightUpLeg", "leg.r": "RightLeg", "foot.r": "RightFoot",
    "shoulder.l": "LeftShoulder", "arm.l": "LeftArm",
    "forearm.l": "LeftForeArm", "hand.l": "LeftHand",
    "shoulder.r": "RightShoulder", "arm.r": "RightArm",
    "forearm.r": "RightForeArm", "hand.r": "RightHand",
}

## Keyframe every Nth frame and let Blender interpolate. Dense enough for a
## sine to read as a curve rather than as a triangle wave.
STEP = 4


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not rigs:
        raise SystemExit("no armature — rig the mesh first")
    rig = rigs[0]
    missing = [key for key, name in BONES.items() if name not in rig.pose.bones]
    if missing:
        raise SystemExit(
            f"rig is missing {len(missing)} expected bones: {', '.join(missing)}.\n"
            f"It has: {', '.join(b.name for b in rig.pose.bones)}\n"
            f"Update BONES in this script rather than animating the wrong joints.")
    return rig


def key(rig, slot: str, frame: int, euler=None, location=None) -> None:
    bone = rig.pose.bones.get(BONES[slot])
    if bone is None:
        return
    bone.rotation_mode = "XYZ"
    if euler is not None:
        bone.rotation_euler = [math.radians(a) for a in euler]
        bone.keyframe_insert("rotation_euler", frame=frame)
    if location is not None:
        bone.location = location
        bone.keyframe_insert("location", frame=frame)


def clear_pose(rig) -> None:
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)


def author_idle(rig, frames: int) -> None:
    """Breathing and a slow weight shift. Small on purpose: idle is what the
    player looks at while reading a dialogue box, and big motion reads as
    fidgeting."""
    for frame in range(0, frames + 1, STEP):
        phase = 2 * math.pi * frame / frames
        breath = math.sin(phase)
        sway = math.sin(phase / 2)
        key(rig, "chest", frame, euler=(-1.6 * breath, 0, 0))
        key(rig, "spine", frame, euler=(0.8 * breath, 0, 0.9 * sway))
        key(rig, "head", frame, euler=(-1.0 * breath, 2.2 * sway, 0))
        key(rig, "hips", frame, euler=(0, 0, -0.7 * sway))
        # Arms hang; a touch of shoulder rise on the inhale keeps them alive.
        # Elbows carry a small natural FLEXION (negative X — see AXES): the
        # pre-MQ1A +2 here was a subtle backward hyperextension.
        for side, sign in (("l", -1.0), ("r", 1.0)):
            key(rig, f"arm.{side}", frame, euler=(1.4 * breath, 0, sign * 2.0))
            key(rig, f"forearm.{side}", frame, euler=(-6.0 - 1.2 * breath, 0, 0))


## Key-pose tables (MQ1A). Values are Blender pose eulers in DEGREES on the
## verified axes above; fractions are of one full cycle, LEFT-leg contact at
## 0.0. The pose names are the animator's checklist — contact, loading,
## mid-stance, toe-off, whip, mid-swing, reach — and the asymmetric fractions
## are the point: a sine gait puts the same time between every pose, which is
## the metronome read the blind pass called robotic. Stance occupies ~40% of
## the cycle at a jog and ~32% at a sprint; everything else is swing.
##
## Stride geometry: the stance thigh sweeps contact->toe-off while the body
## covers speed * stance_time; the sweep angle times ~0.95m leg length plus
## the heel-toe rocker (~0.2-0.3m) must meet that distance or the planted
## foot skates (OF5's measured 3x skate). Both tables below land within ~5%,
## slightly over — overshoot reads as grip, undershoot as ice.
##
## Each entry: fraction -> (thigh_x, knee_x, foot_x).
## Stance fractions are short — 28% (jog) and 25% (sprint) — because both
## speeds are RUNS and a run flies: with the two legs offset 0.5, these
## timings give the cycle two genuine flight windows (0.28-0.5, 0.78-1.0 at
## the jog). The first cut of these tables used a 40% walking stance and
## measured 2.4 m/s of real skate (tools/_probe_foot_skate.gd): the ankle
## only travels ~sin(sweep)x0.95m backward per stance, so the only honest
## ways to close the gap are a bigger sweep (cartoon splits) or less time
## planted. Less time planted is what real legs do at 5+ m/s. The stance
## knots are also spaced so the thigh sweeps at a near-CONSTANT rate while
## planted — a curve that saves its sweep for toe-off skates through early
## stance even when the totals add up (measured, same probe).
JOG_LEG = [
    (0.00, -34.0, 14.0, -12.0),   # contact: heel leads, knee soft
    (0.08, -15.0, 30.0, 2.0),     # loading: knee absorbs, sweep stays linear
    (0.17, 5.0, 18.0, 2.0),       # mid-stance: body passes over, heel rising
    (0.28, 30.0, 20.0, 28.0),     # toe-off: hip extended, ankle pushes
    (0.42, 14.0, 66.0, 12.0),     # early swing: heel lifts toward seat
    (0.62, -16.0, 60.0, -4.0),    # mid-swing: knee leads through
    (0.84, -36.0, 24.0, -14.0),   # reach: shin swings out, toes up
]
SPRINT_LEG = [
    (0.00, -36.0, 24.0, -6.0),    # contact: midfoot, knee loaded
    (0.06, -17.0, 42.0, 6.0),     # loading: deep absorption, sweep linear
    (0.13, 5.0, 28.0, 8.0),       # mid-stance: heel rising already
    (0.22, 32.0, 32.0, 34.0),     # toe-off: full drive
    (0.38, 16.0, 100.0, 18.0),    # whip: heel near the seat
    (0.56, -24.0, 88.0, 0.0),     # mid-swing: folded knee swings through
    (0.75, -46.0, 56.0, -8.0),    # knee drive: thigh high
    (0.89, -40.0, 30.0, -10.0),   # reach: leg extends for contact
]

## fraction -> value tables for the body. Bob dips as each leg loads and
## rises into the flight half of the stride; yaw/list peak at the contacts.
JOG_BODY = {
    "bob":       [(0.08, -0.040), (0.34, 0.012), (0.58, -0.040), (0.84, 0.012)],
    "hips_yaw":  [(0.0, 6.0), (0.25, 0.0), (0.5, -6.0), (0.75, 0.0)],
    "hips_list": [(0.04, 1.5), (0.15, 3.0), (0.34, 0.0),
                  (0.54, -1.5), (0.65, -3.0), (0.84, 0.0)],
    "chest_yaw": [(0.0, -8.0), (0.25, 0.0), (0.5, 8.0), (0.75, 0.0)],
}
SPRINT_BODY = {
    "bob":       [(0.06, -0.050), (0.28, 0.022), (0.56, -0.050), (0.78, 0.022)],
    "hips_yaw":  [(0.0, 8.0), (0.25, 0.0), (0.5, -8.0), (0.75, 0.0)],
    "hips_list": [(0.03, 1.5), (0.11, 3.0), (0.28, 0.0),
                  (0.53, -1.5), (0.61, -3.0), (0.78, 0.0)],
    "chest_yaw": [(0.0, -12.0), (0.25, 0.0), (0.5, 12.0), (0.75, 0.0)],
}

## Whole-gait constants: (lean_hips, lean_spine, lean_chest, head_pitch,
## arm_bias, arm_amp, elbow_base, elbow_deepen, arm_out, hand_curl).
## Arm swing stays sinusoidal on purpose — a swinging arm genuinely is close
## to a pendulum — with the forward peak led slightly (0.47, not 0.5) so the
## arm arrives before the opposite foot the way a real counterweight does.
## Elbow flexes as the arm swings FORWARD (negative X) and opens at the back.
JOG_STYLE = (5.0, 3.0, 4.0, -6.0, -4.0, 22.0, -44.0, -18.0, 5.0, -10.0)
SPRINT_STYLE = (9.0, 5.0, 5.0, -11.0, -6.0, 30.0, -70.0, -24.0, 7.0, -14.0)

ARM_LEAD = 0.47


def _cyclic_catmull(points):
    """A C1 interpolant through cyclic (fraction, value) key poses.

    Catmull-Rom via non-uniform finite differences: the curve passes through
    every authored pose exactly and eases between them, which is what Blender
    would do with hand-set keys — done here numerically so the pose tables
    stay plain data and the same sampler serves every channel.
    """
    pts = sorted(points)
    n = len(pts)

    def sample(p: float) -> float:
        p = p % 1.0
        # A phase before the first knot belongs to the wrap segment (last
        # knot -> first knot + 1), not to a cubic extrapolated backwards off
        # it — the first bake of this sampler launched the hips metres off
        # the ground at exactly the contact frames because of that.
        if p < pts[0][0]:
            p += 1.0
        for i in range(n):
            t1, v1 = pts[i]
            t2, v2 = pts[(i + 1) % n]
            if (i + 1) == n:
                t2 += 1.0
            if t1 <= p < t2 or (i + 1) == n:
                t0, v0 = pts[(i - 1) % n]
                if i == 0:
                    t0 -= 1.0
                t3, v3 = pts[(i + 2) % n]
                if (i + 2) >= n:
                    t3 += 1.0
                u = (p - t1) / (t2 - t1)
                m1 = (v2 - v0) / (t2 - t0) * (t2 - t1)
                m2 = (v3 - v1) / (t3 - t1) * (t2 - t1)
                u2, u3 = u * u, u * u * u
                return ((2 * u3 - 3 * u2 + 1) * v1 + (u3 - 2 * u2 + u) * m1
                        + (-2 * u3 + 3 * u2) * v2 + (u3 - u2) * m2)
        return pts[0][1]

    return sample


def author_gait(rig, frames: int, leg_table, body_tables, style) -> None:
    """One gait cycle from key poses — see the tables above for the design.

    Everything below is sampled and keyed per frame: the splines are already
    smooth, and dense keys survive glTF's animation sampling without
    re-interpolation surprises.
    """
    (lean_hips, lean_spine, lean_chest, head_pitch, arm_bias, arm_amp,
     elbow_base, elbow_deepen, arm_out, hand_curl) = style

    thigh = _cyclic_catmull([(f, v) for f, v, _, _ in leg_table])
    knee = _cyclic_catmull([(f, v) for f, _, v, _ in leg_table])
    foot = _cyclic_catmull([(f, v) for f, _, _, v in leg_table])
    bob = _cyclic_catmull(body_tables["bob"])
    hips_yaw = _cyclic_catmull(body_tables["hips_yaw"])
    hips_list = _cyclic_catmull(body_tables["hips_list"])
    chest_yaw = _cyclic_catmull(body_tables["chest_yaw"])

    for frame in range(0, frames + 1):
        p = (frame / frames) % 1.0

        key(rig, "hips", frame,
            euler=(lean_hips, hips_yaw(p), hips_list(p)),
            location=(0, bob(p), 0))
        key(rig, "spine", frame, euler=(lean_spine, 0, 0))
        key(rig, "chest", frame, euler=(lean_chest, chest_yaw(p), 0))
        # The head stabilises: pitch counters the lean so the gaze stays on
        # the horizon, yaw counters a third of the chest so the face does not
        # swing with the shoulders. Frozen heads read robotic; fully keyed
        # heads read drunk; a damped counter reads alive.
        key(rig, "head", frame, euler=(head_pitch, -chest_yaw(p) * 0.35, 0))

        for side, off in (("l", 0.0), ("r", 0.5)):
            key(rig, f"upleg.{side}", frame, euler=(thigh(p + off), 0, 0))
            key(rig, f"leg.{side}", frame, euler=(knee(p + off), 0, 0))
            key(rig, f"foot.{side}", frame, euler=(foot(p + off), 0, 0))

        # Arms are contralateral: the LEFT arm swings forward with the RIGHT
        # leg, so its forward peak sits near the right leg's contact (0.5),
        # led slightly (ARM_LEAD). Negative X is forward on this rig.
        for side, lead, out_sign in (("l", ARM_LEAD, -1.0), ("r", ARM_LEAD - 0.5, 1.0)):
            swing = math.cos(2 * math.pi * (p - lead))
            # The swing plane is not flat: the hand drifts toward the body's
            # midline as the arm comes forward (adduction), which is what
            # keeps a three-quarter view from flattening the bent arm into a
            # straight zombie reach — the round-1 blind pass's one new find.
            out = arm_out - (arm_out + 4.0) * max(0.0, swing)
            key(rig, f"arm.{side}", frame,
                euler=(arm_bias - arm_amp * swing, 0, out_sign * out))
            # Deepen the elbow as the arm comes forward, open it at the back:
            # base is the mid-swing carry, base + deepen the forward peak,
            # base - deepen the open trail.
            key(rig, f"forearm.{side}", frame,
                euler=(elbow_base + elbow_deepen * swing, 0, 0))
            key(rig, f"hand.{side}", frame, euler=(hand_curl, 0, 0))


def author_jump(rig, frames: int) -> None:
    """Crouch, extend, tuck, reach for the landing — in place.

    The body does not translate: the controller owns the arc, and a clip that
    moved the character would fight it.
    """
    # Re-signed for MQ1A against the verified AXES table: the first version
    # keyed every limb mirrored (legs swung back in the "crouch", arms swung
    # back at full "extension", shins hyperextended forward), and the hips
    # location rode the wrong axis (Z; vertical is Y on this rig).
    crouch, extend, tuck, land = 0, int(frames * 0.28), int(frames * 0.60), frames
    key(rig, "hips", crouch, euler=(6, 0, 0), location=(0, -0.06, 0))
    key(rig, "spine", crouch, euler=(10, 0, 0))
    key(rig, "chest", crouch, euler=(6, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", crouch, euler=(-34, 0, 0))
        key(rig, f"leg.{side}", crouch, euler=(52, 0, 0))
        key(rig, f"foot.{side}", crouch, euler=(-18, 0, 0))
        key(rig, f"arm.{side}", crouch, euler=(26, 0, 0))
        key(rig, f"forearm.{side}", crouch, euler=(-14, 0, 0))

    key(rig, "hips", extend, euler=(-4, 0, 0), location=(0, 0.03, 0))
    key(rig, "spine", extend, euler=(-6, 0, 0))
    key(rig, "chest", extend, euler=(-4, 0, 0))
    key(rig, "head", extend, euler=(-8, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", extend, euler=(10, 0, 0))
        key(rig, f"leg.{side}", extend, euler=(6, 0, 0))
        key(rig, f"foot.{side}", extend, euler=(22, 0, 0))
        key(rig, f"arm.{side}", extend, euler=(-64, 0, 0))
        key(rig, f"forearm.{side}", extend, euler=(-10, 0, 0))

    key(rig, "hips", tuck, euler=(8, 0, 0), location=(0, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", tuck, euler=(-40, 0, 0))
        key(rig, f"leg.{side}", tuck, euler=(64, 0, 0))
        key(rig, f"arm.{side}", tuck, euler=(-20, 0, 0))

    key(rig, "hips", land, euler=(4, 0, 0), location=(0, -0.03, 0))
    key(rig, "spine", land, euler=(7, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", land, euler=(-22, 0, 0))
        key(rig, f"leg.{side}", land, euler=(34, 0, 0))
        key(rig, f"foot.{side}", land, euler=(-12, 0, 0))
        key(rig, f"arm.{side}", land, euler=(14, 0, 0))


def author_throw(rig, frames: int) -> None:
    """Wind up across the body, then throw over the shoulder with the right arm.

    This is the orb throw, so it wants to read as an aimed overarm lob rather
    than a punch: the wind-up turns the chest away from the target and the
    release turns it through, because the rotation is what sells the effort.
    """
    ready, wind, release, recover = 0, int(frames * 0.33), int(frames * 0.62), frames

    # Re-signed for MQ1A (see AXES): the elbow of the throwing arm was keyed
    # +62 backward at the cocked pose — a hyperextended joint at the one
    # moment the camera is looking straight at it — and the follow-through
    # whipped the upper arm down BEHIND the body instead of across it.
    key(rig, "chest", ready, euler=(0, 0, 0))
    key(rig, "arm.r", ready, euler=(0, 0, -4))
    key(rig, "forearm.r", ready, euler=(-6, 0, 0))

    key(rig, "hips", wind, euler=(0, 0, -8))
    key(rig, "spine", wind, euler=(-4, 0, -12))
    key(rig, "chest", wind, euler=(-6, 0, -14))
    key(rig, "head", wind, euler=(0, 0, 8))
    key(rig, "arm.r", wind, euler=(-96, 20, -18))
    key(rig, "forearm.r", wind, euler=(-62, 0, 0))
    key(rig, "hand.r", wind, euler=(14, 0, 0))
    key(rig, "arm.l", wind, euler=(-20, 0, 10))
    key(rig, "forearm.l", wind, euler=(-20, 0, 0))

    key(rig, "hips", release, euler=(0, 0, 10))
    key(rig, "spine", release, euler=(8, 0, 16))
    key(rig, "chest", release, euler=(10, 0, 18))
    key(rig, "head", release, euler=(4, 0, -6))
    key(rig, "arm.r", release, euler=(-8, -10, -8))
    key(rig, "forearm.r", release, euler=(-4, 0, 0))
    key(rig, "hand.r", release, euler=(-12, 0, 0))
    key(rig, "arm.l", release, euler=(12, 0, 8))

    key(rig, "hips", recover, euler=(0, 0, 2))
    key(rig, "spine", recover, euler=(2, 0, 4))
    key(rig, "chest", recover, euler=(2, 0, 4))
    key(rig, "head", recover, euler=(0, 0, 0))
    key(rig, "arm.r", recover, euler=(6, 0, -6))
    key(rig, "forearm.r", recover, euler=(-8, 0, 0))
    key(rig, "arm.l", recover, euler=(0, 0, 6))


def author_chop(rig, frames: int) -> None:
    """A two-handed overhead axe chop, driven down through the target.

    OP21-24. The owner played the shipped build and reported that he "still
    does not see a convincing chopping swing during normal gathering". He was
    looking at the throw: `trainer_model.gd` had no chop role and reused
    `throw` for the tool swing, so pressing Use Tool played an aimed overarm
    LOB — chest turning away, hand opening at the top of the arc, nothing
    travelling down through the tree. There was no chop clip anywhere in the
    project to play instead; `CLIPS` had five entries and this is the sixth.

    What makes a chop read as a chop, and what each key here is for:

    * **It is two-handed.** The prop hangs off the right hand (`tool_hold.gd`
      bone-attaches to `RightHand`), so the left arm cannot literally grip the
      haft without IK this pipeline does not have — but a left arm swinging
      the same arc within a few degrees of the right reads as hands together
      at normal play distance, and a left arm hanging idle at the hip reads
      immediately as a one-armed flail. The left is keyed to shadow the right
      throughout, slightly wider (`Z`) so the arms do not interpenetrate.
    * **The body supplies the force, not the shoulder.** Spine EXTENDS back at
      the raise and FLEXES hard through impact (`+X` is forward flexion — see
      AXES). A chop with a still torso reads as swatting.
    * **The carry is LOW so the lift is visible.** Measured, not judged: the
      first version held the ready pose with the elbow folded to -52 and the
      shoulder at -38, which stands the axe straight up out of the fist and
      puts its head at 2.23 m -- HIGHER than the 2.07 m it reached at the top
      of the wind-up. The swing therefore had no visible upstroke at all; it
      started at its own peak and fell. The carry now sits at the hip
      (shoulder -14, elbow -34) so the raise is a real lift, and `recover`
      returns to that same low carry rather than to the old high one.
    * **It decelerates into the target rather than through the floor.** The
      follow-through is small and the recovery brings the axe back to a ready
      carry, because the swing is repeatable: the player holds the tree down
      and swings again, and a clip that ends splayed cannot loop back into its
      own start.
    * **Knees brace at impact.** A few degrees only; it stops the character
      reading as bolted to the ground at the one frame carrying all the force.

    RE-KEYED AFTER THE FIRST RENDER, and the corrections are worth keeping
    because both were invisible in the numbers. (1) The raise reached only
    HEAD height, not overhead: the elbows were folded so hard (-74) that the
    flexion ate most of the shoulder's travel, so the fold came down to -40
    and the shoulder went up to -146. (2) The chop finished pointing at the
    trainer's own boots — a log-splitter's stroke, aimed where a splitting
    block would be — while the thing being chopped is a STANDING trunk at
    chest height. The impact now stops the arc out in front at trunk height
    (shoulder -62, elbow nearly straight) with half the torso fold, because
    a body bent double at the waist reads as looking at the ground rather
    than driving through wood.

    The hit lands at `impact` and `art.json`'s `chop_impact_fraction` tells
    the game which frame that is, so `tool_hold.gd` resolves the gather when
    the axe is IN the wood rather than at an arbitrary midpoint.
    """
    ready, raise_, impact, follow, recover = 0, int(frames * 0.33), int(frames * 0.60), int(frames * 0.75), frames

    # Ready: axe carried at chest, elbows softly bent. Not the rest pose — a
    # tool that snaps from arms-down to overhead in two frames reads as a pop.
    key(rig, "spine", ready, euler=(2, 0, 0))
    key(rig, "chest", ready, euler=(2, 0, 0))
    key(rig, "head", ready, euler=(4, 0, 0))
    key(rig, "arm.r", ready, euler=(-14, 0, -10))
    key(rig, "forearm.r", ready, euler=(-34, 0, 0))
    key(rig, "arm.l", ready, euler=(-11, 0, 12))
    key(rig, "forearm.l", ready, euler=(-38, 0, 0))

    # Raise: both arms overhead and behind, torso extended back, head still on
    # the target. Elbows stay folded — a straight-armed windmill is a golf
    # swing, not a chop.
    key(rig, "hips", raise_, euler=(0, 0, 2))
    key(rig, "spine", raise_, euler=(-16, 0, 0))
    key(rig, "chest", raise_, euler=(-13, 0, 0))
    key(rig, "head", raise_, euler=(8, 0, 0))
    key(rig, "arm.r", raise_, euler=(-146, 6, -8))
    key(rig, "forearm.r", raise_, euler=(-40, 0, 0))
    key(rig, "hand.r", raise_, euler=(-8, 0, 0))
    key(rig, "arm.l", raise_, euler=(-140, -6, 12))
    key(rig, "forearm.l", raise_, euler=(-44, 0, 0))

    # Impact: the frame the wood takes the edge. Arms nearly straight and
    # forward-down, torso folded through, knees braced.
    key(rig, "hips", impact, euler=(0, 0, -2))
    key(rig, "spine", impact, euler=(9, 0, 0))
    key(rig, "chest", impact, euler=(7, 0, 0))
    key(rig, "head", impact, euler=(4, 0, 0))
    key(rig, "arm.r", impact, euler=(-62, 0, -6))
    key(rig, "forearm.r", impact, euler=(-10, 0, 0))
    key(rig, "hand.r", impact, euler=(6, 0, 0))
    key(rig, "arm.l", impact, euler=(-58, 0, 9))
    key(rig, "forearm.l", impact, euler=(-14, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", impact, euler=(-7, 0, 0))
        key(rig, f"leg.{side}", impact, euler=(13, 0, 0))
        key(rig, f"foot.{side}", impact, euler=(-6, 0, 0))

    # Follow-through: short. The axe settles just past the cut, not past the
    # knees.
    key(rig, "spine", follow, euler=(13, 0, 0))
    key(rig, "chest", follow, euler=(10, 0, 0))
    key(rig, "head", follow, euler=(4, 0, 0))
    key(rig, "arm.r", follow, euler=(-34, 0, -8))
    key(rig, "forearm.r", follow, euler=(-34, 0, 0))
    key(rig, "arm.l", follow, euler=(-30, 0, 10))
    key(rig, "forearm.l", follow, euler=(-38, 0, 0))

    # Recover: back to the ready carry, so a held chop chains into itself.
    key(rig, "hips", recover, euler=(0, 0, 0))
    key(rig, "spine", recover, euler=(3, 0, 0))
    key(rig, "chest", recover, euler=(3, 0, 0))
    key(rig, "head", recover, euler=(4, 0, 0))
    key(rig, "arm.r", recover, euler=(-14, 0, -10))
    key(rig, "forearm.r", recover, euler=(-34, 0, 0))
    key(rig, "hand.r", recover, euler=(0, 0, 0))
    key(rig, "arm.l", recover, euler=(-11, 0, 12))
    key(rig, "forearm.l", recover, euler=(-38, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", recover, euler=(0, 0, 0))
        key(rig, f"leg.{side}", recover, euler=(0, 0, 0))
        key(rig, f"foot.{side}", recover, euler=(0, 0, 0))


def author(rig, name: str, frames: int) -> None:
    clear_pose(rig)
    action = bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action = action

    if name == "idle":
        author_idle(rig, frames)
    elif name == "walk":
        # The controller's "walk" is 5.0 m/s — a jog, and authored as one.
        author_gait(rig, frames, JOG_LEG, JOG_BODY, JOG_STYLE)
    elif name == "sprint":
        author_gait(rig, frames, SPRINT_LEG, SPRINT_BODY, SPRINT_STYLE)
    elif name == "jump":
        author_jump(rig, frames)
    elif name == "throw":
        author_throw(rig, frames)
    elif name == "chop":
        author_chop(rig, frames)

    action.use_fake_user = True
    # Stashed as an NLA strip so the glTF exporter writes every action as its
    # own named animation instead of only the active one.
    track = rig.animation_data.nla_tracks.new()
    track.name = name
    track.strips.new(name, 1, action)
    rig.animation_data.action = None


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... animate_humanoid.py -- <rigged.glb> --out <animated.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("animated.glb"))).resolve()

    rig = load(model)
    bpy.context.scene.render.fps = FPS

    # Drop any animation already on the rig. The normal input is a bare Meshy
    # rig with no clips, so this is a no-op there -- but `assets_raw/` is
    # gitignored and nothing keeps the pre-animation Meshy output past one
    # pipeline run, so re-running this script on an already-shipped
    # *_lod0.glb (R3.0's "re-process through the fixed pipeline", the only
    # source actually available for trainer/grandpa/warden) would otherwise
    # export the old idle/walk/sprint/jump/throw NLA tracks alongside the
    # freshly authored ones under the same names.
    if rig.animation_data:
        for track in list(rig.animation_data.nla_tracks):
            rig.animation_data.nla_tracks.remove(track)
        rig.animation_data.action = None
    for action in list(bpy.data.actions):
        action.use_fake_user = False
    bpy.data.orphans_purge(do_local_ids=True)

    # A stray unskinned object rides along in Meshy output and would be
    # exported as part of the character. Same Icosphere as skin_transfer drops.
    for obj in list(bpy.data.objects):
        if obj.type == "MESH" and not obj.vertex_groups:
            print(f"  dropping stray unskinned object: {obj.name}")
            bpy.data.objects.remove(obj, do_unlink=True)

    # Normalise units BEFORE authoring any clip. Meshy's auto-rig arrives as a
    # centimetre skeleton under a 0.01-scaled Armature, with the mesh's inverse
    # binds carrying the x100 back out — a pair that cancels in a renderer and
    # poisons everything that measures the model, which is how the game shipped
    # a 180-metre trainer twice. The creature path already applies scale at rig
    # time (rig_quadruped.py, skin_transfer.py); this is the same normalisation
    # for the humanoid path, so the exported GLB is metres all the way down:
    # Armature 1.0, bones in metres, inverse binds 1.0. Done before author()
    # so the clips are written against the normalised rest pose.
    bpy.ops.object.select_all(action="DESELECT")
    for obj in bpy.data.objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)

    for name, frames in CLIPS.items():
        author(rig, name, frames)
        print(f"  {name}: {frames} frames")

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(out), export_format="GLB",
        export_animations=True, export_animation_mode="NLA_TRACKS",
        export_skins=True, export_yup=True)
    print(f"\n{len(CLIPS)} clips -> {out}")


if __name__ == "__main__":
    main()
