"""The blind critique's fix list for Terrapup candidate e, applied as geometry.

    blender --background --python tools/art_pipeline/blender/fix_terrapup_e.py \
            -- <model.glb> --out <fixed.glb>

Round 2's blind critique chose candidate e — "wins on the three things texture
cannot fake: lowest tank-like mass, correct blunt big-head face proportion,
and the only genuinely plate-like mantle" — and ruled its remaining faults
fixable by mesh editing rather than regeneration:

  1. "Forepaws... nearly the same size as the hind paws with stubby,
     half-melted claws" against a concept whose front paws are ~2x the hind.
     Fix: scale the front-paw volumes up ~1.6x in width and depth.
  2. "Tail raised ~45 degrees" where the concept holds it low.
     Fix: rotate the tail region down about its root.
  3. Weak skull crest — noted, and deliberately NOT fixed here. Adding
     credible spike geometry is sculpting, not volume manipulation, and a bad
     crest glued on reads worse than a soft one. Recorded as a known
     imperfection for the texture pass to reinforce and the production report
     to carry.

This is a candidate-specific script and says so in its name. It is committed
anyway because the production report must be able to point at the exact
operation that changed the asset, and because the next quadruped's fix list
will start life as a copy of this one.

Both edits use smooth radial falloff rather than hard selections, so the
blend into the body is a curve and not a crease line.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

## How much wider and deeper the front paws become. The critique asked for
## 1.6-1.8x; starting at the bottom of that range because overshooting turns
## "signature digging paws" into "clown shoes" and a second pass is cheap.
PAW_SCALE = 1.6

## Vertical reach of the paw edit, as a fraction of body height. Covers paw
## and lower forearm so the enlarged paw tapers into the leg instead of
## stepping.
PAW_BAND = 0.30

## Radius of the per-paw falloff sphere, as a fraction of body length.
PAW_RADIUS = 0.16

## Degrees the tail comes down. The critique measured it raised ~45 degrees
## and the concept holds it just below horizontal.
TAIL_DROP = 50.0

## Where the tail begins, as a fraction of the body's rear overhang behind the
## rear legs. Falloff runs from the root (no rotation) to the tip (full).
TAIL_START = 0.25


def argv_after_double_dash() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def option(args: list[str], name: str, default=None):
    return args[args.index(name) + 1] if name in args else default


def load_single_mesh(path: pathlib.Path) -> bpy.types.Object:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(path))
    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    if not meshes:
        raise SystemExit("no mesh in the file")
    bpy.ops.object.select_all(action="DESELECT")
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    if len(meshes) > 1:
        bpy.ops.object.join()
    body = bpy.context.view_layer.objects.active
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return body


def bounds(obj: bpy.types.Object) -> tuple[Vector, Vector]:
    low = Vector((math.inf,) * 3)
    high = Vector((-math.inf,) * 3)
    for corner in obj.bound_box:
        point = obj.matrix_world @ Vector(corner)
        low = Vector(map(min, low, point))
        high = Vector(map(max, high, point))
    return low, high


def smooth_step(t: float) -> float:
    t = max(0.0, min(1.0, t))
    return t * t * (3.0 - 2.0 * t)


def front_paw_centres(body: bpy.types.Object) -> list[Vector]:
    """Centroids of the two front paws: lowest-band vertices, front half,
    split left/right. Same clustering idea rig_quadruped.py trusts."""
    low, high = bounds(body)
    size = high - low
    band_top = low.z + size.z * 0.18
    mid_x = (low.x + high.x) / 2
    mid_y = (low.y + high.y) / 2

    left: list[Vector] = []
    right: list[Vector] = []
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z > band_top or point.y > mid_y:
            continue
        (left if point.x < mid_x else right).append(point)
    if not left or not right:
        raise SystemExit("could not find two front paws in the lowest band")
    return [sum(side, Vector()) / len(side) for side in (left, right)]


def enlarge_front_paws(body: bpy.types.Object) -> int:
    """Scale each front paw about its own centre — x and y outward, z from the
    ground up, so bigger feet stay planted instead of sinking through z=0."""
    low, high = bounds(body)
    size = high - low
    radius = max(size) * PAW_RADIUS
    band_top = low.z + size.z * PAW_BAND
    centres = front_paw_centres(body)

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z > band_top:
            continue
        for centre in centres:
            distance = (Vector((point.x, point.y, 0)) - Vector((centre.x, centre.y, 0))).length
            if distance > radius:
                continue
            # Full effect at the paw's heart, feathered to nothing at the rim
            # and toward the top of the band.
            weight = smooth_step(1.0 - distance / radius)
            weight *= smooth_step((band_top - point.z) / (band_top - low.z + 1e-9))
            factor = 1.0 + (PAW_SCALE - 1.0) * weight
            point.x = centre.x + (point.x - centre.x) * factor
            point.y = centre.y + (point.y - centre.y) * factor
            point.z = low.z + (point.z - low.z) * (1.0 + (PAW_SCALE - 1.0) * 0.35 * weight)
            vert.co = body.matrix_world.inverted() @ point
            touched += 1
            break
    return touched


def lower_tail(body: bpy.types.Object) -> int:
    """Rotate the rear overhang down about the tail root, with falloff.

    The rear legs' y extent marks where the body ends; everything behind it by
    TAIL_START of the overhang is tail. Rotation is about the x axis through
    the root point, weighted 0 at the root to 1 at the tip.
    """
    low, high = bounds(body)
    size = high - low
    band_top = low.z + size.z * 0.25
    mid_y = (low.y + high.y) / 2

    # Rearmost ground contact = back of the rear paws.
    rear_paw_y = max(
        (body.matrix_world @ v.co).y
        for v in body.data.vertices
        if (body.matrix_world @ v.co).z < band_top and (body.matrix_world @ v.co).y > mid_y
    )
    overhang = high.y - rear_paw_y
    if overhang < size.y * 0.03:
        print("  no rear overhang to speak of; tail edit skipped")
        return 0

    root_y = rear_paw_y + overhang * TAIL_START
    root_z = low.z + size.z * 0.55
    pivot = Vector((0.0, root_y, root_z))

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.y <= root_y:
            continue
        weight = smooth_step((point.y - root_y) / (high.y - root_y + 1e-9))
        angle = math.radians(-TAIL_DROP) * weight
        rotation = Matrix.Rotation(angle, 4, "X")
        point = pivot + rotation @ (point - pivot)
        vert.co = body.matrix_world.inverted() @ point
        touched += 1
    return touched


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... fix_terrapup_e.py -- <model.glb> --out <fixed.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("fixed.glb"))).resolve()

    body = load_single_mesh(model)
    paw_verts = enlarge_front_paws(body)
    tail_verts = lower_tail(body)
    body.data.update()

    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)

    print(f"\n{model.name} -> {out.name}")
    print(f"  front paws: {paw_verts} verts scaled {PAW_SCALE}x")
    print(f"  tail: {tail_verts} verts rotated {TAIL_DROP} degrees down")
    print("  crest: deliberately untouched — see module docstring")


if __name__ == "__main__":
    main()
