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

LEGS = ["front_upper_l", "front_upper_r", "rear_upper_l", "rear_upper_r"]
LOWER = {"front_upper_l": "front_lower_l", "front_upper_r": "front_lower_r",
         "rear_upper_l": "rear_lower_l", "rear_upper_r": "rear_lower_r"}

## Diagonal pairs move together in a trot: FL+RR, then FR+RL.
PHASE = {"front_upper_l": 0.0, "rear_upper_r": 0.0,
         "front_upper_r": math.pi, "rear_upper_l": math.pi}


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


def author_attack(rig, frames: int) -> None:
    """Terrapup's quick attack: rear up, slam both forepaws down. Anticipation
    on the rear-up is what makes the attack readable at combat distance —
    §16's requirement — so it gets half the clip."""
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
