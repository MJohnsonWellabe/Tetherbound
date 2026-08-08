"""Bend a rigged creature into test poses and render what the skin does.

    blender --background --python tools/art_pipeline/blender/pose_test.py \
            -- <rigged.glb> --out <dir>

§13: test extreme but plausible poses and inspect the weights at the joints.
A weight map can be numerically fine (zero unweighted vertices) and still
collapse a shoulder or candy-wrap a neck the moment it bends — the only way to
know is to bend it and look.

Four poses, each targeting the joints §13 names:

  stride   front-left and rear-right legs swung forward, their pair back —
           the walk cycle's extreme, shows shoulder and hip creasing
  look     head yawed 40° and pitched down — neck twist and jaw-line shear
  crouch   spine curled down, legs folded — the dig/hurt silhouette,
           compresses belly and bunches the mantle
  tailflick tail swung hard left — root weighting, and whether the rump
           follows the tail (it must not)

Rendered with the same camera rig as turntable.py so pose renders and rest
renders are comparable side by side.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Vector

FRAME_FILL = 0.78
ELEVATION_DEGREES = 8.0
WORLD_COLOUR = (0.72, 0.73, 0.75, 1.0)
SUN_ENERGY = 1.6

## Rotations in degrees per pose, per bone. Bones missing from a rig are
## skipped with a note rather than failing, so this works on any armature that
## roughly follows rig_quadruped.py's naming.
POSES = {
    "stride": {
        "front_upper_l": ("x", -35), "front_upper_r": ("x", 30),
        "rear_upper_l": ("x", 30), "rear_upper_r": ("x", -35),
        "front_lower_l": ("x", 15), "rear_lower_r": ("x", 15),
    },
    "look": {"neck": ("z", 25), "head": ("z", 20), "head+": ("x", 25)},
    "crouch": {
        "spine": ("x", 18), "neck": ("x", 22), "head": ("x", 15),
        "front_upper_l": ("x", 40), "front_upper_r": ("x", 40),
        "front_lower_l": ("x", -55), "front_lower_r": ("x", -55),
        "rear_upper_l": ("x", 35), "rear_upper_r": ("x", 35),
        "rear_lower_l": ("x", -45), "rear_lower_r": ("x", -45),
    },
    "tailflick": {"tail_1": ("z", 45), "tail_2": ("z", 35)},
}

ANGLES = {"side": 90.0, "three_quarter": 35.0}


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def world_bounds() -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    depsgraph = bpy.context.evaluated_depsgraph_get()
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        for corner in evaluated.bound_box:
            point = evaluated.matrix_world @ Vector(corner)
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
    return low, high


def build_stage() -> None:
    world = bpy.data.worlds.new("flat")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = WORLD_COLOUR
    world.node_tree.nodes["Background"].inputs[1].default_value = 1.0
    bpy.context.scene.world = world

    sun_data = bpy.data.lights.new("key", type="SUN")
    sun_data.energy = SUN_ENERGY
    sun_data.angle = math.radians(30)
    sun = bpy.data.objects.new("key", sun_data)
    sun.rotation_euler = (math.radians(55), 0.0, math.radians(35))
    bpy.context.scene.collection.objects.link(sun)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = scene.render.resolution_y = 768
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"


def apply_pose(rig: bpy.types.Object, pose: dict) -> list[str]:
    bpy.context.view_layer.objects.active = rig
    bpy.ops.object.mode_set(mode="POSE")
    for bone in rig.pose.bones:
        bone.rotation_mode = "XYZ"
        bone.rotation_euler = (0, 0, 0)

    missing = []
    for name, (axis, degrees) in pose.items():
        target = name.rstrip("+")   # "head+" applies a second axis to head
        bone = rig.pose.bones.get(target)
        if bone is None:
            missing.append(target)
            continue
        index = "xyz".index(axis)
        rotation = list(bone.rotation_euler)
        rotation[index] += math.radians(degrees)
        bone.rotation_euler = rotation
    bpy.ops.object.mode_set(mode="OBJECT")
    return missing


def render(camera: bpy.types.Object, out: pathlib.Path) -> None:
    low, high = world_bounds()
    centre = (low + high) / 2
    extent = max(high - low)
    for view, azimuth in ANGLES.items():
        yaw = math.radians(azimuth)
        pitch = math.radians(ELEVATION_DEGREES)
        direction = Vector((math.sin(yaw) * math.cos(pitch),
                            -math.cos(yaw) * math.cos(pitch),
                            math.sin(pitch)))
        camera.location = centre + direction * extent * 4.0
        camera.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
        camera.data.ortho_scale = extent / FRAME_FILL
        bpy.context.scene.render.filepath = str(out) + f"_{view}.png"
        bpy.ops.render.render(write_still=True)


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... pose_test.py -- <rigged.glb> --out <dir>")
    model = pathlib.Path(args[0]).resolve()
    out_dir = pathlib.Path(option(args, "--out", "shots/pose_test")).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(model))
    rigs = [o for o in bpy.data.objects if o.type == "ARMATURE"]
    if not rigs:
        raise SystemExit(f"{model.name} has no armature — nothing to pose")
    rig = rigs[0]

    build_stage()
    camera_data = bpy.data.cameras.new("cam")
    camera_data.type = "ORTHO"
    camera = bpy.data.objects.new("cam", camera_data)
    bpy.context.scene.collection.objects.link(camera)
    bpy.context.scene.camera = camera

    all_missing: set[str] = set()
    for name, pose in POSES.items():
        missing = apply_pose(rig, pose)
        all_missing.update(missing)
        render(camera, out_dir / name)
        print(f"  {name}: rendered")

    if all_missing:
        print(f"  bones not in this rig, skipped: {', '.join(sorted(all_missing))}")
    print(f"\n{len(POSES) * len(ANGLES)} pose renders -> {out_dir}")
    print("  Look for: collapsing shoulders, candy-wrap neck, rump following the")
    print("  tail, belly intersecting the legs in the crouch.")


if __name__ == "__main__":
    main()
