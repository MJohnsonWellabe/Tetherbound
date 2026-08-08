"""Author the six gameplay clips onto a rig_quadruped skeleton, procedurally.

    blender --background --python tools/art_pipeline/blender/animate_quadruped.py \
            -- <rigged.glb> --out <animated.glb>

The game asks for six roles (scripts/pals/pal_animator.gd, mapped from
data/pals/species.json): idle, walk, run, attack, hit, faint. Meshy's
animation library only drives Meshy's own rigs, which are humanoid-only, so a
quadruped's clips have to come from somewhere else. This authors them in
Blender as keyframed cycles on the skeleton rig_quadruped.py builds.

WHAT THESE CLIPS ARE, HONESTLY. Procedural gait cycles: diagonal leg pairs on
sine phases, spine bob, head counterweight. They are legible — walk reads as
walk, faint reads as faint — and they are not hand-animated character work.
The pipeline doc's §14 rule is that an animation must fit the creature's
anatomy and personality; these fit the anatomy and are neutral on
personality. Good enough to prove the pipeline and to play; the production
report records them as the next thing to upgrade.

The attack is species-informed: Terrapup is a digger, so the quick attack is
a rear-up and double-forepaw slam rather than a generic bite lunge.

All clips animate bones only — the object's origin never moves, because the
game drives the body's position and expects animation in place.
"""

import math
import pathlib
import sys

import bpy

FPS = 24

## name -> (frames, loops). One-shot clips hold their last pose when the
## game's animator freezes them (faint) or blends out (attack, hit).
CLIPS = {
    "idle": (72, True),
    "walk": (32, True),
    "run": (18, True),
    "attack": (22, False),
    "hit": (12, False),
    "faint": (36, False),
}

## Two skeleton layouts, detected from the rig itself: rig_quadruped.py's
## four-legger, and rig_glider.py's two legs + wings. One authoring script
## for both, because the clip ROLES are the game's and identical either way;
## only which bones swing differs.
QUAD_LEGS = ["front_upper_l", "front_upper_r", "rear_upper_l", "rear_upper_r"]
QUAD_LOWER = {"front_upper_l": "front_lower_l", "front_upper_r": "front_lower_r",
              "rear_upper_l": "rear_lower_l", "rear_upper_r": "rear_lower_r"}
## Diagonal pairs move together in a trot: FL+RR, then FR+RL.
QUAD_PHASE = {"front_upper_l": 0.0, "rear_upper_r": 0.0,
              "front_upper_r": math.pi, "rear_upper_l": math.pi}

BIPED_LEGS = ["leg_upper_l", "leg_upper_r"]
BIPED_LOWER = {"leg_upper_l": "leg_lower_l", "leg_upper_r": "leg_lower_r"}
BIPED_PHASE = {"leg_upper_l": 0.0, "leg_upper_r": math.pi}
WINGS = ["wing_upper_l", "wing_upper_r"]
WING_TIPS = {"wing_upper_l": "wing_tip_l", "wing_upper_r": "wing_tip_r"}
ARMS = ["arm_l", "arm_r"]

# Set by detect() once the rig is loaded.
LEGS, LOWER, PHASE = QUAD_LEGS, QUAD_LOWER, QUAD_PHASE
IS_GLIDER = False
IS_SITTER = False


def detect(rig: bpy.types.Object) -> None:
    global LEGS, LOWER, PHASE, IS_GLIDER, IS_SITTER
    names = {b.name for b in rig.data.bones}
    if "wing_upper_l" in names:
        LEGS, LOWER, PHASE = BIPED_LEGS, BIPED_LOWER, BIPED_PHASE
        IS_GLIDER, IS_SITTER = True, False
        print("  glider skeleton detected: 2 legs + wings")
    elif "arm_l" in names:
        LEGS, LOWER, PHASE = BIPED_LEGS, BIPED_LOWER, BIPED_PHASE
        IS_GLIDER, IS_SITTER = False, True
        print("  sitter skeleton detected: 2 legs + held forepaws")


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not rigs:
        raise SystemExit("no armature — run rig_quadruped.py first")
    return rigs[0]


def key(rig: bpy.types.Object, bone_name: str, frame: int,
        euler: tuple[float, float, float] = None,
        location: tuple[float, float, float] = None) -> None:
    bone = rig.pose.bones.get(bone_name)
    if bone is None:
        return
    bone.rotation_mode = "XYZ"
    if euler is not None:
        bone.rotation_euler = [math.radians(a) for a in euler]
        bone.keyframe_insert("rotation_euler", frame=frame)
    if location is not None:
        bone.location = location
        bone.keyframe_insert("location", frame=frame)


def clear_pose(rig: bpy.types.Object) -> None:
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)
        bone.location = (0, 0, 0)


