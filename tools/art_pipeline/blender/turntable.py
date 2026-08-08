"""Render a model from the same four angles as the reference sheets.

    blender --background --python tools/art_pipeline/blender/turntable.py \
            -- <model.glb> --out shots/candidates/terrapup-a [--size 1024]

TETHERBOUND_3D_ART_PIPELINE.md section 9 says to import every candidate,
normalise its scale, put it on a ground plane, use THE SAME orthographic camera
for all of them, and render front, side, back and 3/4 into a comparison folder.

The "same camera" is the entire value. Two candidates photographed from
slightly different angles cannot be compared on proportion, which is the thing
being judged — a longer muzzle and a camera 10 degrees further round look
identical in a still. So nothing here is per-model except the framing distance,
and that is derived from the bounding box by a fixed rule.

The four angles match crop_views.py's output names, so a candidate render and
the concept crop it is being judged against sit side by side by filename.

ORTHOGRAPHIC, deliberately. The reference sheets are drawn flat, with no
perspective convergence. Judging a perspective render against them scores the
lens rather than the creature.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Vector

## Camera angles, as degrees around Z from the model's front. The sheets are
## drawn looking at the creature's front, left side, back, and a 3/4 from its
## front-left — this reproduces that, assuming the model faces -Y (glTF's
## convention after Blender's import axis conversion).
ANGLES = {"front": 0.0, "side": 90.0, "back": 180.0, "three_quarter": 35.0}

## Slight downward tilt. Dead level hides the top of the back — which on
## Terrapup is where the stone mantle lives, and the mantle is the whole
## similarity test for that creature.
ELEVATION_DEGREES = 8.0

## Fraction of the frame the model fills. Below crop_views.py's equivalent
## because the elevation tilt lifts the subject in frame, and a render with the
## feet cut off cannot answer the one question the ground plane is here for.
FRAME_FILL = 0.78

## Flat, neutral, and close to the grey crop_views.py flattens the sheets to, so
## a comparison sheet does not read as two different lighting setups.
##
## Values are chosen to land BELOW clipping. The first version used world
## strength 1.4 over a 0.85 grey, which multiplies to 1.19, and every render
## came back on pure white with the ground plane invisible — so "do the feet
## touch the floor", the question the plane exists to answer, could not be
## asked. Rendering with Standard view transform means there is no filmic
## shoulder to catch an overexposure; the numbers have to be right.
## Darker than feels natural, deliberately. Untextured candidates are near-
## white, and on the original pale stage they rendered at 194-255 luminance —
## a blind critic had to contrast-stretch every frame before it could see the
## form it was asked to judge. A form review that needs post-processing to be
## legible is a broken review.
WORLD_COLOUR = (0.34, 0.35, 0.38, 1.0)
WORLD_STRENGTH = 1.0
SUN_ENERGY = 2.2
GROUND_COLOUR = (0.26, 0.26, 0.29, 1.0)


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load(path: pathlib.Path) -> None:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    suffix = path.suffix.lower()
    if suffix in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=str(path))
    elif suffix == ".fbx":
        bpy.ops.import_scene.fbx(filepath=str(path))
    elif suffix == ".obj":
        bpy.ops.wm.obj_import(filepath=str(path))
    else:
        raise SystemExit(f"unsupported model format: {path.suffix}")


def world_bounds() -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for obj in bpy.data.objects:
        if obj.type != "MESH":
            continue
        for corner in obj.bound_box:
            point = obj.matrix_world @ Vector(corner)
            low = Vector(map(min, low, point))
            high = Vector(map(max, high, point))
    if low.x == math.inf:
        raise SystemExit("model contains no mesh")
    return low, high


def normalise() -> tuple[Vector, float]:
    """Stand the model on z=0, centred in x/y. Returns its centre and size.

    Normalising rather than trusting the file, because a generated asset
    arrives at an arbitrary scale with an arbitrary origin — measured across
    the three creatures already in this project, one was 263 units tall with
    its origin at its middle, one 94 units, and one 3.8 units standing on its
    feet (see pal_body._fit).
    """
    low, high = world_bounds()
    offset = Vector((-(low.x + high.x) / 2, -(low.y + high.y) / 2, -low.z))
    for obj in bpy.data.objects:
        if obj.parent is None:
            obj.location += offset
    bpy.context.view_layer.update()

    low, high = world_bounds()
    size = high - low
    return (low + high) / 2, max(size)


def build_camera() -> bpy.types.Object:
    data = bpy.data.cameras.new("turntable")
    data.type = "ORTHO"
    camera = bpy.data.objects.new("turntable", data)
    bpy.context.scene.collection.objects.link(camera)
    bpy.context.scene.camera = camera
    return camera


def aim(camera: bpy.types.Object, target: Vector, azimuth: float,
        radius: float, extent: float) -> None:
    """Place the camera on a circle around the target, looking at it."""
    yaw = math.radians(azimuth)
    pitch = math.radians(ELEVATION_DEGREES)
    direction = Vector((math.sin(yaw) * math.cos(pitch),
                        -math.cos(yaw) * math.cos(pitch),
                        math.sin(pitch)))
    camera.location = target + direction * radius
    camera.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    camera.data.ortho_scale = extent / FRAME_FILL


def build_lighting() -> None:
    """Flat, even, and boring, so the render shows form rather than lighting.

    A key/fill/rim setup makes every candidate look better and makes them look
    better by different amounts depending on their surface — which is exactly
    the confound to avoid when the question is "which of these is most like the
    drawing". The sheets are lit flat; match them.
    """
    world = bpy.data.worlds.new("flat")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs[0].default_value = WORLD_COLOUR
    world.node_tree.nodes["Background"].inputs[1].default_value = WORLD_STRENGTH
    bpy.context.scene.world = world

    data = bpy.data.lights.new("key", type="SUN")
    data.energy = SUN_ENERGY
    data.angle = math.radians(30)          # soft, so form reads without hard shadow edges
    light = bpy.data.objects.new("key", data)
    light.rotation_euler = (math.radians(55), 0.0, math.radians(35))
    bpy.context.scene.collection.objects.link(light)


def build_ground(extent: float) -> None:
    """A plane at z=0, so feet-not-touching-the-floor is visible rather than inferred.

    Sized far larger than it looks like it needs to be. The camera orbits at
    four times the model's extent, so a plane at six times it ran out before
    the frame did and its far edge cut a diagonal across the 3/4 view — which
    reads as a modelling artefact in an image whose whole job is to show
    modelling artefacts.
    """
    bpy.ops.mesh.primitive_plane_add(size=extent * 40, location=(0, 0, 0))
    plane = bpy.context.active_object
    material = bpy.data.materials.new("ground")
    material.use_nodes = True
    shader = material.node_tree.nodes["Principled BSDF"]
    shader.inputs["Base Color"].default_value = GROUND_COLOUR
    shader.inputs["Roughness"].default_value = 0.9
    plane.data.materials.append(material)


def configure_render(size: int) -> None:
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE_NEXT"
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = False
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "Standard"   # not Filmic: match the flat sheets
    if hasattr(scene, "eevee"):
        scene.eevee.taa_render_samples = 32


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... turntable.py -- <model> --out <dir> [--size N]")

    model = pathlib.Path(args[0]).resolve()
    if not model.exists():
        raise SystemExit(f"no such model: {model}")
    out_dir = pathlib.Path(option(args, "--out", "shots/turntable")).resolve()
    size = int(option(args, "--size", 1024))

    load(model)
    centre, extent = normalise()
    build_lighting()
    build_ground(extent)
    configure_render(size)
    camera = build_camera()

    out_dir.mkdir(parents=True, exist_ok=True)
    radius = extent * 4.0     # ortho, so this only has to clear the model
    for view, azimuth in ANGLES.items():
        aim(camera, centre, azimuth, radius, extent)
        bpy.context.scene.render.filepath = str(out_dir / f"{view}.png")
        bpy.ops.render.render(write_still=True)

    print(f"\n{model.name}: {len(ANGLES)} views -> {out_dir}")
    print(f"  normalised to {extent:.3f} units on its longest axis, standing on z=0")


if __name__ == "__main__":
    main()
