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

WHAT THESE CLIPS ARE, HONESTLY. Procedural cycles, the same standard as the
creatures': counter-phased limb swings on sine curves, with a torso bob and a
head counterweight. Walk reads as walk and throw reads as throw. They are not
hand-animated character work, and the production report says so.

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
## thing the owner read as "unnatural". 15 frames at +-32 deg peaks at
## ~5.1 m/s; 12 frames at +-45 deg peaks at ~8.9 m/s against sprint's 8.6.
CLIPS = {
    "idle": 96,
    "walk": 15,
    "sprint": 12,
    "jump": 28,
    "throw": 24,
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
        for side, sign in (("l", 1.0), ("r", -1.0)):
            key(rig, f"arm.{side}", frame, euler=(1.4 * breath, 0, sign * 2.0))
            key(rig, f"forearm.{side}", frame, euler=(2.0 + 1.2 * breath, 0, 0))


def author_gait(rig, frames: int, swing: float, knee: float, arm: float,
                elbow: float, lean: float, bob: float, sway: float,
                plantar: float) -> None:
    """A jog or a run — never a stroll, because the controller never strolls.

    Rewritten for OF5 ("running and walking look unnatural"). What the first
    version got wrong, visible in a Muybridge strip over striped ground:

    - The recovery leg swung through dead straight; the knee only bent while
      the leg was planted BEHIND the body. Real gait folds the knee while the
      leg swings forward (ground clearance) and lands it near-straight. Here
      the fold is gated on the leg's forward VELOCITY (cos), not its position.
    - Both legs passed through a bolt-upright feet-together rest pose twice a
      cycle. The knee fold above removes it: the passing pose now has a bent
      recovery leg, which is the pose that makes a gait read as a gait.
    - Arms hung straight and nearly still — the "zombie" read. Elbows now
      carry a real standing bend that deepens as the arm swings forward, and
      the shoulder amplitude is worth seeing.
    - Torso was vertical at 5-8.6 m/s. A forward lean scaled to the gait, with
      the head holding level, reads as effort.
    - Feet were plantar-flat throughout. Heel-strike dorsiflexion at front
      contact and a toe-off push at the back give the stride its ends.

    Everything keys on sines of one phase so the cycle still loops seamlessly.
    """
    # 15/12-frame cycles need denser keys than idle's 96: STEP=4 would sample
    # a sine three times per cycle and export a triangle wave.
    for frame in range(0, frames + 1):
        phase = 2 * math.pi * frame / frames
        left = math.sin(phase)
        right = math.sin(phase + math.pi)

        # Twice-per-cycle vertical bob, dipping just after each foot loads.
        # Hips location Y is along the bone (toward the spine) — vertical on
        # this rig — and the units are metres after the normalisation below.
        dip = (0.5 * math.cos(2.0 * phase - 0.6) - 0.5) * bob
        key(rig, "hips", frame,
            euler=(lean * 0.5, 0, sway * left), location=(0, dip, 0))
        key(rig, "spine", frame, euler=(lean * 0.35, 0, -3.0 * left))
        key(rig, "chest", frame, euler=(lean * 0.3, 0, 2.0 * left))
        # Head counter-pitches so the character watches where it is going
        # rather than the ground its torso is leaning toward.
        key(rig, "head", frame, euler=(-lean * 0.75, 0, 0))

        for side, value, vel in (("l", left, math.cos(phase)),
                                 ("r", right, -math.cos(phase))):
            # fold: 1 while the leg swings forward (recovery), 0 in stance.
            fold = max(0.0, vel)
            key(rig, f"upleg.{side}", frame, euler=(swing * value, 0, 0))
            key(rig, f"leg.{side}", frame,
                euler=(-(knee * fold ** 1.5 + 6.0), 0, 0))
            # Heel strike (toes up) at front contact, toe-off push (toes
            # down) at the back, mild dorsiflexion for clearance mid-swing.
            foot = (12.0 * max(0.0, value) ** 2 + 8.0 * fold
                    - plantar * max(0.0, -value) ** 2)
            key(rig, f"foot.{side}", frame, euler=(foot, 0, 0))

        for side, value, sign in (("l", right, 1.0), ("r", left, -1.0)):
            # Carried slightly forward of the hang (-12): a runner's arms work
            # in front of the body's line, and the bias also keeps the swing
            # visible instead of buried against the backpack.
            key(rig, f"arm.{side}", frame, euler=(arm * value - 12.0, 0, sign * 5.0))
            key(rig, f"forearm.{side}", frame,
                euler=(elbow + 18.0 * max(0.0, value), 0, 0))


def author_jump(rig, frames: int) -> None:
    """Crouch, extend, tuck, reach for the landing — in place.

    The body does not translate: the controller owns the arc, and a clip that
    moved the character would fight it.
    """
    crouch, extend, tuck, land = 0, int(frames * 0.28), int(frames * 0.60), frames
    key(rig, "hips", crouch, euler=(6, 0, 0), location=(0, 0, -0.06))
    key(rig, "spine", crouch, euler=(10, 0, 0))
    key(rig, "chest", crouch, euler=(6, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", crouch, euler=(34, 0, 0))
        key(rig, f"leg.{side}", crouch, euler=(-52, 0, 0))
        key(rig, f"foot.{side}", crouch, euler=(18, 0, 0))
        key(rig, f"arm.{side}", crouch, euler=(-28, 0, 0))
        key(rig, f"forearm.{side}", crouch, euler=(22, 0, 0))

    key(rig, "hips", extend, euler=(-4, 0, 0), location=(0, 0, 0.03))
    key(rig, "spine", extend, euler=(-6, 0, 0))
    key(rig, "chest", extend, euler=(-4, 0, 0))
    key(rig, "head", extend, euler=(-8, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", extend, euler=(-12, 0, 0))
        key(rig, f"leg.{side}", extend, euler=(-6, 0, 0))
        key(rig, f"foot.{side}", extend, euler=(-22, 0, 0))
        key(rig, f"arm.{side}", extend, euler=(64, 0, 0))
        key(rig, f"forearm.{side}", extend, euler=(10, 0, 0))

    key(rig, "hips", tuck, euler=(8, 0, 0), location=(0, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", tuck, euler=(40, 0, 0))
        key(rig, f"leg.{side}", tuck, euler=(-64, 0, 0))
        key(rig, f"arm.{side}", tuck, euler=(24, 0, 0))

    key(rig, "hips", land, euler=(4, 0, 0), location=(0, 0, -0.03))
    key(rig, "spine", land, euler=(7, 0, 0))
    for side in ("l", "r"):
        key(rig, f"upleg.{side}", land, euler=(22, 0, 0))
        key(rig, f"leg.{side}", land, euler=(-34, 0, 0))
        key(rig, f"foot.{side}", land, euler=(12, 0, 0))
        key(rig, f"arm.{side}", land, euler=(-14, 0, 0))


def author_throw(rig, frames: int) -> None:
    """Wind up across the body, then throw over the shoulder with the right arm.

    This is the orb throw, so it wants to read as an aimed overarm lob rather
    than a punch: the wind-up turns the chest away from the target and the
    release turns it through, because the rotation is what sells the effort.
    """
    ready, wind, release, recover = 0, int(frames * 0.33), int(frames * 0.62), frames

    key(rig, "chest", ready, euler=(0, 0, 0))
    key(rig, "arm.r", ready, euler=(0, 0, -4))
    key(rig, "forearm.r", ready, euler=(6, 0, 0))

    key(rig, "hips", wind, euler=(0, 0, -8))
    key(rig, "spine", wind, euler=(-4, 0, -12))
    key(rig, "chest", wind, euler=(-6, 0, -14))
    key(rig, "head", wind, euler=(0, 0, 8))
    key(rig, "arm.r", wind, euler=(-96, 20, -18))
    key(rig, "forearm.r", wind, euler=(62, 0, 0))
    key(rig, "hand.r", wind, euler=(-18, 0, 0))
    key(rig, "arm.l", wind, euler=(28, 0, 10))
    key(rig, "forearm.l", wind, euler=(20, 0, 0))

    key(rig, "hips", release, euler=(0, 0, 10))
    key(rig, "spine", release, euler=(8, 0, 16))
    key(rig, "chest", release, euler=(10, 0, 18))
    key(rig, "head", release, euler=(4, 0, -6))
    key(rig, "arm.r", release, euler=(58, -10, -8))
    key(rig, "forearm.r", release, euler=(4, 0, 0))
    key(rig, "hand.r", release, euler=(16, 0, 0))
    key(rig, "arm.l", release, euler=(-16, 0, 8))

    key(rig, "hips", recover, euler=(0, 0, 2))
    key(rig, "spine", recover, euler=(2, 0, 4))
    key(rig, "chest", recover, euler=(2, 0, 4))
    key(rig, "head", recover, euler=(0, 0, 0))
    key(rig, "arm.r", recover, euler=(12, 0, -6))
    key(rig, "forearm.r", recover, euler=(8, 0, 0))
    key(rig, "arm.l", recover, euler=(0, 0, 6))


def author(rig, name: str, frames: int) -> None:
    clear_pose(rig)
    action = bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action = action

    if name == "idle":
        author_idle(rig, frames)
    elif name == "walk":
        # The controller's "walk" is 5.0 m/s — a jog, and authored as one.
        author_gait(rig, frames, swing=32.0, knee=55.0, arm=34.0, elbow=50.0,
                    lean=6.0, bob=0.035, sway=2.0, plantar=25.0)
    elif name == "sprint":
        author_gait(rig, frames, swing=45.0, knee=95.0, arm=48.0, elbow=85.0,
                    lean=14.0, bob=0.06, sway=0.0, plantar=40.0)
    elif name == "jump":
        author_jump(rig, frames)
    elif name == "throw":
        author_throw(rig, frames)

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