def author_idle(rig, frames: int) -> None:
    """Breathing, an ear-level head sway, a lazy tail. Amplitudes tiny: idle
    is what the player stares at in camp, and big motion reads as agitation."""
    for frame in range(0, frames + 1, 6):
        t = frame / frames * 2 * math.pi
        key(rig, "spine", frame, euler=(1.2 * math.sin(t), 0, 0))
        key(rig, "head", frame, euler=(2.0 * math.sin(t + 0.7), 0, 3.0 * math.sin(t * 0.5)))
        key(rig, "tail_1", frame, euler=(0, 0, 6.0 * math.sin(t * 0.5 + 1.0)))
        key(rig, "tail_2", frame, euler=(0, 0, 5.0 * math.sin(t * 0.5 + 1.6)))
        for wing in WINGS:
            # Folded at rest, with a slow settle on top. The generated rest
            # pose has the wings splayed in a T, and an idle that keeps them
            # there reads as a creature mid-crash; the gate critique called it
            # out. Fold = droop and sweep back toward the body.
            sign = 1.0 if wing.endswith("l") else -1.0
            key(rig, wing, frame,
                euler=(0, sign * -38.0, sign * (18.0 + 2.5 * math.sin(t + (0 if sign > 0 else math.pi)))))
            key(rig, WING_TIPS[wing], frame, euler=(0, sign * -30.0, 0))
        for arm in ARMS:
            # Held paws kneading gently — the concept's "forepaws held in
            # front" is a pose, and an idle that abandons it breaks character.
            key(rig, arm, frame, euler=(4.0 * math.sin(t + (0 if arm.endswith("l") else 1.2)), 0, 0))


