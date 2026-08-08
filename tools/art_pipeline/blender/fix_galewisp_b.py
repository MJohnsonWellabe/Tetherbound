"""The blind critique's fix list for Galewisp candidate b, applied as geometry.

    blender --background --python tools/art_pipeline/blender/fix_galewisp_b.py \
            -- <model.glb> --out <fixed.glb>

Round 1's critique chose b — "the upright stance, talon feet, and wing-wrist
digits carry the most concept DNA" — and ruled its faults mesh-editable:

  1. "The tail is a disaster of volume: a huge ground-dragging fur slug,
     close to a third of total body mass... reduce its volume by roughly
     half, re-curve it into the concept's down-then-up sweep, lift the tip
     clear of the ground."
  2. "Enlarge both ear tufts ~30-40 percent and rake them backward."
  3. The roster-wide warning: "wingspan is roughly half what the reference
     shows... texturing will not fix silhouette." Wings are stretched
     outboard here — the glide is this creature's whole identity.

Leg-thinning toward an exposed tarsus is deliberately skipped: carving a
thin ankle into a thick furry leg with radial falloff math produces a
stovepipe, not a tarsus. Recorded as a known imperfection instead.
"""

import math
import pathlib
import sys

import bpy
from mathutils import Matrix, Vector

TAIL_SHRINK = 0.60         # volume multiplier about the tail's own axis
TAIL_RAISE = 30.0          # degrees up about the root
TAIL_START = 0.15

EAR_SCALE = 1.35
EAR_RAKE = 22.0            # degrees backward about the ear base
EAR_Z = 0.74               # ears live above this fraction of height

WING_STRETCH = 1.38        # outboard lengthening
WING_REACH = 0.45          # beyond this fraction of half-width is wing


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


def bounds(obj) -> tuple[Vector, Vector]:
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


def fix_tail(body) -> int:
    """Shrink, lift, and re-carry the rear mass."""
    low, high = bounds(body)
    size = high - low
    band_top = low.z + size.z * 0.30
    mid_y = (low.y + high.y) / 2

    # Feet from the middle band of length — the tail drags the ground behind
    # them, so rearmost-contact is the tail, not a foot (the Ripplet lesson).
    rear_foot_y = max((body.matrix_world @ v.co).y for v in body.data.vertices
                      if (body.matrix_world @ v.co).z < band_top
                      and mid_y < (body.matrix_world @ v.co).y < low.y + size.y * 0.62)
    overhang = high.y - rear_foot_y
    if overhang < size.y * 0.05:
        print("  no rear overhang; tail edit skipped")
        return 0
    root_y = rear_foot_y + overhang * TAIL_START
    root_z = low.z + size.z * 0.45
    pivot = Vector((0.0, root_y, root_z))

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.y <= root_y:
            continue
        weight = smooth_step((point.y - root_y) / (high.y - root_y + 1e-9))
        # Shrink toward the tail's own centreline first, then lift.
        axis = Vector((0.0, point.y, root_z))
        point = axis + (point - axis) * (1.0 - (1.0 - TAIL_SHRINK) * weight)
        rotation = Matrix.Rotation(math.radians(TAIL_RAISE) * weight, 4, "X")
        point = pivot + rotation @ (point - pivot)
        vert.co = body.matrix_world.inverted() @ point
        touched += 1
    return touched


def fix_ears(body) -> int:
    """Enlarge the ear tufts and rake them backward."""
    low, high = bounds(body)
    size = high - low
    ear_floor = low.z + size.z * EAR_Z
    mid_x = (low.x + high.x) / 2

    sides: dict[bool, list[Vector]] = {True: [], False: []}
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z > ear_floor and abs(point.x - mid_x) > size.x * 0.06:
            sides[point.x < mid_x].append(point)
    if not sides[True] or not sides[False]:
        print("  could not find ear tufts; ear edit skipped")
        return 0
    bases = [Vector((min(p.x for p in side) if left else max(p.x for p in side),
                     sum(p.y for p in side) / len(side),
                     min(p.z for p in side)))
             for left, side in ((True, sides[True]), (False, sides[False]))]
    # Base anchor: the ear's lowest, most inboard point — scale about it so
    # tufts grow up-and-out rather than ballooning into the skull.
    bases[0].x = max(p.x for p in sides[True])
    bases[1].x = min(p.x for p in sides[False])

    touched = 0
    rake = Matrix.Rotation(math.radians(EAR_RAKE), 4, "X")
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        if point.z <= ear_floor or abs(point.x - mid_x) <= size.x * 0.06:
            continue
        base = bases[0] if point.x < mid_x else bases[1]
        height_in_ear = (point.z - ear_floor) / max(high.z - ear_floor, 1e-9)
        weight = smooth_step(height_in_ear)
        point = base + (point - base) * (1.0 + (EAR_SCALE - 1.0) * weight)
        point = base + rake @ (point - base) if weight > 0.05 else point
        vert.co = body.matrix_world.inverted() @ point
        touched += 1
    return touched


def stretch_wings(body) -> int:
    """Lengthen the wings outboard. Span is silhouette; texture cannot add it."""
    low, high = bounds(body)
    size = high - low
    mid_x = (low.x + high.x) / 2
    half = size.x / 2
    reach = half * WING_REACH

    touched = 0
    for vert in body.data.vertices:
        point = body.matrix_world @ vert.co
        outboard = abs(point.x - mid_x) - reach
        if outboard <= 0:
            continue
        weight = smooth_step(outboard / (half - reach + 1e-9))
        sign = 1.0 if point.x > mid_x else -1.0
        point.x += sign * outboard * (WING_STRETCH - 1.0) * (0.4 + 0.6 * weight)
        vert.co = body.matrix_world.inverted() @ point
        touched += 1
    return touched


def main() -> None:
    args = argv_after_double_dash()
    if not args:
        raise SystemExit("usage: ... fix_galewisp_b.py -- <model.glb> --out <fixed.glb>")
    model = pathlib.Path(args[0]).resolve()
    out = pathlib.Path(option(args, "--out", model.with_name("fixed.glb"))).resolve()

    body = load_single_mesh(model)
    print(f"  tail: {fix_tail(body)} verts, {TAIL_SHRINK}x volume, {TAIL_RAISE} deg up")
    print(f"  ears: {fix_ears(body)} verts, {EAR_SCALE}x, raked {EAR_RAKE} deg back")
    print(f"  wings: {stretch_wings(body)} verts, {WING_STRETCH}x outboard")
    print("  legs: deliberately untouched — see module docstring")

    body.data.update()
    out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.object.select_all(action="DESELECT")
    body.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(out), export_format="GLB", use_selection=True)
    print(f"\n-> {out}")


if __name__ == "__main__":
    main()
