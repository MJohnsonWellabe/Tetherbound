"""Render a rigged/animated GLB at a bent mid-clip frame, to check for tearing.

    blender --background --python tools/art_pipeline/blender/pose_check.py \
            -- <model.glb> --out shots/pose_check/name.png [--action attack] [--frame 10]

`rig_quadruped.py` warns loudly when a mesh comes back with unweighted
vertices ("these will tear in animation") but a vertex count alone does not
say whether the tear is visible or is three stray interior verts nobody will
ever see. This renders the actual bent pose so that question gets answered
by a frame, not a guess — the same "a rendered frame, not a passing parse
test" standard `ralph/conventions.md` asks for everywhere else.

Reuses turntable.py's normalise/lighting/ground/camera helpers by import
rather than duplicating them.
"""

import math
import pathlib
import sys

import bpy

HERE = pathlib.Path(__file__).parent
sys.path.insert(0, str(HERE))
import turntable  # noqa: E402


def find_armature() -> bpy.types.Object:
    for obj in bpy.data.objects:
        if obj.type == "ARMATURE":
            return obj
    raise SystemExit("no armature in this file; nothing to pose")


def main() -> None:
    args = turntable.argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... pose_check.py -- <model> --out <path.png> [--action attack] [--frame 10]")

    model = pathlib.Path(args[0]).resolve()
    if not model.exists():
        raise SystemExit(f"no such model: {model}")
    out_path = pathlib.Path(turntable.option(args, "--out", "shots/pose_check/out.png")).resolve()
    action_name = turntable.option(args, "--action", "attack")
    frame = int(turntable.option(args, "--frame", 10))
    size = int(turntable.option(args, "--size", 800))

    turntable.load(model)
    rig = find_armature()

    # Blender's glTF importer suffixes re-imported action names with the
    # armature's own object name (e.g. "attack" -> "attack_Armature"), so
    # match by prefix rather than exact name.
    action = bpy.data.actions.get(action_name)
    if action is None:
        for candidate in bpy.data.actions:
            if candidate.name.startswith(action_name):
                action = candidate
                break
    if action is None:
        raise SystemExit(f"no action named '{action_name}'; has: {[a.name for a in bpy.data.actions]}")
    if rig.animation_data is None:
        rig.animation_data_create()
    rig.animation_data.action = action
    bpy.context.scene.frame_set(frame)
    bpy.context.view_layer.update()

    centre, extent = turntable.normalise()
    key = turntable.build_lighting()
    turntable.build_ground(extent)
    turntable.configure_render(size)
    camera = turntable.build_camera()

    radius = extent * 4.0
    azimuth = 35.0
    turntable.aim(camera, centre, azimuth, radius, extent)
    key.rotation_euler = (math.radians(turntable.KEY_ELEVATION_DEGREES), 0.0,
                          math.radians(azimuth + turntable.KEY_OFFSET_DEGREES))

    out_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.context.scene.render.filepath = str(out_path.with_suffix(""))
    bpy.ops.render.render(write_still=True)
    print(f"posed '{action_name}' frame {frame} -> {out_path}")


if __name__ == "__main__":
    main()