def author_gait(rig, frames: int, swing: float, bob: float, lean: float) -> None:
    step = max(2, frames // 8)
    for frame in range(0, frames + 1, step):
        t = frame / frames * 2 * math.pi
        for leg in LEGS:
            phase = PHASE[leg]
            key(rig, leg, frame, euler=(swing * math.sin(t + phase), 0, 0))
            # Lower leg lags a quarter cycle and folds only on the forward swing,
            # which is what stops the gait reading as stiff peg legs.
            fold = max(0.0, math.sin(t + phase - math.pi / 2)) * swing * 0.7
            key(rig, LOWER[leg], frame, euler=(fold, 0, 0))
        key(rig, "pelvis", frame, euler=(lean + bob * 0.4 * math.sin(2 * t), 0, 0))
        key(rig, "spine", frame, euler=(bob * math.sin(2 * t + 0.5), 0, 0))
        key(rig, "head", frame, euler=(-bob * 0.8 * math.sin(2 * t + 0.5) - lean * 0.5, 0, 0))
        key(rig, "tail_1", frame, euler=(0, 0, 8.0 * math.sin(t)))
        if IS_GLIDER:
            # Walk: wings stay mostly folded with a soft pump. Run: they open
            # and flap for real — the glider's run should read as half-flight.
            fold = -30.0 if swing < 30.0 else -8.0
            flap = swing * 0.5
            for wing in WINGS:
                sign = 1.0 if wing.endswith("l") else -1.0
                key(rig, wing, frame,
                    euler=(0, sign * (fold + flap * math.sin(2 * t)), sign * 12.0))
                key(rig, WING_TIPS[wing], frame,
                    euler=(0, sign * (fold * 0.6 + flap * 0.6 * math.sin(2 * t - 0.8)), 0))


def author_attack(rig, frames: int) -> None:
    """The quick attack, with the anticipation half §16 requires.

    Quadruped: rear up, slam both forepaws down (the digger's move).
    Glider: draw the wings back, then a forward buffet with the head driving —
    the wings are the glider's paws.
    Sitter: a body-driven double paw swipe — wind the spine back, then whip
    forward with both arms sweeping down, tail counterswinging.
    """
    if IS_SITTER:
        key(rig, "spine", 0, euler=(0, 0, 0))
        key(rig, "spine", 9, euler=(-16, 0, 0))
        key(rig, "head", 9, euler=(-10, 0, 0))
        key(rig, "tail_1", 9, euler=(-14, 0, 0))
        for arm in ARMS:
            key(rig, arm, 0, euler=(0, 0, 0))
            key(rig, arm, 9, euler=(-55, 0, 0))
        key(rig, "spine", 14, euler=(16, 0, 0))
        key(rig, "head", 14, euler=(12, 0, 0))
        key(rig, "tail_1", 14, euler=(12, 0, 0))
        for arm in ARMS:
            key(rig, arm, 14, euler=(50, 0, 0))
        key(rig, "spine", frames, euler=(0, 0, 0))
        key(rig, "head", frames, euler=(0, 0, 0))
        key(rig, "tail_1", frames, euler=(0, 0, 0))
        for arm in ARMS:
            key(rig, arm, frames, euler=(0, 0, 0))
        return
    if IS_GLIDER:
        key(rig, "spine", 0, euler=(0, 0, 0))
        for wing in WINGS:
            sign = 1.0 if wing.endswith("l") else -1.0
            key(rig, wing, 0, euler=(0, 0, 0))
            key(rig, wing, 10, euler=(0, sign * -50, 0))       # drawn back
            key(rig, WING_TIPS[wing], 10, euler=(0, sign * -25, 0))
            key(rig, wing, 15, euler=(0, sign * 35, 0))        # buffet
            key(rig, WING_TIPS[wing], 15, euler=(0, sign * 30, 0))
            key(rig, wing, frames, euler=(0, 0, 0))
            key(rig, WING_TIPS[wing], frames, euler=(0, 0, 0))
        key(rig, "spine", 10, euler=(-12, 0, 0))
        key(rig, "head", 10, euler=(-10, 0, 0))
        key(rig, "spine", 15, euler=(14, 0, 0))
        key(rig, "head", 15, euler=(16, 0, 0))
        key(rig, "spine", frames, euler=(0, 0, 0))
        key(rig, "head", frames, euler=(0, 0, 0))
        return
    # Anticipation: sit back, head up, paws leave the ground.
    key(rig, "pelvis", 0, euler=(0, 0, 0))
    for name in ("front_upper_l", "front_upper_r"):
        key(rig, name, 0, euler=(0, 0, 0))
    key(rig, "pelvis", 10, euler=(-22, 0, 0))
    key(rig, "spine", 10, euler=(-14, 0, 0))
    key(rig, "head", 10, euler=(-12, 0, 0))
    for name in ("front_upper_l", "front_upper_r"):
        key(rig, name, 10, euler=(-55, 0, 0))
        key(rig, LOWER[name], 10, euler=(30, 0, 0))
    # Strike: everything comes down in a third of the time it took to wind up.
    key(rig, "pelvis", 15, euler=(8, 0, 0))
    key(rig, "spine", 15, euler=(10, 0, 0))
    key(rig, "head", 15, euler=(14, 0, 0))
    for name in ("front_upper_l", "front_upper_r"):
        key(rig, name, 15, euler=(25, 0, 0))
        key(rig, LOWER[name], 15, euler=(-10, 0, 0))
    # Recover.
    key(rig, "pelvis", frames, euler=(0, 0, 0))
    key(rig, "spine", frames, euler=(0, 0, 0))
    key(rig, "head", frames, euler=(0, 0, 0))
    for name in ("front_upper_l", "front_upper_r"):
        key(rig, name, frames, euler=(0, 0, 0))
        key(rig, LOWER[name], frames, euler=(0, 0, 0))


def author_hit(rig, frames: int) -> None:
    key(rig, "spine", 0, euler=(0, 0, 0))
    key(rig, "spine", 3, euler=(-10, 0, 4))
    key(rig, "head", 3, euler=(-16, 0, 6))
    key(rig, "pelvis", 3, euler=(-6, 0, 0))
    key(rig, "spine", frames, euler=(0, 0, 0))
    key(rig, "head", frames, euler=(0, 0, 0))
    key(rig, "pelvis", frames, euler=(0, 0, 0))


def author_faint(rig, frames: int) -> None:
    """Sink, then keel over sideways. The roll is on the pelvis/root chain so
    the whole body goes with it; legs fold rather than stay planted."""
    key(rig, "root", 0, euler=(0, 0, 0), location=(0, 0, 0))
    key(rig, "root", 12, euler=(0, -18, 0), location=(0, -0.06, 0))
    key(rig, "root", frames, euler=(0, -78, 0), location=(0, -0.16, 0))
    key(rig, "head", 8, euler=(-10, 0, 0))
    key(rig, "head", frames, euler=(18, 0, -8))
    for leg in LEGS:
        key(rig, leg, 0, euler=(0, 0, 0))
        key(rig, leg, frames, euler=(30, 0, 0))
        key(rig, LOWER[leg], frames, euler=(-40, 0, 0))
    key(rig, "tail_1", frames, euler=(10, 0, 0))


def author(rig: bpy.types.Object, name: str, frames: int, looping: bool) -> None:
    clear_pose(rig)
    detect(rig)
    action = bpy.data.actions.new(name)
    rig.animation_data_create()
    rig.animation_data.action = action

    if name == "idle":
        author_idle(rig, frames)
    elif name == "walk":
        author_gait(rig, frames, swing=22.0, bob=1.6, lean=0.0)
    elif name == "run":
        author_gait(rig, frames, swing=38.0, bob=3.4, lean=6.0)
    elif name == "attack":
        author_attack(rig, frames)
    elif name == "hit":
        author_hit(rig, frames)
    elif name == "faint":
        author_faint(rig, frames)

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
        raise SystemExit("usage: ... animate_quadruped.py -- <rigged.glb> --out <animated.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("animated.glb"))).resolve()

    rig = load(model)
    bpy.context.scene.render.fps = FPS

    for name, (frames, looping) in CLIPS.items():
        author(rig, name, frames, looping)
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
