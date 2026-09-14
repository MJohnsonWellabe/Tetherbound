"""Append a dedicated side-lying rest clip to an animated quadruped GLB.

    blender --background --python tools/art_pipeline/blender/author_quadruped_rest.py \
            -- <animated.glb> --out <animated_with_rest.glb>

The standard procedural library's ``faint`` clip ends in a compact crouch on
the Terrapup rig.  A bed occupant needs a different authored silhouette: the
root rolls around the rig's true flank axis, the legs fold instead of showing
four soles, and the head settles toward the forepaws.  Existing imported clips
are preserved; this script adds only the one-shot ``rest`` action.
"""

import math
import pathlib
import sys

import bpy


FRAMES = 36
FINAL_ROTATIONS = {
    "root": (0.0, 0.0, 90.0),
    "spine": (8.0, 0.0, 0.0),
    "neck": (18.0, 0.0, 0.0),
    "head": (12.0, 0.0, 0.0),
    "front_upper_l": (-48.0, 0.0, -20.0),
    "front_upper_r": (-42.0, 0.0, 24.0),
    "front_lower_l": (76.0, 0.0, 0.0),
    "front_lower_r": (70.0, 0.0, 0.0),
    "rear_upper_l": (-44.0, 0.0, -18.0),
    "rear_upper_r": (-38.0, 0.0, 20.0),
    "rear_lower_l": (72.0, 0.0, 0.0),
    "rear_lower_r": (66.0, 0.0, 0.0),
    "tail_1": (8.0, 0.0, -10.0),
    "tail_2": (6.0, 0.0, -8.0),
}


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def key_rotation(bone, frame: int, degrees: tuple[float, float, float]) -> None:
    bone.rotation_mode = "XYZ"
    bone.rotation_euler = tuple(math.radians(value) for value in degrees)
    bone.keyframe_insert("rotation_euler", frame=frame)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... author_quadruped_rest.py -- <animated.glb> --out <output.glb>")
    source = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", source.with_name(f"{source.stem}_rest.glb"))).resolve()

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source))
    rigs = [obj for obj in bpy.data.objects if obj.type == "ARMATURE"]
    if len(rigs) != 1:
        raise SystemExit(f"expected one armature, found {len(rigs)}")
    rig = rigs[0]
    missing = sorted(set(FINAL_ROTATIONS) - {bone.name for bone in rig.data.bones})
    if missing:
        raise SystemExit(f"rest clip requires missing bones: {missing}")

    existing_actions = sorted(action.name for action in bpy.data.actions)
    rest_actions = [action for action in bpy.data.actions
                    if action.name == "rest" or action.name.startswith("rest_")]
    if rest_actions and "--replace" not in args:
        raise SystemExit(f"source already contains a rest action: {existing_actions}; pass --replace")
    if rest_actions:
        for track in list(rig.animation_data.nla_tracks):
            if track.name == "rest" or any(strip.action in rest_actions for strip in track.strips):
                rig.animation_data.nla_tracks.remove(track)
        for old_action in rest_actions:
            bpy.data.actions.remove(old_action)

    action = bpy.data.actions.new("rest")
    rig.animation_data_create()
    rig.animation_data.action = action
    for bone_name, final in FINAL_ROTATIONS.items():
        bone = rig.pose.bones[bone_name]
        key_rotation(bone, 0, (0.0, 0.0, 0.0))
        key_rotation(bone, 12, tuple(value * 0.35 for value in final))
        key_rotation(bone, FRAMES, final)
    action.use_fake_user = True
    track = rig.animation_data.nla_tracks.new()
    track.name = "rest"
    track.strips.new("rest", 1, action)
    rig.animation_data.action = None

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=str(out), export_format="GLB", export_animations=True,
        export_animation_mode="NLA_TRACKS", export_skins=True, export_yup=True)
    print(f"existing actions preserved: {existing_actions}")
    print(f"rest: {FRAMES} frames -> {out}")


if __name__ == "__main__":
    main()
